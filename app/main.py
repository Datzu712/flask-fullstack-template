from flask import Flask, request, Response
from os import path, environ
from sqlalchemy import text
from dotenv import load_dotenv
from flask_minify import Minify
from flask_cors import CORS
from werkzeug.exceptions import Unauthorized

from .extensions import db, redis_client

load_dotenv('.flaskenv')

def create_app():
    project_path = path.dirname(path.dirname(__file__)) + '/app'

    app = Flask(
        __name__,
        template_folder=path.join(project_path, 'templates'),
        static_folder=path.join(project_path, 'static'),
        static_url_path='/static',
    )
    CORS(app)

    Minify(app=app, html=True, js=True, cssless=True, go=True, static=True)

    app.config['SQLALCHEMY_DATABASE_URI'] = environ.get('MYSQL_URL')
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    app.config['SQLALCHEMY_ENGINE_OPTIONS'] = {
        'pool_pre_ping': True
    }
    app.config['REDIS_URL'] = environ.get('REDIS_URL')

    db.init_app(app)
    redis_client.init_app(app)
    
    with app.app_context():
        try:
            print('Connecting to MySQL database...')
            db.session.execute(text('SELECT 1+1'))
            print('MySQL connection successful')

            print('Connecting to Redis...')
            redis_client._redis_client.ping()
            print('Redis connection successful')
        except Exception as e:
            print('Database connection failed ', e)

    return app
