from flask import Blueprint, render_template, g
from json import dumps
from werkzeug.exceptions import NotFound

from ..decorators.require_auth import token_required
from ..extensions import db
from ..database.models import User

users_bp = Blueprint('users', __name__, url_prefix='/users')

@users_bp.route('/', methods=['GET'])
@token_required
def view():
    if not g.current_user.admin:
        raise NotFound()

    users = db.session.query(User).all()

    return render_template('views/users.html', active='users', data=users)