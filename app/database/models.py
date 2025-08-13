from typing import Optional
import datetime
import bcrypt
from datetime import date
from decimal import Decimal

from sqlalchemy import Column, DateTime, Enum, ForeignKeyConstraint, Identity, Index, PrimaryKeyConstraint, TIMESTAMP, Table, VARCHAR, text
from sqlalchemy.dialects.oracle import NUMBER
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship

class Base(DeclarativeBase):
    def as_dict(self):
        result = {}
        for c in self.__table__.columns:
            value = getattr(self, c.name)
            if not value and not isinstance(value, int):
                continue

            if isinstance(value, (date, datetime.datetime)):
                result[c.name] = value.isoformat()
            elif isinstance(value, (Decimal)):
                result[c.name] = str(value)
            else:
                result[c.name] = value
        return result


class AppUser(Base):
    __tablename__ = 'app_user'
    __table_args__ = (
        PrimaryKeyConstraint('id', name='user_pk'),
        {'comment': 'Usuarios dentro de la aplicacion'}
    )

    id: Mapped[float] = mapped_column(NUMBER(asdecimal=False), Identity(on_null=False, start=1, increment=1, minvalue=1, maxvalue=9999999999999999999999999999, cycle=False, cache=20, order=False), primary_key=True)
    username: Mapped[str] = mapped_column(VARCHAR(50), nullable=False)
    email: Mapped[str] = mapped_column(VARCHAR(100), nullable=False)
    password_hash: Mapped[str] = mapped_column(VARCHAR(100), nullable=False)
    is_active: Mapped[float] = mapped_column(NUMBER(1, 0, False), nullable=False, server_default=text('0 '))
    role: Mapped[Optional[str]] = mapped_column(Enum('admin', 'receptionist', 'doctor'))
    created_at: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP, server_default=text('SYSTIMESTAMP'))
    updated_at: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP)
    deleted_at: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP)
    
    def set_password(self, plain_password: str):
        self.password_hash = bcrypt.hashpw(
            plain_password.encode('utf-8'), 
            bcrypt.gensalt()
        ).decode('utf-8')

    def check_password(self, plain_password: str):
        return bcrypt.checkpw(plain_password.encode('utf-8'), self.password_hash.encode('utf-8'))


class Doctor(Base):
    __tablename__ = 'doctor'
    __table_args__ = (
        PrimaryKeyConstraint('id', name='doctor_pk'),
    )

    id: Mapped[float] = mapped_column(NUMBER(asdecimal=False), Identity(on_null=False, start=1, increment=1, minvalue=1, maxvalue=9999999999999999999999999999, cycle=False, cache=20, order=False), primary_key=True)
    first_name: Mapped[str] = mapped_column(VARCHAR(100), nullable=False)
    last_name: Mapped[str] = mapped_column(VARCHAR(100), nullable=False)
    email: Mapped[str] = mapped_column(VARCHAR(200), nullable=False)
    phone: Mapped[Optional[str]] = mapped_column(VARCHAR(20))
    created_at: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP, server_default=text('SYSTIMESTAMP'))
    updated_at: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP, server_default=text('null'))
    deleted_at: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP, server_default=text('null\n'))

    area: Mapped[list['Area']] = relationship('Area', secondary='doctor_facility', back_populates='doctor')
    appointment: Mapped[list['Appointment']] = relationship('Appointment', back_populates='doctor')


class Facility(Base):
    __tablename__ = 'facility'
    __table_args__ = (
        PrimaryKeyConstraint('id', name='facility_pk'),
        Index('facility_name_uindex', 'name', unique=True),
        {'comment': 'Establecimiento, por ej (Hospital Clínica Bíblica)'}
    )

    id: Mapped[float] = mapped_column(NUMBER(asdecimal=False), Identity(on_null=False, start=1, increment=1, minvalue=1, maxvalue=9999999999999999999999999999, cycle=False, cache=20, order=False), primary_key=True)
    name: Mapped[str] = mapped_column(VARCHAR(100), nullable=False)
    description: Mapped[str] = mapped_column(VARCHAR(320), nullable=False)
    created_at: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP, server_default=text('SYSTIMESTAMP'))
    updated_at: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP)
    deleted_at: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP)

    area: Mapped[list['Area']] = relationship('Area', back_populates='facility')


class Patient(Base):
    __tablename__ = 'patient'
    __table_args__ = (
        PrimaryKeyConstraint('id', name='patient_pk'),
    )

    id: Mapped[float] = mapped_column(NUMBER(asdecimal=False), Identity(on_null=False, start=1, increment=1, minvalue=1, maxvalue=9999999999999999999999999999, cycle=False, cache=20, order=False), primary_key=True)
    first_name: Mapped[str] = mapped_column(VARCHAR(100), nullable=False)
    last_name: Mapped[str] = mapped_column(VARCHAR(100), nullable=False)
    date_of_birth: Mapped[datetime.datetime] = mapped_column(DateTime, nullable=False)
    gender: Mapped[float] = mapped_column(NUMBER(1, 0, False), nullable=False, comment='0  HOMBRE || MUJER 1')
    email: Mapped[str] = mapped_column(VARCHAR(150), nullable=False)
    phone: Mapped[Optional[str]] = mapped_column(VARCHAR(50))
    address: Mapped[Optional[str]] = mapped_column(VARCHAR(250))
    created_at: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP, server_default=text('SYSTIMESTAMP'))
    updated_at: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP)
    deleted_at: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP)

    appointment: Mapped[list['Appointment']] = relationship('Appointment', back_populates='patient')


class Area(Base):
    __tablename__ = 'area'
    __table_args__ = (
        ForeignKeyConstraint(['facility_id'], ['facility.id'], name='area_facility_id_fk'),
        PrimaryKeyConstraint('id', name='area_pk')
    )

    id: Mapped[float] = mapped_column(NUMBER(asdecimal=False), Identity(on_null=False, start=1, increment=1, minvalue=1, maxvalue=9999999999999999999999999999, cycle=False, cache=20, order=False), primary_key=True)
    facility_id: Mapped[float] = mapped_column(NUMBER(asdecimal=False), nullable=False)
    name: Mapped[str] = mapped_column(VARCHAR(100), nullable=False)
    description: Mapped[str] = mapped_column(VARCHAR(320), nullable=False)
    created_at: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP, server_default=text('SYSTIMESTAMP'))
    updated_at: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP)
    deleted_at: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP)

    facility: Mapped['Facility'] = relationship('Facility', back_populates='area')
    doctor: Mapped[list['Doctor']] = relationship('Doctor', secondary='doctor_facility', back_populates='area')
    room: Mapped[list['Room']] = relationship('Room', back_populates='area')


t_doctor_facility = Table(
    'doctor_facility', Base.metadata,
    Column('area_id', NUMBER(asdecimal=False), primary_key=True),
    Column('doctor_id', NUMBER(asdecimal=False), primary_key=True),
    ForeignKeyConstraint(['area_id'], ['area.id'], ondelete='CASCADE', name='doctor_facility_area_id_fk'),
    ForeignKeyConstraint(['doctor_id'], ['doctor.id'], ondelete='CASCADE', name='doctor_facility_doctor_id_fk'),
    PrimaryKeyConstraint('doctor_id', 'area_id', name='doctor_facility_pk')
)


class Room(Base):
    __tablename__ = 'room'
    __table_args__ = (
        ForeignKeyConstraint(['area_id'], ['area.id'], ondelete='CASCADE', name='room_area_id_fk'),
        PrimaryKeyConstraint('id', name='room_pk')
    )

    id: Mapped[float] = mapped_column(NUMBER(asdecimal=False), Identity(on_null=False, start=1, increment=1, minvalue=1, maxvalue=9999999999999999999999999999, cycle=False, cache=20, order=False), primary_key=True)
    area_id: Mapped[float] = mapped_column(NUMBER(asdecimal=False), nullable=False, comment='Lugar dentro de un área donde los doctores atienden a pacientes')
    name: Mapped[str] = mapped_column(VARCHAR(100), nullable=False)
    description: Mapped[str] = mapped_column(VARCHAR(300), nullable=False)
    created_at: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP, server_default=text('SYSTIMESTAMP'))
    deleted_at: Mapped[Optional[datetime.datetime]] = mapped_column(TIMESTAMP)

    area: Mapped['Area'] = relationship('Area', back_populates='room')
    appointment: Mapped[list['Appointment']] = relationship('Appointment', back_populates='room')


class Appointment(Base):
    __tablename__ = 'appointment'
    __table_args__ = (
        ForeignKeyConstraint(['doctor_id'], ['doctor.id'], name='appointment_doctor_id_fk'),
        ForeignKeyConstraint(['patient_id'], ['patient.id'], name='appointment_patient_id_fk'),
        ForeignKeyConstraint(['room_id'], ['room.id'], name='appointment_room_id_fk'),
        PrimaryKeyConstraint('id', name='appointment_pk'),
        Index('appointment_start_time_end_time_index', 'start_time', 'end_time')
    )

    id: Mapped[float] = mapped_column(NUMBER(asdecimal=False), Identity(on_null=False, start=1, increment=1, minvalue=1, maxvalue=9999999999999999999999999999, cycle=False, cache=20, order=False), primary_key=True)
    patient_id: Mapped[float] = mapped_column(NUMBER(asdecimal=False), nullable=False)
    doctor_id: Mapped[float] = mapped_column(NUMBER(asdecimal=False), nullable=False)
    room_id: Mapped[float] = mapped_column(NUMBER(asdecimal=False), nullable=False)
    start_time: Mapped[datetime.datetime] = mapped_column(TIMESTAMP, nullable=False)
    end_time: Mapped[datetime.datetime] = mapped_column(TIMESTAMP, nullable=False)
    status: Mapped[str] = mapped_column(Enum('scheduled', 'confirmed', 'completed', 'canceled'), nullable=False, server_default=text("'scheduled' "))
    description: Mapped[Optional[str]] = mapped_column(VARCHAR(500))

    doctor: Mapped['Doctor'] = relationship('Doctor', back_populates='appointment')
    patient: Mapped['Patient'] = relationship('Patient', back_populates='appointment')
    room: Mapped['Room'] = relationship('Room', back_populates='appointment')
