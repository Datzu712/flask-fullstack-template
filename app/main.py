from flask import Flask
from os import path, environ
from sqlalchemy import text
from dotenv import load_dotenv
from flask_minify import Minify
from flask_cors import CORS
import sentry_sdk
from sentry_sdk.integrations.flask import FlaskIntegration

from .controllers import app_bp
from .controllers.api import api_bp
from .extensions import db, redis_client

load_dotenv('.flaskenv')

# import logging
# logging.basicConfig()
# logging.getLogger('sqlalchemy.engine').setLevel(logging.INFO)

def create_app():
    project_path = path.dirname(path.dirname(__file__)) + '/app'

    sentry_dsn = environ.get('SENTRY_DSN')

    if sentry_dsn:
        sentry_sdk.init(
            dsn=sentry_dsn,
            traces_sample_rate=1.0,
            profiles_sample_rate=1.0,
            enable_tracing=True,
            environment=environ.get('FLASK_ENV', 'production'),
            integrations=[FlaskIntegration()]
        )
    else:
        print('Sentry DSN not found. Skipping Sentry initialization')

    app = Flask(
        __name__,
        template_folder=path.join(project_path, 'templates'),
        static_folder=path.join(project_path, 'static'),
        static_url_path='/static',
    )
    CORS(app)

    app.register_blueprint(app_bp)
    app.register_blueprint(api_bp)

    Minify(app=app, html=True, js=True, cssless=True, go=True, static=True)

    app.config['SQLALCHEMY_DATABASE_URI'] = environ.get('oracle_url')
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    app.config['SQLALCHEMY_ENGINE_OPTIONS'] = {
        'pool_pre_ping': True
    }
    app.config['REDIS_URL'] = environ.get('REDIS_URL')
    app.config['SECRET_KEY'] = environ.get('SECRET_KEY')
    app.context_processor(lambda: {
        'APP_ENV': environ.get('FLASK_ENV', 'production')
    })

    db.init_app(app)
    redis_client.init_app(app)
    
    with app.app_context():
        try:
            print('Connecting to Oracle database...')
            db.session.execute(text('SELECT 1 FROM DUAL'))
            print('OracleDB connection successful')

            print('Connecting to Redis...')
            redis_client._redis_client.ping()
            print('Redis connection successful')
        except Exception as e:
            print('Database connection failed ', e)

    return app
