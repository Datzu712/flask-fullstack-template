from flask import Blueprint, render_template
import time
from sqlalchemy import text

from ..extensions import db, redis_client
from ..decorators.require_auth import token_required

dashboard_bp = Blueprint('dashboard', __name__, url_prefix='/')

@dashboard_bp.route('/', methods=['GET'])
@token_required
def view():
    # oracle latency
    oracle_start_time = time.time()
    db.session.execute(text('SELECT 1 FROM dual'))
    oracle_end_time = time.time()
    oracle_latency_ms = (oracle_end_time - oracle_start_time) * 1000

    # redis latency
    redis_start_time = time.time()
    redis_client.get('1')
    redis_end_time = time.time()
    redis_latency_ms = (redis_end_time - redis_start_time) * 1000

    return render_template('views/dashboard.html', data = {
        'oracle': oracle_latency_ms,
        'redis': redis_latency_ms,
    }, active='dashboard')
