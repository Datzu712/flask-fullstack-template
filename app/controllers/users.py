from flask import Blueprint, render_template

from ..decorators.require_auth import token_required

users_bp = Blueprint('users', __name__, url_prefix='/users')

@users_bp.route('/', methods=['GET'])
@token_required
def view():
    return render_template('views/users.html', active='users')
