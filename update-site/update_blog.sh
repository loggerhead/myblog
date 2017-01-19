#!/bin/bash

set -e

cd /var/www/blog/output
git fetch origin
git reset --hard origin/master
