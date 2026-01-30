import psycopg
import sys

try:
    print("Attempting to connect to PostgreSQL...")
    conn = psycopg.connect(
        host="localhost",
        port="5432",
        dbname="paperless",
        user="paperless",
        password="StrongPassword"
    )
    print("SUCCESS: Connected to database!")
    conn.close()
except Exception as e:
    print(f"FAILURE: Could not connect. Error: {e}")
    sys.exit(1)
