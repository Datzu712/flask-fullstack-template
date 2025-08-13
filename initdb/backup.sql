create table FACILITY
(
    ID           NUMBER GENERATED AS IDENTITY
		constraint FACILITY_PK
			primary key,
    NAME        VARCHAR2(100) not null,
    DESCRIPTION VARCHAR2(320) not null,
    CREATED_AT  TIMESTAMP(6) default SYSTIMESTAMP,
    UPDATED_AT  TIMESTAMP(6),
    DELETED_AT  TIMESTAMP(6)
)
/

comment on table FACILITY is 'Establecimiento, por ej (Hospital Clínica Bíblica)'
/

create unique index FACILITY_NAME_UINDEX
    on FACILITY (NAME)
/

create table AREA
(
    ID          NUMBER GENERATED AS IDENTITY
		constraint AREA_PK
			primary key,
    FACILITY_ID NUMBER        not null
        constraint AREA_FACILITY_ID_FK
            references FACILITY,
    NAME        VARCHAR2(100) not null,
    DESCRIPTION VARCHAR2(320) not null,
    CREATED_AT  TIMESTAMP(6) default SYSTIMESTAMP,
    UPDATED_AT  TIMESTAMP(6),
    DELETED_AT  TIMESTAMP(6)
)
/

create table DOCTOR
(
    ID         NUMBER GENERATED AS IDENTITY
		constraint DOCTOR_PK
			primary key,
    FIRST_NAME VARCHAR2(100) not null,
    LAST_NAME  VARCHAR2(100) not null,
    PHONE      VARCHAR2(20),
    EMAIL      VARCHAR2(200) not null,
    CREATED_AT TIMESTAMP(6) default SYSTIMESTAMP,
    UPDATED_AT TIMESTAMP(6) default null,
    DELETED_AT TIMESTAMP(6) default null
)
/

create table DOCTOR_FACILITY
(
    AREA_ID   NUMBER not null
        constraint DOCTOR_FACILITY_AREA_ID_FK
            references AREA
                on delete cascade,
    DOCTOR_ID NUMBER not null
        constraint DOCTOR_FACILITY_DOCTOR_ID_FK
            references DOCTOR
                on delete cascade,
    constraint DOCTOR_FACILITY_PK
        primary key (DOCTOR_ID, AREA_ID)
)
/

create table ROOM
(
    ID          NUMBER GENERATED AS IDENTITY
		constraint ROOM_PK
			primary key,
    AREA_ID     NUMBER        not null
        constraint ROOM_AREA_ID_FK
            references AREA
                on delete cascade,
    NAME        VARCHAR2(100) not null,
    DESCRIPTION VARCHAR2(300) not null,
    CREATED_AT  TIMESTAMP(6) default SYSTIMESTAMP,
    DELETED_AT  TIMESTAMP(8)
)
/

comment on column ROOM.AREA_ID is 'Lugar dentro de un área donde los doctores atienden a pacientes'
/

create table PATIENT
(
    ID          NUMBER GENERATED AS IDENTITY
		constraint PATIENT_PK
			primary key,
    FIRST_NAME    VARCHAR2(100) not null,
    LAST_NAME     VARCHAR2(100) not null,
    DATE_OF_BIRTH DATE          not null,
    GENDER        NUMBER(1)     not null,
    PHONE         VARCHAR2(50),
    EMAIL         VARCHAR2(150) not null,
    ADDRESS       VARCHAR2(250),
    CREATED_AT    TIMESTAMP(6) default SYSTIMESTAMP,
    UPDATED_AT    TIMESTAMP(6),
    DELETED_AT    TIMESTAMP(6)
)
/

comment on column PATIENT.GENDER is '0  HOMBRE || MUJER 1'
/

create table APPOINTMENT
(
    ID          NUMBER GENERATED AS IDENTITY
		constraint APPOINTMENT_PK
			primary key,
    PATIENT_ID  NUMBER                           not null
        constraint APPOINTMENT_PATIENT_ID_FK
            references PATIENT,
    DOCTOR_ID   NUMBER                           not null
        constraint APPOINTMENT_DOCTOR_ID_FK
            references DOCTOR,
    ROOM_ID     NUMBER                           not null
        constraint APPOINTMENT_ROOM_ID_FK
            references ROOM,
    START_TIME  TIMESTAMP(6)                     not null,
    END_TIME    TIMESTAMP(6)                     not null,
    STATUS      VARCHAR2(20) default 'scheduled' not null
        constraint CHECK_NAME
            check (status IN ('scheduled', 'confirmed', 'completed', 'canceled')),
    DESCRIPTION VARCHAR2(500)
)
/

create index APPOINTMENT_START_TIME_END_TIME_INDEX
    on APPOINTMENT (START_TIME, END_TIME)
/

create table APP_USER
(
    ID        NUMBER GENERATED AS IDENTITY
		constraint USER_PK
			primary key,
    USERNAME      VARCHAR2(50)           not null,
    EMAIL         VARCHAR2(100)          not null,
    PASSWORD_HASH VARCHAR2(100),
    ROLE          VARCHAR2(20)
        constraint ROLE
            check (role IN ('admin', 'receptionist', 'doctor')),
    IS_ACTIVE     NUMBER(1)    default 0 not null,
    CREATED_AT    TIMESTAMP(6) default SYSTIMESTAMP,
    UPDATED_AT    TIMESTAMP(6),
    DELETED_AT    TIMESTAMP(6)
)
/

comment on table APP_USER is 'Usuarios dentro de la aplicacion'
/

