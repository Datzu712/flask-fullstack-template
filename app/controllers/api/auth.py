from flask import blueprints, request, make_response, redirect, url_for, jsonify, session
from jwt import encode, decode
from os import environ
from uuid import uuid4
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

    session['access_token'] = token

    return jsonify({'message': 'Logged in successfully'}), 201

@auth_bp.route('/logout', methods=['POST'])
def logout():
    token = request.cookies.get('token')
    if not token:
        return jsonify({'error': 'Unauthorized'}), 401

    payload = decode(token, environ.get('SECRET_KEY'), algorithms=['HS256'])
    redis_client._redis_client.delete(f'sessions:{payload.get("userId")}')

    response = make_response(redirect(url_for('home')))
    response.delete_cookie('token')

    return response

@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')
    name = data.get('username')

    if db.session.query(User).filter(User.email == email).first():
        return jsonify({'error': 'User already exists'}), 400

    user = User(email=email, name=name)
    user.id = str(uuid4())
    user.set_password(password)
    db.session.add(user)
    db.session.commit()

    return jsonify({'message': 'User created successfully'}), 201