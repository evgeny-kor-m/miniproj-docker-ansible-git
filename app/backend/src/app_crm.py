import os
import logging
import sys     
from flask import Flask, request, jsonify
import yaml
from helper import *

def setup_logging(default_path='logging_config.yaml', default_level=logging.INFO):

    path = default_path
    if os.path.exists(path):
        with open(path, 'rt') as f:
            config = yaml.safe_load(f.read())
            logging.config.dictConfig(config)
    else:
        logging.basicConfig(level=default_level)   

setup_logging()

app = Flask(__name__)
logger = logging.getLogger(__name__)

db_name = os.getenv("DB_NAME")
db_user = os.getenv("DB_USER")
db_passw = os.getenv("DB_PASSWORD")
db_host = os.getenv("DB_HOST")
db_port = os.getenv("DB_PORT")

dbPg = pgdb(db_host,db_name,db_user,db_passw,db_port)

@app.route("/")
def hello_world():
    return "<h1>Hello, Python mini project</h1>"

@app.route('/healthcheck', methods=['GET'])
def checkStatus():
    response = {
        'healthCheck': 'Flask service is up and running!',
        'dbConfig': {
            'host': db_host,
            'port': db_port,
            'database': db_name
        }
    }
    return jsonify(response), 200

@app.route("/getusers", methods=['GET'])
def get_users_route():
    if request.method == 'GET':

        num_row = request.args.get('num_row')

        if not num_row:
            json_body = request.get_json(silent=True)
            if json_body:
                num_row = json_body.get('num_row')
        try:
            if num_row and str(num_row).isdigit() and int(num_row) > 0 :
                response = dbPg.selectRows(int(num_row))
            else:
                response = dbPg.selectRows("ALL")
            return jsonify(response), 200
        
        except Exception as e:
            logger.error(f"Error in get_users_route: {e}", exc_info=True)
            return jsonify({"error in get_users_route": str(e)}), 500

@app.route("/setusers", methods=['POST'])
def set_users_route():
    if request.method == 'POST':
        json_body = request.get_json(silent=True)
        if json_body:
            username = json_body.get('username')
            password = json_body.get('password')
            email = json_body.get('email')
        else:
            username = request.form.get('username')
            password = request.form.get('password')
            email = request.form.get('email')

        if not all([username, password, email]):
            return jsonify({"error": "Missing required fields"}), 400
            
        try:
            response_data = dbPg.insertRow(username, password, email)
            return jsonify(response_data), 200
        except Exception as e:
            logger.error(f"Error in set_users_route: {e}", exc_info=True)
            return jsonify({"error in set_users_route": str(e)}), 500



if __name__ == "__main__":
    app_port = os.getenv("APP_PORT")
    logger.info(f"Starting Flask app on port {app_port}")
    app.run(debug=True, host='0.0.0.0', port=app_port)


# For URL query parameters, use request.args.

# search = request.args.get("search")
# page = request.args.get("page")
# For posted form input, use request.form.

# email = request.form.get('email')
# password = request.form.get('password')
# For JSON posted with content type application/json, use request.get_json().