from flask import jsonify, session, g, redirect, request, url_for
from functools import wraps
from os import environ
import jwt
from werkzeug.exceptions import Forbidden

from .extensions import db, redis_client
from .database.models import User

# U can use this function as a middleware to check if the user is authenticated
def is_authenticated():
    token = session.get('access_token')
    if not token:
        return False
    
    try:
        data = jwt.decode(token, environ.get('SECRET_KEY'), algorithms=['HS256'])
        current_user = db.session.query(User).filter_by(id=data['userId']).first()

        if not current_user:
            return False
        
        cached_session = redis_client.get(f'sessions:{current_user.id}').decode('utf-8')
        if not cached_session or cached_session != token:
            return False
        
        g.current_user = current_user
        redis_client.setex(f'sessions:{current_user.id}', 1800, token) # reset token ttl
    except Exception as e:
        print(e)
        return False