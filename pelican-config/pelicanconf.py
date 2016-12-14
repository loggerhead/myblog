#!/usr/bin/env python
# -*- coding: utf-8 -*- #
from __future__ import unicode_literals
import os
import time
import subprocess
from datetime import date

RELATIVE_URLS = True

AUTHOR = 'loggerhead'
SITENAME = "loggerhead's blog"
SITEURL = 'https://loggerhead.me'
DISPLAY_PAGES_ON_MENU = False

ENABLE_GOOGLE_SEARCH = True
GOOGLE_CUSTOM_SEARCH_ID = "005992921674098475959:hyjwdbdoqt8"
ENABLE_GOOGLE_ANALYTICS = False
ENABLE_DUOSHUO = False
DUOSHUO_USER = 'loggerhead'
ENABLE_DISQUS = True
DISQUS_USER = 'loggerhead'
DISQUS_SITENAME = DISQUS_USER
SITE_DESCRIPTION = "loggerhead的个人博客"
GOOGLE_SITE_VERIFICATION_CODE = os.environ['GOOGLE_SITE_VERIFICATION_CODE']

PATH = 'content'
PAGE_URL = '{slug}.html'
PAGE_SAVE_AS = PAGE_URL
ARTICLE_URL = 'posts/{slug}.html'
ARTICLE_SAVE_AS = ARTICLE_URL
TAG_URL = 'tag/{slug}.html'
TAG_SAVE_AS = TAG_URL
TAGS_URL = 'tags/index.html'
TAGS_SAVE_AS = TAGS_URL
AUTHOR_SAVE_AS = ''
AUTHORS_SAVE_AS = ''

DEFAULT_PAGINATION = 10

TIMEZONE = 'Asia/Shanghai'
DEFAULT_LANG = u'zh'

FEED_ALL_ATOM = 'atom.xml'
CATEGORY_FEED_ATOM = None
TRANSLATION_FEED_ATOM = None
AUTHOR_FEED_ATOM = None
AUTHOR_FEED_RSS = None

MENUITEMS = (
    ('首页', 'index.html'),
    ('归档', 'archives.html'),
    ('关于', 'about.html'),
)

SOCIAL = (
    ('GitHub', 'https://github.com/loggerhead'),
    ('HackerRank', 'https://www.hackerrank.com/loggerhead'),
    ('豆瓣', 'https://douban.com/people/loggerhead'),
)

MD_EXTENSIONS = ['toc', 'del_ins', 'tables',
                 'fenced_code', 'codehilite(css_class=highlight, linenums=True)',
                 'extra']

MATH_JAX = {
    'show_menu': False,
    'source': "//cdn.bootcss.com/mathjax/2.6.0/MathJax.js?config=TeX-AMS-MML_HTMLorMML"
}

THEME = "themes/github-fanatic"
subprocess.Popen([os.path.join(THEME, 'static/update_js.sh')])

DATE_FORMATS = {
    'zh': '%Y-%m-%d',
}
DEFAULT_CATEGORY = u'default'
IGNORE_FILES = ['.*', '_*']
TEMPLATE_PAGES = {
    "404.html": "404.html",
}
PAGE_PATHS = ['_pages']
ARTICLE_EXCLUDES = ['_private']
STATIC_PATHS = ['_images']
PUT_AT_ROOT = ['_extra']

# When experimenting with different plugins
# (especially the ones that deal with metadata and content)
# caching may interfere and the changes may not be visible.
# In such cases disable caching
# LOAD_CONTENT_CACHE = False

SUMMARY_MAX_LENGTH   = 255
SUMMARY_BEGIN_MARKER = '<!--- SUMMARY_BEGIN -->'
SUMMARY_END_MARKER   = '<!--- SUMMARY_END -->'

SITEMAP = {
    'format': 'xml',
    'priorities': {
        'articles': 1.0,
        'indexes': 0.5,
        'pages': 0.5,
    },
    'changefreqs': {
        'articles': 'monthly',
        'indexes': 'monthly',
        'pages': 'yearly',
    }
}

PLUGIN_PATHS = ["plugins"]
PLUGINS = [
    # "render_math",
    "pelican-katex",
    "pelican-md-yaml",
    "pelican-summary",
    "sitemap",
    "assets",
    # "minify",
]

################################################################################
def get_theme_file_path(theme_file_path):
    theme_dir = os.path.join(os.path.dirname(__file__), 'output')
    return os.path.join(theme_dir, theme_file_path)

def get_modified_time(theme_file_path):
    return str(int(os.path.getmtime(get_theme_file_path(theme_file_path))))

def sha1(theme_file_path):
    import hashlib
    with open(get_theme_file_path(theme_file_path), 'rb') as f:
        return str(hashlib.sha1(f.read()).hexdigest())

def hash(theme_file_path):
    return sha1(theme_file_path)[:7]

JINJA_FILTERS = {
    'hash': hash,
    'sha1': sha1,
}

CURRENT_YEAR = date.today().year

STATIC_PATHS.extend(PUT_AT_ROOT)

def list_files(dirpath):
    return [os.path.join(dirpath, f) for f in os.listdir(dirpath) if not f.startswith('.')]

EXTRA_PATH_METADATA = {}
for path in PUT_AT_ROOT:
    for file in list_files(os.path.join(PATH, path)):
        EXTRA_PATH_METADATA[file.lstrip(PATH + '/')] = {'path': os.path.basename(file)}
