import json
import os

import boto3
import psycopg2
from dotenv import load_dotenv
from flask import Flask, jsonify

load_dotenv()

app = Flask(__name__)


def get_db_credentials():
    secret_name = os.getenv("AWS_SECRET_NAME", "postgresql-credentials")
    region_name = os.getenv("AWS_REGION", "us-east-1")

    client = boto3.client(
        "secretsmanager",
        region_name=region_name
    )

    response = client.get_secret_value(
        SecretId=secret_name
    )

    secret = json.loads(response["SecretString"])

    return secret["DB_USERNAME"], secret["DB_PASSWORD"]


def get_db_connection():
    username, password = get_db_credentials()

    return psycopg2.connect(
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT", "5432"),
        database=os.getenv("DB_NAME"),
        user=username,
        password=password,
    )


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "healthy"}), 200


@app.route("/db-health", methods=["GET"])
def db_health():
    connection = None
    cursor = None

    try:
        connection = get_db_connection()
        cursor = connection.cursor()

        cursor.execute("SELECT 1;")
        result = cursor.fetchone()

        if result == (1,):
            return jsonify({
                "status": "healthy",
                "database": "connected"
            }), 200

        return jsonify({
            "status": "unhealthy",
            "database": "unexpected response"
        }), 500

    except Exception:
        return jsonify({
            "status": "unhealthy",
            "database": "connection failed"
        }), 500

    finally:
        if cursor:
            cursor.close()

        if connection:
            connection.close()


@app.route("/users", methods=["GET"])
def users():
    connection = None
    cursor = None

    try:
        connection = get_db_connection()
        cursor = connection.cursor()

        cursor.execute(
            "SELECT id, name, email FROM users ORDER BY id;"
        )

        rows = cursor.fetchall()

        users_list = [
            {
                "id": row[0],
                "name": row[1],
                "email": row[2]
            }
            for row in rows
        ]

        return jsonify(users_list), 200

    except Exception:
        return jsonify({
            "error": "database operation failed"
        }), 500

    finally:
        if cursor:
            cursor.close()

        if connection:
            connection.close()


if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=5000
    )
