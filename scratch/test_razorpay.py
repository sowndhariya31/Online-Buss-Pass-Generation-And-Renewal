import os
import razorpay
from dotenv import load_dotenv

load_dotenv()

key_id = os.environ.get('RAZORPAY_KEY_ID')
key_secret = os.environ.get('RAZORPAY_KEY_SECRET')

print(f"Key ID: {key_id}")
print(f"Key Secret: {key_secret[:4]}..." if key_secret else "Key Secret: None")

try:
    client = razorpay.Client(auth=(key_id, key_secret))
    order = client.order.create({
        'amount': 28000,
        'currency': 'INR',
        'payment_capture': '1'
    })
    print("Order successfully created! Order Details:")
    print(order)
except Exception as e:
    print(f"Error creating order: {e}")
