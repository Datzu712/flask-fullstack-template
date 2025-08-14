from flask import blueprints

from .auth import auth_bp
from .dashboard import dashboard_bp
from .patients import patients_bp
from .facility import facilities_bp
from .area import areas_bp
from .doctor import doctors_bp
from .rooms import rooms_bp
# from .clients import clients_bp
from .users import users_bp

# App views
app_bp = blueprints.Blueprint('app', __name__, url_prefix='/')

app_bp.register_blueprint(auth_bp)
app_bp.register_blueprint(dashboard_bp)
app_bp.register_blueprint(patients_bp)
app_bp.register_blueprint(facilities_bp)
app_bp.register_blueprint(areas_bp)
app_bp.register_blueprint(doctors_bp)
app_bp.register_blueprint(rooms_bp)
app_bp.register_blueprint(users_bp)

# app_bp.register_blueprint(clients_bp)
