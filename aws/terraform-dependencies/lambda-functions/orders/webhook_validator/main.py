import os
import json
import boto3
import stripe

# Lấy biến môi trường
SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']
STRIPE_SECRET_NAME = os.environ['STRIPE_SECRET_NAME']

sns_client = boto3.client('sns')
secrets_client = boto3.client('secretsmanager')

# Lấy secret từ Secrets Manager
secret_payload = secrets_client.get_secret_value(SecretId=STRIPE_SECRET_NAME)
# Stripe secret được lưu dưới dạng key 'webhook_secret' trong JSON
STRIPE_WEBHOOK_SECRET = json.loads(secret_payload['SecretString'])['webhook_secret']

def handler(event, context):
    try:
        stripe_signature = event['headers'].get('stripe-signature')
        payload = event['body']

        # Xác thực chữ ký webhook
        stripe_event = stripe.Webhook.construct_event(
            payload=payload, sig_header=stripe_signature, secret=STRIPE_WEBHOOK_SECRET
        )

        # Chỉ xử lý sự kiện 'checkout.session.completed'
        if stripe_event['type'] == 'checkout.session.completed':
            print(f"Processing event: {stripe_event['id']}")

            # Đẩy message vào SNS topic
            response = sns_client.publish(
                TopicArn=SNS_TOPIC_ARN,
                Message=json.dumps(stripe_event['data']['object']),
                MessageStructure='string'
            )
            print(f"Message {response['MessageId']} published to {SNS_TOPIC_ARN}")

        return {
            'statusCode': 200,
            'body': json.dumps({'status': 'success'})
        }

    except stripe.error.SignatureVerificationError as e:
        print(f"Signature verification error: {e}")
        return {'statusCode': 400, 'body': 'Invalid signature'}
    except Exception as e:
        print(f"Error: {e}")
        return {'statusCode': 500, 'body': 'Internal server error'}

# filepath: aws/terraform-dependencies/lambda-functions/orders/webhook_validator/requirements.txt
boto3
stripe
