from flask import Blueprint, render_template, g
from json import dumps

from ..decorators.require_auth import token_required
from ..extensions import db
from ..database.models import Client, UserClient

clients_bp = Blueprint('clients', __name__, url_prefix='/clients')

@clients_bp.route('/', methods=['GET'])
@token_required
def view():
    return render_template('views/clients.html', active='clients')