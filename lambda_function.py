import json
import os
import urllib3
from datetime import datetime

http = urllib3.PoolManager()

def lambda_handler(event, context):
    d0 = datetime(2023, 1, 19)
    d1 = datetime.today()
    delta = d1 - d0
    s = f"day {delta.days} of no danielle newjeans gf"
    send_webhook(s)

def send_webhook(content: str):
    url = os.environ['WEBHOOK_URL']
    msg = {
        "username": "tfw no gf",
        "content": content,
        "avatar_url": "https://cdn.discordapp.com/attachments/342727918679490561/1072240877021433856/image.png"
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