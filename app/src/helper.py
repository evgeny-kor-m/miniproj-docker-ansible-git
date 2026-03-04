
import json

import psycopg2
from psycopg2 import Error

class pgdb:
    def __init__(self,_host,_dbname,_username,_password,_port):
        self.host = _host
        self.dbname=_dbname
        self.username = _username
        self.password = _password
        self.port = _port
        self.conn = None
        self.cur = None

    def pg_connect(self):
        try:
            self.conn = psycopg2.connect(dbname=self.dbname, 
                                         user=self.username, 
                                         password=self.password, 
                                         host=self.host, 
                                         port=self.port)
            print("Connected to PostgreSQL successfully!")

            self.cur = self.conn.cursor()
            self.cur.execute("SELECT version();")
            
            db_version = self.cur.fetchone()
            print(f"PostgreSQL version: {db_version}")

        except Exception as e:
            print(f"An error occurred: {e}")

    def pg_disconnect(self) -> None:
        # Close the cursor and connection
        if self.cur:
            self.cur.close()
        if self.conn:
            self.conn.close()
        print("Disconnected from PostgreSQL !")

    def insertRow(self,username,passw,email):
        sequence_name='get_postgres_table_seq'
        try:
            self.pg_connect()

            self.cur.execute(f"SELECT nextval('{sequence_name}');")
            next_value = self.cur.fetchone()[0]

            print(f"Current value of the sequence '{sequence_name}': {next_value}")

            with self.conn.cursor() as cur:
                cur.execute("""
                    INSERT INTO POSTGRES_TABLE (RLO, USERNAME, PASSWORD, EMAIL)
                    VALUES (%s, %s, %s, %s)
                """, (next_value, username, passw, email) )
            self.conn.commit()

            return json.dumps({"ok": "Row successfully inserted to database"})
        except (Exception, Error) as error:
            print(f"Error: {error}")
            return json.dumps({"error": str(error)}),500

        finally:
            self.pg_disconnect()

    def selectRows(self,rowNum) -> str:
        try:
            self.pg_connect()

            with self.conn.cursor() as cur:
                
                query = f"SELECT * FROM POSTGRES_TABLE LIMIT {rowNum}"
                cur.execute(query)
                columns = [desc[0] for desc in cur.description]
                data = [dict(zip(columns, row)) for row in cur.fetchall()]
                return json.dumps({"ok": data}, ensure_ascii=False, default=str)
            
        except (Exception, Error) as error:
            print(f"Error: {error}")
            return json.dumps({"error": str(error)}),500
            
        finally:
            self.pg_disconnect()

