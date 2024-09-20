from flask import Blueprint, request, g
from json import dumps
from uuid import uuid4
from sqlalchemy import or_

from ...decorators.require_auth import token_required
from ...extensions import db
from ...database.models import Client, UserClient

clients_api_bp = Blueprint('clients_api', __name__, url_prefix='/clients')

@clients_api_bp.route('/', methods=['POST'])
@token_required
def create():
    data = request.get_json()
    client = Client(
        name=data['name'],
        email=data['email'],
        phone=data['phone'],
        address=data['address'],
        id=str(uuid4())
    )

    already_exists = db.session.query(Client).filter(
        or_(Client.email == client.email, Client.phone == client.phone)
    ).first()
    if already_exists:
        return dumps({'message': 'Client already exists'}), 400

    db.session.add(client)
    db.session.commit()
    db.session.flush()

    relationship = UserClient(
        user_id=g.current_user.id,
        client_id=client.id
    )
    db.session.add(relationship)
    db.session.commit()
    
    return dumps(client.as_dict())

@clients_api_bp.route('/', methods=['GET'])
@token_required
def read():
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

    return dumps(clients)

@clients_api_bp.route('/<client_id>', methods=['PATCH'])
@token_required
def update(client_id):
    data = request.get_json()

    client = None
    if g.current_user.admin:
        client = db.session.query(Client).filter(Client.id == client_id).first()
    else:
        client = db.session.query(Client).join(UserClient).filter(
            UserClient.user_id == g.current_user.id,
            UserClient.client_id == client_id
        ).first()

    if not client:
        return dumps({'message': 'Client not found'}), 404

    client.name = data['name']
    client.email = data['email']
    client.phone = data['phone']
    client.address = data['address']

    db.session.commit()

    return dumps(client.as_dict())

@clients_api_bp.route('/<client_id>', methods=['DELETE'])
@token_required
def delete(client_id):

    client = None
    if g.current_user.admin:
        client = db.session.query(Client).filter(Client.id == client_id).first()
    else:
        client = db.session.query(Client).join(UserClient).filter(
            UserClient.user_id == g.current_user.id,
            UserClient.client_id == client_id
        ).first()

    if not client:
        return dumps({'message': 'Client not found'}), 404
    
    db.session.query(UserClient).filter(UserClient.client_id == client.id).delete()
    db.session.delete(client)
    db.session.commit()

    return dumps(client.as_dict())