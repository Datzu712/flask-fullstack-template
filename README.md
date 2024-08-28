# Flask Full Stack Application (For Life, S.A uni)

![alt text](image.png)

## Table of contents
1. [Tech Stack](#tech-stack)
2. [Installation](#installation)
    1. [Local setup](#local-setup)
    2. [Docker setup](#docker-setup)
3. [Author](#author)

## Tech Stack
- [Flask](https://flask.palletsprojects.com/en/3.0.x/)
- [Redis](https://redis.io/es/)
- [MySQL](https://www.mysql.com/)
- [Docker/docker compose](https://www.docker.com/)
- [SqlAlchemy](https://www.sqlalchemy.org/)
- [Nginx](https://nginx.org/en/)
- MVC Architecture
- LAMP Stack
- [Bootstrap 5 (MDB)](https://mdbootstrap.com/)
- [JWT authentication](https://jwt.io/)

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

### Local setup (Keep in mind that you need to have MySQL and Redis installed)

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
1. Generate the certificates for the Nginx server
```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout nginx/ssl/cert.key -out nginx/ssl/cert.crt
```
2. Run the docker compose command
```bash
docker compose --env-file .flaskenv up
```

3. Access the application on `https://localhost:443`

To stop the application run
```bash
docker compose --env-file .flaskenv down
```

## Author
- [Datzu712](https://github.com/Datzu712/)
