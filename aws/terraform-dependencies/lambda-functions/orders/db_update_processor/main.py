import os
import json
import boto3
from decimal import Decimal

ORDERS_TABLE_NAME = os.environ['ORDERS_TABLE_NAME']
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(ORDERS_TABLE_NAME)

def handler(event, context):
    for record in event['Records']:
        try:
            order_data = json.loads(record['body'])
            order_id = order_data['id']

            print(f"Saving order {order_id} to DynamoDB table {ORDERS_TABLE_NAME}")

            # Chuyển đổi float sang Decimal để tương thích với DynamoDB
            item_to_save = json.loads(json.dumps(order_data), parse_float=Decimal)

            # Thêm order_id làm primary key
            item_to_save['order_id'] = order_id
            # Thêm customer_email làm GSI key
            item_to_save['customer_email'] = order_data['customer_details']['email']

            table.put_item(Item=item_to_save)
            print(f"Successfully saved order {order_id}")

        except Exception as e:
            print(f"Failed to process message: {record['messageId']}. Error: {e}")
            raise e
    return {'status': 'success'}

# filepath: aws/terraform-dependencies/lambda-functions/orders/db_update_processor/requirements.txt
boto3
