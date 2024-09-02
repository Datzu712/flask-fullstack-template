from flask import blueprints, request, make_response, redirect, url_for, jsonify, session, render_template
from jwt import encode, decode
from os import environ
from uuid import uuid4
from datetime import datetime, timedelta
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

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
    redis_client._redis_client.setex(f'sessions:{user.id}', 1800, token)

    session['access_token'] = token

    return jsonify({'message': 'Logged in successfully'}), 201

@auth_bp.route('/logout', methods=['POST'])
def logout():
    token = session.get('access_token')
    if not token:
        return jsonify({'error': 'Unauthorized'}), 401

    payload = decode(token, environ.get('SECRET_KEY'), algorithms=['HS256'])
    redis_client._redis_client.delete(f'sessions:{payload.get("userId")}')

    session.pop('access_token', None)

    return jsonify({'message': 'Logged out successfully'}), 201

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

@auth_bp.route('/forgot-password', methods=['POST'])
def forgot_password():
    data = request.get_json()
    email = data.get('email')

    user = db.session.query(User).filter(
        User.email == email
    ).first()

    if not user:
        print(f'User with email {email} not found')
        return jsonify({'message': 'If the email is valid, a password reset link will be sent to it'}), 201

    redis_client._redis_client.delete(f'password-reset:{user.id}')

    token = encode(
        { 
            'email': email,
            'userId': user.id,
            'exp': (datetime.now() + timedelta(days=1)).timestamp()
        }, 
        environ.get('SECRET_KEY'), 
        algorithm='HS256'
    )
    redis_client._redis_client.setex(f'password-reset:{user.id}', 86400, token)

    url = environ.get('APP_URL') + url_for('app.auth.reset_password', token=token)

    html_content = render_template(
        '/emails/forgot-pass.html', 
        url=url
    )

    SMTP_SERVER = environ.get('SMTP_SERVER')
    SMTP_PORT = environ.get('SMTP_PORT')
    SMTP_USERNAME = environ.get('SMTP_USERNAME')
    SMTP_PASSWORD = environ.get('SMTP_PASSWORD')
    SMTP_FROM_EMAIL = environ.get('SMTP_FROM_EMAIL')


    message = MIMEMultipart()
    message['From'] = SMTP_FROM_EMAIL
    message['To'] = email
    message['Subject'] = 'Password Reset'
    message.attach(MIMEText(html_content, 'html'))

    with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
        print(f'Sending email to {email}')
        server.starttls()
        server.login(SMTP_USERNAME, SMTP_PASSWORD)
        server.sendmail(SMTP_FROM_EMAIL, email, message.as_string())

    return jsonify({'message': 'If the email is valid, a password reset link will be sent to it'}), 201

@auth_bp.route('/reset-password/<token>', methods=['POST'])
def reset_password(token):
    data = request.get_json()
    password = data.get('password')

    try:
        payload = decode(token, environ.get('SECRET_KEY'), algorithms=['HS256'])
    except:
        return jsonify({'error': 'Invalid token'}), 400

    cached_reset_token = redis_client.get(f'password-reset:{payload.get("userId")}').decode('utf-8')
    if not cached_reset_token or cached_reset_token != token:
        return jsonify({'error': 'Invalid token'}), 400

    user = db.session.query(User).filter(
        User.id == payload.get('userId')
    ).first()

    if not user:
        return jsonify({'error': 'Invalid token'}), 400

    redis_client._redis_client.delete(f'password-reset:{user.id}')

    user.set_password(password)
    db.session.commit()

    return jsonify({'message': 'Password reset successfully'}), 201

