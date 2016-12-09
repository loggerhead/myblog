#!/usr/bin/env python
import os
import sys
import logging
import subprocess
from flask import Flask
app = Flask(__name__)
workdir = os.path.dirname(os.path.realpath(__file__))

@app.route('/coding/push', methods=['GET', 'POST', 'HEAD'])
def update_blog():
    if subprocess.call([os.path.join(workdir, 'update_blog.sh')]) == 0:
        app.logger.info("update success")
        return "update success"
    else:
        app.logger.error("update failed")
        return "update failed"

@app.route('/')
def index():
    return ('OK', 204)

if __name__ == '__main__':
    handler = logging.StreamHandler(sys.stdout)
    handler.setLevel(logging.INFO)
    app.logger.addHandler(handler)
    app.logger.setLevel(logging.INFO)
    app.run(host='127.0.0.1', port=8888)
