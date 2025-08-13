from flask import Blueprint, request
from json import dumps
from sqlalchemy.exc import SQLAlchemyError
from datetime import datetime
from sqlalchemy import text
import logging

from ...decorators.require_auth import token_required
from ...database.models import Area, Facility
from ...extensions import db

areas_api_bp = Blueprint('areas_api', __name__, url_prefix='/areas')
logger = logging.getLogger(__name__)

@areas_api_bp.route('/', methods=['GET'])
@token_required
def get_all():
    try:
        areas = db.session.query(Area).filter(Area.deleted_at.is_(None)).all()
        return {"data": [area.as_dict() for area in areas]}
    except SQLAlchemyError as e:
        logger.error(f"Database error in get_all_areas: {str(e)}")
        return dumps({'message': 'Internal server error'}), 500

@areas_api_bp.route('/', methods=['POST'])
@token_required
def create():
    try:
        next_id = db.session.execute(
            text('SELECT MAX(id) FROM AREA')
        ).scalar() or 0
        
        data = request.get_json()
        
        # Validate if facility exists
        facility = db.session.query(Facility).filter(
            Facility.id == data['facility_id'],
            Facility.deleted_at.is_(None)
        ).first()
        
        if not facility:
            return dumps({'message': 'Facility not found'}), 404
        
        area = Area(
            name=data['name'],
            description=data['description'],
            facility_id=data['facility_id'],
            id=next_id+1
        )

        already_exists = db.session.query(Area).filter(
            Area.name == area.name,
            Area.facility_id == area.facility_id,
            Area.deleted_at.is_(None)
        ).first()
        if already_exists:
            return dumps({'message': 'Area already exists in this facility'}), 400

        db.session.add(area)
        db.session.commit()
        
        return dumps(area.as_dict())
    except KeyError as e:
        return dumps({'message': 'Missing required fields'}), 400
    except SQLAlchemyError as e:
        db.session.rollback()
        logger.error(f"Database error in create_area: {str(e)}")
        return dumps({'message': 'Internal server error'}), 500

@areas_api_bp.route('/<int:area_id>', methods=['GET'])
@token_required
def get_one(area_id):
    try:
        area = db.session.query(Area).filter(Area.id == area_id).first()
        
        if not area:
            return dumps({'message': 'Area not found'}), 404
            
        return dumps(area.as_dict())
    except SQLAlchemyError as e:
        logger.error(f"Database error in get_area {area_id}: {str(e)}")
        return dumps({'message': 'Internal server error'}), 500

@areas_api_bp.route('/<int:area_id>', methods=['PATCH'])
@token_required
def update(area_id):
    try:
        data = request.get_json()
        area = db.session.query(Area).filter(Area.id == area_id).first()

        if not area:
            return dumps({'message': 'Area not found'}), 404

        if 'name' in data:
            # Check if new name doesn't conflict with existing areas in the same facility
            existing = db.session.query(Area).filter(
                Area.name == data['name'],
                Area.facility_id == area.facility_id,
                Area.id != area_id,
                Area.deleted_at.is_(None)
            ).first()
            if existing:
                return dumps({'message': 'Area with this name already exists in this facility'}), 400
            area.name = data['name']

        if 'description' in data:
            area.description = data['description']

        if 'facility_id' in data:
            facility = db.session.query(Facility).filter(
                Facility.id == data['facility_id'],
                Facility.deleted_at.is_(None)
            ).first()
            
            if not facility:
                return dumps({'message': 'Facility not found'}), 404
                
            area.facility_id = data['facility_id']

        area.updated_at = datetime.now()
        db.session.commit()
        return dumps(area.as_dict())
    except SQLAlchemyError as e:
        db.session.rollback()
        logger.error(f"Database error in update_area {area_id}: {str(e)}")
        return dumps({'message': 'Internal server error'}), 500

@areas_api_bp.route('/<int:area_id>', methods=['DELETE'])
@token_required
def delete(area_id):
    try:
        area = db.session.query(Area).filter(Area.id == area_id).first()

        if not area:
            return dumps({'message': 'Area not found'}), 404
        
        area.deleted_at = datetime.now()
        db.session.commit()

        return {'message': 'Area deleted successfully'}
    except SQLAlchemyError as e:
        db.session.rollback()
        logger.error(f"Database error in delete_area {area_id}: {str(e)}")
        return dumps({'message': 'Internal server error'}), 500
