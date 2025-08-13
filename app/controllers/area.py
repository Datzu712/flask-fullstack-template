from flask import Blueprint, render_template

from ..decorators.require_auth import token_required

areas_bp = Blueprint('areas', __name__, url_prefix='/areas')

@areas_bp.route('/', methods=['GET'])
@token_required
def view():
    return render_template('views/areas.html', active='areas')
