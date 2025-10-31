import os
import json
import boto3
from botocore.exceptions import ClientError

SES_SENDER_EMAIL = os.environ['SES_SENDER_EMAIL']
ses_client = boto3.client('ses')

def handler(event, context):
    for record in event['Records']:
        try:
            order_data = json.loads(record['body'])
            customer_email = order_data['customer_details']['email']
            order_id = order_data['id']
            amount_total = order_data['amount_total'] / 100 # Chuyển từ cents sang dollars

            print(f"Sending confirmation for order {order_id} to {customer_email}")

            # Gửi email
            ses_client.send_email(
                Source=SES_SENDER_EMAIL,
                Destination={'ToAddresses': [customer_email]},
                Message={
                    'Subject': {'Data': f'Order Confirmation #{order_id}'},
                    'Body': {
                        'Text': {'Data': f'Thank you for your order! Your order ID is {order_id}. Total amount: ${amount_total:.2f}.'}
                    }
                }
            )
            print("Email sent successfully.")

        except (ClientError, KeyError, json.JSONDecodeError) as e:
            print(f"Failed to process message: {record['messageId']}. Error: {e}")
            # Ném lỗi để message được gửi lại hoặc vào DLQ
            raise e
    return {'status': 'success'}

# filepath: aws/terraform-dependencies/lambda-functions/orders/email_processor/requirements.txt
boto3
