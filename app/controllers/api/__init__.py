from flask import  blueprints

from .auth import auth_bp
from .patients import patients_api_bp
from .facilities import facilities_api_bp
from .areas import areas_api_bp
from .doctors import doctors_api_bp
from .rooms import rooms_api_bp
from .users import users_api_bp
from .appointments import appointments_api_bp

api_bp = blueprints.Blueprint('api', __name__, url_prefix='/api')

api_bp.register_blueprint(auth_bp)
api_bp.register_blueprint(patients_api_bp)
api_bp.register_blueprint(facilities_api_bp)
api_bp.register_blueprint(areas_api_bp)
api_bp.register_blueprint(doctors_api_bp)
api_bp.register_blueprint(rooms_api_bp)
api_bp.register_blueprint(users_api_bp)
api_bp.register_blueprint(appointments_api_bp)

