#!/usr/bin/env python
# -*- coding: UTF-8 -*-

# check web.py package
class PackageError(Exception): pass
try:
    import web
except ImportError:
    raise PackageError('need web.py package')

# importing
from settings import *
from utils import *

def main():
   pass 

if __name__ == '__main__':
    main()
