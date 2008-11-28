#!/usr/bin/env python
# encoding: utf-8

# Author: Zhang Huangbin <michaelbibby (at) gmail.com>

from distutils.core import setup
from babel.messages.frontend import (compile_catalog,
        extract_messages, init_catalog, update_catalog)

args = {
        'name': 'iRedAdmin',
        'version': '0.0.1',
        'author': 'Zhang Huangbin',
        'author_email': 'michaelbibby@gmail.com',
        'cmdclass': {
            'compile_catalog': compile_catalog,
            'extract_messages': extract_messages,
            'init_catalog': init_catalog,
            'update_catalog': update_catalog,
        },
        }

setup(**args)
