from flask import blueprints, request, make_response, redirect, url_for, jsonify
from jwt import encode, decode
from os import environ
from werkzeug.exceptions import Forbidden
from json import dumps
from datetime import datetime

from ...extensions import db, redis_client
from ...database.models import User

auth_bp = blueprints.Blueprint('auth', __name__, url_prefix='/auth')

@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')

    user = db.session.query(User).filter(
        User.email == email
    ).first()

    if not user or not user.check_password(password):
        return jsonify({'error': 'Invalid email or password'}), 401
    
    token = encode(
        { 
            'email': email,
            'username': user.name,
            'userId': user.id,
            'admin': user.admin,
            'ct': datetime.now().timestamp()
        }, 
        environ.get('SECRET_KEY'), 
        algorithm='HS256'
    )
    redis_client._redis_client.setex(f'sessions:{user.id}', 900, token)

    response = make_response(redirect(url_for('dashboard')))
    response.set_cookie('token', token, httponly=True, secure=True)

    return response
