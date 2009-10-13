'''
settings for program
'''

__all__ = ['cfg']

import web
import os

cfg = web.storage()
cfg.run_path = os.path.dirname(os.path.abspath(__file__)) + os.path.sep

cfg.db = web.storage(
    dbn = 'mysql',
    host = 'localhost',
    port = 3306,
    db = 'iredadmin',
    user = 'iredadmin',
    passwd = 'secret_passwd'
)

