from flask import Blueprint, render_template

from ..decorators.require_auth import token_required

doctors_bp = Blueprint('doctors', __name__, url_prefix='/doctors')

@doctors_bp.route('/', methods=['GET'])
@token_required
def view():
    return render_template('views/doctors.html', active='doctors')
