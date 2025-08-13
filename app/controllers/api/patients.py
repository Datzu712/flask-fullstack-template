from flask import Blueprint, request, g

from ...decorators.require_auth import token_required
from ...database.models import Patient
from ...extensions import db

patients_api_bp = Blueprint('patients_api', __name__, url_prefix='/patients')

@patients_api_bp.route('/', methods=['GET'])
@token_required
def get_all_patients():
    patients = db.session.query(Patient).all()
    return {"patients": [patient.to_dict() for patient in patients]}