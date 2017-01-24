#!/usr/bin/env python
import os
import sys
import hmac
import hashlib
import logging
import subprocess
from flask import Flask, request

app = Flask(__name__)
WORKDIR = os.path.dirname(os.path.realpath(__file__))
UPDATE_URL = os.environ['BLOG_UPDATE_URL']
WEBHOOK_TOKEN = str.encode(os.environ['BLOG_WEBHOOK_TOKEN'])


def secure_compare(s1, s2):
    result = len(s1) == len(s2)
    for x, y in zip(s1, s2):
        result = result and (x == y)
    return result


def validate_gtihub_webhook(request):
    sha_name, signature = request.headers['X-Hub-Signature'].split('=')
    if sha_name != 'sha1':
        return False
    mac = hmac.new(WEBHOOK_TOKEN, msg=request.data, digestmod=hashlib.sha1)
    return secure_compare(mac.hexdigest(), signature)


def validate_coding_webhook(request):
    token = request.get_json()['token']
    return secure_compare(token, WEBHOOK_TOKEN)


def validate_webhook(request):
    user_agent = request.headers.get('User-Agent', '').lower()
    try:
        if 'github' in user_agent:
            return validate_gtihub_webhook(request)
        if 'coding' in user_agent:
            return validate_coding_webhook(request)
    except (KeyError, RuntimeError):
        pass
    return False


@app.route(UPDATE_URL, methods=['POST'])
def update_blog():
    if validate_webhook(request):
        if subprocess.call([os.path.join(WORKDIR, 'update_blog.sh')]) == 0:
            app.logger.info("update success")
            return "update success"
        else:
            app.logger.error("update failed")
            return "update failed"
    else:
        app.logger.info("auth failed")
        return ('auth failed', 403)


# used for debug
@app.route('/')
def index():
    return ('OK', 204)


if __name__ == '__main__':
    print("update url: {}".format(UPDATE_URL))
    handler = logging.StreamHandler(sys.stdout)
    handler.setLevel(logging.INFO)
    app.logger.addHandler(handler)
    app.logger.setLevel(logging.INFO)
    app.run(host='127.0.0.1', port=8888)

