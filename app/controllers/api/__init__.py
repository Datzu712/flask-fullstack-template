from flask import  blueprints

from .auth import auth_bp

api_bp = blueprints.Blueprint('api', __name__, url_prefix='/api')

api_bp.register_blueprint(auth_bp)