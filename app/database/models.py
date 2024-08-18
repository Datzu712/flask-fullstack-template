from datetime import date, datetime
from decimal import Decimal
from sqlalchemy import Column, String, TIMESTAMP, text
from sqlalchemy.dialects.mysql import INTEGER, TINYINT
from sqlalchemy.ext.declarative import declarative_base
import bcrypt

class Base(declarative_base()):
    __abstract__ = True

    def as_dict(self):
        result = {}
        for c in self.__table__.columns:
            value = getattr(self, c.name)
            if not value:
                continue

            if isinstance(value, (date, datetime)):
                result[c.name] = value.isoformat()
            elif isinstance(value, Decimal):
                result[c.name] = str(value)
            else:
                result[c.name] = value
        return result

metadata = Base.metadata


class Client(Base):
    __tablename__ = 'client'

    id = Column(String(36), primary_key=True, comment='UUIDV4')
    name = Column(INTEGER(11), nullable=False, unique=True)
    email = Column(String(100), nullable=False, unique=True)
    phone = Column(String(48), nullable=False)
    address = Column(String(504))
    created_at = Column(TIMESTAMP, nullable=False, server_default=text("current_timestamp()"))
    updated_at = Column(TIMESTAMP, nullable=False, server_default=text("current_timestamp()"))


class User(Base):
    __tablename__ = 'users'

    id = Column(String(36), primary_key=True, comment='UUID')
    name = Column(String(100), nullable=False)
    email = Column(String(100), nullable=False, unique=True)
    password = Column(String(255), nullable=False, comment='Hashed password')
    admin = Column(TINYINT(1), nullable=False, server_default=text("0"))
    created_at = Column(TIMESTAMP, nullable=False, server_default=text("current_timestamp()"))
    updated_at = Column(TIMESTAMP, nullable=False, server_default=text("current_timestamp()"))

    def set_password(self, plain_password):
            self.password = bcrypt.hashpw(
                plain_password.encode('utf-8'), 
                bcrypt.gensalt()
            ).decode('utf-8')

    def check_password(self, plain_password):
        return bcrypt.checkpw(plain_password.encode('utf-8'), self.password.encode('utf-8'))

# testing
if __name__ == "__main__":
    user = User()
    user.set_password("testpass")

    # Verificamos la contraseña
    print(user.check_password("testpass"))
    print(user.check_password("wrongpassword")) 