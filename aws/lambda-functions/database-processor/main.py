import json
import boto3
import os
from datetime import datetime
import logging
from decimal import Decimal
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb')

# Environment variables
ORDERS_TABLE_NAME = os.environ['ORDERS_TABLE']
PROCESSING_LOGS_TABLE_NAME = os.environ['PROCESSING_LOGS_TABLE']

# DynamoDB tables
orders_table = dynamodb.Table(ORDERS_TABLE_NAME)
logs_table = dynamodb.Table(PROCESSING_LOGS_TABLE_NAME)

def log_processing_event(order_id, event_type, status, details=None):
    """Log processing events to DynamoDB"""
    try:
        import time
        log_id = f"{order_id}#database#{int(time.time())}"
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

def update_order_status(order_data, status):
    """Update order status in DynamoDB"""
    try:
        order_id = order_data.get('order_id')
        if not order_id:
            raise ValueError("Missing order_id in order data")

        # Convert float to Decimal for DynamoDB
        amount = order_data.get('amount', 0)
        if isinstance(amount, float):
            amount = Decimal(str(amount))

        # Update order with new status
        response = orders_table.update_item(
            Key={'order_id': order_id},
            UpdateExpression='SET #status = :status, updated_at = :updated_at, processing_status = :processing_status',
            ExpressionAttributeNames={
                '#status': 'status'
            },
            ExpressionAttributeValues={
                ':status': status,
                ':updated_at': datetime.utcnow().isoformat(),
                ':processing_status': 'completed' if status == 'processed' else 'failed'
            },
            ReturnValues='ALL_NEW'
        )

        logger.info(f"Updated order {order_id} status to {status}")
        return response['Attributes']

    except ClientError as e:
        logger.error(f"DynamoDB error updating order: {e}")
        raise
    except Exception as e:
        logger.error(f"Error updating order status: {e}")
        raise

def create_order_record(order_data):
    """Create new order record in DynamoDB"""
    try:
        order_id = order_data.get('order_id')
        if not order_id:
            raise ValueError("Missing order_id in order data")

        # Convert float to Decimal for DynamoDB
        amount = order_data.get('amount', 0)
        if isinstance(amount, float):
            amount = Decimal(str(amount))

        # Prepare order item for DynamoDB
        order_item = {
            'order_id': order_id,
            'customer_email': order_data.get('customer_email', ''),
            'amount': amount,
            'currency': order_data.get('currency', 'USD'),
            'status': 'processing',
            'processing_status': 'pending',
            'created_at': datetime.utcnow().isoformat(),
            'updated_at': datetime.utcnow().isoformat(),
            'metadata': order_data.get('metadata', {}),
            'stripe_session_id': order_data.get('stripe_session_id', ''),
            'webhook_timestamp': order_data.get('timestamp', datetime.utcnow().isoformat())
        }

        # Store order in DynamoDB
        orders_table.put_item(Item=order_item)

        logger.info(f"Created order record: {order_id}")
        return order_item

    except ClientError as e:
        logger.error(f"DynamoDB error creating order: {e}")
        raise
    except Exception as e:
        logger.error(f"Error creating order record: {e}")
        raise

def process_order_completion(order_data):
    """Process order completion - update status and add completion data"""
    try:
        order_id = order_data.get('order_id')

        # Check if order exists
        try:
            response = orders_table.get_item(Key={'order_id': order_id})
            if 'Item' not in response:
                # Order doesn't exist, create it
                logger.info(f"Order {order_id} not found, creating new record")
                create_order_record(order_data)

            # Update order status to completed
            updated_order = update_order_status(order_data, 'completed')

            log_processing_event(
                order_id,
                'order_completion',
                'success',
                {
                    'updated_fields': ['status', 'processing_status', 'updated_at'],
                    'final_status': 'completed'
                }
            )

            return updated_order

        except ClientError as e:
            logger.error(f"Error checking/updating order: {e}")
            raise

    except Exception as e:
        logger.error(f"Error processing order completion: {e}")
        raise

def process_order_failure(order_data):
    """Process order failure - update status and log error"""
    try:
        order_id = order_data.get('order_id')
        error = order_data.get('error', 'Unknown error')

        # Update order status to failed
        updated_order = update_order_status(order_data, 'failed')

        # Add error details to order
        orders_table.update_item(
            Key={'order_id': order_id},
            UpdateExpression='SET error_details = :error, error_timestamp = :error_timestamp',
            ExpressionAttributeValues={
                ':error': error,
                ':error_timestamp': datetime.utcnow().isoformat()
            }
        )

        log_processing_event(
            order_id,
            'order_failure',
            'failed',
            {
                'error': error,
                'failure_reason': 'processing_error'
            }
        )

        logger.info(f"Processed order failure for {order_id}: {error}")
        return updated_order

    except Exception as e:
        logger.error(f"Error processing order failure: {e}")
        raise

def handler(event, context):
    """Process SQS messages for database operations"""
    try:
        processed_count = 0
        failed_count = 0

        for record in event['Records']:
            try:
                # Parse SQS message
                message_body = json.loads(record['body'])

                # Handle SNS message format
                if 'Message' in message_body:
                    order_data = json.loads(message_body['Message'])
                else:
                    order_data = message_body

                event_type = order_data.get('event_type')
                order_id = order_data.get('order_id')

                logger.info(f"Processing database operation for order {order_id}, event: {event_type}")

                if event_type == 'order_completed':
                    process_order_completion(order_data)
                elif event_type == 'order_failed':
                    process_order_failure(order_data)
                elif event_type == 'order_processing':
                    # Update status to processing
                    update_order_status(order_data, 'processing')
                    log_processing_event(
                        order_id,
                        'order_status_update',
                        'success',
                        {'new_status': 'processing'}
                    )
                else:
                    logger.warning(f"Unknown event type: {event_type}")
                    continue

                processed_count += 1

            except Exception as e:
                logger.error(f"Error processing record: {str(e)}")
                failed_count += 1

                # Log the failed processing
                if 'order_id' in locals():
                    log_processing_event(
                        order_id,
                        'database_processing_error',
                        'failed',
                        {'error': str(e)}
                    )

        logger.info(f"Database processing complete. Processed: {processed_count}, Failed: {failed_count}")

        return {
            'statusCode': 200,
            'body': json.dumps({
                'processed': processed_count,
                'failed': failed_count
            })
        }

    except Exception as e:
        logger.error(f"Error in database processor: {str(e)}")
        raise
