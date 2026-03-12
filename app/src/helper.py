
import json
import logging
import sys
import psycopg2
from psycopg2 import Error

logger = logging.getLogger(__name__)


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
            logger.info(f"Attempting connection to {self.host}:{self.port}/{self.dbname}")
            logger.info(f"Connection params: user={self.username}, port={self.port}")

            self.conn = psycopg2.connect(dbname=self.dbname, 
                                         user=self.username, 
                                         password=self.password, 
                                         host=self.host, 
                                         port=self.port,
                                         connect_timeout=10)
            logger.info("Connected to PostgreSQL successfully!")

            self.cur = self.conn.cursor()
            self.cur.execute("SELECT version();")
            
            db_version = self.cur.fetchone()
            logger.info(f"PostgreSQL version: {db_version}")

        except psycopg2.OperationalError as e:
            error_msg = f"Cannot connect to database at {self.host}:{self.port} - {str(e)}"
            logger.error(error_msg)
            raise Exception(error_msg)
        
        except Exception as e:
            error_msg = f"Database connection failed: {str(e)}"
            logger.error(error_msg)
            raise Exception(error_msg)

    def pg_disconnect(self) -> None:
        # Close the cursor and connection
        if self.cur:
            self.cur.close()
        if self.conn:
            self.conn.close()
        logger.info(f"Disconnected from PostgreSQL !")

    def insertRow(self,username,passw,email):
        sequence_name='put_postgres_table_seq'
        try:
            self.pg_connect()

            self.cur.execute(f"SELECT nextval('{sequence_name}');")
            next_value = self.cur.fetchone()[0]

            logger.info(f">>>>>>>>>>>>>>>>>> next_value : {next_value} , sequence_name : {sequence_name}")

            with self.conn.cursor() as cur:
                cur.execute("""
                    INSERT INTO POSTGRES_TABLE (RLO, USERNAME, PASSWORD, EMAIL)
                    VALUES (%s, %s, %s, %s)
                """, (next_value, username, passw, email) )
            self.conn.commit()

            return {"ok": "Row successfully inserted to database"}
        except Exception as error:
            logger.error(f"insertRow Error: {error}")
            if self.conn:
                self.conn.rollback()
            raise Exception(f"Insert failed: {str(error)}")

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
                return {"ok": data}
            
        except Exception as error:
            logger.error(f"selectRows Error: {error}")
            raise Exception(f"Select failed: {str(error)}")
            
        finally:
            self.pg_disconnect()

