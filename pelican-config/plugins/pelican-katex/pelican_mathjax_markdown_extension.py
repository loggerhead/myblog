# -*- coding: utf-8 -*-
"""
Pelican Mathjax Markdown Extension
==================================
An extension for the Python Markdown module that enables
the Pelican python blog to process mathjax. This extension
gives Pelican the ability to use Mathjax as a "first class
citizen" of the blog
"""

import markdown

from markdown.util import etree
from markdown.util import AtomicString

class PelicanMathJaxPattern(markdown.inlinepatterns.Pattern):
    """Inline markdown processing that matches mathjax"""

    def __init__(self, pelican_mathjax_extension, tag, pattern):
        super(PelicanMathJaxPattern,self).__init__(pattern)
        self.math_tag_class = pelican_mathjax_extension.getConfig('math_tag_class')
        self.pelican_mathjax_extension = pelican_mathjax_extension
        self.tag = tag

    def handleMatch(self, m):
        node = markdown.util.etree.Element(self.tag)
        node.set('class', self.math_tag_class)
        node.text = markdown.util.AtomicString(m.group('math'))
        return node

class PelicanMathJaxCorrectDisplayMath(markdown.treeprocessors.Treeprocessor):
    """Corrects invalid html that results from a <div> being put inside
    a <p> for displayed math"""

    def __init__(self, pelican_mathjax_extension):
        self.pelican_mathjax_extension = pelican_mathjax_extension

    def correct_html(self, root, children, div_math, insert_idx, text):
        """Separates out <div class="math"> from the parent tag <p>. Anything
        in between is put into its own parent tag of <p>"""

        current_idx = 0

        for idx in div_math:
            el = markdown.util.etree.Element('p')
            el.text = text
            el.extend(children[current_idx:idx])

            # Test to ensure that empty <p> is not inserted
            if len(el) != 0 or (el.text and not el.text.isspace()):
               root.insert(insert_idx, el)
               insert_idx += 1

            text = children[idx].tail
            children[idx].tail = None
            root.insert(insert_idx, children[idx])
            insert_idx += 1
            current_idx = idx+1

        el = markdown.util.etree.Element('p')
        el.text = text
        el.extend(children[current_idx:])

        if len(el) != 0 or (el.text and not el.text.isspace()):
            root.insert(insert_idx, el)

    def run(self, root):
        """Searches for <div class="math"> that are children in <p> tags and corrects
        the invalid HTML that results"""

        math_tag_class = self.pelican_mathjax_extension.getConfig('math_tag_class')

        for parent in root:
            div_math = []
            children = list(parent)

            for div in parent.findall('div'):
                if div.get('class') == math_tag_class:
                    div_math.append(children.index(div))

            # Do not process further if no displayed math has been found
            if not div_math:
                continue

            insert_idx = list(root).index(parent)
            self.correct_html(root, children, div_math, insert_idx, parent.text)
            root.remove(parent)  # Parent must be removed last for correct insertion index

        return root

class PelicanMathJaxExtension(markdown.Extension):
    """A markdown extension enabling mathjax processing in Markdown for Pelican"""
    def __init__(self, config):
        # Needed for markdown versions >= 2.5
        self.config['math_tag_class'] = ['math', 'The class of the tag in which mathematics is wrapped']
        super(PelicanMathJaxExtension,self).__init__(**config)
        # Used as a flag to determine if javascript
        # needs to be injected into a document
        self.mathjax_needed = False

    def extendMarkdown(self, md, md_globals):
        # Regex to detect mathjax
        mathjax_inline_regex = r'(?P<prefix>\$)(?P<math>.+?)(?P<suffix>(?<!\s)\2)'
        mathjax_display_regex = r'(?P<prefix>\$\$|\\begin\{(.+?)\})(?P<math>.+?)(?P<suffix>\2|\\end\{\3\})'

        # Process mathjax before escapes are processed since escape processing will
        # intefer with mathjax. The order in which the displayed and inlined math
        # is registered below matters
        md.inlinePatterns.add('mathjax_displayed', PelicanMathJaxPattern(self, 'div', mathjax_display_regex), '<escape')
        md.inlinePatterns.add('mathjax_inlined', PelicanMathJaxPattern(self, 'span', mathjax_inline_regex), '<escape')

        # Correct the invalid HTML that results from teh displayed math (<div> tag within a <p> tag)
        md.treeprocessors.add('mathjax_correctdisplayedmath', PelicanMathJaxCorrectDisplayMath(self), '>inline')
