from flask import Blueprint, render_template

from ..decorators.require_auth import token_required

facilities_bp = Blueprint('facilities', __name__, url_prefix='/facilities')

@facilities_bp.route('/', methods=['GET'])
@token_required
def view():
    return render_template('views/facilities.html', active='facilities')