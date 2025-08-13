from flask import Blueprint, request, g
from json import dumps
from sqlalchemy.exc import SQLAlchemyError
import logging
from datetime import datetime
from sqlalchemy import text

from ...decorators.require_auth import token_required
from ...database.models import Patient
from ...extensions import db

patients_api_bp = Blueprint('patients_api', __name__, url_prefix='/patients')
logger = logging.getLogger(__name__)

@patients_api_bp.route('/', methods=['GET'])
@token_required
def get_all_patients():
    try:
        patients = db.session.query(Patient).filter(Patient.deleted_at.is_(None)).all()
        return {"data": [patient.as_dict() for patient in patients]}
    except SQLAlchemyError as e:
        logger.error(f"Database error in get_all_patients: {str(e)}")
        return dumps({'message': 'Internal server error'}), 500

@patients_api_bp.route('/', methods=['POST'])
@token_required
def create():
    try:
        next_id = db.session.execute(
            text('SELECT MAX(id) FROM PATIENT')
        ).scalar() or 0
        
        data = request.get_json()
        date_of_birth = datetime.strptime(data['date_of_birth'].split('T')[0], '%Y-%m-%d').date()
        
        patient = Patient(
            first_name=data['first_name'],
            last_name=data['last_name'],
            date_of_birth=date_of_birth,
            gender=data['gender'],
            email=data['email'],
            phone=data.get('phone'),
            address=data.get('address'),
            id=next_id+1
        )

        already_exists = db.session.query(Patient).filter(
            Patient.email == patient.email
        ).first()
        if already_exists:
            return dumps({'message': 'Patient already exists'}), 400

        db.session.add(patient)
        db.session.commit()
        
        return dumps(patient.as_dict())
    except KeyError as e:
        return dumps({'message': 'Missing required fields'}), 400
    except SQLAlchemyError as e:
        db.session.rollback()
        logger.error(f"Database error in create_patient: {str(e)}")
        return dumps({'message': 'Internal server error'}), 500

@patients_api_bp.route('/<int:patient_id>', methods=['GET'])
@token_required
def get_one(patient_id):
    try:
        patient = db.session.query(Patient).filter(Patient.id == patient_id).first()
        
        if not patient:
            return dumps({'message': 'Patient not found'}), 404
            
        return dumps(patient.as_dict())
    except SQLAlchemyError as e:
        logger.error(f"Database error in get_patient {patient_id}: {str(e)}")
        return dumps({'message': 'Internal server error'}), 500

@patients_api_bp.route('/<int:patient_id>', methods=['PATCH'])
@token_required
def update(patient_id):
    try:
        data = request.get_json()
        patient = db.session.query(Patient).filter(Patient.id == patient_id).first()
        print(data)

        if not patient:
            return dumps({'message': 'Patient not found'}), 404

        for field in ['first_name', 'last_name', 'date_of_birth', 'gender', 'email', 'phone', 'address']:
            if field in data:
                setattr(patient, field, data[field])

        if data.get('date_of_birth'):
            fixed_date = datetime.strptime(data['date_of_birth'].split('T')[0], '%Y-%m-%d').date()
            patient.date_of_birth = fixed_date
        
        db.session.commit()
        return dumps(patient.as_dict())
    except SQLAlchemyError as e:
        db.session.rollback()
        logger.error(f"Database error in update_patient {patient_id}: {str(e)}")
        return dumps({'message': 'Internal server error'}), 500

@patients_api_bp.route('/<int:patient_id>', methods=['DELETE'])
@token_required
def delete(patient_id):
    try:
        patient = db.session.query(Patient).filter(Patient.id == patient_id).first()

        if not patient:
            return dumps({'message': 'Patient not found'}), 404
        
        patient.deleted_at = datetime.now()
        db.session.commit()

        return {'message': 'Patient deleted successfully'}
    except SQLAlchemyError as e:
        db.session.rollback()
        logger.error(f"Database error in delete_patient {patient_id}: {str(e)}")
        return dumps({'message': 'Internal server error'}), 500