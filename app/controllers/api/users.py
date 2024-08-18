from flask import Blueprint, request, g
from json import dumps

from ...decorators.require_auth import token_required
from ...extensions import db
from ...database.models import User, UserClient

user_api_bp = Blueprint('user_api', __name__, url_prefix='/users')

@user_api_bp.route('/<userId>', methods=['DELETE'])
@token_required
def delete(userId):
    if not g.current_user.admin:
        return dumps({'message': 'Unauthorized'}), 403

    user = db.session.query(User).filter(User.id == userId).first()
    if not user:
        return dumps({'message': 'User not found'}), 404

    db.session.query(UserClient).filter(UserClient.user_id == userId).delete()
    db.session.delete(user)  # Cambiado de User a user
    db.session.commit()

    return dumps({'message': 'User deleted'}), 200