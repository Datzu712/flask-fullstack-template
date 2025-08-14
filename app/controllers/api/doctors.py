from flask import Blueprint, request
from json import dumps
from sqlalchemy.exc import SQLAlchemyError
from datetime import datetime
import logging
from sqlalchemy import text

from ...decorators.require_auth import token_required
from ...database.models import Doctor, Area
from ...extensions import db

doctors_api_bp = Blueprint('doctors_api', __name__, url_prefix='/doctors')
logger = logging.getLogger(__name__)

@doctors_api_bp.route('/', methods=['GET'])
@token_required
def get_all():
    try:
        doctors = db.session.query(Doctor).filter(Doctor.deleted_at.is_(None)).all()
        return {"data": [doctor.as_dict() for doctor in doctors]}
    except SQLAlchemyError as e:
        logger.error(f"Database error in get_all_doctors: {str(e)}")
        return dumps({'message': 'Internal server error'}), 500

@doctors_api_bp.route('/', methods=['POST'])
@token_required
def create():
    try:
        data = request.get_json()
        
        # Check if doctor with same email already exists
        existing_doctor = db.session.query(Doctor).filter(
            Doctor.email == data['email'],
            Doctor.deleted_at.is_(None)
        ).first()
        
        if existing_doctor:
            return dumps({'message': 'A doctor with this email already exists'}), 409
        
        doctor = Doctor(
            first_name=data['first_name'],
            last_name=data['last_name'],
            email=data['email'],
            phone=data.get('phone')  # phone is optional
        )

        # Handle areas assignment if provided
        if 'areas' in data:
            areas = db.session.query(Area).filter(
                Area.id.in_(data['areas']),
                Area.deleted_at.is_(None)
            ).all()
            doctor.areas = areas

        db.session.add(doctor)
        db.session.commit()
        
        return dumps(doctor.as_dict())
    except KeyError as e:
        return dumps({'message': 'Missing required fields'}), 400
    except SQLAlchemyError as e:
        db.session.rollback()
        logger.error(f"Database error in create_doctor: {str(e)}")
        return dumps({'message': 'Internal server error'}), 500

@doctors_api_bp.route('/<int:doctor_id>', methods=['GET'])
@token_required
def get_one(doctor_id):
    try:
        doctor = db.session.query(Doctor).filter(
            Doctor.id == doctor_id,
            Doctor.deleted_at.is_(None)
        ).first()
        
        if not doctor:
            return dumps({'message': 'Doctor not found'}), 404
            
        return dumps(doctor.as_dict())
    except SQLAlchemyError as e:
        logger.error(f"Database error in get_doctor {doctor_id}: {str(e)}")
        return dumps({'message': 'Internal server error'}), 500

@doctors_api_bp.route('/<int:doctor_id>', methods=['PATCH'])
@token_required
def update(doctor_id):
    try:
        data = request.get_json()
        doctor = db.session.query(Doctor).filter(
            Doctor.id == doctor_id,
            Doctor.deleted_at.is_(None)
        ).first()

        if not doctor:
            return dumps({'message': 'Doctor not found'}), 404

        # Check email uniqueness if email is being updated
        if 'email' in data and data['email'] != doctor.email:
            existing = db.session.query(Doctor).filter(
                Doctor.email == data['email'],
                Doctor.id != doctor_id,
                Doctor.deleted_at.is_(None)
            ).first()
            if existing:
                return dumps({'message': 'A doctor with this email already exists'}), 409
                
        if 'first_name' in data:
            doctor.first_name = data['first_name']
            
        if 'last_name' in data:
            doctor.last_name = data['last_name']
            
        if 'email' in data:
            doctor.email = data['email']
            
        if 'phone' in data:
            doctor.phone = data['phone']

        if 'areas' in data:
            areas = db.session.query(Area).filter(
                Area.id.in_(data['areas']),
                Area.deleted_at.is_(None)
            ).all()
            doctor.areas = db.session.query(Area).filter(
                Area.id.in_(data['areas']),
                Area.deleted_at.is_(None)
            ).all()
            if existing:
                return dumps({'message': 'A doctor with this email already exists'}), 409
            doctor.email = data['email']

        if 'first_name' in data:
            doctor.first_name = data['first_name']
        if 'last_name' in data:
            doctor.last_name = data['last_name']
        if 'phone' in data:
            doctor.phone = data['phone']

        # Update areas if provided
        if 'areas' in data:
            areas = db.session.query(Area).filter(
                Area.id.in_(data['areas']),
                Area.deleted_at.is_(None)
            ).all()
            doctor.area = areas

        doctor.updated_at = datetime.now()
        db.session.commit()
        return dumps(doctor.as_dict())
    except SQLAlchemyError as e:
        db.session.rollback()
        logger.error(f"Database error in update_doctor {doctor_id}: {str(e)}")
        return dumps({'message': 'Internal server error'}), 500

@doctors_api_bp.route('/<int:doctor_id>', methods=['DELETE'])
@token_required
def delete(doctor_id):
    try:
        doctor = db.session.query(Doctor).filter(
            Doctor.id == doctor_id,
            Doctor.deleted_at.is_(None)
        ).first()

        if not doctor:
            return dumps({'message': 'Doctor not found'}), 404
        
        doctor.deleted_at = datetime.now()
        db.session.commit()

        return {'message': 'Doctor deleted successfully'}
    except SQLAlchemyError as e:
        db.session.rollback()
        logger.error(f"Database error in delete_doctor {doctor_id}: {str(e)}")
        return dumps({'message': 'Internal server error'}), 500
