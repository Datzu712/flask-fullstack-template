from flask import Blueprint, request
from json import dumps
from sqlalchemy.exc import SQLAlchemyError
import logging
from datetime import datetime
from sqlalchemy import text

from ...decorators.require_auth import token_required
from ...database.models import Facility
from ...extensions import db

facilities_api_bp = Blueprint('facilities_api', __name__, url_prefix='/facilities')
logger = logging.getLogger(__name__)

@facilities_api_bp.route('/', methods=['GET'])
@token_required
def get_all():
    try:
        facilities = db.session.query(Facility).filter(Facility.deleted_at.is_(None)).all()
        return {"data": [facility.as_dict() for facility in facilities]}
    except SQLAlchemyError as e:
        logger.error(f"Database error in get_all_facilities: {str(e)}")
        return dumps({'message': 'Internal server error'}), 500

@facilities_api_bp.route('/', methods=['POST'])
@token_required
def create():
    try:
        next_id = db.session.execute(
            text('SELECT MAX(id) FROM FACILITY')
        ).scalar() or 0
        
        data = request.get_json()
        
        facility = Facility(
            name=data['name'],
            description=data['description'],
            id=next_id+1
        )

        already_exists = db.session.query(Facility).filter(
            Facility.name == facility.name
        ).first()
        if already_exists:
            return dumps({'message': 'Facility already exists'}), 400

        db.session.add(facility)
        db.session.commit()
        
        return dumps(facility.as_dict())
    except KeyError as e:
        return dumps({'message': 'Missing required fields'}), 400
    except SQLAlchemyError as e:
        db.session.rollback()
        logger.error(f"Database error in create_facility: {str(e)}")
        return dumps({'message': 'Internal server error'}), 500

@facilities_api_bp.route('/<int:facility_id>', methods=['GET'])
@token_required
def get_one(facility_id):
    try:
        facility = db.session.query(Facility).filter(Facility.id == facility_id).first()
        
        if not facility:
            return dumps({'message': 'Facility not found'}), 404
            
        return dumps(facility.as_dict())
    except SQLAlchemyError as e:
        logger.error(f"Database error in get_facility {facility_id}: {str(e)}")
        return dumps({'message': 'Internal server error'}), 500

@facilities_api_bp.route('/<int:facility_id>', methods=['PATCH'])
@token_required
def update(facility_id):
    try:
        data = request.get_json()
        facility = db.session.query(Facility).filter(Facility.id == facility_id).first()

        if not facility:
            return dumps({'message': 'Facility not found'}), 404

        if 'name' in data:
            # Check if new name doesn't conflict with existing facilities
            existing = db.session.query(Facility).filter(
                Facility.name == data['name'],
                Facility.id != facility_id
            ).first()
            if existing:
                return dumps({'message': 'Facility name already exists'}), 400
            facility.name = data['name']

        if 'description' in data:
            facility.description = data['description']

        facility.updated_at = datetime.now()
        db.session.commit()
        return dumps(facility.as_dict())
    except SQLAlchemyError as e:
        db.session.rollback()
        logger.error(f"Database error in update_facility {facility_id}: {str(e)}")
        return dumps({'message': 'Internal server error'}), 500

@facilities_api_bp.route('/<int:facility_id>', methods=['DELETE'])
@token_required
def delete(facility_id):
    try:
        facility = db.session.query(Facility).filter(Facility.id == facility_id).first()

        if not facility:
            return dumps({'message': 'Facility not found'}), 404
        
        facility.deleted_at = datetime.now()
        db.session.commit()

        return {'message': 'Facility deleted successfully'}
    except SQLAlchemyError as e:
        db.session.rollback()
        logger.error(f"Database error in delete_facility {facility_id}: {str(e)}")
        return dumps({'message': 'Internal server error'}), 500