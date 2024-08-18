from flask import Blueprint, render_template, g
from json import dumps

from ..decorators.require_auth import token_required
from ..extensions import db
from ..database.models import Client, UserClient

clients_bp = Blueprint('clients', __name__, url_prefix='/clients')

@clients_bp.route('/', methods=['GET'])
@token_required
def view():
    clients = db.session.query(Client)

    if g.current_user.admin:
        clients = clients.all()
    
    else:
        clients = clients.join(UserClient).filter(
            UserClient.user_id == g.current_user.id
        ).all()
        if len(clients) == 0:
            clients = []
        
    clients = [c.as_dict() for c in clients]

    return render_template('views/clients.html', active='clients', data=clients)