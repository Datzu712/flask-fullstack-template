from flask import Blueprint, render_template

from ..decorators.require_auth import token_required

rooms_bp = Blueprint('rooms', __name__, url_prefix='/rooms')

@rooms_bp.route('/', methods=['GET'])
@token_required
def view():
    return render_template('views/rooms.html', active='rooms')
