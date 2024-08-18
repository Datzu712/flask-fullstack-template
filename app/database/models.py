from datetime import date, datetime
from decimal import Decimal
from sqlalchemy import Column, ForeignKey, String, TIMESTAMP, UniqueConstraint, text
from sqlalchemy.dialects.mysql import INTEGER, TINYINT
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
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
    name = Column(String(100), nullable=False, unique=True)
    email = Column(String(100), nullable=False, unique=True)
    phone = Column(String(48), nullable=False)
    address = Column(String(504))
    created_at = Column(TIMESTAMP, nullable=False, server_default=text("current_timestamp()"))
    updated_at = Column(TIMESTAMP, nullable=False, server_default=text("current_timestamp()"))

    # users that have access to this client
    user_clients = relationship("UserClient", back_populates="client")

class User(Base):
    __tablename__ = 'users'

    id = Column(String(36), primary_key=True, comment='UUID')
    name = Column(String(100), nullable=False)
    email = Column(String(100), nullable=False, unique=True)
    password = Column(String(255), nullable=False, comment='Hashed password')
    admin = Column(TINYINT(1), nullable=False, server_default=text("0"))
    created_at = Column(TIMESTAMP, nullable=False, server_default=text("current_timestamp()"))
    updated_at = Column(TIMESTAMP, nullable=False, server_default=text("current_timestamp()"))

    user_clients = relationship("UserClient", back_populates="user")

    def set_password(self, plain_password: str):
            self.password = bcrypt.hashpw(
                plain_password.encode('utf-8'), 
                bcrypt.gensalt()
            ).decode('utf-8')

    def check_password(self, plain_password: str):
        return bcrypt.checkpw(plain_password.encode('utf-8'), self.password.encode('utf-8'))

class UserClient(Base):
    __tablename__ = 'user_clients'

    user_id = Column(String(36), ForeignKey('users.id'), primary_key=True, nullable=False)
    client_id = Column(String(36), ForeignKey('client.id'), primary_key=True, nullable=False)

    __table_args__ = (
        UniqueConstraint('client_id', 'user_id', name='user_clients_client_id_user_id_uindex'),
    )

    # Relationships (optional, if you want to establish ORM relationships)
    user = relationship("User", back_populates="user_clients")
    client = relationship("Client", back_populates="user_clients")

# testing
if __name__ == "__main__":
    user = User()
    user.set_password("testpass")

    # Verificamos la contraseña
    print(user.check_password("testpass"))
    print(user.check_password("wrongpassword")) 