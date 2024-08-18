from flask import  blueprints
from os import environ

from .auth import auth_bp
from .clients import clients_api_bp
from .users import user_api_bp

api_bp = blueprints.Blueprint('api', __name__, url_prefix='/api')

api_bp.register_blueprint(auth_bp)
api_bp.register_blueprint(clients_api_bp)
api_bp.register_blueprint(user_api_bp)

if environ.get('FLASK_ENV') == 'development':
    from .dev import dev_bp
    api_bp.register_blueprint(dev_bp)
else:
    print('Skipping dev routes')