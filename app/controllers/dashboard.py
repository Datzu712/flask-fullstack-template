from flask import Blueprint, render_template

dashboard_bp = Blueprint('dashboard', __name__, url_prefix='/')

class Dashboard:
    @dashboard_bp.route('/', methods=['GET'])
    @staticmethod
    def view():
        return render_template('views/dashboard.html')