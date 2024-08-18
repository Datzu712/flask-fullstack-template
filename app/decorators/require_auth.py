from flask import request, jsonify, redirect, url_for
from functools import wraps
from os import environ
import jwt

from ..extensions import db, redis_client
from ..database.models import User

def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.cookies.get('token')
        if not token:
            return redirect(url_for('app.auth.login'))

        try:
            data = jwt.decode(token, environ.get('SECRET_KEY'), algorithms=['HS256'])
            current_user = db.session.query(User).filter_by(id=data['user_id']).first()

            if not current_user:
                return jsonify({ 'message': 'Forbidden' }), 403
            
            cached_session = redis_client.get(f'{current_user.id}:session')
            if not cached_session or cached_session != token:
                return jsonify({ 'message': 'Forbidden' }), 403
            
            # reset token ttl
            redis_client.setex(f'{current_user.id}:session', 900, token)
        except:
            return jsonify({'message': 'Token is invalid!'}), 403

        return f(current_user, *args, **kwargs)
    return decorated