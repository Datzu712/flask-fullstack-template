from flask import Blueprint
import faker
from uuid import uuid4

from ...database.models import Client
from ...extensions import db

dev_bp = Blueprint('dev', __name__, url_prefix='/dev')

@dev_bp.route('/ping', methods=['GET'])
def ping():
    return 'pong'

@dev_bp.route('/faker', methods=['GET'])
def health():
    fake = faker.Faker()

    used_mails = []
    used_names = []

    for _ in range(1000):
        email = fake.email()
        if email in used_mails:
            continue

        name = fake.name()
        if name in used_names:
            continue

        used_mails.append(email)
        used_names.append(name)

        client = Client(
            name=name,
            email=email,
            phone=fake.phone_number(),
            address=fake.address(),
            id=str(uuid4())
        )
        db.session.add(client)

    db.session.commit()
    return 'Faker data generated'