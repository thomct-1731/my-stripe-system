import json
import boto3
import os
from datetime import datetime
import logging
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
ses_client = boto3.client('ses')
secrets_client = boto3.client('secretsmanager')
dynamodb = boto3.resource('dynamodb')

# Environment variables
EMAIL_CONFIG_SECRET_NAME = os.environ.get('EMAIL_CONFIG_SECRET', '')
PROCESSING_LOGS_TABLE_NAME = os.environ.get('PROCESSING_LOGS_TABLE', '')
SES_SENDER_EMAIL = os.environ.get('SES_SENDER_EMAIL', 'noreply@yourdomain.com')

def get_email_config():
    """Retrieve email configuration from Secrets Manager"""
    if not EMAIL_CONFIG_SECRET_NAME:
        # Return default config if no secret configured
        return {
            'from_email': SES_SENDER_EMAIL,
            'support_email': 'support@yourdomain.com'
        }

    try:
        response = secrets_client.get_secret_value(SecretId=EMAIL_CONFIG_SECRET_NAME)
        return json.loads(response['SecretString'])
    except ClientError as e:
        logger.error(f"Error retrieving email config: {e}")
        # Return default config on error
        return {
            'from_email': SES_SENDER_EMAIL,
            'support_email': 'support@yourdomain.com'
        }

def log_processing_event(order_id, event_type, status, details=None):
    """Log processing events to DynamoDB if table is configured"""
    if not PROCESSING_LOGS_TABLE_NAME:
        return

    try:
        import time
        logs_table = dynamodb.Table(PROCESSING_LOGS_TABLE_NAME)
        log_id = f"{order_id}#email#{int(time.time())}"
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

def send_order_confirmation_email(order_data, email_config):
    """Send order confirmation email via SES"""
    try:
        customer_email = order_data.get('customer_email')
        if not customer_email:
            logger.warning("No customer email found in order data")
            return False

        order_id = order_data.get('order_id')
        amount = order_data.get('amount', 0)
        currency = order_data.get('currency', 'USD').upper()

        # Handle both integer cents and decimal formats
        if isinstance(amount, (int, float)) and amount > 100:
            formatted_amount = f"{amount / 100:.2f} {currency}"
        else:
            formatted_amount = f"{amount:.2f} {currency}"

        subject = f"Order Confirmation - {order_id}"

        # Enhanced HTML email template
        html_body = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>
                body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .header {{ background-color: #f8f9fa; padding: 20px; text-align: center; }}
                .content {{ padding: 20px; background-color: #ffffff; }}
                .order-details {{ background-color: #f8f9fa; padding: 15px; margin: 20px 0; border-radius: 5px; }}
                .footer {{ text-align: center; padding: 20px; font-size: 12px; color: #666; }}
                .success {{ color: #28a745; font-weight: bold; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1 class="success">Order Confirmed!</h1>
                </div>
                <div class="content">
                    <p>Dear Valued Customer,</p>
                    <p>Thank you for your order! We've successfully received your payment and are now processing your order.</p>

                    <div class="order-details">
                        <h3>Order Details:</h3>
                        <ul>
                            <li><strong>Order ID:</strong> {order_id}</li>
                            <li><strong>Amount:</strong> {formatted_amount}</li>
                            <li><strong>Status:</strong> <span class="success">Confirmed & Processing</span></li>
                            <li><strong>Order Date:</strong> {order_data.get('created_at', datetime.utcnow().isoformat())}</li>
                        </ul>
                    </div>

                    <p>What's next?</p>
                    <ul>
                        <li>We'll prepare your order for shipment</li>
                        <li>You'll receive a shipping confirmation with tracking information</li>
                        <li>Your order will be delivered to your specified address</li>
                    </ul>

                    <p>If you have any questions about your order, please don't hesitate to contact our support team.</p>

                    <p>Thank you for choosing us!</p>
                </div>
                <div class="footer">
                    <p>This is an automated message. Please do not reply to this email.</p>
                    <p>For support, contact us at {email_config.get('support_email', 'support@yourdomain.com')}</p>
                </div>
            </div>
        </body>
        </html>
        """

        # Plain text version
        text_body = f"""
        Order Confirmation - Thank You!

        Dear Valued Customer,

        Thank you for your order! We've successfully received your payment and are now processing your order.

        Order Details:
        - Order ID: {order_id}
        - Amount: {formatted_amount}
        - Status: Confirmed & Processing
        - Order Date: {order_data.get('created_at', datetime.utcnow().isoformat())}

        What's next?
        - We'll prepare your order for shipment
        - You'll receive a shipping confirmation with tracking information
        - Your order will be delivered to your specified address

        If you have any questions about your order, please contact our support team at {email_config.get('support_email', 'support@yourdomain.com')}.

        Thank you for choosing us!

        ---
        This is an automated message. Please do not reply to this email.
        """

        # Send email via SES
        response = ses_client.send_email(
            Source=email_config['from_email'],
            Destination={
                'ToAddresses': [customer_email]
            },
            Message={
                'Subject': {
                    'Data': subject,
                    'Charset': 'UTF-8'
                },
                'Body': {
                    'Html': {
                        'Data': html_body,
                        'Charset': 'UTF-8'
                    },
                    'Text': {
                        'Data': text_body,
                        'Charset': 'UTF-8'
                    }
                }
            }
        )

        logger.info(f"Order confirmation email sent to {customer_email}, MessageId: {response['MessageId']}")
        return response['MessageId']

    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == 'MessageRejected':
            logger.error(f"SES rejected email to {customer_email}: {e}")
        elif error_code == 'SendingPausedException':
            logger.error(f"SES sending paused: {e}")
        else:
            logger.error(f"SES error: {e}")
        raise
    except Exception as e:
        logger.error(f"Email sending error: {e}")
        raise

def send_order_failed_email(order_data, email_config):
    """Send order failure notification to support team"""
    try:
        support_email = email_config.get('support_email', 'support@yourdomain.com')
        order_id = order_data.get('order_id')
        error = order_data.get('error', 'Unknown error')

        subject = f"Order Processing Failed - {order_id}"

        body = f"""
        Order Processing Failure Alert

        An order failed to process properly:

        Order ID: {order_id}
        Customer Email: {order_data.get('customer_email', 'N/A')}
        Error: {error}
        Timestamp: {datetime.utcnow().isoformat()}

        Please investigate this issue immediately.
        """

        response = ses_client.send_email(
            Source=email_config['from_email'],
            Destination={
                'ToAddresses': [support_email]
            },
            Message={
                'Subject': {
                    'Data': subject,
                    'Charset': 'UTF-8'
                },
                'Body': {
                    'Text': {
                        'Data': body,
                        'Charset': 'UTF-8'
                    }
                }
            }
        )

        logger.info(f"Failure notification sent to support team, MessageId: {response['MessageId']}")
        return response['MessageId']

    except Exception as e:
        logger.error(f"Failed to send failure notification: {e}")
        raise

def handler(event, context):
    """Process SQS messages for email sending"""
    try:
        # Get email configuration
        email_config = get_email_config()

        processed_count = 0
        failed_count = 0

        for record in event['Records']:
            order_id = None
            try:
                # Parse SQS message
                message_body = json.loads(record['body'])

                # Handle SNS message format
                if 'Message' in message_body:
                    order_data = json.loads(message_body['Message'])
                else:
                    order_data = message_body

                order_id = order_data.get('order_id')
                event_type = order_data.get('event_type')

                logger.info(f"Processing email for order {order_id}, event: {event_type}")

                # Send appropriate email based on event type
                if event_type == 'order_completed':
                    message_id = send_order_confirmation_email(order_data, email_config)

                    log_processing_event(
                        order_id,
                        'email_sent',
                        'success',
                        {
                            'email_type': 'confirmation',
                            'recipient': order_data.get('customer_email'),
                            'ses_message_id': message_id
                        }
                    )

                elif event_type == 'order_failed':
                    message_id = send_order_failed_email(order_data, email_config)

                    log_processing_event(
                        order_id,
                        'failure_notification_sent',
                        'success',
                        {
                            'email_type': 'failure_notification',
                            'recipient': email_config.get('support_email'),
                            'ses_message_id': message_id
                        }
                    )

                else:
                    logger.warning(f"Unhandled event type for email: {event_type}")
                    continue

                processed_count += 1

            except Exception as e:
                logger.error(f"Error processing email record: {str(e)}", exc_info=True)
                failed_count += 1

                # Log the failed processing
                if order_id:
                    log_processing_event(
                        order_id,
                        'email_processing_error',
                        'failed',
                        {'error': str(e)}
                    )

        logger.info(f"Email processing complete. Processed: {processed_count}, Failed: {failed_count}")

        return {
            'statusCode': 200,
            'body': json.dumps({
                'processed': processed_count,
                'failed': failed_count
            })
        }

    except Exception as e:
        logger.error(f"Error in email processor: {str(e)}", exc_info=True)
        raise
