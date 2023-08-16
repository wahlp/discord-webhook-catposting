import json
import os
import random
import urllib3

http = urllib3.PoolManager()

def lambda_handler(event, context):
    possible_search_terms = [
        'cat',
        'cat sleep',
        'floppa',
        'bingus',
        'post this cat',
        'cat jinx',
        'cat when the',
        'oh the misery',
        'cat heres the',
        'cat review',
        'cat wrap',
        'cat goober',
        'cat sandwich',
        'this cat is',
        'cat facetime',
        'cat dead chat',
        'ok i pull up',
        'cat insane',
        'cat stare',
        'cat boing'
    ]
    search_term = random.choice(possible_search_terms)

    gif_urls = get(search_term)
    chosen = random.choice(gif_urls)

    send_webhook(chosen)

def get(search_term, limit = 16):
    apikey = os.getenv("TENOR_API_KEY")
    if apikey is None:
        raise Exception('API key is missing')
    
    client_key = "discord webhook daily post"

    r = http.request("GET",
        "https://tenor.googleapis.com/v2/search?q=%s&key=%s&client_key=%s&limit=%s"
        % (search_term, apikey, client_key, limit))

    if r.status != 200:
        raise Exception(f'response returned status code {r.status_code}')
    
    top_8gifs = json.loads(r.data)
    gif_urls = [x['itemurl'] for x in top_8gifs['results']]
    return gif_urls

def send_webhook(content: str):
    url = os.environ['WEBHOOK_URL']
    msg = {
        "username": "cat gif of the day",
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
    # local testing
    lambda_handler(None, None)