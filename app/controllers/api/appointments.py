from flask import Blueprint, request
from json import dumps
from sqlalchemy.exc import SQLAlchemyError
from datetime import datetime
from sqlalchemy import text
import logging

from ...decorators.require_auth import token_required
from ...database.models import Appointment, Patient, Doctor, Room
from ...extensions import db

appointments_api_bp = Blueprint('appointments_api', __name__, url_prefix='/appointments')
logger = logging.getLogger(__name__)

@appointments_api_bp.route('/', methods=['GET'])
@token_required
def get_all():
    try:
        appointments = db.session.query(Appointment).filter(Appointment.status != 'canceled').all()
        return {"data": [appointment.as_dict() for appointment in appointments]}
    except SQLAlchemyError as e:
        logger.error(f"Database error in get_all_appointments: {str(e)}")
        return dumps({'message': 'Internal server error'}), 500

@appointments_api_bp.route('/', methods=['POST'])
@token_required
def create():
    try:
        next_id = db.session.execute(
            text('SELECT MAX(id) FROM APPOINTMENT')
        ).scalar() or 0
        
        data = request.get_json()
        
        # Validate if patient exists
        patient = db.session.query(Patient).filter(
            Patient.id == data['patient_id'],
            Patient.deleted_at.is_(None)
        ).first()
        
        if not patient:
            return dumps({'message': 'Patient not found'}), 404
            
        # Validate if doctor exists
        doctor = db.session.query(Doctor).filter(
            Doctor.id == data['doctor_id'],
            Doctor.deleted_at.is_(None)
        ).first()
        
        if not doctor:
            return dumps({'message': 'Doctor not found'}), 404
            
        # Validate if room exists
        room = db.session.query(Room).filter(
            Room.id == data['room_id'],
            Room.deleted_at.is_(None)
        ).first()
        
        if not room:
            return dumps({'message': 'Room not found'}), 404
        
        appointment = Appointment(
            patient_id=data['patient_id'],
            doctor_id=data['doctor_id'],
            room_id=data['room_id'],
            start_time=datetime.fromisoformat(data['start_time']),
            end_time=datetime.fromisoformat(data['end_time']),
            status=data.get('status', 'scheduled'),
            description=data.get('description', ''),
            id=next_id+1
        )

        # Check for overlapping appointments
        overlapping = db.session.query(Appointment).filter(
            Appointment.doctor_id == appointment.doctor_id,
            Appointment.status != 'canceled',
            # Either start or end time falls within the existing appointment
            ((Appointment.start_time <= appointment.start_time) & (Appointment.end_time > appointment.start_time)) |
            ((Appointment.start_time < appointment.end_time) & (Appointment.end_time >= appointment.end_time)) |
            # Or the new appointment fully contains an existing appointment
            ((Appointment.start_time >= appointment.start_time) & (Appointment.end_time <= appointment.end_time))
        ).first()
        
        if overlapping:
            return dumps({'message': 'Doctor already has an appointment during this time'}), 400
            
        # Also check if the room is already booked
        room_booked = db.session.query(Appointment).filter(
            Appointment.room_id == appointment.room_id,
            Appointment.status != 'canceled',
            # Similar time overlap check
            ((Appointment.start_time <= appointment.start_time) & (Appointment.end_time > appointment.start_time)) |
            ((Appointment.start_time < appointment.end_time) & (Appointment.end_time >= appointment.end_time)) |
            ((Appointment.start_time >= appointment.start_time) & (Appointment.end_time <= appointment.end_time))
        ).first()
        
        if room_booked:
            return dumps({'message': 'Room already booked during this time'}), 400

        db.session.add(appointment)
        db.session.commit()
        
        return dumps(appointment.as_dict())
    except KeyError as e:
        return dumps({'message': f'Missing required fields: {str(e)}'}), 400
    except SQLAlchemyError as e:
        db.session.rollback()
        logger.error(f"Database error in create_appointment: {str(e)}")
        return dumps({'message': 'Internal server error'}), 500

@appointments_api_bp.route('/<int:appointment_id>', methods=['GET'])
@token_required
def get_one(appointment_id):
    try:
        appointment = db.session.query(Appointment).filter(Appointment.id == appointment_id).first()
        
        if not appointment:
            return dumps({'message': 'Appointment not found'}), 404
            
        return dumps(appointment.as_dict())
    except SQLAlchemyError as e:
        logger.error(f"Database error in get_appointment {appointment_id}: {str(e)}")
        return dumps({'message': 'Internal server error'}), 500

@appointments_api_bp.route('/<int:appointment_id>', methods=['PATCH'])
@token_required
def update(appointment_id):
    try:
        data = request.get_json()
        appointment = db.session.query(Appointment).filter(Appointment.id == appointment_id).first()

        if not appointment:
            return dumps({'message': 'Appointment not found'}), 404
            
        # Handle status updates
        if 'status' in data:
            if data['status'] not in ['scheduled', 'confirmed', 'completed', 'canceled']:
                return dumps({'message': 'Invalid status value'}), 400
            appointment.status = data['status']

        # Handle patient update
        if 'patient_id' in data:
            patient = db.session.query(Patient).filter(
                Patient.id == data['patient_id'],
                Patient.deleted_at.is_(None)
            ).first()
            
            if not patient:
                return dumps({'message': 'Patient not found'}), 404
                
            appointment.patient_id = data['patient_id']
            
        # Handle doctor update
        if 'doctor_id' in data:
            doctor = db.session.query(Doctor).filter(
                Doctor.id == data['doctor_id'],
                Doctor.deleted_at.is_(None)
            ).first()
            
            if not doctor:
                return dumps({'message': 'Doctor not found'}), 404
                
            appointment.doctor_id = data['doctor_id']
            
        # Handle room update
        if 'room_id' in data:
            room = db.session.query(Room).filter(
                Room.id == data['room_id'],
                Room.deleted_at.is_(None)
            ).first()
            
            if not room:
                return dumps({'message': 'Room not found'}), 404
                
            appointment.room_id = data['room_id']
            
        # Handle time updates
        time_updated = False
        if 'start_time' in data:
            appointment.start_time = datetime.fromisoformat(data['start_time'])
            time_updated = True
            
        if 'end_time' in data:
            appointment.end_time = datetime.fromisoformat(data['end_time'])
            time_updated = True
            
        if 'description' in data:
            appointment.description = data['description']
            
        # If time was updated, check for conflicts
        if time_updated and appointment.status != 'canceled':
            # Check for overlapping appointments for the doctor
            overlapping = db.session.query(Appointment).filter(
                Appointment.doctor_id == appointment.doctor_id,
                Appointment.id != appointment_id,
                Appointment.status != 'canceled',
                # Time overlap check
                ((Appointment.start_time <= appointment.start_time) & (Appointment.end_time > appointment.start_time)) |
                ((Appointment.start_time < appointment.end_time) & (Appointment.end_time >= appointment.end_time)) |
                ((Appointment.start_time >= appointment.start_time) & (Appointment.end_time <= appointment.end_time))
            ).first()
            
            if overlapping:
                return dumps({'message': 'Doctor already has an appointment during this time'}), 400
                
            # Also check if the room is already booked
            room_booked = db.session.query(Appointment).filter(
                Appointment.room_id == appointment.room_id,
                Appointment.id != appointment_id,
                Appointment.status != 'canceled',
                # Similar time overlap check
                ((Appointment.start_time <= appointment.start_time) & (Appointment.end_time > appointment.start_time)) |
                ((Appointment.start_time < appointment.end_time) & (Appointment.end_time >= appointment.end_time)) |
                ((Appointment.start_time >= appointment.start_time) & (Appointment.end_time <= appointment.end_time))
            ).first()
            
            if room_booked:
                return dumps({'message': 'Room already booked during this time'}), 400

        db.session.commit()
        return dumps(appointment.as_dict())
    except SQLAlchemyError as e:
        db.session.rollback()
        logger.error(f"Database error in update_appointment {appointment_id}: {str(e)}")
        return dumps({'message': 'Internal server error'}), 500

@appointments_api_bp.route('/<int:appointment_id>', methods=['DELETE'])
@token_required
def delete(appointment_id):
    try:
        appointment = db.session.query(Appointment).filter(Appointment.id == appointment_id).first()

        if not appointment:
            return dumps({'message': 'Appointment not found'}), 404
        
        # Instead of hard deleting, we set status to canceled
        appointment.status = 'canceled'
        db.session.commit()

        return {'message': 'Appointment cancelled successfully'}
    except SQLAlchemyError as e:
        db.session.rollback()
        logger.error(f"Database error in delete_appointment {appointment_id}: {str(e)}")
        return dumps({'message': 'Internal server error'}), 500
