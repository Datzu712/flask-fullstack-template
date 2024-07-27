# For Life, S.A Full Stack Application

## Table of contents
1. [Tech Stack](#tech-stack)
2. [Installation](#installation)
    1. [Local setup](#local-setup)
    2. [Docker setup](#docker-setup)

## Tech Stack
- [Flask](https://flask.palletsprojects.com/en/3.0.x/)
- [Redis](https://redis.io/es/)
- [MySQL](https://www.mysql.com/)
- [Docker/docker compose](https://www.docker.com/)
- [Swagger](https://swagger.io/) (todo)
- [SqlAlchemy](https://www.sqlalchemy.org/)
- MVC Architecture
- LAMP Stack

## Installation
1. Clone the repository
```bash
git clone https://github.com/Datzu712/For_Life_S.A.git
```

2. Setup the environment variables
Rename the `.flaskenv.example` file to `.flaskenv` and set the values for the environment variables
```bash
FLASK_APP=wsgi
FLASK_DEBUG=True
FLASK_ENV=development
FLASK_RUN_PORT=8080
FLASK_RUN_HOST=0.0.0.0

MYSQL_URL=mysql+pymysql://admin:root@mysql:3306/uni
# Mysql conf for docker (you can leave it blank if you are not using docker)
MYSQL_USERNAME=admin
MYSQL_PASSWORD=root
MYSQL_HOST=mysql
MYSQL_PORT=3306
MYSQL_DATABASE=uni

REDIS_URL=redis://admin:root@redis:6379/0
# Redis conf for docker (you can leave it blank if you are not using docker)
REDIS_USERNAME=admin
REDIS_PASSWORD=root
REDIS_PORT=6379
```

### Local setup

3. Create a virtual environment
```bash
python3 -m venv .venv
```

4. Activate the virtual environment (Linux)
```bash
source .venv/bin/activate
```

4.1 Activate the virtual environment (Windows)
```bash
.venv\Scripts\activate
```

5. Install the dependencies
```bash
pip install -r requirements.txt
```

6. Run the application
```bash
flask run
```

### Docker setup
1. Run the docker compose command
```bash
docker compose --env-file .flaskenv up
```

2. Access the application on `http://localhost:8080`

3. To stop the application run
```bash
docker compose --env-file .flaskenv down
```