import os
from flask import Flask
import psycopg2

app = Flask(__name__)

def get_db_connection():
    conn = psycopg2.connect(
        host=os.environ.get("DB_HOST", "db"),
        database=os.environ.get("DB_NAME", "sessiondb"),
        user=os.environ.get("DB_USER", "postgres"),
        password=os.environ.get("DB_PASSWORD", "postgres")
    )
    return conn

@app.route("/")
def home():
    return "Session 24 - Flask running inside Docker!"

@app.route("/db-check")
def db_check():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT version();")
        version = cur.fetchone()
        cur.close()
        conn.close()
        return f"Connected to Postgres: {version[0]}"
    except Exception as e:
        return f"DB connection failed: {str(e)}", 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
