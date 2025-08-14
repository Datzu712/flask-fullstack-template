from flask import Blueprint, g
from json import dumps

from ...decorators.require_auth import token_required
from ...extensions import db
from ...database.models import AppUser

user_api_bp = Blueprint('user_api', __name__, url_prefix='/users')

@user_api_bp.route('/<userId>', methods=['DELETE'])
@token_required
def delete(userId):
    try:
        user = db.session.query(AppUser).filter(AppUser.id == userId).first()
        if not user:
            return dumps({'message': 'User not found'}), 404

        db.session.delete(user)
        db.session.commit()

        return dumps({'message': 'User deleted'}), 200
    except Exception as e:
        db.session.rollback()
        return dumps({'message': 'An error occurred', 'error': str(e)}), 500

@user_api_bp.route('/', methods=['GET'])
@token_required
def list():
    users = db.session.query(AppUser).all()

    return dumps([user.as_dict() for user in users]), 200