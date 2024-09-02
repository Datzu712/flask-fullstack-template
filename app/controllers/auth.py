from flask import blueprints, render_template
from jwt import decode
from os import environ
from werkzeug.exceptions import NotFound

from ..extensions import redis_client

auth_bp = blueprints.Blueprint('auth', __name__, url_prefix='/auth')

@auth_bp.route('/login', methods=['GET'])
def login():
    return render_template('views/login.html')

@auth_bp.route('/forgot-password', methods=['GET'])
def forgot_password():
    return render_template('views/forgot-password.html')

@auth_bp.route('/singup', methods=['GET'])
def signup():
    return render_template('views/signup.html')

@auth_bp.route('/reset-password/<token>', methods=['GET'])
def reset_password(token):
    try:
        payload = decode(token, environ.get('SECRET_KEY'), algorithms=['HS256'])
        data = redis_client._redis_client.get(f'password-reset:{payload.get("userId")}').decode('utf-8')

        print(data)
        if not data or data != token:
            print('Token not found or expired')
            return NotFound()
    except Exception as e:
        print(e)
        raise NotFound()

    return render_template('views/reset-password.html', token=token)
