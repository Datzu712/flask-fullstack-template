from flask import blueprints, render_template

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