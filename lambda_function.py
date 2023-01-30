import random

def lambda_handler(event, context):
    s = f"Hello, your lucky number is {random.randint(0, 99)}"
    return s
