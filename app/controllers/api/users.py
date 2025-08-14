from flask import Blueprint, request
from json import dumps
from sqlalchemy.exc import SQLAlchemyError
import logging
from datetime import datetime
from sqlalchemy import text

from ...decorators.require_auth import token_required
from ...database.models import AppUser
from ...extensions import db

users_api_bp = Blueprint('users_api', __name__, url_prefix='/users')
logger = logging.getLogger(__name__)

@users_api_bp.route('/', methods=['GET'])
@token_required
def get_all():
    try:
        users = db.session.query(AppUser).filter(AppUser.deleted_at.is_(None)).all()
        return {"data": [user.as_dict() for user in users]}
    except SQLAlchemyError as e:
        logger.error(f"Database error in get_all_users: {str(e)}")
        return dumps({'message': 'Internal server error'}), 500

@users_api_bp.route('/', methods=['POST'])
@token_required
def create():
    try:
        next_id = db.session.execute(
            text('SELECT MAX(id) FROM APP_USER')
        ).scalar() or 0
        
        data = request.get_json()
        
        user = AppUser(
            username=data['username'],
            email=data['email'],
            role=data.get('role', 'receptionist'),
            is_active=1,
            id=next_id+1
        )
        
        user.set_password(data['password'])

        already_exists = db.session.query(AppUser).filter(
            (AppUser.email == user.email) | (AppUser.username == user.username)
        ).first()
        if already_exists:
            return dumps({'message': 'User already exists'}), 400

        db.session.add(user)
        db.session.commit()
        
        return dumps(user.as_dict())
    except KeyError as e:
        return dumps({'message': 'Missing required fields'}), 400
    except SQLAlchemyError as e:
        db.session.rollback()
        logger.error(f"Database error in create_user: {str(e)}")
        return dumps({'message': 'Internal server error'}), 500

@users_api_bp.route('/<int:user_id>', methods=['GET'])
@token_required
def get_one(user_id):
    try:
        user = db.session.query(AppUser).filter(AppUser.id == user_id).first()
        
        if not user:
            return dumps({'message': 'User not found'}), 404
            
        return dumps(user.as_dict())
    except SQLAlchemyError as e:
        logger.error(f"Database error in get_user {user_id}: {str(e)}")
        return dumps({'message': 'Internal server error'}), 500

@users_api_bp.route('/<int:user_id>', methods=['PATCH'])
@token_required
def update(user_id):
    try:
        data = request.get_json()
        user = db.session.query(AppUser).filter(AppUser.id == user_id).first()

        if not user:
            return dumps({'message': 'User not found'}), 404

        if 'username' in data:
            # Check if new username doesn't conflict with existing users
            existing = db.session.query(AppUser).filter(
                AppUser.username == data['username'],
                AppUser.id != user_id
            ).first()
            if existing:
                return dumps({'message': 'Username already exists'}), 400
            user.username = data['username']

        if 'email' in data:
            # Check if new email doesn't conflict with existing users
            existing = db.session.query(AppUser).filter(
                AppUser.email == data['email'],
                AppUser.id != user_id
            ).first()
            if existing:
                return dumps({'message': 'Email already exists'}), 400
            user.email = data['email']

        if 'role' in data:
            user.role = data['role']

        if 'password' in data:
            user.set_password(data['password'])

        if 'is_active' in data:
            user.is_active = 1 if data['is_active'] else 0

        user.updated_at = datetime.now()
        db.session.commit()
        return dumps(user.as_dict())
    except SQLAlchemyError as e:
        db.session.rollback()
        logger.error(f"Database error in update_user {user_id}: {str(e)}")
        return dumps({'message': 'Internal server error'}), 500

@users_api_bp.route('/<int:user_id>', methods=['DELETE'])
@token_required
def delete(user_id):
    try:
        user = db.session.query(AppUser).filter(AppUser.id == user_id).first()

        if not user:
            return dumps({'message': 'User not found'}), 404
        
        user.deleted_at = datetime.now()
        db.session.commit()

        return {'message': 'User deleted successfully'}
    except SQLAlchemyError as e:
        db.session.rollback()
        logger.error(f"Database error in delete_user {user_id}: {str(e)}")
        return dumps({'message': 'Internal server error'}), 500
