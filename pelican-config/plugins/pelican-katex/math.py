# -*- coding: utf-8 -*-
"""
Math Render Plugin for Pelican
==============================
This plugin allows your site to render Math. It uses
the MathJax JavaScript engine.

For markdown, the plugin works by creating a Markdown
extension which is used during the markdown compilation stage.
Math therefore gets treated like a "first class citizen" in Pelican

For reStructuredText, the plugin instructs the rst engine
to output Mathjax for for math.

The mathjax script is automatically inserted into the HTML.

Typogrify Compatibility
-----------------------
This plugin now plays nicely with Typogrify, but it requires
Typogrify version 2.04 or above.

User Settings
-------------
Users are also able to pass a dictionary of settings in the settings file which
will control how the MathJax library renders things. This could be very useful
for template builders that want to adjust the look and feel of the math.
See README for more details.
"""

import os
import sys

from pelican import signals

try:
    from .pelican_mathjax_markdown_extension import PelicanMathJaxExtension
except ImportError as e:
    PelicanMathJaxExtension = None
    print("\nMarkdown is not installed, so math only works in reStructuredText.\n")


def process_settings(pelicanobj):
    return pelicanobj.settings.get('MATH_JAX', {})

def mathjax_for_markdown(pelicanobj, mathjax_settings):
    """Instantiates a customized markdown extension for handling mathjax
    related content"""
    # Create the configuration for the markdown template
    config = {
        'math_tag_class': 'math',
    }

    # Instantiate markdown extension and append it to the current extensions
    try:
        pelicanobj.settings['MD_EXTENSIONS'].append(PelicanMathJaxExtension(config))
    except:
        sys.excepthook(*sys.exc_info())
        sys.stderr.write("\nError - the pelican mathjax markdown extension failed to configure. MathJax is non-functional.\n")
        sys.stderr.flush()

def pelican_init(pelicanobj):
    """Loads the mathjax script according to the settings. Instantiate the Python
    markdown extension, passing in the mathjax script as config parameter
    """
    # Process settings
    mathjax_settings = process_settings(pelicanobj)
    mathjax_for_markdown(pelicanobj, mathjax_settings)

def register():
    """Plugin registration"""
    signals.initialized.connect(pelican_init)