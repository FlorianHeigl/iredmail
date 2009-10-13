#!/usr/bin/env python
# -*- coding: UTF-8 -*-

__all__ = [
    'get_db',
]

from settings import *
import web

def get_db():
    return web.database(**cfg.db)

