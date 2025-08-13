from flask import Blueprint, render_template

from ..decorators.require_auth import token_required

patients_bp = Blueprint('patients', __name__, url_prefix='/patients')

@patients_bp.route('/', methods=['GET'])
@token_required
def view():
    return render_template('views/patients.html', active='patients')