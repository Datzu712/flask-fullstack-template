from flask import  blueprints

from .auth import auth_bp
from .patients import patients_api_bp
from .facilities import facilities_api_bp
from .areas import areas_api_bp
from .doctors import doctors_api_bp
from .rooms import rooms_api_bp
# from .clients import clients_api_bp
from .users import user_api_bp

api_bp = blueprints.Blueprint('api', __name__, url_prefix='/api')

api_bp.register_blueprint(auth_bp)
api_bp.register_blueprint(patients_api_bp)
api_bp.register_blueprint(facilities_api_bp)
api_bp.register_blueprint(areas_api_bp)
api_bp.register_blueprint(doctors_api_bp)
api_bp.register_blueprint(rooms_api_bp)
# api_bp.register_blueprint(clients_api_bp)
api_bp.register_blueprint(user_api_bp)


# from .dev import dev_bp
# api_bp.register_blueprint(dev_bp)
