import json
import os
import random
import urllib3

http = urllib3.PoolManager()

def lambda_handler(event, context):
    s = f"Hello, your lucky number is {random.randint(0, 99)}"
    send_webhook(s)

def send_webhook(content: str):
    url = os.environ['WEBHOOK_URL']
    msg = {
        "username": "Lucky Number Bot",
        "content": content,
    }

    encoded_msg = json.dumps(msg).encode("utf-8")
    resp = http.request("POST", url, headers={'Content-Type': 'application/json'}, body=encoded_msg)
    print(
        {
            "message": content,
            "status_code": resp.status,
            "response": resp.data,
        }
    )

if __name__ == '__main__':
    send_webhook('testing locally')