from flask import Flask,request
from helper import *


app = Flask(__name__)
dbPg = pgdb("127.0.0.1","postgres","postgres","postgresdb",5433)

@app.route("/")
def hello_world():
    return "<h1>Hello, Python mini project</h1>"

@app.route('/healthcheck', methods=['GET'])
def checkStatus():
    response = {
        'healthCheck': 'Flask service is up and running!'
    }
    return response, 200

@app.route("/getusers", methods=['GET'])
def get_users_route():
    if request.method == 'GET':
        num_row = request.args.get('num_row')

        if not num_row:
            json_body = request.get_json(silent=True)
            if json_body:
                num_row = json_body.get('num_row')
        try:
            if num_row and int(num_row) > 0:
                response = dbPg.selectRows(int(num_row))
            else:
                response = dbPg.selectRows("ALL")
        except ValueError:
            response = dbPg.selectRows("ALL")

    return response, 200

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

        if not username or not password or not email:
            return {"error": "Missing required fields (username, password, email)"}, 400
        response = dbPg.insertRow(username,password,email)

    return response, 200
   
if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=5000)


# For URL query parameters, use request.args.

# search = request.args.get("search")
# page = request.args.get("page")
# For posted form input, use request.form.

# email = request.form.get('email')
# password = request.form.get('password')
# For JSON posted with content type application/json, use request.get_json().