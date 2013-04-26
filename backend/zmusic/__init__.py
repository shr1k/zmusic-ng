#!/usr/bin/env python

from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager
import os
import sys
import pkgutil

app = Flask(__name__)

base_dir = os.path.dirname(os.path.abspath(__file__))
if os.path.exists(os.path.join(base_dir, 'app.cfg')):
	app.config.from_pyfile(os.path.join(base_dir, 'app.cfg'))
elif os.path.exists(os.path.join(base_dir, '../app.cfg')):
	app.config.from_pyfile(os.path.join(base_dir, '../app.cfg'))
else:
	raise IOError("Could not find app.cfg.")

db = SQLAlchemy(app)

login_manager = LoginManager()
import zmusic.login
login_manager.setup_app(app)

import zmusic.endpoints
