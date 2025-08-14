from flask import Blueprint, request
from json import dumps
from sqlalchemy.exc import SQLAlchemyError
from datetime import datetime
from sqlalchemy import text

from ...decorators.require_auth import token_required
from ...database.models import Room, Area
from ...extensions import db

rooms_api_bp = Blueprint('rooms_api', __name__, url_prefix='/rooms')

@rooms_api_bp.route('/', methods=['GET'])
@token_required
def get_all():
    try:
        rooms = db.session.query(Room).filter(Room.deleted_at.is_(None)).all()
        return {"data": [room.as_dict() for room in rooms]}
    except SQLAlchemyError as e:
        print(e)
        return dumps({'message': 'Internal server error'}), 500

@rooms_api_bp.route('/', methods=['POST'])
@token_required
def create():
    try:
        next_id = db.session.execute(
            text('SELECT MAX(id) FROM ROOM')
        ).scalar() or 0
        
        data = request.get_json()
        
        # Validate if area exists
        area = db.session.query(Area).filter(
            Area.id == data['area_id'],
            Area.deleted_at.is_(None)
        ).first()
        
        if not area:
            return dumps({'message': 'Area not found'}), 404
        
        room = Room(
            name=data['name'],
            description=data['description'],
            area_id=data['area_id'],
            id=next_id+1
        )

        already_exists = db.session.query(Room).filter(
            Room.name == room.name,
            Room.area_id == room.area_id,
            Room.deleted_at.is_(None)
        ).first()
        
        if already_exists:
            return dumps({'message': 'A room with this name already exists in this area'}), 400

        db.session.add(room)
        db.session.commit()
        
        return dumps(room.as_dict())
    except KeyError as e:
        return dumps({'message': 'Missing required fields'}), 400
    except SQLAlchemyError as e:
        db.session.rollback()
        return dumps({'message': 'Internal server error'}), 500

@rooms_api_bp.route('/<int:room_id>', methods=['GET'])
@token_required
def get_one(room_id):
    try:
        room = db.session.query(Room).filter(Room.id == room_id).first()
        
        if not room:
            return dumps({'message': 'Room not found'}), 404
            
        return dumps(room.as_dict())
    except SQLAlchemyError as e:
        return dumps({'message': 'Internal server error'}), 500

@rooms_api_bp.route('/<int:room_id>', methods=['PATCH'])
@token_required
def update(room_id):
    try:
        data = request.get_json()
        room = db.session.query(Room).filter(Room.id == room_id).first()

        if not room:
            return dumps({'message': 'Room not found'}), 404

        if 'name' in data:
            # Check if new name doesn't conflict with existing rooms in the same area
            existing = db.session.query(Room).filter(
                Room.name == data['name'],
                Room.area_id == room.area_id,
                Room.id != room_id,
                Room.deleted_at.is_(None)
            ).first()
            if existing:
                return dumps({'message': 'A room with this name already exists in this area'}), 400
            room.name = data['name']

        if 'description' in data:
            room.description = data['description']

        if 'area_id' in data:
            area = db.session.query(Area).filter(
                Area.id == data['area_id'],
                Area.deleted_at.is_(None)
            ).first()
            
            if not area:
                return dumps({'message': 'Area not found'}), 404
                
            room.area_id = data['area_id']

        db.session.commit()
        return dumps(room.as_dict())
    except SQLAlchemyError as e:
        db.session.rollback()
        return dumps({'message': 'Internal server error'}), 500

@rooms_api_bp.route('/<int:room_id>', methods=['DELETE'])
@token_required
def delete(room_id):
    try:
        room = db.session.query(Room).filter(Room.id == room_id).first()

        if not room:
            return dumps({'message': 'Room not found'}), 404
        
        room.deleted_at = datetime.now()
        db.session.commit()

        return {'message': 'Room deleted successfully'}
    except SQLAlchemyError as e:
        db.session.rollback()
        return dumps({'message': 'Internal server error'}), 500
