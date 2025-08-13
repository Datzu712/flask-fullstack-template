-- Eliminar objetos en orden de dependencia (inverso a la creación). esto sirve para "limpiar la base de datos y poder ejecutar todo de nuevo, pueden descomentar.  
--DROP TABLE APPOINTMENT CASCADE CONSTRAINTS;
--DROP TABLE APP_USER CASCADE CONSTRAINTS;
--DROP TABLE DOCTOR_FACILITY CASCADE CONSTRAINTS;
--DROP TABLE PATIENT CASCADE CONSTRAINTS;
-- TABLE ROOM CASCADE CONSTRAINTS;
--DROP TABLE DOCTOR CASCADE CONSTRAINTS;
--DROP TABLE AREA CASCADE CONSTRAINTS;
--DROP TABLE FACILITY CASCADE CONSTRAINTS;

-- Eliminar el tablespace si existe, asegurando un inicio limpio.
--DROP TABLESPACE health_care_data INCLUDING CONTENTS AND DATAFILES;

-- Crear el tablespace nuevamente
CREATE TABLESPACE health_care_data
DATAFILE 'health_care_data_02.dbf'
SIZE 200M
AUTOEXTEND ON NEXT 50M;

---

-- Crear todas las tablas con su respectivo tablespace
CREATE TABLE FACILITY
(
    ID            NUMBER GENERATED AS IDENTITY
        constraint FACILITY_PK
            primary key,
    NAME          VARCHAR2(100) not null,
    DESCRIPTION   VARCHAR2(320) not null,
    CREATED_AT    TIMESTAMP(6) default SYSTIMESTAMP,
    UPDATED_AT    TIMESTAMP(6),
    DELETED_AT    TIMESTAMP(6)
)
TABLESPACE health_care_data;

COMMENT ON TABLE FACILITY IS 'Establecimiento, por ej (Hospital Clínica Bíblica)';

CREATE UNIQUE INDEX FACILITY_NAME_UINDEX
    ON FACILITY (NAME)
    TABLESPACE health_care_data;

CREATE TABLE AREA
(
    ID            NUMBER GENERATED AS IDENTITY
        constraint AREA_PK
            primary key,
    FACILITY_ID   NUMBER not null
        constraint AREA_FACILITY_ID_FK
            references FACILITY,
    NAME          VARCHAR2(100) not null,
    DESCRIPTION   VARCHAR2(320) not null,
    CREATED_AT    TIMESTAMP(6) default SYSTIMESTAMP,
    UPDATED_AT    TIMESTAMP(6),
    DELETED_AT    TIMESTAMP(6)
)
TABLESPACE health_care_data;

CREATE TABLE DOCTOR
(
    ID            NUMBER GENERATED AS IDENTITY
        constraint DOCTOR_PK
            primary key,
    FIRST_NAME    VARCHAR2(100) not null,
    LAST_NAME     VARCHAR2(100) not null,
    PHONE         VARCHAR2(20),
    EMAIL         VARCHAR2(200) not null,
    CREATED_AT    TIMESTAMP(6) default SYSTIMESTAMP,
    UPDATED_AT    TIMESTAMP(6) default null,
    DELETED_AT    TIMESTAMP(6) default null
)
TABLESPACE health_care_data;

CREATE TABLE DOCTOR_FACILITY
(
    AREA_ID       NUMBER not null
        constraint DOCTOR_FACILITY_AREA_ID_FK
            references AREA
                on delete cascade,
    DOCTOR_ID     NUMBER not null
        constraint DOCTOR_FACILITY_DOCTOR_ID_FK
            references DOCTOR
                on delete cascade,
    constraint DOCTOR_FACILITY_PK
        primary key (DOCTOR_ID, AREA_ID)
)
TABLESPACE health_care_data;

CREATE TABLE ROOM
(
    ID            NUMBER GENERATED AS IDENTITY
        constraint ROOM_PK
            primary key,
    AREA_ID       NUMBER not null
        constraint ROOM_AREA_ID_FK
            references AREA
                on delete cascade,
    NAME          VARCHAR2(100) not null,
    DESCRIPTION   VARCHAR2(300) not null,
    CREATED_AT    TIMESTAMP(6) default SYSTIMESTAMP,
    DELETED_AT    TIMESTAMP(8)
)
TABLESPACE health_care_data;

COMMENT ON COLUMN ROOM.AREA_ID IS 'Lugar dentro de un área donde los doctores atienden a pacientes';

CREATE TABLE PATIENT
(
    ID            NUMBER GENERATED AS IDENTITY
        constraint PATIENT_PK
            primary key,
    FIRST_NAME    VARCHAR2(100) not null,
    LAST_NAME     VARCHAR2(100) not null,
    DATE_OF_BIRTH DATE not null,
    GENDER        NUMBER(1) not null,
    PHONE         VARCHAR2(50),
    EMAIL         VARCHAR2(150) not null,
    ADDRESS       VARCHAR2(250),
    CREATED_AT    TIMESTAMP(6) default SYSTIMESTAMP,
    UPDATED_AT    TIMESTAMP(6),
    DELETED_AT    TIMESTAMP(6)
)
TABLESPACE health_care_data;

COMMENT ON COLUMN PATIENT.GENDER IS '0 HOMBRE || MUJER 1';

CREATE TABLE APPOINTMENT
(
    ID            NUMBER GENERATED AS IDENTITY
        constraint APPOINTMENT_PK
            primary key,
    PATIENT_ID    NUMBER not null
        constraint APPOINTMENT_PATIENT_ID_FK
            references PATIENT,
    DOCTOR_ID     NUMBER not null
        constraint APPOINTMENT_DOCTOR_ID_FK
            references DOCTOR,
    ROOM_ID       NUMBER not null
        constraint APPOINTMENT_ROOM_ID_FK
            references ROOM,
    START_TIME    TIMESTAMP(6) not null,
    END_TIME      TIMESTAMP(6) not null,
    STATUS        VARCHAR2(20) default 'scheduled' not null
        constraint CHECK_NAME
            check (status IN ('scheduled', 'confirmed', 'completed', 'canceled')),
    DESCRIPTION   VARCHAR2(500)
)
TABLESPACE health_care_data;

CREATE INDEX APPOINTMENT_START_TIME_END_TIME_INDEX
    ON APPOINTMENT (START_TIME, END_TIME)
    TABLESPACE health_care_data;

CREATE TABLE APP_USER
(
    ID            NUMBER GENERATED AS IDENTITY
        constraint USER_PK
            primary key,
    USERNAME      VARCHAR2(50) not null,
    EMAIL         VARCHAR2(100) not null,
    PASSWORD_HASH VARCHAR2(100),
    ROLE          VARCHAR2(20)
        constraint ROLE
            check (role IN ('admin', 'receptionist', 'doctor')),
    IS_ACTIVE     NUMBER(1) default 0 not null,
    CREATED_AT    TIMESTAMP(6) default SYSTIMESTAMP,
    UPDATED_AT    TIMESTAMP(6),
    DELETED_AT    TIMESTAMP(6)
)
TABLESPACE health_care_data;

COMMENT ON TABLE APP_USER IS 'Usuarios dentro de la aplicacion';

-- Si se quiere comprobar si las tablas e indices se crearon en el table space, descomenten y ejecuten esta consulta :)

--SELECT table_name, tablespace_name
--FROM user_tables
--WHERE tablespace_name = 'HEALTH_CARE_DATA';

--SELECT index_name, tablespace_name
--FROM user_indexes
--WHERE tablespace_name = 'HEALTH_CARE_DATA';


ALTER TABLE FACILITY MODIFY ID GENERATED BY DEFAULT AS IDENTITY;
ALTER TABLE AREA MODIFY ID GENERATED BY DEFAULT AS IDENTITY;
ALTER TABLE DOCTOR MODIFY ID GENERATED BY DEFAULT AS IDENTITY;
ALTER TABLE ROOM MODIFY ID GENERATED BY DEFAULT AS IDENTITY;
ALTER TABLE PATIENT MODIFY ID GENERATED BY DEFAULT AS IDENTITY;
ALTER TABLE APPOINTMENT MODIFY ID GENERATED BY DEFAULT AS IDENTITY;
ALTER TABLE APP_USER MODIFY ID GENERATED BY DEFAULT AS IDENTITY;

--------------------------------------------------------------------------------------------------------
--ROLES

ALTER SESSION SET CONTAINER = XEPDB1;

--Pueden dropear los roles o users si es necesario o necesitan re-correr el script
--Si no los deja hacer nada o crearlos y da error ORA... probablemente tienen que cambiar el contenedor raiz corriendo el siguiente comando: ALTER SESSION SET CONTAINER = CDB$ROOT;     

--DROP ROLE ROL_ADMIN;
--DROP ROLE ROL_DOCTOR;
--DROP ROLE ROL_RECEPTIONIST;

--DROP USER admin_healthcare CASCADE;
--DROP USER doctor_user CASCADE;
--DROP USER receptionist_user CASCADE;

CREATE ROLE ROL_ADMIN;
CREATE ROLE ROL_DOCTOR;
CREATE ROLE ROL_RECEPTIONIST;

-- Creación de usuarios locales
CREATE USER admin_healthcare IDENTIFIED BY "ClaveSeguraAdmin"
DEFAULT TABLESPACE health_care_data
TEMPORARY TABLESPACE TEMP;

CREATE USER doctor_user IDENTIFIED BY "ClaveDoctor123"
DEFAULT TABLESPACE health_care_data
TEMPORARY TABLESPACE TEMP;

CREATE USER receptionist_user IDENTIFIED BY "ClaveRecepcionista123"
DEFAULT TABLESPACE health_care_data
TEMPORARY TABLESPACE TEMP;

-- Asignación de roles y permisos básicos a los usuarios
GRANT CONNECT, RESOURCE, ROL_ADMIN TO admin_healthcare;
GRANT CONNECT, RESOURCE, ROL_DOCTOR TO doctor_user;
GRANT CONNECT, RESOURCE, ROL_RECEPTIONIST TO receptionist_user;

-- Permisos específicos para cada rol
-- ROL_ADMIN: Acceso total para administrar la base de datos
GRANT ALL ON FACILITY TO ROL_ADMIN;
GRANT ALL ON AREA TO ROL_ADMIN;
GRANT ALL ON DOCTOR TO ROL_ADMIN;
GRANT ALL ON ROOM TO ROL_ADMIN;
GRANT ALL ON DOCTOR_FACILITY TO ROL_ADMIN;
GRANT ALL ON PATIENT TO ROL_ADMIN;
GRANT ALL ON APPOINTMENT TO ROL_ADMIN;
GRANT ALL ON APP_USER TO ROL_ADMIN;

-- ROL_DOCTOR: Permisos para ver pacientes y gestionar citas
GRANT SELECT, INSERT, UPDATE ON APPOINTMENT TO ROL_DOCTOR;
GRANT SELECT ON PATIENT TO ROL_DOCTOR;
GRANT SELECT ON ROOM TO ROL_DOCTOR;
GRANT SELECT ON DOCTOR TO ROL_DOCTOR;

-- ROL_RECEPTIONIST: Permisos para gestionar pacientes y citas
GRANT SELECT, INSERT, UPDATE, DELETE ON PATIENT TO ROL_RECEPTIONIST;
GRANT SELECT, INSERT, UPDATE, DELETE ON APPOINTMENT TO ROL_RECEPTIONIST;
GRANT SELECT ON DOCTOR TO ROL_RECEPTIONIST;
GRANT SELECT ON ROOM TO ROL_RECEPTIONIST;



------------------------------------------------------------------------------------------------------------------------

-- Inserts

-- FACILITES
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (16, 'Annie Penn Hospital', 'Enfocado potenciada infraestructura', TIMESTAMP '2025-07-02 11:26:44.474000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (17, 'Bert Fish Medical Center', 'Multi capa no-volátil base del conocimiento', TIMESTAMP '2025-07-02 11:26:44.474000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (18, 'Coalinga Regional Medical Center', 'Enfocado en la calidad homogénea codificar', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (19, 'Children''s Hospital of Georgia', 'Totalmente configurable logística focus group', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (20, 'Aspen Valley Hospital', 'Centrado en el negocio tolerante a fallos jerarquía', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (21, 'Bryan Whitfield Memorial Hospital', 'Implementado basado en contenido archivo', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (22, 'CarolinaEast Medical Center', 'Actualizable generado por la demanda fidelidad', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (23, 'Candler Hospital', 'Auto proporciona orientado a objetos extranet', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (24, 'Capital Region Medical Center', 'Mejorado basado en contenido iniciativa', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (25, 'Burbank Community Hospital', 'Reducido holística software', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (26, 'Cape Canaveral Hospital', 'Organizado nacional conjunto de instrucciones', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (27, 'Birkeland Maternity Center', 'Multi plataforma generado por la demanda website', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (28, 'Brooks County Hospital', 'en fases maximizada circuito', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (29, 'Bridgeport Hospital', 'Monitorizado bifurcada modelo', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (30, 'Dana-Farber Cancer Institute', 'Open-source ejecutiva complejidad', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (31, 'Alice Hyde Medical Center', 'Fácil heurística flexibilidad', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (32, 'Charlevoix Area Hospital', 'Configurable tiempo real base de trabajo', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (33, 'Baltimore VA Medical Center', 'Seguro incremental data-warehouse', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (34, 'Central Florida Regional Hospital', 'Public-key sensible al contexto colaboración', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (35, 'Aspirus Ontonagon Hospital', 'Multi grupo cohesiva productividad', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (36, 'Alamance Regional Medical Center', 'Auto proporciona misión crítica groupware', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (37, 'Children''s Mercy Northland', 'Realineado estatica capacidad', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (38, 'Beacon Center', 'Universal sistémica alianza', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (39, 'Cordova Community Medical Center', 'Sincronizado multimedia previsión', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (40, 'A.O. Fox Memorial Hospital', 'Inverso basado en contenido codificar', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (41, 'Boone Hospital Center', 'Versatil 5th generación jerarquía', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (42, 'County Hospital', 'Total didactica funcionalidad', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (43, 'Beverly Hospital', 'Auto proporciona tolerancia cero estructura de precios', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (44, 'Carson City Hospital', 'Equilibrado transicional Interfaz gráfico de usuario', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (45, 'Century City Hospital', 'Polarizado estable flexibilidad', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (46, 'Anaheim General Hospital', 'Equilibrado multitarea iniciativa', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (47, 'Byrd Regional Hospital', 'Optimizado radical inteligencia artificial', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (48, 'Bath Va Medical Center', 'Adaptativo potenciada software', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (49, 'Crisp Regional Hospital', 'Reducido terciaria emulación', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (50, 'Clinton County Hospital', 'Reducido móbil instalación', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (51, 'Conejos County Hospital', 'Inverso 6th generación mediante', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (52, 'Bingham Memorial Hospital', 'Intuitivo homogénea paradigma', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (53, 'Blank Children''s Hospital', 'Orígenes intermedia flexibilidad', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (54, 'Central State Hospital', 'En red asimétrica núcleo', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (55, 'Conway Regional Health System', 'Equilibrado multitarea circuito', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (56, 'Carolinas ContinueCARE Hospital at Pineville', 'Implementado ejecutiva red de area local', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (57, 'Blythedale Children''s Hospital', 'Cara a cara didactica proceso de mejora', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (58, 'Crotched Mountain Rehabilitation Center', 'Obligatorio asimétrica implementación', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (59, 'Blackford Community Hospital', 'Versatil intangible orquestar', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (60, 'Community Hospital of Los Gatos', 'Fácil modular concepto', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (61, 'Choctaw General Hospital', 'Orgánico metódica habilidad', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (62, 'AcuteCare Health System', 'Organizado optimizada éxito', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (63, 'Clark Regional Medical Center', 'Horizontal nacional instalación', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (64, 'Deaconess Incarnate Word Health System', 'Cara a cara sistémica data-warehouse', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (65, 'Angel Medical Center', 'Asimilado ejecutiva sinergia', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (66, 'Alpena Regional Medical Center', 'Obligatorio valor añadido capacidad', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (67, 'Columbia Regional Hospital', 'Gestionado logística medición', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (68, 'Arizona Heart Institute', 'Orgánico secundaria previsión', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (69, 'Avista Adventist Hospital', 'Multi canal intermedia inteligencia artificial', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (70, 'Bellflower Medical Center', 'Re-implementado asíncrona alianza', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (71, 'Craig Hospital', 'Proactivo estatica estructura de precios', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (72, 'Children''s Hospital Los Angeles', 'Virtual sistemática matrices', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (73, 'Barrow Regional Medical Center', 'Orientado a equipos dinámica conglomeración', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (74, 'Bonner General Hospital', 'Perseverando dedicada Interfaz Gráfica', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (75, 'CenterPointe Hospital', 'Innovador neutral solución', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (76, 'Barton Memorial Hospital', 'Enfocado en la calidad global protocolo', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (77, 'De Queen Medical Center', 'Fácil explícita base de trabajo', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (78, 'Christian Hospital', 'Multi canal estable conglomeración', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (79, 'Brooks Rehabilitation', 'Inverso explícita conjunto', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (80, 'Catholic Medical Center', 'Total coherente base de trabajo', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (81, 'Coast Plaza Hospital', 'Pre-emptivo analizada groupware', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (82, 'Christus St. Patrick Hospital', 'Operativo local base del conocimiento', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (83, 'Dallas County Hospital', 'Sincronizado orientado a objetos gestión presupuestaria', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (84, 'CareLink of Jackson', 'Clonado vía web metodologías', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (85, 'Chestatee Regional Hospital', 'Intercambiable sensible al contexto productividad', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (86, 'Colorado Mental Health Institute at Pueblo', 'en fases 5th generación sinergia', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (87, 'Community Hospital of the Monterey Peninsula', 'Re-implementado intangible matrices', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (88, 'Bullitt County Medical Center', 'Orientado a equipos dedicada estandardización', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (89, 'Brandon Regional Hospital', 'Optimizado secundaria paralelismo', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (90, 'Christus Schumpert Hospital', 'Universal tangible funcionalidad', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (91, 'Community Memorial Hospital', 'Inverso cliente servidor firmware', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (92, 'Boca Raton Regional Hospital', 'Operativo hibrida hardware', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (93, 'Central Valley General Hospital', 'Auto proporciona basado en necesidades matrices', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (94, 'Day Kimball Hospital', 'Inverso sistémica base del conocimiento', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (95, 'Cardinal Glennon Children''s Hospital', 'Exclusivo monitorizada por red red de area local', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (96, 'Cushing Memorial Hospital', 'Total tangible flexibilidad', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (97, 'Alaska Native Medical Center', 'Multi grupo compuesto extranet', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);
INSERT INTO TEST_USER.FACILITY (ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (98, 'Animas Surgical Hospital', 'Orígenes incremental archivo', TIMESTAMP '2025-07-02 11:26:44.475000', null, null);

-- AREAS
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (75, 61, 'Servicios de Alimentación / Nutrición y Dietética', 'Ascisco coepi caste vacuus celebrer varius teneo.', TIMESTAMP '2025-02-03 18:55:29.794000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (76, 20, 'Oftalmología', 'Quia totus cattus utilis.', TIMESTAMP '2024-09-08 13:52:46.999000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (77, 47, 'Dirección General / Gerencia', 'Derelinquo conventus desipio.', TIMESTAMP '2025-01-02 11:23:25.184000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (78, 83, 'Traumatología y Ortopedia', 'Adulatio socius volva statim.', TIMESTAMP '2024-08-26 16:32:26.622000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (79, 71, 'Ginecología y Obstetricia', 'Coma doloribus combibo caritas illo canonicus approbo uberrime.', TIMESTAMP '2025-04-15 02:21:52.969000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (80, 56, 'Urgencias / Emergencias', 'Dolorem curo ultio curto quod certus consequatur possimus tergum.', TIMESTAMP '2024-07-11 09:35:09.864000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (81, 44, 'Box de Reanimación / Box de Críticos', 'Ducimus corrupti tenus usus conatus arbustum cilicium.', TIMESTAMP '2025-05-21 00:46:05.195000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (1, 95, 'Dirección Financiera / Administrativa', 'Ustulo ratione derelinquo apparatus.', TIMESTAMP '2025-01-26 11:40:08.502000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (2, 33, 'Trabajo Social', 'Sequi defetiscor vaco vado angulus.', TIMESTAMP '2024-11-04 04:05:23.032000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (3, 18, 'Urgencias / Emergencias', 'Incidunt desparatus consequatur talio audacia consuasor.', TIMESTAMP '2025-04-20 11:13:25.682000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (4, 60, 'Servicios de Alimentación / Nutrición y Dietética', 'Admiratio aspernatur alii in.', TIMESTAMP '2025-05-31 06:36:20.418000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (5, 56, 'Traumatología y Ortopedia', 'Aequitas culpa vestrum stipes tamquam depono curtus.', TIMESTAMP '2025-02-14 07:01:01.053000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (6, 39, 'Dirección de Gestión y Servicios Generales', 'Acidus adversus ancilla.', TIMESTAMP '2025-02-28 00:07:07.196000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (7, 52, 'Limpieza / Higiene Hospitalaria', 'Patior decimus colo tardus debitis.', TIMESTAMP '2025-02-04 21:30:34.877000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (8, 84, 'Dirección Financiera / Administrativa', 'Aut antepono suscipio aiunt hic patrocinor alioqui decens similique arca.', TIMESTAMP '2024-10-25 15:14:39.512000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (9, 35, 'Dirección Médica', 'Ago dolore subnecto acquiro ago arbitro timidus.', TIMESTAMP '2025-05-06 06:32:07.052000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (10, 72, 'Otorrinolaringología (ORL)', 'Cerno vehemens territo.', TIMESTAMP '2025-05-18 06:14:56.277000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (11, 54, 'Hematología (laboratorio)', 'Cavus circumvenio sordeo unde.', TIMESTAMP '2025-03-10 03:02:24.438000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (12, 97, 'Cardiología', 'Thymbra acer aeger tam voluptates creptio conqueror absorbeo.', TIMESTAMP '2024-11-26 06:44:47.327000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (13, 55, 'Limpieza / Higiene Hospitalaria', 'Bellum at desparatus.', TIMESTAMP '2024-10-02 15:47:21.160000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (14, 85, 'Oncología Médica', 'Crux accommodo strues.', TIMESTAMP '2025-01-23 08:33:28.582000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (15, 94, 'Oftalmología', 'Carbo suffoco adversus victus vulnus aliquid asporto velociter viriliter adaugeo.', TIMESTAMP '2025-02-07 12:28:26.483000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (16, 97, 'Dermatología', 'Delibero anser iste voro.', TIMESTAMP '2025-04-11 17:16:24.879000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (17, 31, 'Unidad Coronaria', 'Desino tonsor aequus armarium ascit itaque.', TIMESTAMP '2025-06-04 09:09:08.430000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (18, 84, 'Seguridad', 'Vulpes ter totus deleo.', TIMESTAMP '2024-07-13 17:39:06.656000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (19, 24, 'Neonatología / Unidad de Cuidados Intensivos Neonatales (UCIN)', 'Canto terga acies magnam omnis audax tracto celer stipes theologus.', TIMESTAMP '2025-03-11 07:30:21.413000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (20, 20, 'Medicina Nuclear', 'Utrum ademptio victoria vinum depereo angelus tandem labore.', TIMESTAMP '2025-03-24 18:16:19.830000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (21, 71, 'Atención al Paciente / Servicio de Información', 'Viscus totus defessus ver aetas necessitatibus bene usque.', TIMESTAMP '2024-08-25 07:50:03.234000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (22, 29, 'Hematología', 'Vox id desipio abduco currus valetudo audacia accusator thalassinus uterque.', TIMESTAMP '2024-11-14 00:18:55.030000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (23, 94, 'Cardiología', 'Calculus alii crudelis.', TIMESTAMP '2024-07-31 08:36:19.802000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (24, 49, 'Mamografía', 'Damnatio crebro defaeco cruciamentum est taedium tabesco.', TIMESTAMP '2025-06-25 07:45:39.160000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (25, 24, 'Gastroenterología', 'Cruentus sum demens curtus solitudo synagoga coma bellum minima adinventitias.', TIMESTAMP '2025-05-07 14:02:17.803000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (26, 91, 'Microbiología', 'Quo arbitro creptio clamo concido solio.', TIMESTAMP '2024-11-20 20:04:54.916000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (27, 56, 'Dirección de Gestión y Servicios Generales', 'Nobis ulterius urbs credo.', TIMESTAMP '2024-11-21 06:59:36.239000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (28, 50, 'Pediatría', 'Amplus concedo tenus undique aduro.', TIMESTAMP '2025-05-23 03:10:12.868000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (29, 56, 'Pediatría', 'Vinco uter saepe sit arbustum sopor traho antea.', TIMESTAMP '2025-01-12 18:43:06.082000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (30, 17, 'Servicios de Alimentación / Nutrición y Dietética', 'Aureus debilito thymbra aro deprecator speciosus totidem.', TIMESTAMP '2025-02-06 15:17:18.419000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (31, 26, 'Infectología', 'Apud velociter caelestis.', TIMESTAMP '2024-07-25 08:04:04.698000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (32, 85, 'Limpieza / Higiene Hospitalaria', 'Accusator conculco cura deludo depraedor varius delectus complectus defero vomito.', TIMESTAMP '2024-12-11 13:58:32.222000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (33, 62, 'Unidad de Cuidados Intensivos (UCI)', 'Cedo vesica deduco vita.', TIMESTAMP '2025-05-17 16:54:52.298000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (34, 36, 'Oftalmología', 'Conduco velit somniculosus sumptus addo nihil pax repellat.', TIMESTAMP '2024-07-07 12:25:41.184000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (35, 94, 'Infectología-3db09ca3-1e8f-4ee3-b075-1f50bec3431c', 'Terror suus ambitus.', TIMESTAMP '2024-08-02 19:25:39.563000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (36, 85, 'Seguridad', 'Qui totam copia coadunatio cavus compello colligo non amplus.', TIMESTAMP '2024-08-13 05:22:57.833000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (37, 79, 'Cardiología', 'Stabilis amaritudo adversus vilicus.', TIMESTAMP '2025-04-28 07:50:24.320000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (38, 61, 'Medicina Nuclear', 'Defaeco aegre comis timor contigo calco tergiversatio laboriosam.', TIMESTAMP '2025-03-18 23:41:53.521000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (39, 21, 'Alergología', 'Bibo tempore communis cado conqueror.', TIMESTAMP '2025-03-29 10:53:46.831000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (40, 96, 'Bioquímica', 'Usus caries absens demergo voco perspiciatis tero.', TIMESTAMP '2025-06-20 05:46:15.129000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (41, 61, 'Otorrinolaringología (ORL)', 'Calamitas tabgo delectus cruciamentum dolorem.', TIMESTAMP '2025-05-15 01:11:12.380000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (42, 80, 'Unidad de Diálisis', 'Abscido stipes temeritas.', TIMESTAMP '2024-11-20 08:37:46.063000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (43, 31, 'Farmacia Hospitalaria', 'Amaritudo anser acsi beatae desparatus temperantia rem undique speculum.', TIMESTAMP '2025-02-23 03:17:20.066000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (44, 72, 'Dirección de Recursos Humanos', 'Cogo veniam accusamus caput statim voluptas custodia utrum ascisco.', TIMESTAMP '2024-08-16 18:47:27.023000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (45, 16, 'Unidad de Cuidados Intensivos Neonatales (UCIN)', 'Adinventitias in quasi crebro voluptates defessus conscendo alveus considero.', TIMESTAMP '2024-11-28 08:08:01.499000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (46, 91, 'Medicina Interna', 'Uterque altus titulus quo aliqua autus tandem.', TIMESTAMP '2024-10-13 22:16:51.964000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (47, 57, 'Urgencias / Emergencias', 'Minus usitas convoco patior uredo aequus cinis.', TIMESTAMP '2024-11-11 00:49:04.017000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (48, 53, 'Mamografía', 'Corona vetus umerus voluptates.', TIMESTAMP '2024-09-12 00:54:00.691000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (49, 45, 'Unidad de Cuidados Intensivos Neonatales (UCIN)', 'Acsi suspendo laboriosam.', TIMESTAMP '2025-06-20 20:53:05.070000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (50, 35, 'Unidad de Cirugía Mayor Ambulatoria (UCMA)', 'Harum articulus tubineus acidus.', TIMESTAMP '2024-08-02 14:53:48.953000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (51, 97, 'Rehabilitación y Fisioterapia', 'Velum alienus totidem caute torqueo depopulo adsuesco cernuus.', TIMESTAMP '2024-09-15 19:23:26.066000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (52, 67, 'Dirección Médica', 'Tamdiu molestias porro auditor comptus subseco cum voro.', TIMESTAMP '2024-09-13 03:23:06.642000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (53, 30, 'Atención al Paciente / Servicio de Información', 'Caelum aegrus aegre creber triumphus tabella ad.', TIMESTAMP '2024-11-12 03:27:39.138000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (54, 48, 'Radiología Convencional (Rayos X)', 'Capillus perspiciatis casus tunc curo decretum mollitia.', TIMESTAMP '2024-12-07 14:34:39.196000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (55, 70, 'Dirección de Recursos Humanos', 'Vix non agnitio inventore beneficium conscendo absque desidero decet.', TIMESTAMP '2024-09-23 10:00:34.909000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (56, 36, 'Urgencias / Emergencias-8d84dab0-7aca-417c-8cbe-cf091166b6f1', 'Umerus careo comprehendo advoco cresco cribro pecto vix tergiversatio.', TIMESTAMP '2025-02-13 20:29:04.894000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (57, 46, 'Oncología Médica', 'Atrox omnis curiositas tres paens caries timidus magni suspendo tot.', TIMESTAMP '2025-02-24 17:27:29.856000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (58, 29, 'Unidad de Cirugía Mayor Ambulatoria (UCMA)', 'Suasoria calculus adduco deinde nesciunt debitis voluptas.', TIMESTAMP '2025-01-20 03:40:51.975000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (59, 32, 'Microbiología', 'Capio comparo culpo claro communis tandem delinquo ipsa est est.', TIMESTAMP '2025-06-25 02:11:48.248000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (60, 60, 'Mamografía', 'Natus alter ipsam.', TIMESTAMP '2025-02-04 02:35:26.007000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (61, 55, 'Atención al Paciente / Servicio de Información', 'Torrens urbanus alias cupiditas abundans cupio laudantium vitae uberrime deripio.', TIMESTAMP '2024-08-10 19:43:27.397000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (62, 30, 'Esterilización', 'Thymbra aranea nam aequitas.', TIMESTAMP '2025-01-07 08:03:45.732000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (63, 67, 'Quirófano / Área Quirúrgica', 'Veniam deduco recusandae.', TIMESTAMP '2025-01-21 10:56:11.958000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (64, 36, 'Traumatología y Ortopedia', 'Inflammatio animus summopere arca dolor uredo stella angelus ubi.', TIMESTAMP '2024-08-30 05:21:29.257000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (65, 44, 'Ecografía / Ultrasonido', 'Conculco eum arca acquiro virga.', TIMESTAMP '2025-06-18 05:30:34.636000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (66, 79, 'Ginecología y Obstetricia', 'Amo vado combibo cogo minima tardus adeptio carbo caecus ante.', TIMESTAMP '2025-01-22 13:24:06.239000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (67, 61, 'Unidad Coronaria', 'Votum est tardus adfero.', TIMESTAMP '2024-10-13 12:24:35.406000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (68, 19, 'Rehabilitación y Fisioterapia', 'Vox curso coruscus eius cognatus ambitus adsum armarium alter.', TIMESTAMP '2025-05-17 22:33:46.218000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (69, 41, 'Bioquímica', 'Celebrer comptus damno vita substantia socius contigo.', TIMESTAMP '2025-06-19 13:55:41.611000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (70, 21, 'Nutrición y Dietética / Servicios de Alimentación', 'Conspergo texo tabella solum veritas.', TIMESTAMP '2024-10-02 12:05:22.673000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (71, 94, 'Urgencias / Emergencias', 'Comedo conturbo concedo fuga derideo debitis abbas cur tres caste.', TIMESTAMP '2024-09-11 15:08:51.451000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (72, 93, 'Análisis Clínicos', 'Balbus demulceo pectus caries cubicularis coniecto velociter barba copia.', TIMESTAMP '2024-08-29 19:41:55.723000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (73, 80, 'Cardiología', 'Attero sum utpote.', TIMESTAMP '2024-10-23 14:32:18.558000', null, null);
INSERT INTO TEST_USER.AREA (ID, FACILITY_ID, NAME, DESCRIPTION, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (74, 65, 'Radioterapia Oncológica', 'Temporibus bene tondeo magni.', TIMESTAMP '2024-10-15 16:02:45.443000', null, null);

-- DOCTORS
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (88, 'Mayte', 'Alonzo Alcaraz', '938-137-206', 'Esperanza.AbregoPichardo@hotmail.com', TIMESTAMP '2025-02-16 23:29:06.188000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (89, 'Luis', 'Delagarza Sedillo', '939-260-225', 'Mario_CorreaGallardo1@hotmail.com', TIMESTAMP '2024-11-07 07:52:48.226000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (90, 'Maica', 'Rivero León', '989.007.580', 'Clemente3@yahoo.com', TIMESTAMP '2024-09-16 17:29:33.787000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (91, 'Amalia', 'Ochoa Olivas', '967 880 349', 'Elisa.FloresAcevedo@yahoo.com', TIMESTAMP '2025-04-15 17:41:22.805000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (92, 'Ariadna', 'Torres Tijerina', '957.960.814', 'Cristobal76@yahoo.com', TIMESTAMP '2024-11-21 23:54:03.651000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (93, 'Mayte', 'Rubio Regalado', '991878508', 'Maica.MurilloMaya26@hotmail.com', TIMESTAMP '2025-01-25 02:57:52.081000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (94, 'Julio', 'Lozada Gutiérrez', '909312909', 'Maria43@gmail.com', TIMESTAMP '2024-09-16 03:46:43.105000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (95, 'Rafael', 'Godoy Curiel', '967-264-056', 'Armando.CovarrubiasChavez@yahoo.com', TIMESTAMP '2024-09-12 15:53:47.797000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (96, 'Clara', 'Palacios Manzanares', '932.150.170', 'Gregorio.ResendezMadrigal@yahoo.com', TIMESTAMP '2024-08-08 10:30:58.057000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (97, 'María Cristina', 'Miranda Carrera', '903059974', 'Josefina43@hotmail.com', TIMESTAMP '2024-07-19 02:57:56.371000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (98, 'Alejandro', 'Estévez Holguín', '992-877-750', 'Nicolas_LovatoAvila12@gmail.com', TIMESTAMP '2024-09-20 06:53:25.199000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (99, 'Marilú', 'Alonzo Rodríguez', '928-320-249', 'Eduardo38@gmail.com', TIMESTAMP '2025-03-22 17:34:38.332000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (100, 'Rafael', 'Arredondo Coronado', '985.277.061', 'Antonio.MataCarrasquillo61@yahoo.com', TIMESTAMP '2024-09-08 08:42:18.037000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (101, 'Pablo', 'Apodaca Covarrubias', '952.589.859', 'Dolores_CastellanosLinares45@yahoo.com', TIMESTAMP '2025-03-01 08:37:19.912000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (102, 'Graciela', 'Muñiz Ponce', '942 202 985', 'Maica_JaquezLucero@gmail.com', TIMESTAMP '2024-10-24 11:57:29.473000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (103, 'Jaime', 'Oquendo Zayas', '993 079 796', 'Alicia_ReynaAvalos@gmail.com', TIMESTAMP '2025-02-01 07:06:28.439000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (104, 'Isabela', 'Salcedo Villanueva', '919787168', 'JuanCarlos.OlivarezNoriega@hotmail.com', TIMESTAMP '2024-09-15 14:07:13.212000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (105, 'Elvira', 'Chávez Cerda', '993-066-491', 'Laura_OsorioNavarrete69@hotmail.com', TIMESTAMP '2025-04-07 07:30:38.082000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (106, 'Bernardo', 'Casarez Garibay', '913.519.705', 'Daniel.DuranMedrano@hotmail.com', TIMESTAMP '2024-10-18 06:53:46.245000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (107, 'Federico', 'Aparicio Polanco', '946-826-420', 'Leticia_TellezArce54@gmail.com', TIMESTAMP '2024-07-14 09:08:11.369000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (108, 'Isabela', 'Lemus Mendoza', '948-800-182', 'Alberto36@hotmail.com', TIMESTAMP '2025-04-13 13:07:08.002000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (109, 'Micaela', 'Quezada Flores', '914-624-569', 'Javier.MelgarMontoya@hotmail.com', TIMESTAMP '2024-12-15 23:46:35.248000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (110, 'Blanca', 'Madrigal Urrutia', '902-069-551', 'Rosa.JaramilloGaitan39@yahoo.com', TIMESTAMP '2025-06-17 22:16:35.341000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (111, 'María Elena', 'Contreras Razo', '989961891', 'Adriana.MonteroLemus76@gmail.com', TIMESTAMP '2025-01-28 11:24:41.305000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (112, 'Raúl', 'Robles Espinal', '954 038 618', 'Hugo_CisnerosMaldonado@gmail.com', TIMESTAMP '2025-01-28 11:45:00.423000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (113, 'Jordi', 'Sosa Rivero', '916647670', 'Clemente.RodriguezAbreu@gmail.com', TIMESTAMP '2024-11-16 17:17:03.581000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (114, 'Mónica', 'Garay Márquez', '976-553-417', 'Lilia38@gmail.com', TIMESTAMP '2024-12-04 00:51:21.643000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (115, 'Sofía', 'Tapia Sauceda', '924548331', 'Caridad_OlveraBenavides50@yahoo.com', TIMESTAMP '2025-04-08 10:44:53.392000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (116, 'Javier', 'Amaya Abrego', '983.668.067', 'Joaquin_FelicianoRaya@gmail.com', TIMESTAMP '2024-10-15 19:14:15.443000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (117, 'Graciela', 'Montalvo Garrido', '906325038', 'LuisMiguel41@hotmail.com', TIMESTAMP '2025-04-02 17:35:35.081000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (118, 'Nicolás', 'Cerda Tafoya', '934.970.066', 'Pedro_PolancoTorres89@gmail.com', TIMESTAMP '2025-07-01 03:50:07.629000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (119, 'Jordi', 'Arriaga Meraz', '920.523.546', 'Natalia_NazarioRojo19@hotmail.com', TIMESTAMP '2025-04-07 20:24:12.179000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (120, 'Rubén', 'Rico Segovia', '924-955-547', 'JulioCesar.FariasMireles81@gmail.com', TIMESTAMP '2025-05-21 00:10:13.076000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (121, 'Tomás', 'Zepeda Echevarría', '961 434 776', 'MariaLuisa3@gmail.com', TIMESTAMP '2024-08-11 03:23:56.952000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (122, 'Andrés', 'Heredia Echevarría', '921-860-312', 'Lola0@yahoo.com', TIMESTAMP '2025-05-21 00:21:44.822000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (123, 'Hugo', 'Rivero Campos', '915-788-592', 'Marta38@yahoo.com', TIMESTAMP '2024-07-03 15:02:42.924000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (124, 'Salvador', 'Parra Delao', '924.710.632', 'Magdalena.TeranMaya@hotmail.com', TIMESTAMP '2024-11-27 06:50:58.340000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (125, 'Hugo', 'Banda Montoya', '925999811', 'JoseLuis.CottoApodaca89@gmail.com', TIMESTAMP '2025-03-07 06:00:46.237000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (126, 'Juana', 'Negrete Holguín', '902-817-038', 'Ivan_EscobarBonilla@yahoo.com', TIMESTAMP '2025-04-19 07:42:22.881000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (1, 'Patricia', 'Ornelas Guillén', '951 490 727', 'Francisco.ZepedaTello@yahoo.com', TIMESTAMP '2024-10-24 13:32:58.274000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (2, 'Daniel', 'Rosado Roque', '917040052', 'Jorge15@gmail.com', TIMESTAMP '2024-08-12 00:06:37.083000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (3, 'Margarita', 'Zayas Villanueva', '997 775 957', 'Dorotea.SevillaChavarria19@gmail.com', TIMESTAMP '2025-05-04 21:26:54.658000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (4, 'Hernán', 'Reynoso Marín', '959.485.653', 'Carla45@gmail.com', TIMESTAMP '2024-11-15 03:26:08.871000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (5, 'Laura', 'Medrano Cintrón', '913.383.959', 'Victoria22@hotmail.com', TIMESTAMP '2024-11-15 09:05:36.460000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (6, 'Gabriel', 'Nieves Navarro', '908 448 547', 'Ramon23@yahoo.com', TIMESTAMP '2024-12-05 01:17:23.408000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (7, 'Lola', 'Matías Espinosa', '930-148-919', 'Carlos.GomezMoreno@hotmail.com', TIMESTAMP '2024-11-18 03:45:15.900000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (8, 'Fernando', 'Estrada Alfaro', '972.876.580', 'Lorenzo_LeivaGomez@yahoo.com', TIMESTAMP '2025-02-08 19:15:33.152000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (9, 'Maica', 'Rael Serna', '935.058.314', 'Bernardo34@gmail.com', TIMESTAMP '2025-03-12 03:00:33.612000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (10, 'Rosalia', 'Montes Loera', '914.562.909', 'Hernan_BermudezRivera@hotmail.com', TIMESTAMP '2024-09-29 03:54:20.386000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (11, 'Maica', 'Hernández Osorio', '977-621-784', 'Dolores_SerratoOlmos52@gmail.com', TIMESTAMP '2025-03-06 18:11:32.085000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (12, 'Concepción', 'Leiva Aguilar', '948.369.363', 'Mariana7@gmail.com', TIMESTAMP '2024-08-26 07:01:10.217000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (13, 'Rocío', 'Perea Crespo', '935 122 713', 'Jeronimo41@yahoo.com', TIMESTAMP '2025-04-28 21:51:46.642000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (14, 'Rosa', 'Sevilla Véliz', '986.479.762', 'JuanRamon_GaitanRascon@hotmail.com', TIMESTAMP '2024-11-20 00:21:39.575000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (15, 'Rebeca', 'Hurtado Garibay', '954.309.500', 'Ramona.CarreraRoybal27@hotmail.com', TIMESTAMP '2025-07-02 11:14:02.535000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (16, 'Ángela', 'Aguilera Álvarez', '949.122.309', 'JoseEmilio_GallegosPedroza@gmail.com', TIMESTAMP '2025-03-01 23:57:20.216000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (17, 'Benito', 'Noriega Arteaga', '972.484.954', 'Laura33@gmail.com', TIMESTAMP '2025-05-04 08:12:37.699000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (18, 'Lucas', 'Adame García', '957.572.632', 'Alfredo_VillegasBetancourt33@yahoo.com', TIMESTAMP '2025-03-20 17:02:35.838000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (19, 'Mario', 'Mena Palomino', '979 664 792', 'Benjamin.VacaLeyva33@hotmail.com', TIMESTAMP '2024-07-11 00:11:38.825000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (20, 'Estela', 'Guardado Miramontes', '921.606.906', 'Andres80@hotmail.com', TIMESTAMP '2025-03-17 07:14:22.844000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (21, 'Bernardo', 'Molina Serrano', '985-464-541', 'David99@yahoo.com', TIMESTAMP '2024-10-22 08:59:34.269000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (22, 'Francisca', 'Estrada Ocampo', '952 666 611', 'Maica76@yahoo.com', TIMESTAMP '2025-06-20 11:14:14.521000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (23, 'Anni', 'Gamboa Luevano', '925819607', 'Luisa.CarbajalAlvarez13@gmail.com', TIMESTAMP '2024-10-06 15:37:41.297000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (24, 'Débora', 'Peña Iglesias', '940627312', 'Oscar_BarraganUrrutia@gmail.com', TIMESTAMP '2025-01-11 10:26:30.789000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (25, 'Felipe', 'Molina Quezada', '981-834-359', 'Sergi_PachecoZelaya@hotmail.com', TIMESTAMP '2024-09-09 22:00:51.838000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (26, 'José', 'Barraza Jaimes', '928846357', 'Antonio.ConcepcionQuintanilla31@yahoo.com', TIMESTAMP '2025-01-08 06:35:08.106000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (27, 'Concepción', 'Cervantes Zambrano', '921.583.568', 'Mariano83@gmail.com', TIMESTAMP '2024-07-13 04:20:49.402000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (28, 'Diana', 'Laboy Lebrón', '959962462', 'Jennifer_MaestasCollazo@gmail.com', TIMESTAMP '2025-05-31 00:17:24.928000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (29, 'Sofía', 'Matos Sierra', '997.890.164', 'Alicia.VacaQuintero43@yahoo.com', TIMESTAMP '2025-04-22 08:15:54.729000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (30, 'Maica', 'Gil Brito', '909557594', 'Gabriela5@gmail.com', TIMESTAMP '2025-05-05 23:27:30.199000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (31, 'Barbara', 'Palacios Verdugo', '944-793-290', 'Andrea.BeltranFrias@gmail.com', TIMESTAMP '2025-03-10 18:09:44.611000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (32, 'Alberto', 'Carvajal Moya', '974914150', 'Sonia78@yahoo.com', TIMESTAMP '2024-10-15 12:53:31.552000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (33, 'Víctor', 'Romero Ruíz', '934-151-771', 'Norma.CaballeroFajardo77@gmail.com', TIMESTAMP '2024-08-14 05:07:02.393000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (34, 'Anita', 'Botello Valentín', '914.441.920', 'Nicolas83@gmail.com', TIMESTAMP '2024-08-11 04:22:31.512000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (35, 'Adán', 'Guzmán Bernal', '903480669', 'Ines.IglesiasMaldonado17@hotmail.com', TIMESTAMP '2025-06-02 02:26:13.870000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (36, 'Elisa', 'Salcido Castro', '964 976 413', 'Jose_SoteloLaureano17@yahoo.com', TIMESTAMP '2025-04-10 13:49:45.876000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (37, 'Catalina', 'Jáquez Carrasquillo', '988-960-572', 'MariaSoledad.LomeliDelgado@hotmail.com', TIMESTAMP '2024-09-15 15:51:41.290000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (38, 'Claudia', 'Balderas Valenzuela', '937-570-756', 'Rosario.deJesusYanez@yahoo.com', TIMESTAMP '2024-11-28 23:25:02.122000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (39, 'María José', 'Palomino Monroy', '925849028', 'Tomas_CornejoColon@yahoo.com', TIMESTAMP '2025-04-19 09:00:31.925000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (40, 'Marco Antonio', 'Ávalos Venegas', '994 741 604', 'David90@hotmail.com', TIMESTAMP '2024-08-07 02:31:33.032000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (41, 'Diego', 'Aguilar Leal', '905099924', 'Olivia.BecerraEscobar@hotmail.com', TIMESTAMP '2024-07-25 09:22:04.748000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (42, 'Magdalena', 'Salcedo Berríos', '948.292.347', 'Homero98@yahoo.com', TIMESTAMP '2024-11-07 19:43:13.502000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (43, 'Cristóbal', 'Fajardo Cintrón', '910-260-362', 'Pedro59@gmail.com', TIMESTAMP '2024-08-08 14:54:55.091000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (44, 'María del Carmen', 'Hidalgo Tórrez', '917-458-199', 'Leonor69@gmail.com', TIMESTAMP '2024-07-18 16:49:50.067000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (45, 'Manuel', 'Orozco Casillas', '976968973', 'Sofia91@yahoo.com', TIMESTAMP '2025-03-01 22:07:23.767000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (46, 'Lorenzo', 'Magaña Mares', '966.918.551', 'Guadalupe_DelagarzaCeballos5@gmail.com', TIMESTAMP '2025-01-05 04:54:39.975000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (47, 'Graciela', 'Mendoza Gaona', '980-799-309', 'Hernan_AbreuSolorzano7@hotmail.com', TIMESTAMP '2024-08-30 03:52:57.585000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (48, 'Francisca', 'Flórez Deleón', '920491090', 'AnaMaria_MascarenasArreola86@hotmail.com', TIMESTAMP '2025-04-14 13:01:57.670000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (49, 'Lola', 'Brito Toro', '913213864', 'Jorge.CasarezCasillas8@gmail.com', TIMESTAMP '2024-07-05 04:38:34.332000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (50, 'Emilia', 'Guerrero Rojo', '973.213.782', 'Alicia.CabreraPelayo14@yahoo.com', TIMESTAMP '2024-10-26 01:21:27.414000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (51, 'Raquel', 'Caraballo Nazario', '991 096 882', 'Victor69@hotmail.com', TIMESTAMP '2024-07-31 08:13:31.934000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (52, 'Marilú', 'Rojo Luevano', '914.778.033', 'Anni_VerdugoArreola24@hotmail.com', TIMESTAMP '2024-09-10 03:04:57.660000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (53, 'Rosa', 'Villanueva Tello', '938-888-795', 'Francisco_OrdonezGamboa35@gmail.com', TIMESTAMP '2024-10-12 10:15:54.719000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (54, 'Luisa', 'Laboy Casares', '912779149', 'JuanRamon_RangelRocha@hotmail.com', TIMESTAMP '2025-04-24 08:27:05.128000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (55, 'Ana', 'Guillén Rosario', '972-084-676', 'MariaEugenia.PenaPina@hotmail.com', TIMESTAMP '2024-12-06 03:30:18.828000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (56, 'Cristián', 'Chávez Moreno', '979.757.324', 'Lola_ArmasCadena@gmail.com', TIMESTAMP '2024-12-03 21:43:36.533000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (57, 'Gonzalo', 'Batista Iglesias', '978.850.430', 'Hernan74@yahoo.com', TIMESTAMP '2025-02-13 20:32:23.791000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (58, 'Daniel', 'Urías Córdova', '962890673', 'Fernando_GuevaraSamaniego61@yahoo.com', TIMESTAMP '2025-04-18 10:45:32.041000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (59, 'Raquel', 'Olivo Galván', '992 785 278', 'Josefina16@yahoo.com', TIMESTAMP '2025-02-25 01:07:24.600000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (60, 'Juan', 'Cuellar Vázquez', '953-750-642', 'Ricardo_TamezOcampo@hotmail.com', TIMESTAMP '2024-08-27 22:17:39.838000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (61, 'Pío', 'Rentería Mendoza', '910-728-328', 'Ines_ArmijoSalazar@hotmail.com', TIMESTAMP '2025-06-28 18:16:16.616000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (62, 'Claudio', 'Romero Leyva', '955 647 203', 'MariaSoledad81@yahoo.com', TIMESTAMP '2025-05-03 20:25:35.126000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (63, 'Ana Luisa', 'Godínez Camacho', '945 137 479', 'Yolanda.MarquezSaldana94@gmail.com', TIMESTAMP '2025-05-28 15:05:53.645000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (64, 'Jorge', 'Santiago Mata', '915 375 421', 'Esperanza91@hotmail.com', TIMESTAMP '2025-03-20 07:17:52.570000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (65, 'José Eduardo', 'Aranda Garza', '973.647.191', 'Reina.MoraAyala67@yahoo.com', TIMESTAMP '2024-10-11 05:09:36.120000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (66, 'Francisca', 'Abeyta Blanco', '966-865-437', 'Rosalia_TorrezCervantes@gmail.com', TIMESTAMP '2025-03-09 04:30:03.162000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (67, 'Juan', 'Moya Zambrano', '966-383-245', 'Juan_AlcalaTijerina71@gmail.com', TIMESTAMP '2025-06-17 12:28:24.358000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (68, 'Alejandro', 'Terrazas Abrego', '989308364', 'Felipe.NevarezAponte73@hotmail.com', TIMESTAMP '2025-01-03 10:51:21.889000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (69, 'Rebeca', 'Montéz Zelaya', '975-937-734', 'Ruben.TejadaValdivia86@hotmail.com', TIMESTAMP '2025-04-10 18:29:36.546000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (70, 'Diana', 'Pabón Cedillo', '967 876 489', 'Andres10@hotmail.com', TIMESTAMP '2025-05-17 10:08:47.242000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (71, 'Diego', 'Vallejo Guzmán', '993 832 928', 'MariaEugenia41@gmail.com', TIMESTAMP '2024-07-08 03:22:26.624000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (72, 'Eloisa', 'Velásquez Marrero', '903 969 277', 'Mariano_QuinonezRael@yahoo.com', TIMESTAMP '2025-06-07 04:39:29.344000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (73, 'Claudia', 'Atencio Montenegro', '957.687.091', 'Rosa39@hotmail.com', TIMESTAMP '2024-08-08 07:52:32.374000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (74, 'Eva', 'Olivares Delapaz', '945 244 178', 'Timoteo62@gmail.com', TIMESTAMP '2024-09-19 01:04:40.263000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (75, 'Lorena', 'Mireles Muñoz', '959152182', 'Natalia57@yahoo.com', TIMESTAMP '2024-12-30 14:59:36.233000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (76, 'Felipe', 'Garza Navarrete', '944.480.735', 'Agustin.CamachoBustos68@yahoo.com', TIMESTAMP '2024-10-30 02:17:23.692000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (77, 'Cecilia', 'Robles Zaragoza', '935-642-207', 'Luis8@gmail.com', TIMESTAMP '2025-04-25 15:30:20.723000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (78, 'Marcela', 'Mojica Quesada', '982 780 254', 'Emilio_IglesiasVarela@gmail.com', TIMESTAMP '2025-05-17 08:41:51.647000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (79, 'Mayte', 'Salazar Argüello', '958.614.927', 'Antonio95@hotmail.com', TIMESTAMP '2025-03-02 13:37:43.355000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (80, 'José Luis', 'Sáenz Valle', '995-640-592', 'Armando.MaldonadoLopez85@hotmail.com', TIMESTAMP '2024-10-19 09:51:37.565000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (81, 'Guillermina', 'Brito Pichardo', '973.393.046', 'Pilar_NunezGranados@yahoo.com', TIMESTAMP '2025-04-04 05:51:46.212000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (82, 'Amalia', 'Segovia Olivas', '904292259', 'Gloria98@gmail.com', TIMESTAMP '2024-12-13 16:02:09.346000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (83, 'Victoria', 'Cepeda Terrazas', '920414861', 'Cecilia41@gmail.com', TIMESTAMP '2024-10-22 18:40:40.612000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (84, 'Mercedes', 'Nieto Santiago', '916 385 583', 'Vicente1@gmail.com', TIMESTAMP '2025-02-28 21:58:24.826000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (85, 'Margarita', 'Crespo Esquivel', '998563761', 'Francisco_OlivarezSalcido@yahoo.com', TIMESTAMP '2024-10-25 07:12:02.914000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (86, 'Federico', 'Cardona Baca', '994-579-223', 'Marcos.MayaOrosco9@hotmail.com', TIMESTAMP '2024-12-08 12:50:45.887000', null, null);
INSERT INTO TEST_USER.DOCTOR (ID, FIRST_NAME, LAST_NAME, PHONE, EMAIL, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (87, 'Rafael', 'Salgado Verduzco', '935.711.941', 'Leonor_VelizValladares@yahoo.com', TIMESTAMP '2025-04-07 18:09:20.744000', null, null);

-- DOCTOR_FACILITIES
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (49, 2);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (76, 3);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (62, 4);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (35, 6);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (74, 6);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (41, 7);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (6, 10);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (17, 10);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (28, 11);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (34, 12);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (59, 12);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (5, 13);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (62, 13);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (72, 13);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (58, 16);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (78, 16);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (81, 17);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (36, 18);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (3, 19);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (68, 19);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (22, 20);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (17, 21);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (8, 22);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (71, 23);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (18, 24);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (19, 27);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (28, 29);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (23, 30);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (55, 31);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (65, 31);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (77, 31);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (53, 32);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (57, 32);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (81, 32);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (3, 33);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (56, 35);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (24, 37);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (31, 38);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (80, 38);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (14, 40);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (27, 40);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (3, 41);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (5, 41);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (52, 41);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (63, 41);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (67, 43);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (69, 43);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (77, 43);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (45, 44);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (44, 45);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (67, 45);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (45, 46);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (65, 46);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (24, 47);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (1, 48);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (76, 48);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (15, 49);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (68, 49);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (76, 49);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (54, 50);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (2, 51);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (62, 51);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (76, 52);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (1, 55);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (11, 57);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (72, 58);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (75, 58);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (5, 59);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (27, 60);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (58, 60);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (47, 61);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (16, 62);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (7, 63);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (23, 65);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (15, 66);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (10, 68);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (36, 69);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (51, 70);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (71, 72);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (7, 74);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (26, 74);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (18, 78);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (70, 78);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (23, 79);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (11, 80);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (19, 81);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (80, 81);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (41, 83);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (34, 84);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (41, 84);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (78, 84);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (4, 85);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (32, 85);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (52, 88);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (32, 90);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (35, 90);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (32, 91);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (43, 91);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (73, 91);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (24, 92);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (77, 92);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (19, 93);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (42, 96);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (36, 97);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (22, 98);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (59, 99);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (5, 100);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (21, 100);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (51, 100);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (14, 102);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (55, 104);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (33, 105);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (36, 106);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (49, 106);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (19, 107);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (3, 108);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (81, 109);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (9, 111);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (39, 111);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (79, 111);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (80, 112);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (5, 113);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (76, 113);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (41, 114);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (28, 115);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (37, 115);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (18, 116);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (27, 116);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (1, 119);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (29, 120);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (81, 120);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (6, 121);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (29, 121);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (30, 121);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (11, 122);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (33, 122);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (72, 122);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (9, 123);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (12, 123);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (19, 123);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (20, 124);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (40, 124);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (59, 124);
INSERT INTO TEST_USER.DOCTOR_FACILITY (AREA_ID, DOCTOR_ID) VALUES (39, 126);

-- Rooms
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (17, 79, 'Room 0', 'The sleek and nice Toallas comes with blanco LED lighting for smart functionality', TIMESTAMP '2024-08-12 01:40:33.175000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (18, 78, 'Room 1', 'New Bicicleta model with 71 GB RAM, 434 GB storage, and long features', TIMESTAMP '2025-05-08 14:24:00.721000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (19, 74, 'Room 2', 'Professional-grade Zapatos perfect for probable training and recreational use', TIMESTAMP '2024-11-03 08:02:28.416000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (20, 13, 'Room 3', 'The Gilberto Raton is the latest in a series of moist products from Fonseca, Caraballo y Romero Asociados', TIMESTAMP '2025-02-13 14:48:21.039000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (21, 37, 'Room 4', 'Our moist-inspired Camiseta brings a taste of luxury to your deficient lifestyle', TIMESTAMP '2024-11-02 10:55:46.550000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (22, 48, 'Room 5', 'Savor the moist essence in our Sopa, designed for ultimate culinary adventures', TIMESTAMP '2024-08-21 10:54:52.951000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (23, 30, 'Room 6', 'Introducing the Estonia-inspired Pizza, blending another style with local craftsmanship', TIMESTAMP '2024-12-05 21:53:59.046000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (24, 7, 'Room 7', 'Savor the bitter essence in our Patatas fritas, designed for appropriate culinary adventures', TIMESTAMP '2024-07-16 16:49:16.930000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (25, 41, 'Room 8', 'Discover the frog-like agility of our Silla, perfect for superior users', TIMESTAMP '2024-07-17 11:59:19.577000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (26, 17, 'Room 9', 'The Centrado en el usuario asíncrona marco de tiempo Ensalada offers reliable performance and average design', TIMESTAMP '2025-01-26 23:42:19.329000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (27, 68, 'Room 10', 'Our juicy-inspired Pollo brings a taste of luxury to your nimble lifestyle', TIMESTAMP '2024-10-28 08:02:24.751000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (28, 9, 'Room 11', 'Discover the hippopotamus-like agility of our Camiseta, perfect for royal users', TIMESTAMP '2025-06-19 22:40:37.234000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (29, 40, 'Room 12', 'New fucsia Sopa with ergonomic design for discrete comfort', TIMESTAMP '2024-10-27 07:12:41.046000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (30, 17, 'Room 13', 'Introducing the Costa de Marfil-inspired Pantalones, blending simple style with local craftsmanship', TIMESTAMP '2024-09-04 03:24:32.636000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (31, 66, 'Room 14', 'Discover the fish-like agility of our Pollo, perfect for puny users', TIMESTAMP '2025-03-24 13:27:51.792000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (32, 4, 'Room 15', 'Experience the amarillo brilliance of our Raton, perfect for candid environments', TIMESTAMP '2025-02-12 11:59:38.105000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (33, 12, 'Room 16', 'The Visionario coherente colaboración Pescado offers reliable performance and direct design', TIMESTAMP '2024-10-20 18:01:36.942000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (34, 74, 'Room 17', 'Sorprendente Guantes designed with Acero for likable performance', TIMESTAMP '2024-12-17 20:05:02.323000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (35, 76, 'Room 18', 'The Fundamental sensible al contexto metodologías Camiseta offers reliable performance and lumpy design', TIMESTAMP '2025-01-06 16:05:51.025000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (36, 78, 'Room 19', 'Discover the cooperative new Coche with an exciting mix of Plástico ingredients', TIMESTAMP '2025-06-04 17:36:25.510000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (37, 43, 'Room 20', 'Our fox-friendly Toallas ensures minor comfort for your pets', TIMESTAMP '2024-12-05 08:58:12.044000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (38, 11, 'Room 21', 'The Óscar Pelota is the latest in a series of alert products from Escobar y Girón', TIMESTAMP '2024-09-21 01:06:19.939000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (39, 42, 'Room 22', 'Discover the brown new Raton with an exciting mix of Algodón ingredients', TIMESTAMP '2024-12-19 02:55:42.968000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (40, 62, 'Room 23', 'Ergonómico Pelota designed with Hormigon for actual performance', TIMESTAMP '2024-11-27 01:53:28.329000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (41, 13, 'Room 24', 'Innovative Bacon featuring raw technology and Hormigon construction', TIMESTAMP '2024-07-09 11:42:11.275000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (42, 57, 'Room 25', 'Innovative Teclado featuring tense technology and Granito construction', TIMESTAMP '2025-03-19 06:20:30.999000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (43, 18, 'Room 26', 'The Gerardo Bicicleta is the latest in a series of oddball products from Bravo Ríos Hermanos', TIMESTAMP '2024-11-13 20:07:53.576000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (44, 45, 'Room 27', 'New magenta Camiseta with ergonomic design for useless comfort', TIMESTAMP '2025-06-02 13:01:02.012000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (45, 81, 'Room 28', 'The sleek and broken Camiseta comes with celeste LED lighting for smart functionality', TIMESTAMP '2025-04-30 18:03:22.476000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (46, 53, 'Room 29', 'Ergonomic Salchichas made with Hormigon for all-day rural support', TIMESTAMP '2024-08-30 12:00:45.606000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (47, 31, 'Room 30', 'Ergonomic Pantalones made with Hormigon for all-day whirlwind support', TIMESTAMP '2025-02-21 10:14:27.690000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (48, 48, 'Room 31', 'Savor the creamy essence in our Pollo, designed for back culinary adventures', TIMESTAMP '2024-10-02 12:51:58.881000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (49, 21, 'Room 32', 'Contreras Hermanos''s most advanced Ordenador technology increases negative capabilities', TIMESTAMP '2025-01-12 08:18:37.481000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (50, 72, 'Room 33', 'Our squirrel-friendly Pantalones ensures stiff comfort for your pets', TIMESTAMP '2025-02-27 10:18:50.718000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (51, 49, 'Room 34', 'The Daniel Mesa is the latest in a series of acceptable products from Briones y Pedraza', TIMESTAMP '2025-01-12 17:26:26.003000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (52, 73, 'Room 35', 'Professional-grade Teclado perfect for stained training and recreational use', TIMESTAMP '2025-01-02 16:58:07.440000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (53, 8, 'Room 36', 'Professional-grade Queso perfect for pale training and recreational use', TIMESTAMP '2025-05-31 09:31:12.282000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (54, 68, 'Room 37', 'The Teodoro Pizza is the latest in a series of fortunate products from Paz e Hijos', TIMESTAMP '2024-12-10 07:48:44.713000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (55, 45, 'Room 38', 'Innovative Raton featuring mysterious technology and Hormigon construction', TIMESTAMP '2025-02-11 00:03:17.679000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (56, 23, 'Room 39', 'New lavanda Ensalada with ergonomic design for total comfort', TIMESTAMP '2024-10-16 04:32:45.510000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (57, 45, 'Room 40', 'New Zapatos model with 35 GB RAM, 543 GB storage, and flustered features', TIMESTAMP '2025-04-17 16:21:19.528000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (58, 7, 'Room 41', 'The azul marino Ordenador combines Alemania aesthetics with Lutetium-based durability', TIMESTAMP '2024-11-12 18:32:57.594000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (59, 62, 'Room 42', 'The Lucas Camiseta is the latest in a series of sociable products from Saavedra, Esparza y Solano Asociados', TIMESTAMP '2024-07-03 09:29:56.691000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (60, 47, 'Room 43', 'The sleek and silent Pelota comes with fucsia LED lighting for smart functionality', TIMESTAMP '2025-05-23 00:10:36.146000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (61, 10, 'Room 44', 'Innovative Raton featuring illiterate technology and Metal construction', TIMESTAMP '2025-01-10 23:40:15.626000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (62, 54, 'Room 45', 'The sleek and imaginative Pescado comes with plateado LED lighting for smart functionality', TIMESTAMP '2024-09-24 05:38:38.836000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (63, 40, 'Room 46', 'Discover the sure-footed new Salchichas with an exciting mix of Algodón ingredients', TIMESTAMP '2024-07-25 00:30:51.581000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (64, 71, 'Room 47', 'Rústico Raton designed with Plástico for creative performance', TIMESTAMP '2025-01-13 04:38:36.824000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (65, 5, 'Room 48', 'Professional-grade Ensalada perfect for easy training and recreational use', TIMESTAMP '2025-02-25 21:28:44.202000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (66, 52, 'Room 49', 'Increible Guantes designed with Granito for pushy performance', TIMESTAMP '2024-11-04 03:41:06.936000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (67, 13, 'Room 50', 'Professional-grade Silla perfect for ugly training and recreational use', TIMESTAMP '2024-07-05 00:19:37.293000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (68, 57, 'Room 51', 'The sleek and immaculate Bacon comes with beige LED lighting for smart functionality', TIMESTAMP '2024-08-22 10:20:19.291000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (69, 42, 'Room 52', 'The Compartible no-volátil actitud Raton offers reliable performance and harmful design', TIMESTAMP '2025-06-27 17:40:53.651000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (70, 56, 'Room 53', 'Featuring Chlorine-enhanced technology, our Pelota offers unparalleled stable performance', TIMESTAMP '2025-05-10 06:05:07.308000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (71, 56, 'Room 54', 'Experience the naranja brilliance of our Camiseta, perfect for strict environments', TIMESTAMP '2025-04-30 13:32:01.179000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (72, 59, 'Room 55', 'Our spicy-inspired Mesa brings a taste of luxury to your ambitious lifestyle', TIMESTAMP '2025-07-01 16:34:36.656000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (73, 9, 'Room 56', 'Artesanal Pollo designed with Granito for blind performance', TIMESTAMP '2024-08-23 09:34:27.973000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (74, 41, 'Room 57', 'Our peacock-friendly Mesa ensures big comfort for your pets', TIMESTAMP '2025-01-11 02:37:12.077000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (75, 18, 'Room 58', 'New Gorro model with 80 GB RAM, 734 GB storage, and hospitable features', TIMESTAMP '2024-10-02 11:47:56.372000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (76, 26, 'Room 59', 'New fucsia Pelota with ergonomic design for unwritten comfort', TIMESTAMP '2024-07-02 23:59:00.964000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (77, 72, 'Room 60', 'Barela y Quiñones''s most advanced Bacon technology increases puny capabilities', TIMESTAMP '2024-09-18 02:20:52.360000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (78, 68, 'Room 61', 'The Daniela Pollo is the latest in a series of lively products from Montalvo y Delgado', TIMESTAMP '2024-11-10 20:21:57.419000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (79, 52, 'Room 62', 'Rústico Bicicleta designed with Acero for bitter performance', TIMESTAMP '2025-01-17 09:29:08.865000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (80, 71, 'Room 63', 'Discover the horse-like agility of our Queso, perfect for unpleasant users', TIMESTAMP '2025-04-22 18:42:47.621000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (81, 12, 'Room 64', 'The Ignacio Coche is the latest in a series of sad products from Cortéz Negrón Hermanos', TIMESTAMP '2024-08-12 04:59:20.221000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (82, 69, 'Room 65', 'New Bacon model with 95 GB RAM, 949 GB storage, and tricky features', TIMESTAMP '2024-12-01 20:45:27.120000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (83, 59, 'Room 66', 'Fantástico Mesa designed with Ladrillo for arid performance', TIMESTAMP '2025-06-05 11:04:29.228000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (84, 70, 'Room 67', 'The celeste Gorro combines Irlanda aesthetics with Titanium-based durability', TIMESTAMP '2025-01-11 15:30:27.519000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (85, 47, 'Room 68', 'Professional-grade Toallas perfect for digital training and recreational use', TIMESTAMP '2024-10-30 18:04:21.758000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (86, 41, 'Room 69', 'The Orígenes generada por el cliente arquitectura Sopa offers reliable performance and submissive design', TIMESTAMP '2025-05-18 21:15:00.949000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (87, 8, 'Room 70', 'Experience the terracota brilliance of our Sopa, perfect for red environments', TIMESTAMP '2025-04-26 19:24:13.124000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (88, 52, 'Room 71', 'Experience the índigo brilliance of our Gorro, perfect for well-lit environments', TIMESTAMP '2024-08-13 17:45:23.052000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (89, 55, 'Room 72', 'The Juan Ensalada is the latest in a series of hungry products from Cisneros y Rico', TIMESTAMP '2024-10-11 15:04:11.421000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (90, 35, 'Room 73', 'Discover the crocodile-like agility of our Pollo, perfect for energetic users', TIMESTAMP '2024-10-20 06:58:15.678000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (91, 41, 'Room 74', 'Fantástico Pizza designed with Hormigon for trim performance', TIMESTAMP '2024-07-26 03:28:02.567000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (92, 2, 'Room 75', 'Innovative Pantalones featuring well-made technology and Madera construction', TIMESTAMP '2025-02-24 01:51:54.147000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (93, 12, 'Room 76', 'Innovative Queso featuring dull technology and Madera construction', TIMESTAMP '2024-07-13 22:56:54.989000', null);
INSERT INTO TEST_USER.ROOM (ID, AREA_ID, NAME, DESCRIPTION, CREATED_AT, DELETED_AT) VALUES (94, 38, 'Room 77', 'Professional-grade Raton perfect for knowledgeable training and recreational use', TIMESTAMP '2025-03-24 09:11:55.546000', null);

-- PATIENTS
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Jorge Luis', 'Sierra Alfaro', TIMESTAMP '1998-10-21 18:00:00', 0, '993 958 023', 'AnaLuisa86@hotmail.com', 'Urbanización Ángela Villanueva s/n.', TIMESTAMP '2025-03-13 10:05:50.560000', null, null, 61);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Leonor', 'Sanabria Acuña', TIMESTAMP '1948-05-07 18:00:00', 1, '988471523', 'Octavio59@gmail.com', 'Arrabal Verónica s/n.', TIMESTAMP '2024-12-10 07:36:57.114000', null, null, 62);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Alejandro', 'Archuleta Robledo', TIMESTAMP '1968-06-15 18:00:00', 1, '901.825.725', 'Diego_PachecoMayorga@hotmail.com', 'Entrada Jaime Angulo, 6', TIMESTAMP '2025-06-24 11:58:12.425000', null, null, 63);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Marilú', 'Murillo Montemayor', TIMESTAMP '1953-11-27 18:00:00', 1, '970 214 012', 'Luz19@hotmail.com', 'Poblado Teresa 9', TIMESTAMP '2025-05-23 16:10:08.915000', null, null, 64);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Adela', 'Quiñones Mata', TIMESTAMP '1993-06-22 18:00:00', 0, '917.319.426', 'Esteban8@yahoo.com', 'Arroyo Luz, 8', TIMESTAMP '2024-10-09 19:33:54.888000', null, null, 65);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Alejandra', 'Zapata Galarza', TIMESTAMP '2000-07-27 18:00:00', 0, '951-373-028', 'Olivia_MarreroAranda52@yahoo.com', 'Ramal Concepción Matías, 29', TIMESTAMP '2025-04-17 05:36:41.555000', null, null, 66);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Gustavo', 'Holguín Robledo', TIMESTAMP '1938-10-25 18:00:00', 1, '938-123-064', 'Jordi.CruzResendez81@gmail.com', 'Rua Jordi Cerda 34', TIMESTAMP '2024-12-07 05:22:41.090000', null, null, 67);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Sergi', 'Preciado Solorzano', TIMESTAMP '1940-03-24 18:00:00', 1, '933-471-367', 'Raquel.GranadosOcampo30@yahoo.com', 'Vía Luisa 77', TIMESTAMP '2024-07-02 20:53:48.156000', null, null, 68);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Norma', 'Madera Urbina', TIMESTAMP '1966-06-01 18:00:00', 0, '907-864-688', 'German85@gmail.com', 'Calle Jorge Luis, 2', TIMESTAMP '2024-07-05 08:30:07.053000', null, null, 69);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Barbara', 'Bravo Zayas', TIMESTAMP '1982-12-01 18:00:00', 1, '979943887', 'Ramona15@yahoo.com', 'Lado Hugo Nieves, 60', TIMESTAMP '2025-02-27 18:19:41.324000', null, null, 70);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Carlota', 'Báez Ozuna', TIMESTAMP '1995-11-04 18:00:00', 0, '971-573-499', 'Leonor_PadillaCantu63@gmail.com', 'Prolongación Caridad Hernández, 8', TIMESTAMP '2025-04-09 13:00:26.739000', null, null, 71);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Lucía', 'Calvillo Caraballo', TIMESTAMP '1963-01-03 18:00:00', 0, '986.391.793', 'Teresa.AcostaLucio27@hotmail.com', 'Conjunto Patricia Lomeli, 85', TIMESTAMP '2024-07-11 06:55:43.662000', null, null, 72);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Hernán', 'León Arenas', TIMESTAMP '1976-11-04 18:00:00', 1, '967638663', 'Dolores46@gmail.com', 'Rambla Juan Carlos, 40', TIMESTAMP '2025-01-07 07:26:30.673000', null, null, 73);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('César', 'Haro Villa', TIMESTAMP '1962-07-14 18:00:00', 0, '946-993-165', 'Amalia.MolinaSantillan56@gmail.com', 'Entrada Gilberto Delrío 4', TIMESTAMP '2024-07-27 07:56:35.243000', null, null, 74);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Rosa', 'Leal Ortiz', TIMESTAMP '1978-06-01 18:00:00', 1, '918 162 836', 'Luz_OrtizFerrer70@yahoo.com', 'Caserio Federico 85', TIMESTAMP '2024-07-21 14:49:53.576000', null, null, 75);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Claudia', 'Vaca Fierro', TIMESTAMP '1957-08-26 18:00:00', 0, '910-017-737', 'Lucas.TorrezZamora64@gmail.com', 'Puente Nicolás Tello 1', TIMESTAMP '2025-05-03 14:15:49.084000', null, null, 76);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('José Luis', 'Rodarte Pabón', TIMESTAMP '1935-01-04 18:00:00', 1, '903 881 258', 'Jennifer14@gmail.com', 'Bajada Rubén, 28', TIMESTAMP '2024-10-03 00:52:53.519000', null, null, 77);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Maricarmen', 'Toledo Flórez', TIMESTAMP '1958-05-20 18:00:00', 1, '929.079.998', 'Olivia_ArreolaQuezada58@hotmail.com', 'Muelle José Eduardo, 51', TIMESTAMP '2024-11-16 20:35:54.981000', null, null, 78);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Jacobo', 'Santiago Mireles', TIMESTAMP '1960-01-28 18:00:00', 0, '946 159 927', 'Leonor.LaboyGurule@yahoo.com', 'Sector Berta Barraza 46', TIMESTAMP '2024-07-02 13:46:38.905000', null, null, 79);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Homero', 'Santillán Esquibel', TIMESTAMP '2000-12-09 18:00:00', 1, '939.974.322', 'Clara_JassoFerrer55@yahoo.com', 'Ronda María Anguiano 64', TIMESTAMP '2025-04-07 15:12:56.372000', null, null, 80);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Alberto', 'Roque Cazares', TIMESTAMP '1989-12-16 18:00:00', 1, '952.467.463', 'MariaElena21@yahoo.com', 'Barranco Elisa 2', TIMESTAMP '2025-02-14 11:59:14.660000', null, null, 81);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Cristóbal', 'Baeza Abeyta', TIMESTAMP '1990-04-12 18:00:00', 1, '964 549 298', 'MariaElena93@hotmail.com', 'Plaza Gabriel Ríos, 7', TIMESTAMP '2025-01-26 04:34:02.066000', null, null, 82);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('José', 'Garay Orellana', TIMESTAMP '2003-02-12 18:00:00', 1, '916782637', 'Salvador39@gmail.com', 'Extrarradio Elisa Castro 7', TIMESTAMP '2025-01-12 23:37:24.092000', null, null, 83);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Jacobo', 'Ruíz Salcedo', TIMESTAMP '1983-10-14 18:00:00', 1, '982-166-246', 'Marcos_DiazBarrera@yahoo.com', 'Arroyo Teodoro s/n.', TIMESTAMP '2024-08-02 00:39:05.678000', null, null, 84);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Marcos', 'Cuellar Rivas', TIMESTAMP '1944-01-11 18:00:00', 0, '984457951', 'AnaMaria76@yahoo.com', 'Caserio Adán Villaseñor, 26', TIMESTAMP '2024-10-20 19:45:44.387000', null, null, 85);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('José Eduardo', 'Feliciano Medina', TIMESTAMP '1963-02-11 18:00:00', 1, '993.817.418', 'Raquel_MuroBurgos88@hotmail.com', 'Plaza María Cristina Alaníz s/n.', TIMESTAMP '2025-02-16 23:40:04.892000', null, null, 86);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Josep', 'Botello Rincón', TIMESTAMP '1966-12-09 18:00:00', 1, '983184517', 'Debora.VillalpandoChacon33@gmail.com', 'Calle Esperanza, 4', TIMESTAMP '2025-01-06 08:09:44.382000', null, null, 87);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Miguel Ángel', 'Palomo Fernández', TIMESTAMP '1952-06-22 18:00:00', 0, '917-155-789', 'Homero_PulidoRojo75@hotmail.com', 'Explanada Isabela, 2', TIMESTAMP '2024-09-18 18:09:30.715000', null, null, 88);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('José Eduardo', 'Briones Argüello', TIMESTAMP '1949-10-09 18:00:00', 1, '968995224', 'JuanCarlos8@yahoo.com', 'Jardines Diego Delapaz, 95', TIMESTAMP '2024-11-23 21:02:03.554000', null, null, 89);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Lucía', 'Álvarez Ibarra', TIMESTAMP '1979-11-13 18:00:00', 0, '989.557.649', 'Hermenegildo.AgostoVillalobos@yahoo.com', 'Paseo Pablo, 8', TIMESTAMP '2024-12-07 14:30:15.632000', null, null, 90);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Julio César', 'Villanueva Haro', TIMESTAMP '1967-08-29 18:00:00', 0, '995-059-633', 'Ivan94@hotmail.com', 'Calle Jacobo Casares 21', TIMESTAMP '2025-05-29 23:39:59.882000', null, null, 91);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Sergi', 'Acevedo Salcedo', TIMESTAMP '1965-07-14 18:00:00', 0, '924328375', 'Joaquin81@yahoo.com', 'Rambla Antonia 92', TIMESTAMP '2025-06-12 05:19:13.271000', null, null, 92);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Clara', 'Rivas Casanova', TIMESTAMP '1995-12-22 18:00:00', 1, '904.753.876', 'Mayte.PreciadoPuga83@hotmail.com', 'Prolongación César, 75', TIMESTAMP '2024-09-27 23:41:51.311000', null, null, 93);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Teresa', 'Solorzano Castillo', TIMESTAMP '1976-01-30 18:00:00', 1, '928448144', 'Amalia26@yahoo.com', 'Mercado Raquel, 26', TIMESTAMP '2024-11-27 20:40:31.871000', null, null, 94);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Julio', 'Barraza Marín', TIMESTAMP '1984-08-29 18:00:00', 1, '999 116 053', 'Elena_OrtegaPorras88@yahoo.com', 'Mercado Hernán Torres 9', TIMESTAMP '2024-10-26 13:24:24.337000', null, null, 95);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('María Luisa', 'Tirado Orozco', TIMESTAMP '2005-10-28 18:00:00', 1, '969.647.375', 'Patricio98@hotmail.com', 'Extrarradio Miguel Sandoval 22', TIMESTAMP '2025-04-28 22:46:19.211000', null, null, 96);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('María Luisa', 'Serrato Saavedra', TIMESTAMP '1999-06-09 18:00:00', 1, '921 021 510', 'Hermenegildo.NavaEscamilla@gmail.com', 'Ronda Francisca 66', TIMESTAMP '2024-09-18 05:52:31.418000', null, null, 97);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Ángel', 'Leiva Uribe', TIMESTAMP '1992-10-24 18:00:00', 1, '947.862.196', 'Cecilia.CaraballoChavez@yahoo.com', 'Paseo Jacobo Zúñiga s/n.', TIMESTAMP '2025-01-13 06:24:18.370000', null, null, 98);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('María Cristina', 'Urías Sierra', TIMESTAMP '1935-08-01 18:00:00', 1, '957.918.865', 'Norma27@hotmail.com', 'Sector Juan Carlos 1', TIMESTAMP '2025-04-05 08:34:35.956000', null, null, 99);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Andrés', 'Jaramillo Vaca', TIMESTAMP '1998-12-11 18:00:00', 1, '963-125-296', 'Carlota.VerdugoTrevino41@gmail.com', 'Plaza Vicente Guzmán s/n.', TIMESTAMP '2024-12-12 00:17:48.756000', null, null, 100);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Cecilia', 'Núñez Salinas', TIMESTAMP '1979-03-13 19:00:00', 0, '927-893-288', 'Alfredo46@gmail.com', 'Sección Maricarmen Montoya 7', TIMESTAMP '2025-05-27 01:55:46.043000', null, null, 101);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Eduardo', 'Zepeda Barajas', TIMESTAMP '1967-02-20 18:00:00', 1, '955-985-282', 'Joaquin_TiradoSantacruz@gmail.com', 'Pasaje Soledad Lemus s/n.', TIMESTAMP '2025-04-19 13:41:42.035000', null, null, 102);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('José Luis', 'Zambrano Meza', TIMESTAMP '1994-08-07 18:00:00', 0, '987721861', 'Elisa_SerratoNieto@hotmail.com', 'Salida Luisa Loera, 9', TIMESTAMP '2024-08-05 22:32:35.805000', null, null, 103);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Jaime', 'Tello Ayala', TIMESTAMP '1995-07-28 18:00:00', 1, '944-537-055', 'MariaJose.RodriguezDeleon88@yahoo.com', 'Torrente Agustín 44', TIMESTAMP '2024-12-22 09:24:40.211000', null, null, 104);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Norma', 'Granado Saldaña', TIMESTAMP '1938-12-18 18:00:00', 1, '963.559.338', 'Ines80@yahoo.com', 'Avenida Andrea 14', TIMESTAMP '2024-09-09 08:59:45.943000', null, null, 105);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Mario', 'Avilés Olivera', TIMESTAMP '1962-02-12 18:00:00', 0, '993980721', 'Lourdes18@hotmail.com', 'Polígono Sonia s/n.', TIMESTAMP '2024-11-26 08:20:32.229000', null, null, 106);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Matilde', 'Cintrón Posada', TIMESTAMP '1934-10-02 18:00:00', 0, '971 007 658', 'Rocio_OlivaresCano@yahoo.com', 'Huerta Miguel, 73', TIMESTAMP '2025-02-21 21:35:39.728000', null, null, 107);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Hugo', 'Miranda Haro', TIMESTAMP '1976-03-06 18:00:00', 0, '959-233-492', 'Carlota.AlonzoAtencio@yahoo.com', 'Ramal Gloria Montes 47', TIMESTAMP '2024-11-25 09:38:16.287000', null, null, 108);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Mayte', 'Armendáriz Moreno', TIMESTAMP '2000-04-01 18:00:00', 1, '944919444', 'Francisco.deJesusCarrera53@yahoo.com', 'Entrada Luis, 8', TIMESTAMP '2024-08-21 06:14:14.728000', null, null, 109);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Timoteo', 'Bustos Mares', TIMESTAMP '1984-07-06 18:00:00', 1, '930-226-188', 'Lilia_RomoRoldan14@yahoo.com', 'Sector Mónica, 37', TIMESTAMP '2024-07-20 10:30:16.792000', null, null, 110);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Elisa', 'Báez Toledo', TIMESTAMP '1944-04-01 18:00:00', 1, '927590421', 'Veronica.ParedesRosario@hotmail.com', 'Bajada César Rojas, 96', TIMESTAMP '2024-08-31 12:12:43.977000', null, null, 111);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Fernando', 'Altamirano Casanova', TIMESTAMP '1935-09-03 18:00:00', 1, '948 635 722', 'AnaLuisa24@gmail.com', 'Carretera Adela Mejía, 2', TIMESTAMP '2024-08-03 13:22:39.720000', null, null, 112);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('María Eugenia', 'Negrón Vargas', TIMESTAMP '1965-05-21 18:00:00', 0, '933.140.455', 'LuisMiguel_CorderoVargas@yahoo.com', 'Vía Pública Felipe Lugo 26', TIMESTAMP '2025-01-04 15:12:41.039000', null, null, 113);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('María Soledad', 'Vega Botello', TIMESTAMP '1936-12-16 18:00:00', 1, '950.196.133', 'MariaCristina.BarriosOrosco@yahoo.com', 'Polígono Antonio, 68', TIMESTAMP '2025-02-03 18:11:16.838000', null, null, 114);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Mario', 'Paredes Ibarra', TIMESTAMP '1978-06-13 18:00:00', 0, '998 645 762', 'Roser_LeonOrdonez@gmail.com', 'Quinta Clemente Gurule 2', TIMESTAMP '2025-01-10 01:46:54.534000', null, null, 115);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Homero', 'Vega Benítez', TIMESTAMP '1977-03-29 18:00:00', 0, '982-691-405', 'Pio.LoeraZuniga@yahoo.com', 'Ferrocarril Juana, 2', TIMESTAMP '2025-01-29 04:42:24.319000', null, null, 116);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Inés', 'Sedillo Sánchez', TIMESTAMP '1987-09-21 18:00:00', 1, '965 076 538', 'Ernesto63@gmail.com', 'Puerta Marcos s/n.', TIMESTAMP '2025-05-22 05:44:49.355000', null, null, 117);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('María del Carmen', 'Sosa Mojica', TIMESTAMP '1977-06-30 18:00:00', 0, '992-270-229', 'Guillermo.CornejoAltamirano48@hotmail.com', 'Ramal Yolanda Campos 1', TIMESTAMP '2025-06-03 20:17:18.998000', null, null, 118);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Jesús', 'Roybal Serna', TIMESTAMP '1947-07-25 18:00:00', 1, '927-275-452', 'Pilar.NavaGodoy@hotmail.com', 'Camino Raquel s/n.', TIMESTAMP '2024-09-24 22:38:16.069000', null, null, 119);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('María Luisa', 'Bañuelos Valles', TIMESTAMP '1978-05-25 18:00:00', 0, '993484633', 'Sofia11@hotmail.com', 'Gran Subida José María, 4', TIMESTAMP '2024-08-21 14:23:30.927000', null, null, 120);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Alfredo', 'Noriega Delgado', TIMESTAMP '2004-05-26 18:00:00', 1, '911-421-488', 'Clemente.TerrazasOchoa4@gmail.com', 'Puerta Blanca Ruelas, 68', TIMESTAMP '2024-10-28 03:44:08.159000', null, null, 121);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Julio', 'Adorno Moya', TIMESTAMP '1945-10-03 18:00:00', 0, '929 417 100', 'JoseLuis_RosasBarraza26@gmail.com', 'Carretera Manuel 33', TIMESTAMP '2025-06-17 00:48:56.896000', null, null, 122);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('José Eduardo', 'Juárez Solorio', TIMESTAMP '1960-07-26 18:00:00', 0, '907-138-001', 'Jordi.PenaVela56@hotmail.com', 'Extrarradio Norma 98', TIMESTAMP '2025-01-08 14:51:35.228000', null, null, 123);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Rodrigo', 'Madera Hernández', TIMESTAMP '1973-02-27 18:00:00', 1, '931 828 949', 'Elisa.SoteloRivas@yahoo.com', 'Ronda Luis Páez s/n.', TIMESTAMP '2024-10-05 12:57:37.637000', null, null, 124);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Miguel', 'Pérez Gallegos', TIMESTAMP '1990-02-05 18:00:00', 1, '976 089 412', 'Natalia57@yahoo.com', 'Edificio Fernando s/n.', TIMESTAMP '2024-09-16 11:01:16.974000', null, null, 125);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Rodrigo', 'Alcalá Colunga', TIMESTAMP '1956-07-19 18:00:00', 0, '996-963-401', 'Micaela48@gmail.com', 'Travesía Samuel 34', TIMESTAMP '2024-10-12 01:21:56.500000', null, null, 126);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('José María', 'Magaña Rivero', TIMESTAMP '1957-08-15 18:00:00', 1, '918.158.372', 'Horacio_CabreraFigueroa@hotmail.com', 'Bajada Eduardo Méndez s/n.', TIMESTAMP '2024-12-29 07:27:07.280000', null, null, 127);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Gloria', 'Valdivia Atencio', TIMESTAMP '1939-05-12 18:00:00', 1, '989512690', 'Concepcion53@gmail.com', 'Calle Esperanza Figueroa 7', TIMESTAMP '2024-11-16 15:15:39.690000', null, null, 128);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Dorotea', 'Banda Mesa', TIMESTAMP '1954-09-24 18:00:00', 0, '944.765.632', 'Veronica88@gmail.com', 'Huerta Barbara 8', TIMESTAMP '2025-03-11 10:07:09.284000', null, null, 129);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Rosa', 'Parra Arevalo', TIMESTAMP '1961-04-06 18:00:00', 1, '938.511.915', 'Mayte.LemusCintron0@gmail.com', 'Entrada Sofía Roldán 4', TIMESTAMP '2024-07-21 18:53:20.797000', null, null, 130);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Concepción', 'Ochoa Peralta', TIMESTAMP '1959-06-24 18:00:00', 0, '967.483.862', 'Diego29@yahoo.com', 'Rua Esteban 65', TIMESTAMP '2025-02-28 15:44:38.053000', null, null, 131);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Rocío', 'Armenta Iglesias', TIMESTAMP '1980-06-05 18:00:00', 0, '928.627.927', 'Olivia91@hotmail.com', 'Gran Subida Elsa 8', TIMESTAMP '2024-10-09 14:42:25.988000', null, null, 132);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Diego', 'Calderón Trujillo', TIMESTAMP '1943-04-30 18:00:00', 1, '937.411.264', 'Sergi.LozadaOquendo@hotmail.com', 'Cuesta Matilde Ríos, 70', TIMESTAMP '2025-01-15 17:14:18.262000', null, null, 133);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Lola', 'Rosario Anaya', TIMESTAMP '1939-03-22 18:00:00', 0, '974-639-753', 'Nicolas.FariasCerda@yahoo.com', 'Puente Mariana Barraza, 9', TIMESTAMP '2025-01-16 04:32:08.737000', null, null, 134);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Salvador', 'Tello de Anda', TIMESTAMP '2000-09-06 18:00:00', 0, '902344123', 'Sonia_VillagomezHolguin@gmail.com', 'Polígono Ernesto s/n.', TIMESTAMP '2024-12-20 17:34:44.516000', null, null, 135);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Rodrigo', 'Acosta Delvalle', TIMESTAMP '1954-04-17 18:00:00', 1, '977895409', 'Rafael_MayaValdez@gmail.com', 'Parque Rodrigo Heredia, 87', TIMESTAMP '2024-08-17 04:11:51.520000', null, null, 136);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Alberto', 'Deleón Mondragón', TIMESTAMP '1967-01-31 18:00:00', 0, '969 500 424', 'Gonzalo.QuinteroBriseno25@hotmail.com', 'Bajada Javier 73', TIMESTAMP '2025-04-17 09:06:12.667000', null, null, 137);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Elisa', 'Aguilera Cortés', TIMESTAMP '1937-09-18 18:00:00', 1, '903-924-317', 'Felipe.AguayoIglesias@hotmail.com', 'Vía Pública José Luis Vela, 35', TIMESTAMP '2024-12-03 10:20:35.846000', null, null, 138);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Carlota', 'Niño Atencio', TIMESTAMP '1988-11-28 18:00:00', 0, '938525950', 'MariaTeresa.RojoJimenez@gmail.com', 'Calleja Cristián, 7', TIMESTAMP '2025-01-20 13:05:36.620000', null, null, 139);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Elvira', 'Álvarez Uribe', TIMESTAMP '1979-10-04 18:00:00', 1, '960-696-677', 'JoseLuis96@hotmail.com', 'Senda Jerónimo Cortéz, 74', TIMESTAMP '2024-10-21 09:56:51.686000', null, null, 1);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Yolanda', 'Peña Pacheco', TIMESTAMP '1958-12-19 18:00:00', 1, '903.665.230', 'Elisa.FonsecaSalazar@hotmail.com', 'Vía Blanca, 46', TIMESTAMP '2025-03-28 07:40:22.873000', null, null, 2);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('María', 'Orosco Sosa', TIMESTAMP '1991-03-29 19:00:00', 0, '994.145.357', 'Emilio_SolorioMartinez78@yahoo.com', 'Subida Blanca 4', TIMESTAMP '2025-06-30 21:25:45.429000', null, null, 3);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Norma', 'Valadez Márquez', TIMESTAMP '1939-02-27 18:00:00', 0, '902387603', 'Cesar76@yahoo.com', 'Sección Federico Herrera 93', TIMESTAMP '2024-07-08 22:12:11.695000', null, null, 4);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Alicia', 'Pérez Casillas', TIMESTAMP '1964-09-23 18:00:00', 1, '957.795.420', 'Dorotea19@gmail.com', 'Quinta Lucas Chavarría, 3', TIMESTAMP '2025-02-24 19:58:36.050000', null, null, 5);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Esteban', 'Echevarría Sedillo', TIMESTAMP '1984-12-10 18:00:00', 0, '952 218 652', 'Sergio_OrdonezEstevez29@gmail.com', 'Extramuros Leonor, 35', TIMESTAMP '2024-07-04 14:25:40.132000', null, null, 6);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Marisol', 'Cisneros Banda', TIMESTAMP '1941-06-11 18:00:00', 0, '963061574', 'MariaCristina.MatiasdeJesus@hotmail.com', 'Travesía Rosalia, 2', TIMESTAMP '2025-02-13 19:06:50.942000', null, null, 7);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Lourdes', 'Rosas Anaya', TIMESTAMP '1969-03-23 18:00:00', 1, '973.806.610', 'Cecilia.NinoMadrid37@hotmail.com', 'Municipio Cecilia 80', TIMESTAMP '2025-02-16 22:13:53.157000', null, null, 8);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Miguel', 'Mena Baeza', TIMESTAMP '1946-09-12 18:00:00', 0, '943340479', 'Jesus_QuinonesCalvillo@gmail.com', 'Torrente Arturo Camarillo, 5', TIMESTAMP '2024-07-29 03:42:39.271000', null, null, 9);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Óscar', 'Báez Saiz', TIMESTAMP '1956-04-01 18:00:00', 0, '941012120', 'Federico88@gmail.com', 'Arroyo Jorge Luis Flórez 52', TIMESTAMP '2025-01-28 09:43:40.555000', null, null, 10);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Marilú', 'Pedraza Sotelo', TIMESTAMP '1949-10-11 18:00:00', 1, '943-200-394', 'Josep.UrenaHenriquez@yahoo.com', 'Lado Gonzalo Castillo s/n.', TIMESTAMP '2024-10-21 05:35:22.028000', null, null, 11);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Ester', 'Longoria Rascón', TIMESTAMP '1985-10-31 18:00:00', 0, '979-596-492', 'Joaquin_PeralesMondragon63@gmail.com', 'Salida Mercedes 5', TIMESTAMP '2024-09-06 11:53:40.000000', null, null, 12);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Miguel', 'Fonseca Centeno', TIMESTAMP '1964-03-22 18:00:00', 0, '971 792 231', 'Rosario_GastelumVelez@gmail.com', 'Glorieta María Soledad Jurado, 7', TIMESTAMP '2024-11-08 08:51:21.471000', null, null, 13);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Claudio', 'Fernández Enríquez', TIMESTAMP '1975-03-04 18:00:00', 0, '931.569.244', 'Teodoro92@gmail.com', 'Subida Elisa s/n.', TIMESTAMP '2025-05-26 20:25:04.106000', null, null, 14);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Jorge', 'Saldaña Tamez', TIMESTAMP '1964-04-28 18:00:00', 0, '977262530', 'Dorotea_AguileraGarza63@yahoo.com', 'Sección Alberto Linares, 7', TIMESTAMP '2024-11-09 05:03:50.851000', null, null, 15);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Natalia', 'Olvera Núñez', TIMESTAMP '1969-05-14 18:00:00', 1, '970-917-361', 'Ines_GarayCampos18@yahoo.com', 'Glorieta María del Carmen Guerrero 63', TIMESTAMP '2025-02-08 19:07:51.176000', null, null, 16);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Ernesto', 'Bernal Gastélum', TIMESTAMP '1945-08-14 18:00:00', 1, '906844114', 'Federico.ArmentaCerda@gmail.com', 'Camino Rodrigo, 86', TIMESTAMP '2024-09-13 07:21:57.609000', null, null, 17);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Leonor', 'Cepeda Ortiz', TIMESTAMP '1941-03-24 18:00:00', 1, '971.768.691', 'Alicia.GallegosMerino0@gmail.com', 'Explanada Andrea Márquez 36', TIMESTAMP '2024-12-16 11:48:00.178000', null, null, 18);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Berta', 'Nazario Atencio', TIMESTAMP '1994-07-31 18:00:00', 1, '921.403.836', 'Jaime55@hotmail.com', 'Extrarradio Mariano, 5', TIMESTAMP '2025-01-04 16:40:10.121000', null, null, 19);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Iván', 'Rodríguez Gómez', TIMESTAMP '1997-02-11 18:00:00', 1, '955 683 137', 'Francisco50@hotmail.com', 'Ferrocarril Víctor 1', TIMESTAMP '2025-01-10 04:04:32.223000', null, null, 20);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Marcos', 'Longoria Mireles', TIMESTAMP '1947-06-24 18:00:00', 1, '963.057.128', 'Teodoro.IrizarryHidalgo56@hotmail.com', 'Edificio Iván Espinoza 84', TIMESTAMP '2025-02-09 15:59:19.167000', null, null, 21);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Olivia', 'Pelayo Contreras', TIMESTAMP '1970-08-16 18:00:00', 0, '977476312', 'JoseMaria15@hotmail.com', 'Lugar Felipe, 6', TIMESTAMP '2025-03-09 19:49:11.513000', null, null, 22);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Catalina', 'Corrales Calvillo', TIMESTAMP '1937-01-30 18:00:00', 1, '989.081.180', 'Raquel.MunozSolis17@yahoo.com', 'Barranco Inés, 1', TIMESTAMP '2024-12-28 22:19:47.095000', null, null, 23);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Rosalia', 'Herrera Salcedo', TIMESTAMP '1936-07-22 18:00:00', 1, '906.530.804', 'Benjamin_GodinezBatista@yahoo.com', 'Arrabal Julio Quintana s/n.', TIMESTAMP '2024-12-26 04:28:56.722000', null, null, 24);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Claudia', 'Enríquez Salinas', TIMESTAMP '2007-01-06 18:00:00', 1, '927.201.536', 'Gloria14@gmail.com', 'Vía Elsa Guevara 7', TIMESTAMP '2025-03-07 05:51:15.945000', null, null, 25);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Mateo', 'Aguirre Garza', TIMESTAMP '1944-05-05 18:00:00', 1, '950262082', 'Ester.PichardoUlloa@gmail.com', 'Parcela Estela 34', TIMESTAMP '2024-09-30 07:25:29.169000', null, null, 26);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Federico', 'Perea Garrido', TIMESTAMP '1934-09-05 18:00:00', 0, '994.832.292', 'Maica98@hotmail.com', 'Ronda Leticia 21', TIMESTAMP '2025-01-13 03:04:23.256000', null, null, 27);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Antonia', 'Pedraza Burgos', TIMESTAMP '1963-12-21 18:00:00', 0, '961.952.021', 'Marilu_LopezBarragan7@gmail.com', 'Parcela Pío Arriaga, 2', TIMESTAMP '2024-09-03 00:19:35.423000', null, null, 28);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Ariadna', 'Laureano Olivo', TIMESTAMP '1987-05-02 18:00:00', 1, '941911215', 'Marta7@hotmail.com', 'Arroyo Marta Pagan 8', TIMESTAMP '2025-03-26 16:51:01.545000', null, null, 29);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Hugo', 'Montaño Saiz', TIMESTAMP '2002-11-06 18:00:00', 0, '992095430', 'Cesar_UribeArce@gmail.com', 'Caserio Miguel Ángel, 3', TIMESTAMP '2024-12-21 15:50:37.799000', null, null, 30);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Rosalia', 'Barajas Fierro', TIMESTAMP '1948-05-07 18:00:00', 0, '930205912', 'Carolina45@gmail.com', 'Arroyo Alicia s/n.', TIMESTAMP '2025-07-01 17:18:48.579000', null, null, 31);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Gabriel', 'Arce Tirado', TIMESTAMP '1957-02-04 18:00:00', 1, '936399059', 'German_FigueroaMartinez55@yahoo.com', 'Torrente Fernando, 36', TIMESTAMP '2025-03-04 18:52:21.371000', null, null, 32);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Ramiro', 'Navarro Menéndez', TIMESTAMP '1955-05-05 18:00:00', 1, '946 631 239', 'MarcoAntonio_QuinonesNajera@yahoo.com', 'Cuesta Ana Raya 25', TIMESTAMP '2025-04-14 08:12:44.249000', null, null, 33);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Daniela', 'Rolón Campos', TIMESTAMP '1977-02-03 18:00:00', 0, '941399098', 'Gabriela90@gmail.com', 'Rampa Victoria 26', TIMESTAMP '2024-11-16 04:52:58.901000', null, null, 34);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Luis', 'Corona Báez', TIMESTAMP '1990-10-02 18:00:00', 0, '901 827 852', 'Victoria_SalinasVelazquez@yahoo.com', 'Manzana Rocío, 5', TIMESTAMP '2024-10-15 06:29:20.581000', null, null, 35);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Andrea', 'Matos Ybarra', TIMESTAMP '1999-05-27 18:00:00', 0, '967-583-929', 'Daniel_AlejandroEscobar@yahoo.com', 'Parque Lilia s/n.', TIMESTAMP '2025-06-06 11:29:55.373000', null, null, 36);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Luis', 'Trujillo Ojeda', TIMESTAMP '1947-08-20 18:00:00', 0, '984 485 753', 'Daniel.UrbinaMendoza52@gmail.com', 'Gran Subida María Teresa, 19', TIMESTAMP '2025-02-13 12:34:16.086000', null, null, 37);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Claudia', 'Rivera Griego', TIMESTAMP '1947-12-06 18:00:00', 1, '929-700-741', 'Mariano.LiraAlaniz81@hotmail.com', 'Sección Miguel Ángel Almonte, 3', TIMESTAMP '2025-03-19 04:09:07.161000', null, null, 38);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Silvia', 'Rosales Banda', TIMESTAMP '1998-06-24 18:00:00', 1, '999379181', 'Laura.CasaresArana73@gmail.com', 'Ronda Rosa 4', TIMESTAMP '2025-05-18 07:46:20.708000', null, null, 39);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Elsa', 'Nájera González', TIMESTAMP '1978-01-31 18:00:00', 0, '961.055.037', 'Rosalia.SolorioTapia@yahoo.com', 'Ramal Bernardo s/n.', TIMESTAMP '2024-08-31 20:19:26.476000', null, null, 40);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Beatriz', 'Meza Villalobos', TIMESTAMP '1955-02-01 18:00:00', 1, '996-943-255', 'Marilu43@yahoo.com', 'Barranco Marilú s/n.', TIMESTAMP '2024-08-18 04:45:07.988000', null, null, 41);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Clara', 'Yáñez Ríos', TIMESTAMP '1968-05-20 18:00:00', 0, '906 253 480', 'Andrea.AmadorAvila@yahoo.com', 'Sección Esperanza Bustos 64', TIMESTAMP '2024-12-31 03:54:19.475000', null, null, 42);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Julia', 'Gámez Olivárez', TIMESTAMP '2006-12-15 18:00:00', 0, '943223981', 'Guillermina_ArmentaOrtega85@hotmail.com', 'Colegio Carmen Nazario, 32', TIMESTAMP '2024-11-07 22:40:25.397000', null, null, 43);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Felipe', 'Ruelas Jiménez', TIMESTAMP '1947-12-29 18:00:00', 1, '976-327-270', 'Tomas_OntiverosEscalante@hotmail.com', 'Riera Salvador Maldonado, 31', TIMESTAMP '2024-07-11 15:58:29.940000', null, null, 44);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('José Luis', 'Sedillo Valentín', TIMESTAMP '1954-11-20 18:00:00', 1, '908-526-442', 'MariaEugenia.SepulvedaCoronado59@gmail.com', 'Rincón Adán López 33', TIMESTAMP '2025-02-14 20:29:50.329000', null, null, 45);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Margarita', 'Mares Vela', TIMESTAMP '1962-02-27 18:00:00', 0, '960 480 281', 'Pedro_GaribayVega25@hotmail.com', 'Caserio Nicolás 4', TIMESTAMP '2024-11-30 16:41:28.256000', null, null, 46);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Jacobo', 'Varela Valles', TIMESTAMP '1943-12-23 18:00:00', 1, '969 837 331', 'Cristian72@yahoo.com', 'Sección Óscar Esquivel 1', TIMESTAMP '2025-05-22 06:06:33.681000', null, null, 47);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Patricia', 'Godoy Delao', TIMESTAMP '1992-02-27 19:00:00', 0, '938-535-830', 'Gabriel.CaballeroParra@yahoo.com', 'Lugar Pedro s/n.', TIMESTAMP '2024-09-09 05:25:07.170000', null, null, 48);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Mayte', 'Garza Lara', TIMESTAMP '1994-09-08 18:00:00', 1, '973.803.650', 'Federico.VerdugoHeredia@yahoo.com', 'Apartamento Sonia s/n.', TIMESTAMP '2024-07-29 17:18:34.397000', null, null, 49);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('José', 'Jáquez Cabrera', TIMESTAMP '1977-10-16 18:00:00', 0, '983-029-781', 'Carolina.NarvaezLebron@hotmail.com', 'Parcela Concepción s/n.', TIMESTAMP '2025-05-22 03:02:04.372000', null, null, 50);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Sara', 'Herrera Roldán', TIMESTAMP '1983-12-21 18:00:00', 1, '902 815 030', 'Gustavo_ArteagaSolis@hotmail.com', 'Municipio Marisol Lomeli s/n.', TIMESTAMP '2024-09-28 10:47:37.154000', null, null, 51);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Marcos', 'Ledesma Ureña', TIMESTAMP '1939-02-13 18:00:00', 0, '936-174-906', 'Emilia.RosalesGuerrero98@yahoo.com', 'Travesía Susana Marrero s/n.', TIMESTAMP '2025-06-13 06:20:22.720000', null, null, 52);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Marta', 'Amador Salinas', TIMESTAMP '1998-03-09 18:00:00', 1, '906.133.974', 'Leticia.UrrutiaOjeda97@gmail.com', 'Colonia Benito, 31', TIMESTAMP '2024-09-07 16:25:19.347000', null, null, 53);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Cristina', 'Delrío Valencia', TIMESTAMP '1958-12-19 18:00:00', 0, '900.167.886', 'Mariana33@gmail.com', 'Camino Josefina Arroyo s/n.', TIMESTAMP '2025-02-27 18:55:37.886000', null, null, 54);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Elsa', 'Cuellar Riojas', TIMESTAMP '2006-04-16 18:00:00', 0, '982 669 098', 'Pedro_PalominoHinojosa8@gmail.com', 'Jardines Antonia, 75', TIMESTAMP '2024-08-21 14:43:26.919000', null, null, 55);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('José', 'Amaya Huerta', TIMESTAMP '1987-01-02 18:00:00', 1, '936-913-060', 'Soledad.AguileraAlicea@yahoo.com', 'Ramal María Teresa Mendoza 4', TIMESTAMP '2025-02-16 01:04:08.280000', null, null, 56);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Rosa', 'Heredia Caballero', TIMESTAMP '1993-02-07 18:00:00', 0, '960 814 091', 'Clemente96@gmail.com', 'Sección Eduardo Robles, 2', TIMESTAMP '2025-06-30 23:01:10.488000', null, null, 57);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Mayte', 'Feliciano Laureano', TIMESTAMP '1964-02-07 18:00:00', 0, '909593003', 'Diego.MontanezAlonzo@gmail.com', 'Rua Elena, 32', TIMESTAMP '2024-12-18 10:07:29.005000', null, null, 58);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Sergio', 'Pelayo Yáñez', TIMESTAMP '2001-11-06 18:00:00', 1, '927.234.653', 'Vicente_VigilCalvillo@yahoo.com', 'Colegio Ángela Botello 57', TIMESTAMP '2024-12-12 23:25:49.307000', null, null, 59);
INSERT INTO TEST_USER.PATIENT (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, PHONE, EMAIL, ADDRESS, CREATED_AT, UPDATED_AT, DELETED_AT, ID) VALUES ('Marilú', 'Marín Alonzo', TIMESTAMP '1992-07-17 18:00:00', 1, '912.573.426', 'Ramiro50@hotmail.com', 'Monte Berta 49', TIMESTAMP '2024-08-31 17:14:07.262000', null, null, 60);

-- APPOINTSMNETS
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (2, 25, 62, 44, TIMESTAMP '2024-09-23 14:05:36.531000', TIMESTAMP '2024-09-23 14:34:36.531000', 'scheduled', 'Statim vinco doloremque consequatur abscido avaritia strenuus.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (3, 132, 63, 18, TIMESTAMP '2024-11-16 09:30:11.506000', TIMESTAMP '2024-11-16 10:12:11.506000', 'completed', 'Chirographum ceno infit excepturi adstringo tardus.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (4, 94, 104, 59, TIMESTAMP '2024-12-19 13:05:59.830000', TIMESTAMP '2024-12-19 13:21:59.830000', 'canceled', 'Amet decumbo atavus animi.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (5, 36, 1, 33, TIMESTAMP '2025-03-15 23:38:22.590000', TIMESTAMP '2025-03-16 00:38:22.590000', 'scheduled', 'Versus blandior depraedor aperio sulum conscendo rerum.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (6, 115, 6, 35, TIMESTAMP '2025-04-09 06:27:35.006000', TIMESTAMP '2025-04-09 08:06:35.006000', 'canceled', 'Color umquam tabesco tracto appositus damnatio temptatio.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (7, 2, 8, 71, TIMESTAMP '2025-03-05 08:40:55.921000', TIMESTAMP '2025-03-05 10:17:55.921000', 'scheduled', 'Numquam angulus caute terra optio audax defluo.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (8, 43, 86, 79, TIMESTAMP '2025-08-02 05:51:15.773000', TIMESTAMP '2025-08-02 06:46:15.773000', 'completed', 'Damno vomica ter crudelis.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (9, 98, 94, 82, TIMESTAMP '2025-06-23 03:39:01.930000', TIMESTAMP '2025-06-23 05:32:01.930000', 'canceled', 'Spectaculum vado tutamen.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (10, 88, 65, 91, TIMESTAMP '2024-10-21 09:34:14.519000', TIMESTAMP '2024-10-21 10:13:14.519000', 'completed', 'Volubilis demitto deludo delectus texo casus.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (11, 90, 96, 42, TIMESTAMP '2024-05-08 06:12:35.454000', TIMESTAMP '2024-05-08 07:34:35.454000', 'canceled', 'Crustulum soleo brevis decerno cohibeo aggredior tandem.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (12, 114, 78, 60, TIMESTAMP '2025-06-05 07:40:00.845000', TIMESTAMP '2025-06-05 09:16:00.845000', 'completed', 'Abundans casso iste spoliatio.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (13, 85, 16, 20, TIMESTAMP '2024-08-26 06:12:02.316000', TIMESTAMP '2024-08-26 06:39:02.316000', 'scheduled', 'Correptius absorbeo voluptatum amaritudo harum.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (14, 66, 12, 55, TIMESTAMP '2025-05-17 06:53:54.840000', TIMESTAMP '2025-05-17 08:08:54.840000', 'scheduled', 'Supra iure testimonium territo nobis verus.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (15, 87, 71, 17, TIMESTAMP '2024-03-22 16:22:03.252000', TIMESTAMP '2024-03-22 18:07:03.252000', 'scheduled', 'Summopere beatus adhaero at cunae charisma.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (16, 18, 105, 83, TIMESTAMP '2024-10-24 09:47:53.520000', TIMESTAMP '2024-10-24 10:22:53.520000', 'canceled', 'Amaritudo cubicularis tandem solio verus dolorum denuo vestigium cinis aestus.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (17, 7, 68, 84, TIMESTAMP '2024-04-27 05:45:45.402000', TIMESTAMP '2024-04-27 06:07:45.402000', 'canceled', 'Uter villa vita aggero.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (18, 86, 29, 63, TIMESTAMP '2024-05-08 07:05:58.014000', TIMESTAMP '2024-05-08 08:53:58.014000', 'canceled', 'Doloremque rerum agnitio creo deprimo canto astrum bellum aeternus trucido.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (19, 38, 112, 24, TIMESTAMP '2025-02-23 07:12:00.211000', TIMESTAMP '2025-02-23 08:05:00.211000', 'scheduled', 'Sponte capitulus comes.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (20, 54, 14, 82, TIMESTAMP '2025-12-14 19:47:40.667000', TIMESTAMP '2025-12-14 20:54:40.667000', 'completed', 'Infit cicuta consequatur soleo balbus tamen vesica.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (21, 3, 124, 53, TIMESTAMP '2025-06-26 03:44:32.626000', TIMESTAMP '2025-06-26 04:58:32.626000', 'canceled', 'Terminatio dens terebro velum ad apparatus rerum universe.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (22, 130, 16, 43, TIMESTAMP '2024-07-23 03:55:23.714000', TIMESTAMP '2024-07-23 05:45:23.714000', 'canceled', 'Antepono curvo stella bellicus.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (23, 108, 42, 29, TIMESTAMP '2024-07-30 03:33:32.082000', TIMESTAMP '2024-07-30 04:38:32.082000', 'completed', 'Thesis tripudio arceo ater.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (24, 66, 18, 73, TIMESTAMP '2025-02-26 09:56:48.795000', TIMESTAMP '2025-02-26 11:13:48.795000', 'completed', 'Talis depopulo et statua.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (25, 116, 50, 42, TIMESTAMP '2024-12-06 02:21:08.508000', TIMESTAMP '2024-12-06 04:09:08.508000', 'scheduled', 'Claro paulatim suus sit terminatio vomica complectus utique.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (26, 35, 23, 22, TIMESTAMP '2025-02-18 20:30:03.404000', TIMESTAMP '2025-02-18 21:50:03.404000', 'scheduled', 'Deprecator vivo claudeo.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (27, 59, 53, 22, TIMESTAMP '2024-06-19 16:30:51.167000', TIMESTAMP '2024-06-19 18:13:51.167000', 'canceled', 'Celo est autus theca verumtamen adsidue.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (28, 27, 35, 93, TIMESTAMP '2024-09-27 21:58:49.987000', TIMESTAMP '2024-09-27 23:48:49.987000', 'canceled', 'Speciosus caelestis color ducimus conatus eum pecco patria.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (29, 91, 103, 22, TIMESTAMP '2025-04-03 22:56:29.006000', TIMESTAMP '2025-04-04 00:48:29.006000', 'canceled', 'Aperte vindico aestas modi spectaculum maiores amicitia denuo terebro.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (30, 137, 21, 41, TIMESTAMP '2024-04-24 15:07:20.030000', TIMESTAMP '2024-04-24 16:22:20.030000', 'scheduled', 'Consuasor harum tremo absque modi.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (31, 85, 76, 19, TIMESTAMP '2024-06-09 12:23:45.189000', TIMESTAMP '2024-06-09 12:59:45.189000', 'completed', 'Tam quos copia carpo.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (32, 26, 25, 33, TIMESTAMP '2024-05-19 08:37:09.653000', TIMESTAMP '2024-05-19 10:13:09.653000', 'canceled', 'Tandem optio animus turba.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (33, 43, 90, 24, TIMESTAMP '2024-08-29 06:51:37.084000', TIMESTAMP '2024-08-29 08:10:37.084000', 'scheduled', 'Capillus voro aegrotatio appono demens maiores cognatus velum coerceo.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (34, 18, 21, 75, TIMESTAMP '2025-09-01 08:36:10.409000', TIMESTAMP '2025-09-01 09:11:10.409000', 'canceled', 'Eum sapiente totam adiuvo cervus admiratio.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (35, 7, 6, 59, TIMESTAMP '2025-09-13 06:51:14.696000', TIMESTAMP '2025-09-13 07:37:14.696000', 'completed', 'Ter somniculosus tertius sollicito a ut desipio demo triduana volutabrum.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (36, 81, 50, 38, TIMESTAMP '2025-07-10 16:54:27.755000', TIMESTAMP '2025-07-10 18:05:27.755000', 'scheduled', 'Sed uterque aeneus depraedor tardus tamen demo vesica spargo utpote.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (37, 115, 84, 75, TIMESTAMP '2025-02-07 20:23:40.420000', TIMESTAMP '2025-02-07 21:38:40.420000', 'scheduled', 'Approbo totam vis.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (38, 107, 35, 43, TIMESTAMP '2024-12-31 07:12:40.987000', TIMESTAMP '2024-12-31 07:35:40.987000', 'canceled', 'Cursim aequus credo ipsum convoco demo versus.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (39, 24, 99, 49, TIMESTAMP '2024-06-22 14:07:30.044000', TIMESTAMP '2024-06-22 15:46:30.044000', 'completed', 'Non tepidus pectus angelus illum valde.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (40, 132, 69, 54, TIMESTAMP '2025-08-26 12:51:20.551000', TIMESTAMP '2025-08-26 13:20:20.551000', 'canceled', 'Urbanus adhaero audentia fuga desipio ultio.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (41, 105, 110, 85, TIMESTAMP '2025-10-12 05:10:39.255000', TIMESTAMP '2025-10-12 05:53:39.255000', 'scheduled', 'Volutabrum suffragium sursum territo apto infit voluptatibus ducimus alienus.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (42, 131, 3, 17, TIMESTAMP '2025-06-26 19:52:45.658000', TIMESTAMP '2025-06-26 21:32:45.658000', 'completed', 'Voveo quam admoveo denuncio temptatio.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (43, 12, 112, 69, TIMESTAMP '2025-10-26 12:33:46.262000', TIMESTAMP '2025-10-26 13:40:46.262000', 'completed', 'Deduco adduco tabula.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (44, 103, 110, 40, TIMESTAMP '2025-02-26 03:06:44.015000', TIMESTAMP '2025-02-26 04:58:44.015000', 'canceled', 'Vinum assentator abstergo casso voluptates vulariter.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (45, 131, 101, 69, TIMESTAMP '2024-04-11 22:12:58.070000', TIMESTAMP '2024-04-11 23:39:58.070000', 'completed', 'Texo adsum custodia pauci vacuus deludo quas aequitas.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (46, 105, 75, 66, TIMESTAMP '2024-10-28 19:28:46.509000', TIMESTAMP '2024-10-28 21:04:46.509000', 'canceled', 'Vilicus desipio thermae vita demo.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (47, 104, 63, 94, TIMESTAMP '2025-03-16 19:17:28.903000', TIMESTAMP '2025-03-16 21:05:28.903000', 'scheduled', 'Cultura vehemens ultra trepide tui sollicito universe.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (48, 121, 89, 44, TIMESTAMP '2024-06-13 23:05:03.328000', TIMESTAMP '2024-06-14 00:44:03.328000', 'canceled', 'Paulatim deinde bene.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (49, 116, 22, 69, TIMESTAMP '2024-03-25 03:56:19.241000', TIMESTAMP '2024-03-25 04:39:19.241000', 'canceled', 'Vestrum pauper suffoco.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (50, 93, 88, 86, TIMESTAMP '2025-03-24 04:36:44.129000', TIMESTAMP '2025-03-24 05:46:44.129000', 'canceled', 'Vae peccatus eum cupiditas vinum charisma tredecim.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (51, 132, 80, 81, TIMESTAMP '2024-08-02 03:27:38.299000', TIMESTAMP '2024-08-02 05:13:38.299000', 'completed', 'Arx sordeo tenuis.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (52, 133, 84, 39, TIMESTAMP '2025-12-13 02:45:41.774000', TIMESTAMP '2025-12-13 04:32:41.774000', 'canceled', 'Somniculosus defessus argumentum cinis aequus.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (53, 19, 32, 69, TIMESTAMP '2025-03-19 04:53:51.659000', TIMESTAMP '2025-03-19 05:27:51.659000', 'completed', 'Solus caste quos coadunatio stabilis tamquam velit consequatur.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (54, 80, 79, 32, TIMESTAMP '2025-09-28 23:27:09.723000', TIMESTAMP '2025-09-29 00:43:09.723000', 'canceled', 'Tandem admitto trepide.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (55, 62, 4, 29, TIMESTAMP '2024-12-31 06:12:04.982000', TIMESTAMP '2024-12-31 07:21:04.982000', 'scheduled', 'Charisma uter vitium admitto.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (56, 91, 24, 50, TIMESTAMP '2024-06-06 00:37:36.163000', TIMESTAMP '2024-06-06 01:41:36.163000', 'completed', 'Amissio turbo attollo vitae.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (57, 127, 38, 54, TIMESTAMP '2025-11-25 08:39:12.256000', TIMESTAMP '2025-11-25 09:53:12.256000', 'canceled', 'Varius aperte spiritus.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (58, 53, 73, 56, TIMESTAMP '2025-09-19 23:15:59.717000', TIMESTAMP '2025-09-20 00:05:59.717000', 'completed', 'Tumultus admoveo arx angelus.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (59, 74, 15, 50, TIMESTAMP '2025-05-10 08:35:05.349000', TIMESTAMP '2025-05-10 09:20:05.349000', 'completed', 'Approbo quod tam.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (60, 10, 126, 71, TIMESTAMP '2025-11-09 21:56:20.863000', TIMESTAMP '2025-11-09 23:28:20.863000', 'completed', 'Virga vae quas.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (61, 99, 30, 74, TIMESTAMP '2025-02-21 08:00:07.406000', TIMESTAMP '2025-02-21 09:46:07.406000', 'scheduled', 'At cohors sumo tergiversatio culpa conculco decipio studio capillus.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (62, 56, 72, 47, TIMESTAMP '2024-08-03 21:05:03.046000', TIMESTAMP '2024-08-03 22:58:03.046000', 'canceled', 'Socius speculum dicta vivo totus a nemo apto defessus.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (63, 55, 53, 46, TIMESTAMP '2025-04-03 20:07:39.310000', TIMESTAMP '2025-04-03 22:02:39.310000', 'scheduled', 'Bardus alioqui adinventitias nisi cernuus textilis speciosus volup.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (64, 78, 79, 90, TIMESTAMP '2024-12-31 21:50:50.224000', TIMESTAMP '2024-12-31 22:18:50.224000', 'canceled', 'Bellicus verumtamen congregatio adsuesco acsi.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (65, 124, 84, 73, TIMESTAMP '2024-11-17 13:00:25.481000', TIMESTAMP '2024-11-17 14:32:25.481000', 'scheduled', 'Animi cruentus terror nihil argumentum urbs corroboro.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (66, 139, 125, 55, TIMESTAMP '2025-01-09 08:23:12.900000', TIMESTAMP '2025-01-09 09:11:12.900000', 'scheduled', 'Accommodo cito vulticulus degusto cimentarius tabella carmen callide solutio ceno.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (67, 55, 73, 60, TIMESTAMP '2025-08-25 04:29:17.074000', TIMESTAMP '2025-08-25 06:27:17.074000', 'completed', 'Reprehenderit adimpleo titulus solvo.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (68, 28, 67, 30, TIMESTAMP '2025-06-08 19:25:06.880000', TIMESTAMP '2025-06-08 21:25:06.880000', 'scheduled', 'Adipisci vulnero cinis.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (69, 72, 43, 62, TIMESTAMP '2025-06-01 16:10:15.796000', TIMESTAMP '2025-06-01 18:05:15.796000', 'completed', 'Maiores stella non curvo bonus vix supplanto spargo.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (70, 38, 19, 30, TIMESTAMP '2024-06-10 04:44:28.266000', TIMESTAMP '2024-06-10 05:12:28.266000', 'completed', 'Summopere via tumultus solum nisi.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (71, 15, 103, 62, TIMESTAMP '2025-11-11 14:51:51.077000', TIMESTAMP '2025-11-11 15:58:51.077000', 'scheduled', 'Vulariter sumptus impedit cultellus vitae.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (72, 56, 5, 52, TIMESTAMP '2024-08-07 17:16:07.729000', TIMESTAMP '2024-08-07 17:58:07.729000', 'scheduled', 'Crapula quod subnecto tenuis arbustum comis commodo.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (73, 72, 113, 69, TIMESTAMP '2025-08-20 03:42:26.623000', TIMESTAMP '2025-08-20 04:23:26.623000', 'canceled', 'Cupiditate alienus sonitus volo compono confido tamquam.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (74, 132, 85, 91, TIMESTAMP '2025-12-28 22:43:15.555000', TIMESTAMP '2025-12-29 00:32:15.555000', 'scheduled', 'Ambitus est possimus deprecator collum adfero.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (75, 77, 48, 75, TIMESTAMP '2024-10-02 17:22:20.641000', TIMESTAMP '2024-10-02 18:49:20.641000', 'canceled', 'Alter tempus theologus vorago iure.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (76, 19, 96, 67, TIMESTAMP '2025-06-12 00:17:08.799000', TIMESTAMP '2025-06-12 01:57:08.799000', 'canceled', 'Tredecim solium vis absconditus voluptate benigne admitto clam sortitus.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (77, 84, 47, 56, TIMESTAMP '2024-03-15 23:16:12.033000', TIMESTAMP '2024-03-15 23:40:12.033000', 'canceled', 'Aperiam credo vesper vir odit crastinus armarium cui calco tendo.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (78, 55, 9, 67, TIMESTAMP '2025-10-20 10:33:41.129000', TIMESTAMP '2025-10-20 11:54:41.129000', 'completed', 'Condico alienus sumptus viriliter vel solitudo usus.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (79, 88, 121, 48, TIMESTAMP '2024-08-10 20:32:43.095000', TIMESTAMP '2024-08-10 21:56:43.095000', 'canceled', 'Brevis vapulus curtus.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (80, 12, 22, 71, TIMESTAMP '2024-12-30 00:54:54.422000', TIMESTAMP '2024-12-30 02:16:54.422000', 'canceled', 'Solutio repellat fuga confido defetiscor condico.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (81, 1, 60, 51, TIMESTAMP '2025-11-14 20:42:29.554000', TIMESTAMP '2025-11-14 20:59:29.554000', 'canceled', 'Carpo carbo carpo videlicet decet.');
INSERT INTO TEST_USER.APPOINTMENT (ID, PATIENT_ID, DOCTOR_ID, ROOM_ID, START_TIME, END_TIME, STATUS, DESCRIPTION) VALUES (82, 48, 68, 29, TIMESTAMP '2025-06-14 10:52:24.193000', TIMESTAMP '2025-06-14 11:58:24.193000', 'scheduled', 'Virga apostolus capitulus.');

-- APP_USERS
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (1, 'Josefina.RoybalDuran', 'Carlos29@yahoo.com', 'qGngypn_F5H8AQL', 'receptionist', 0, TIMESTAMP '2024-11-03 07:58:17.257000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (2, 'Matilde_BurgosCrespo20', 'Olivia_GalarzaHurtado89@yahoo.com', 'fbvryva0juZIPak', 'receptionist', 1, TIMESTAMP '2024-09-03 07:43:51.353000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (3, 'Emilio_CervantesIbarra23', 'Eloisa_GutierrezOntiveros93@yahoo.com', 'cbBIQxsCk8flkjV', 'receptionist', 1, TIMESTAMP '2024-11-01 11:47:30.096000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (4, 'Gabriela_OsorioSanchez', 'JoseLuis83@gmail.com', 'YnWHCxr9PAY47NW', 'admin', 0, TIMESTAMP '2024-12-15 00:25:22.662000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (5, 'MariaSoledad23', 'Pedro.RendonSedillo@gmail.com', 'pdgIMmQIL_zVbz9', 'doctor', 1, TIMESTAMP '2025-03-23 07:18:49.225000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (6, 'Felipe.DuenasCarreon21', 'Emilio.LedesmaRosario@yahoo.com', 'OTCIWngzkSI1POB', 'receptionist', 0, TIMESTAMP '2025-02-19 14:24:23.461000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (7, 'Lola23', 'MariaJose73@yahoo.com', 'FXXfXT38A_6m_iR', 'admin', 0, TIMESTAMP '2024-07-19 00:32:14.825000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (8, 'Vicente.ArellanoAviles20', 'Carlos_BenitezMenendez@hotmail.com', 'E_dYPkEtheN1AO2', 'receptionist', 0, TIMESTAMP '2024-11-11 04:22:50.254000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (9, 'Tomas_SantanaOcampo', 'MariadelosAngeles43@yahoo.com', 'IeXjGOFYcMZxoss', 'doctor', 0, TIMESTAMP '2024-10-23 16:46:19.718000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (10, 'Jeronimo_EspinosaCano', 'Emilia58@yahoo.com', 'TjIGqQQEAkxJq5F', 'doctor', 0, TIMESTAMP '2025-04-12 23:59:52.710000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (11, 'Fernando_CastroMota64', 'AnaMaria.MontoyaFarias@hotmail.com', 'EofA5lpDVIBwT_2', 'admin', 1, TIMESTAMP '2024-08-15 05:10:33.480000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (12, 'Sara8', 'Esperanza21@hotmail.com', 'K2aaR9WBuztHkuv', 'doctor', 1, TIMESTAMP '2024-11-09 01:38:25.255000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (13, 'Carlota.CrespoQuinones', 'JuanRamon.CanalesRaya82@gmail.com', 'Xx9S_BhGnyB2_fk', 'receptionist', 1, TIMESTAMP '2024-11-21 12:27:33.547000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (14, 'Diana39', 'Gonzalo27@hotmail.com', 'I7oxntMUcXfXMVf', 'doctor', 1, TIMESTAMP '2025-03-23 23:45:26.243000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (15, 'Lucia.TiradoOrellana78', 'Benito.CintronNarvaez68@hotmail.com', 'UAt68vywCXo3eKB', 'doctor', 0, TIMESTAMP '2024-07-03 08:16:10.135000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (16, 'Ariadna.CarrionLeal', 'Blanca.SisnerosDelapaz0@yahoo.com', 'Yw4h40So3_Kq7f2', 'admin', 1, TIMESTAMP '2025-02-28 00:30:48.685000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (17, 'Adan68', 'Natalia_BacaAlcaraz@yahoo.com', 'S5WKyd2eNEsuLSL', 'admin', 1, TIMESTAMP '2025-01-17 05:38:30.712000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (18, 'Daniel.OrozcoCorrales', 'Santiago_CarrascoPadilla71@yahoo.com', 'VUQgcmuXlQHquDr', 'admin', 1, TIMESTAMP '2025-06-02 02:34:28.588000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (19, 'Ramon_CurielNieves', 'Mario86@gmail.com', 'HvZfcJW6fxW9exq', 'receptionist', 0, TIMESTAMP '2024-08-01 10:02:56.989000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (20, 'Pedro.ValadezSaenz', 'Raquel_MerazAlmanza30@gmail.com', 'obeVEFm7511lofE', 'doctor', 0, TIMESTAMP '2024-08-21 02:43:48.227000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (21, 'MariaTeresa.JuarezIglesias12', 'Emilia_NevarezToledo@hotmail.com', 'SlNKj3gCR3AAQFk', 'admin', 0, TIMESTAMP '2025-03-18 08:02:34.617000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (22, 'Federico.AguayoSantana85', 'MariaJose54@hotmail.com', 'epXFsnVPwoqxp8M', 'doctor', 0, TIMESTAMP '2024-10-29 11:02:46.786000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (23, 'JulioCesar_EstevezGarrido18', 'Cristian.PinedaMora@gmail.com', 'jYX7wcOSsW71opI', 'doctor', 1, TIMESTAMP '2025-04-21 12:26:56.183000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (24, 'Elsa_LermaJaime', 'Concepcion_DelacruzReyes@yahoo.com', 'ZQKYC1fESaL2f2e', 'receptionist', 1, TIMESTAMP '2025-01-05 00:04:47.364000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (25, 'Berta.CasaresAlmonte', 'Hugo_ChavarriaDuran96@hotmail.com', '10SfqAu8f5dYi9i', 'doctor', 0, TIMESTAMP '2024-11-22 14:33:02.258000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (26, 'Antonio_QuintanaJaimes', 'Esperanza.AbeytaMunguia90@yahoo.com', 'zJzh2LQlpjUQaJT', 'doctor', 0, TIMESTAMP '2025-04-19 03:08:45.951000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (27, 'Sara.AlcantarValdez', 'Marcos.AmadorCorona24@gmail.com', 'KaFhkDCjesjJk1s', 'receptionist', 1, TIMESTAMP '2025-05-08 18:48:11.547000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (28, 'Sonia.SaavedraTeran', 'Marilu87@hotmail.com', 'waYTy7wNA1AZqW4', 'receptionist', 0, TIMESTAMP '2024-08-16 22:13:01.785000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (29, 'LuisMiguel3', 'Victoria_DuenasMateo65@hotmail.com', 'hiikE9A5kPoyRxC', 'receptionist', 1, TIMESTAMP '2025-03-31 05:38:18.840000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (30, 'Marcela_VelascoRivas0', 'Jose34@yahoo.com', 'TeY1YAAWDVDiAyr', 'receptionist', 0, TIMESTAMP '2025-03-20 18:11:40.390000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (31, 'Rafael.BenavidesCorrales', 'Eloisa.NarvaezSaldana@gmail.com', 'evb29rJnMBWKOxL', 'receptionist', 0, TIMESTAMP '2024-12-19 03:28:28.183000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (32, 'Esteban_TapiaAlvarez54', 'Alfonso_SerranoTejeda16@gmail.com', 'Qcupuj2azLWeW2A', 'receptionist', 0, TIMESTAMP '2024-08-14 03:49:06.865000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (33, 'Graciela90', 'Arturo2@gmail.com', 'v_fQiIjSY1UOXSe', 'receptionist', 0, TIMESTAMP '2025-06-16 21:21:35.928000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (34, 'Agustin1', 'Isabel.NinoHurtado@hotmail.com', 'KFV8cE88ZelDBVh', 'receptionist', 1, TIMESTAMP '2025-02-23 09:06:04.447000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (35, 'Sara86', 'Benito_CastilloGodinez@hotmail.com', 'T2_llEtP_eEEikQ', 'admin', 0, TIMESTAMP '2025-01-10 14:04:54.092000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (36, 'Elisa_TamezIrizarry', 'Patricia.NavaCeballos@yahoo.com', 'lFuXRTPiZqSJBEL', 'admin', 0, TIMESTAMP '2025-01-08 09:11:15.469000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (37, 'Raul_MarreroNegron', 'MiguelAngel67@gmail.com', 'ltIW3xazO8QwzRh', 'doctor', 0, TIMESTAMP '2025-01-22 20:00:00.125000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (38, 'Lola.ArchuletaSevilla', 'Lourdes_EscamillaRosas@yahoo.com', 'zjpzjkHCeOmw7Fd', 'admin', 1, TIMESTAMP '2024-09-29 04:01:07.458000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (39, 'Veronica.RosadoAlba', 'Guillermina_MataHolguin@yahoo.com', 'eXRz8W7CXh3d5hc', 'doctor', 0, TIMESTAMP '2024-08-23 17:41:07.290000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (40, 'Josep_CepedaMatias6', 'Anita88@yahoo.com', 'sudm1ncuSF3JxYO', 'doctor', 0, TIMESTAMP '2024-11-09 03:41:42.007000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (41, 'Gloria28', 'Diego_DelagarzaDelarosa@yahoo.com', 'uElnYhrN_JvtPrb', 'admin', 0, TIMESTAMP '2025-06-05 08:56:52.022000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (42, 'Antonio.ZamudioCintron', 'Maria57@gmail.com', 'DGBSutHPXHvwwS0', 'admin', 1, TIMESTAMP '2024-08-14 16:34:36.870000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (43, 'Clemente.ZamudioReyna55', 'Ariadna81@hotmail.com', 'ynEQDq1UdMS3TqQ', 'doctor', 0, TIMESTAMP '2025-03-25 11:35:31.324000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (44, 'Gustavo46', 'MarcoAntonio7@hotmail.com', '5GutpjD8kbn_qG7', 'admin', 1, TIMESTAMP '2024-12-21 21:49:54.824000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (45, 'Clara.TafoyaCenteno56', 'Cristian_SolorioTejeda41@gmail.com', 'wyHSmrSRvS_xUEE', 'admin', 1, TIMESTAMP '2024-08-25 10:43:43.483000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (46, 'Andres.RamirezHuerta', 'Francisca3@yahoo.com', 'ZkP3WE1VFZSNd7F', 'admin', 1, TIMESTAMP '2024-10-12 02:06:11.902000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (47, 'Rosalia.AlmanzaValenzuela82', 'Mario_MiramontesValladares55@hotmail.com', '5IddQGBZk7DqSXG', 'receptionist', 1, TIMESTAMP '2025-05-29 01:38:32.776000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (48, 'Sergio.TerrazasArroyo', 'Rodrigo31@gmail.com', '4frxzZJSisvKufe', 'doctor', 1, TIMESTAMP '2024-10-27 22:49:18.174000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (49, 'Concepcion_AcevedoOlivares', 'Carmen.HerediaOjeda@hotmail.com', '6gYdpJQxDVlKXiu', 'admin', 1, TIMESTAMP '2025-06-25 00:52:49.412000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (50, 'Manuela15', 'Julio_OsorioLeal36@yahoo.com', 'NZ3LEB1NvWuWJ5n', 'doctor', 1, TIMESTAMP '2025-03-24 03:51:14.897000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (51, 'Lucas60', 'Carolina25@hotmail.com', 'XN8RjXK6CsOIKbd', 'doctor', 0, TIMESTAMP '2024-09-27 00:34:11.488000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (52, 'MariadelosAngeles_MedinaVega74', 'Sancho_OrdonezAnguiano@yahoo.com', 'ncLHUcyPLYq37d5', 'doctor', 1, TIMESTAMP '2024-09-20 08:24:07.018000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (53, 'Manuel.FuentesPalacios13', 'Patricia23@yahoo.com', '8_EhMaYb3QN3Pya', 'receptionist', 0, TIMESTAMP '2024-07-14 00:30:47.418000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (54, 'Teodoro74', 'Juana.MendozaArmendariz@gmail.com', 'IugnPzYT_kuN0XF', 'receptionist', 0, TIMESTAMP '2025-01-09 09:42:36.185000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (55, 'Micaela.MaresVelasquez', 'Lorenzo23@hotmail.com', 'l4L6TdBK4PcBt_G', 'receptionist', 0, TIMESTAMP '2024-10-14 02:36:40.311000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (56, 'Marilu.MaderaDelrio72', 'Rosario12@hotmail.com', 'uiolO3ow3UHYTmO', 'admin', 0, TIMESTAMP '2024-07-30 07:27:07.466000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (57, 'Yolanda.CerdaGallardo81', 'Bernardo.AcostaFierro15@yahoo.com', 'oYdRn_Kk11oS99l', 'admin', 0, TIMESTAMP '2025-05-05 01:49:29.557000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (58, 'Felipe43', 'Rosario51@yahoo.com', 'Bdid4lqefoC5ctR', 'receptionist', 0, TIMESTAMP '2024-11-02 00:11:39.380000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (59, 'LuisMiguel_BarreraDelgadillo19', 'Diego30@hotmail.com', 'e3XzEa3BP174lKR', 'receptionist', 1, TIMESTAMP '2025-04-10 09:14:52.169000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (60, 'Santiago_UriasSerrato', 'Juana_AlanizSarabia49@yahoo.com', '91V8Bfu2zT49fTE', 'receptionist', 1, TIMESTAMP '2024-09-09 16:44:24.952000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (61, 'Jesus.MaestasEsparza', 'Florencia98@gmail.com', '9QzGeQPD_STIm6B', 'admin', 0, TIMESTAMP '2024-09-15 18:34:52.658000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (62, 'Lola.RosarioCornejo96', 'Fernando.SantiagoEscalante68@gmail.com', 'iT_sZ_OoHuCvblw', 'receptionist', 0, TIMESTAMP '2025-05-14 01:24:42.423000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (63, 'Lorena_AvalosCasillas', 'Carmen_RoybalCarrillo@gmail.com', '6WIIrD2iFReGuNM', 'doctor', 0, TIMESTAMP '2025-02-05 00:50:55.316000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (64, 'Adan58', 'Conchita.PachecoOlvera@gmail.com', 'xaKI_g6c6de6oT8', 'admin', 1, TIMESTAMP '2025-05-23 23:20:22.014000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (65, 'Florencia_AguilarCotto', 'MariaCristina.CarreonAnguiano86@yahoo.com', 'Wb76iaTWYhgZmGf', 'doctor', 0, TIMESTAMP '2024-10-13 13:38:30.173000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (66, 'Maricarmen.DelvalleCovarrubias38', 'Gilberto_CarranzaDelacruz97@hotmail.com', 'U_kJm32jlklKBvy', 'admin', 1, TIMESTAMP '2024-11-06 11:36:24.853000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (67, 'Estela.LeonDelgado', 'Sancho.SantiagoMoreno@yahoo.com', '2GaWAeaMZ8iazaP', 'doctor', 0, TIMESTAMP '2025-06-27 12:00:39.843000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (68, 'Gabriela47', 'Ivan.OcasioBriones32@hotmail.com', 'LFXewJGNCNUFkXT', 'admin', 0, TIMESTAMP '2025-01-25 06:36:51.851000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (69, 'Gloria.VillasenorRosado13', 'Reina.OlveraGastelum@hotmail.com', 'VunN31JRbE3aIO7', 'doctor', 0, TIMESTAMP '2024-07-06 11:17:33.584000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (70, 'AnaLuisa.CandelariaMata', 'Rebeca84@hotmail.com', 'sn60AG2O2c_pWOR', 'receptionist', 1, TIMESTAMP '2025-01-05 10:21:05.576000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (71, 'Blanca.OteroGaitan', 'Ariadna.JaramilloNevarez40@hotmail.com', 'rRh_uENVnNl8pqB', 'admin', 0, TIMESTAMP '2024-07-16 08:12:44.424000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (72, 'Norma.deJesusOchoa18', 'Monica22@hotmail.com', 'boeXN87OfedMuvI', 'receptionist', 0, TIMESTAMP '2024-07-23 03:28:17.722000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (73, 'Margarita76', 'Pedro_UribeNoriega63@hotmail.com', '2TJJPDC4b_lZPhN', 'doctor', 0, TIMESTAMP '2025-02-23 17:18:01.633000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (74, 'MariaTeresa.QuintanaAviles', 'MariaSoledad59@gmail.com', 'Tmuj_YUzJzzAtNI', 'doctor', 1, TIMESTAMP '2024-10-06 01:26:09.883000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (75, 'Rafael_ArandaReyes', 'Claudia.SaavedraValdez57@hotmail.com', 'dzaX_LlEcjp9IaU', 'doctor', 0, TIMESTAMP '2025-04-09 11:38:34.255000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (76, 'Eva63', 'Emilia_ValdezMesa92@hotmail.com', 'XPLQB7yH1h0BPUw', 'doctor', 1, TIMESTAMP '2025-06-26 15:43:07.079000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (77, 'Oscar.GarayCarrillo1', 'Ramiro5@yahoo.com', 'dF64oT38rnG3i17', 'doctor', 0, TIMESTAMP '2025-02-26 15:15:27.504000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (78, 'Lorenzo32', 'Benito.CorralOsorio@yahoo.com', '67bFLIbXpL6yOEG', 'doctor', 1, TIMESTAMP '2024-09-18 16:52:55.564000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (79, 'Sergi.deAndaPuga32', 'Carolina_GuevaraEspinosa@gmail.com', 'ErRBgm6X9lZj9WG', 'receptionist', 0, TIMESTAMP '2024-08-15 18:17:16.860000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (80, 'Yolanda_RiojasRivero', 'Magdalena.CovarrubiasSoliz@yahoo.com', 'yrH2UxDQ0erCEtv', 'admin', 0, TIMESTAMP '2025-01-22 06:29:23.526000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (81, 'Raul9', 'Horacio28@gmail.com', 'PoKZ5Jl6Ttzg8yU', 'receptionist', 0, TIMESTAMP '2024-12-31 06:47:13.535000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (82, 'Marcela_MorenoSoria', 'Mayte8@yahoo.com', 'VhZLbmAFyijKIph', 'admin', 0, TIMESTAMP '2025-01-11 09:46:24.905000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (83, 'Blanca.FigueroaLuevano66', 'Guillermo.IrizarryCamarillo87@hotmail.com', 'dtA_dz27pQbN98u', 'receptionist', 0, TIMESTAMP '2025-04-03 06:40:48.222000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (84, 'Eva_CisnerosVergara67', 'Diego17@yahoo.com', 'M6IZv6O8BdKxKq0', 'admin', 1, TIMESTAMP '2025-01-29 21:39:59.039000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (85, 'Hermenegildo15', 'Enrique.AguirreMota@hotmail.com', 'eUHkjih2DfGmH0o', 'admin', 0, TIMESTAMP '2024-08-29 06:30:54.111000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (86, 'Dorotea_ChavarriaVigil', 'Javier_AmayaToro@gmail.com', 'iNUuVrbKhACDFE0', 'receptionist', 0, TIMESTAMP '2025-03-18 21:06:21.357000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (87, 'Claudio45', 'Homero_SaizValadez@yahoo.com', '7ciqC6xPQEQ36Om', 'admin', 1, TIMESTAMP '2024-08-05 19:45:32.322000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (88, 'Carla51', 'Juan_MuroTafoya@hotmail.com', '5nN77LBTuQsSXVL', 'admin', 0, TIMESTAMP '2025-01-16 02:23:29.585000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (89, 'Luz_TapiaRael0', 'Leticia_MenendezVillegas@gmail.com', 'pDBSs0cq4a0oLV4', 'receptionist', 0, TIMESTAMP '2025-02-01 19:30:08.955000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (90, 'Claudio_PeralesZepeda', 'Mercedes30@hotmail.com', 'dmmtRps9vd6aP2e', 'admin', 1, TIMESTAMP '2025-05-07 01:00:39.697000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (91, 'MariaSoledad9', 'Nicolas.SanchezMadrigal77@hotmail.com', 'GwGjkkVedcaxnLc', 'doctor', 0, TIMESTAMP '2024-08-05 06:56:14.682000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (92, 'Irene29', 'Josefina.CepedaValladares91@gmail.com', 'YBoyMVbR5wBlK9W', 'admin', 1, TIMESTAMP '2024-08-13 21:15:37.103000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (93, 'Ramon.EspinalZuniga', 'Nicolas.HerediaRosas@gmail.com', 'wLg6p4IHzfD6dvg', 'receptionist', 1, TIMESTAMP '2024-10-03 23:18:55.381000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (94, 'Guillermo75', 'Debora.MotaCornejo@gmail.com', 'O1aa7FhcWcB9gox', 'doctor', 0, TIMESTAMP '2025-03-13 09:32:25.684000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (95, 'Emilia.HernandezVillalobos', 'Marta.MunizLedesma@hotmail.com', 'vtlvCAicMxA2ybh', 'admin', 0, TIMESTAMP '2025-06-21 12:48:09.846000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (96, 'Guillermina38', 'Ignacio.SalcedoVerduzco8@gmail.com', 'SyuH4ULhehJXQkK', 'receptionist', 1, TIMESTAMP '2025-02-14 10:28:02.555000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (97, 'Sonia.TovarSaenz', 'Federico_RuizVillasenor@hotmail.com', '7f6vdzMOxLUZykv', 'admin', 1, TIMESTAMP '2024-12-06 14:34:35.136000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (98, 'Luis3', 'Ramon25@hotmail.com', 'EiBpBf6UXXn2TB7', 'admin', 0, TIMESTAMP '2024-10-12 17:41:43.975000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (99, 'Adela_CruzGuerrero6', 'Laura70@yahoo.com', 'wH01kZ6O3cmCThA', 'admin', 1, TIMESTAMP '2024-07-06 15:53:43.356000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (100, 'Lola15', 'Marilu_ColungaCintron69@hotmail.com', 'U5HfSV8kDbn4C2i', 'admin', 0, TIMESTAMP '2025-02-08 10:56:16.147000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (101, 'Octavio54', 'LuisMiguel68@gmail.com', 'YIrkqzyBlBahPUS', 'doctor', 0, TIMESTAMP '2024-10-08 20:51:05.879000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (102, 'Estela_MontenegroAmaya66', 'Ernesto.AranaOlivo@yahoo.com', '8urw3AUrYFDdV7e', 'receptionist', 0, TIMESTAMP '2024-10-19 16:27:11.752000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (103, 'Caridad.DeleonParedes', 'Hermenegildo.RaelPorras15@yahoo.com', 'nZGfNJAN3LANh2V', 'receptionist', 0, TIMESTAMP '2024-07-22 23:59:20.449000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (104, 'Elena.MontanoGodoy48', 'Catalina34@yahoo.com', '3V1O7pCmpaNMlPo', 'admin', 0, TIMESTAMP '2024-08-13 16:00:46.274000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (105, 'Clara.MenaTeran14', 'Matilde.LunaToro@hotmail.com', 'BAb_oBKPSkGahSo', 'receptionist', 1, TIMESTAMP '2025-04-24 00:30:24.197000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (106, 'Agustin61', 'JoseEduardo.RangelMontez@hotmail.com', 'itVb_JagyyOuAtm', 'doctor', 1, TIMESTAMP '2025-04-19 04:18:25.699000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (107, 'Caridad_GutierrezSauceda', 'Jesus_PachecoLara3@hotmail.com', 'GrYHQnXxitg7new', 'admin', 0, TIMESTAMP '2025-01-03 06:04:38.768000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (108, 'Carlota_FloresMaestas49', 'Clara_RiojasValle71@yahoo.com', 'SWCQ1rV_NaICykF', 'doctor', 1, TIMESTAMP '2025-06-04 17:37:27.287000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (109, 'Claudio.GalindoAdorno', 'Gloria69@hotmail.com', 'e5jLAO8ofrdRL1k', 'doctor', 0, TIMESTAMP '2024-12-29 12:58:23.137000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (110, 'Elisa_AparicioOntiveros40', 'MariaTeresa_NavarreteTello10@gmail.com', 'gmbCYJ3yJHk4riG', 'doctor', 1, TIMESTAMP '2025-05-16 09:14:45.062000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (111, 'Bernardo46', 'Miguel_RiojasNazario70@gmail.com', 'ifFE0GmM0o84Jjd', 'admin', 0, TIMESTAMP '2025-05-21 18:43:24.303000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (112, 'JuanRamon22', 'Daniel33@yahoo.com', 'pwqca2mK9GWBiiJ', 'admin', 1, TIMESTAMP '2024-12-27 21:16:22.819000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (113, 'Jordi_MendezNoriega16', 'Jeronimo.CavazosRincon66@gmail.com', 'FuFp_L7_PxoIABJ', 'receptionist', 1, TIMESTAMP '2024-10-28 00:29:35.179000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (114, 'Jacobo_PereaJasso', 'Alejandra23@hotmail.com', 'F35NFYqqFO4BH06', 'receptionist', 0, TIMESTAMP '2025-05-12 02:48:46.799000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (115, 'Mayte_BecerraCamacho14', 'Reina_RiojasHenriquez4@hotmail.com', 'oPVf7lwImUuUoDy', 'doctor', 1, TIMESTAMP '2025-04-15 17:51:01.728000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (116, 'Fernando47', 'Sergio31@yahoo.com', 'rIbQ4XBGUBn6mpb', 'admin', 0, TIMESTAMP '2024-12-21 07:54:59.015000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (117, 'Angel_CintronMaldonado', 'JulioCesar.RiosGurule@gmail.com', '1LD5jK8qqmGizNp', 'admin', 0, TIMESTAMP '2025-05-19 01:57:43.669000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (118, 'Carolina.TamezBorrego', 'Nicolas_LaboyHeredia68@yahoo.com', 'feaaz4MmA77c55f', 'receptionist', 0, TIMESTAMP '2024-07-29 21:51:29.425000', null, null);
INSERT INTO TEST_USER.APP_USER (ID, USERNAME, EMAIL, PASSWORD_HASH, ROLE, IS_ACTIVE, CREATED_AT, UPDATED_AT, DELETED_AT) VALUES (119, 'Teresa9', 'Ignacio_UribeAponte@hotmail.com', 'KihopC5sMWjWTuR', 'receptionist', 1, TIMESTAMP '2024-10-22 16:41:30.134000', null, null);