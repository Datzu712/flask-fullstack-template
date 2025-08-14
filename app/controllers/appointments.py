from flask import Blueprint, render_template

from ..decorators.require_auth import token_required

appointments_bp = Blueprint('appointments', __name__, url_prefix='/appointments')

@appointments_bp.route('/', methods=['GET'])
@token_required
def view():
    return render_template('views/appointments.html', active='appointments')
