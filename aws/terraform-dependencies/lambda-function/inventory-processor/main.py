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
        log_id = f"{order_id}#inventory#{int(time.time())}"
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

def get_order_details(order_id):
    """Retrieve order details from DynamoDB"""
    try:
        response = orders_table.get_item(Key={'order_id': order_id})
        if 'Item' in response:
            return response['Item']
        else:
            logger.warning(f"Order {order_id} not found in database")
            return None
    except ClientError as e:
        logger.error(f"Error retrieving order {order_id}: {e}")
        raise

def update_inventory_status(order_id, inventory_status, details=None):
    """Update inventory processing status for an order"""
    try:
        update_expression = 'SET inventory_status = :status, inventory_updated_at = :updated_at'
        expression_values = {
            ':status': inventory_status,
            ':updated_at': datetime.utcnow().isoformat()
        }

        if details:
            update_expression += ', inventory_details = :details'
            expression_values[':details'] = details

        response = orders_table.update_item(
            Key={'order_id': order_id},
            UpdateExpression=update_expression,
            ExpressionAttributeValues=expression_values,
            ReturnValues='UPDATED_NEW'
        )

        logger.info(f"Updated inventory status for order {order_id} to {inventory_status}")
        return response['Attributes']

    except ClientError as e:
        logger.error(f"Error updating inventory status: {e}")
        raise

def process_inventory_allocation(order_data):
    """Process inventory allocation for completed order"""
    try:
        order_id = order_data.get('order_id')

        # Get order details if not provided
        if not order_data.get('amount'):
            order_details = get_order_details(order_id)
            if not order_details:
                raise ValueError(f"Order {order_id} not found")
            order_data.update(order_details)

        # Simulate inventory check and allocation
        # In real implementation, this would integrate with inventory management system
        inventory_items = []

        # Parse order metadata for product information
        metadata = order_data.get('metadata', {})
        line_items = order_data.get('line_items', [])

        # Simulate inventory processing based on order amount
        amount = float(order_data.get('amount', 0))
        if isinstance(amount, Decimal):
            amount = float(amount)

        # Simple inventory logic based on order value
        if amount > 0:
            # Simulate inventory allocation
            allocated_items = {
                'total_items': max(1, int(amount / 1000)),  # Assume $10 per item
                'allocation_method': 'fifo',
                'warehouse_location': 'US-EAST-1',
                'estimated_ship_date': datetime.utcnow().isoformat(),
                'tracking_number': f"TRK{order_id[-8:].upper()}",
                'allocation_timestamp': datetime.utcnow().isoformat()
            }

            # Update order with inventory information
            update_inventory_status(order_id, 'allocated', allocated_items)

            log_processing_event(
                order_id,
                'inventory_allocated',
                'success',
                {
                    'allocated_items': allocated_items,
                    'allocation_method': 'automatic'
                }
            )

            logger.info(f"Successfully allocated inventory for order {order_id}")
            return allocated_items
        else:
            raise ValueError("Invalid order amount for inventory allocation")

    except Exception as e:
        logger.error(f"Error processing inventory allocation: {e}")

        # Update status to failed
        update_inventory_status(order_id, 'failed', {'error': str(e)})

        log_processing_event(
            order_id,
            'inventory_allocation_failed',
            'failed',
            {'error': str(e)}
        )
        raise

def process_inventory_cancellation(order_data):
    """Process inventory cancellation for cancelled/failed orders"""
    try:
        order_id = order_data.get('order_id')

        # Check if inventory was previously allocated
        order_details = get_order_details(order_id)
        if order_details and order_details.get('inventory_status') == 'allocated':

            # Simulate inventory deallocation
            cancellation_details = {
                'cancelled_at': datetime.utcnow().isoformat(),
                'cancellation_reason': 'order_cancelled',
                'inventory_returned': True,
                'refund_eligible': True
            }

            # Update inventory status
            update_inventory_status(order_id, 'cancelled', cancellation_details)

            log_processing_event(
                order_id,
                'inventory_cancelled',
                'success',
                cancellation_details
            )

            logger.info(f"Successfully cancelled inventory allocation for order {order_id}")
            return cancellation_details
        else:
            logger.info(f"No inventory allocation found for order {order_id}, skipping cancellation")
            return {'status': 'no_allocation_found'}

    except Exception as e:
        logger.error(f"Error processing inventory cancellation: {e}")

        log_processing_event(
            order_id,
            'inventory_cancellation_failed',
            'failed',
            {'error': str(e)}
        )
        raise

def process_inventory_update(order_data):
    """Process general inventory updates"""
    try:
        order_id = order_data.get('order_id')

        # Update inventory status to processing
        update_details = {
            'processing_started_at': datetime.utcnow().isoformat(),
            'status': 'processing',
            'queue_position': 1  # Could be calculated based on order priority
        }

        update_inventory_status(order_id, 'processing', update_details)

        log_processing_event(
            order_id,
            'inventory_processing_started',
            'success',
            update_details
        )

        logger.info(f"Started inventory processing for order {order_id}")
        return update_details

    except Exception as e:
        logger.error(f"Error processing inventory update: {e}")

        log_processing_event(
            order_id,
            'inventory_update_failed',
            'failed',
            {'error': str(e)}
        )
        raise

def handler(event, context):
    """Process SQS messages for inventory management"""
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

                logger.info(f"Processing inventory operation for order {order_id}, event: {event_type}")

                if event_type == 'order_completed':
                    process_inventory_allocation(order_data)
                elif event_type == 'order_cancelled':
                    process_inventory_cancellation(order_data)
                elif event_type == 'order_processing':
                    process_inventory_update(order_data)
                else:
                    logger.warning(f"Unhandled event type for inventory: {event_type}")
                    continue

                processed_count += 1

            except Exception as e:
                logger.error(f"Error processing inventory record: {str(e)}")
                failed_count += 1

        logger.info(f"Inventory processing complete. Processed: {processed_count}, Failed: {failed_count}")

        return {
            'statusCode': 200,
            'body': json.dumps({
                'processed': processed_count,
                'failed': failed_count
            })
        }

    except Exception as e:
        logger.error(f"Error in inventory processor: {str(e)}")
        raise
