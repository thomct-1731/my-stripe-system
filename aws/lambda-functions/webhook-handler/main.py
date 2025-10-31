import json
import boto3
import hashlib
import hmac
import os
import time
from datetime import datetime
from botocore.exceptions import ClientError
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
sns_client = boto3.client('sns')
dynamodb = boto3.resource('dynamodb')
secrets_client = boto3.client('secretsmanager')

# Environment variables
SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']
STRIPE_WEBHOOK_SECRET_NAME = os.environ['STRIPE_WEBHOOK_SECRET']
ORDERS_TABLE_NAME = os.environ.get('ORDERS_TABLE', '')
PROCESSING_LOGS_TABLE_NAME = os.environ.get('PROCESSING_LOGS_TABLE', '')

def get_stripe_webhook_secret():
    """Retrieve Stripe webhook secret from Secrets Manager"""
    try:
        response = secrets_client.get_secret_value(SecretId=STRIPE_WEBHOOK_SECRET_NAME)
        secrets_data = json.loads(response['SecretString'])
        return secrets_data['webhook_secret']
    except ClientError as e:
        logger.error(f"Error retrieving secret: {e}")
        raise

def verify_webhook_signature(payload, signature, secret):
    """Verify Stripe webhook signature"""
    try:
        elements = signature.split(',')
        signature_dict = {}

        for element in elements:
            key, value = element.split('=', 1)
            signature_dict[key] = value

        timestamp = signature_dict.get('t')
        signature_hash = signature_dict.get('v1')

        if not timestamp or not signature_hash:
            logger.error("Missing timestamp or signature hash")
            return False

        # Create signed payload
        signed_payload = f"{timestamp}.{payload}"

        # Calculate expected signature
        expected_signature = hmac.new(
            secret.encode('utf-8'),
            signed_payload.encode('utf-8'),
            hashlib.sha256
        ).hexdigest()

        # Compare signatures securely
        return hmac.compare_digest(expected_signature, signature_hash)

    except Exception as e:
        logger.error(f"Error verifying signature: {e}")
        return False

def log_processing_event(order_id, event_type, status, details=None):
    """Log processing events to DynamoDB if table is configured"""
    if not PROCESSING_LOGS_TABLE_NAME:
        return

    try:
        logs_table = dynamodb.Table(PROCESSING_LOGS_TABLE_NAME)
        log_id = f"{order_id}#{event_type}#{int(time.time())}"
        ttl = int(time.time()) + (30 * 24 * 60 * 60)  # 30 days TTL

        item = {
            'log_id': log_id,
            'timestamp': datetime.utcnow().isoformat(),
            'order_id': order_id,
            'event_type': event_type,
            'status': status,
            'ttl': ttl
        }

        if details:
            item['details'] = details

        logs_table.put_item(Item=item)
        logger.info(f"Logged event: {log_id}")
    except Exception as e:
        logger.error(f"Failed to log event: {e}")

def process_stripe_event(event_data):
    """Process Stripe webhook event"""
    event_type = event_data.get('type')
    event_id = event_data.get('id')

    logger.info(f"Processing Stripe event: {event_type} (ID: {event_id})")

    # Process payment success events
    if event_type in ['checkout.session.completed', 'payment_intent.succeeded']:

        if event_type == 'checkout.session.completed':
            session = event_data['data']['object']
            order_id = session['id']
            customer_email = session.get('customer_details', {}).get('email', '')
            amount = session['amount_total']
            currency = session['currency']
        else:  # payment_intent.succeeded
            payment_intent = event_data['data']['object']
            order_id = payment_intent['id']
            customer_email = payment_intent.get('receipt_email', '')
            amount = payment_intent['amount']
            currency = payment_intent['currency']

        # Create order data for SNS
        order_data = {
            'order_id': order_id,
            'customer_email': customer_email,
            'amount': amount,
            'currency': currency,
            'status': 'completed',
            'stripe_event_id': event_id,
            'stripe_event_type': event_type,
            'created_at': datetime.utcnow().isoformat(),
            'metadata': session.get('metadata', {}) if event_type == 'checkout.session.completed'
                       else payment_intent.get('metadata', {})
        }

        try:
            # Store order in DynamoDB if table is configured
            if ORDERS_TABLE_NAME:
                orders_table = dynamodb.Table(ORDERS_TABLE_NAME)

                # Convert amount to Decimal for DynamoDB
                from decimal import Decimal
                db_item = order_data.copy()
                db_item['amount'] = Decimal(str(amount))
                db_item['updated_at'] = datetime.utcnow().isoformat()

                orders_table.put_item(Item=db_item)
                logger.info(f"Stored order in DynamoDB: {order_id}")

            # Log the event
            log_processing_event(
                order_id,
                'webhook_received',
                'success',
                {'stripe_event_type': event_type, 'event_id': event_id}
            )

            # Publish to SNS for further processing
            message = {
                'event_type': 'order_completed',
                **order_data
            }

            response = sns_client.publish(
                TopicArn=SNS_TOPIC_ARN,
                Message=json.dumps(message),
                MessageAttributes={
                    'event_type': {
                        'DataType': 'String',
                        'StringValue': 'order_completed'
                    },
                    'order_id': {
                        'DataType': 'String',
                        'StringValue': order_id
                    }
                }
            )

            logger.info(f"Published SNS message {response['MessageId']} for order: {order_id}")

            return {'status': 'success', 'order_id': order_id, 'message_id': response['MessageId']}

        except Exception as e:
            logger.error(f"Error processing order: {e}")

            # Log the error
            log_processing_event(
                order_id,
                'webhook_processing_error',
                'failed',
                {'error': str(e), 'event_type': event_type}
            )

            # Publish error event
            error_message = {
                'event_type': 'order_failed',
                'order_id': order_id,
                'error': str(e),
                'stripe_event_id': event_id,
                'timestamp': datetime.utcnow().isoformat()
            }

            sns_client.publish(
                TopicArn=SNS_TOPIC_ARN,
                Message=json.dumps(error_message),
                MessageAttributes={
                    'event_type': {
                        'DataType': 'String',
                        'StringValue': 'order_failed'
                    }
                }
            )

            raise
    else:
        logger.info(f"Unhandled event type: {event_type}")
        return {'status': 'ignored', 'event_type': event_type}

def handler(event, context):
    """Main Lambda handler for API Gateway"""
    try:
        # Parse API Gateway event
        body = event.get('body', '')
        headers = event.get('headers', {})

        # Handle case-insensitive headers
        stripe_signature = None
        for key, value in headers.items():
            if key.lower() == 'stripe-signature':
                stripe_signature = value
                break

        if not stripe_signature:
            logger.error("Missing Stripe signature")
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json'
                },
                'body': json.dumps({'error': 'Missing Stripe signature'})
            }

        # Verify webhook signature
        webhook_secret = get_stripe_webhook_secret()
        if not verify_webhook_signature(body, stripe_signature, webhook_secret):
            logger.error("Invalid Stripe signature")
            return {
                'statusCode': 401,
                'headers': {
                    'Content-Type': 'application/json'
                },
                'body': json.dumps({'error': 'Invalid signature'})
            }

        # Parse event data
        try:
            event_data = json.loads(body)
        except json.JSONDecodeError as e:
            logger.error(f"Invalid JSON payload: {e}")
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json'
                },
                'body': json.dumps({'error': 'Invalid JSON payload'})
            }

        # Process the event
        result = process_stripe_event(event_data)

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json'
            },
            'body': json.dumps({
                'message': 'Webhook processed successfully',
                'result': result
            })
        }

    except Exception as e:
        logger.error(f"Webhook handler error: {e}", exc_info=True)
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json'
            },
            'body': json.dumps({'error': 'Internal server error'})
        }
