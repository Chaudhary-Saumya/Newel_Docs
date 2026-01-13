#!/bin/bash
# Script to fix missing database tables in paperless-ngx
# Run this in WSL: bash fix_missing_tables.sh

cd ~/paperless-ngx/src
source ../venv/bin/activate

echo "Checking database state..."

python << 'PYTHON_SCRIPT'
import os
import sys
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'paperless.settings')
django.setup()

from django.db import connection

cursor = connection.cursor()

# Check existing tables
cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
existing_tables = {row[0] for row in cursor.fetchall()}

print(f"Found {len(existing_tables)} existing tables")

# Check and create documents_paperlesstask
if 'documents_paperlesstask' not in existing_tables:
    print("\nCreating documents_paperlesstask table...")
    try:
        cursor.execute("""
            CREATE TABLE documents_paperlesstask (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                task_id VARCHAR(255) NOT NULL UNIQUE,
                acknowledged BOOLEAN NOT NULL DEFAULT 0,
                task_file_name VARCHAR(255),
                task_name VARCHAR(255),
                status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
                date_created DATETIME,
                date_started DATETIME,
                date_done DATETIME,
                result TEXT,
                type VARCHAR(30) NOT NULL DEFAULT 'auto_task',
                owner_id INTEGER,
                FOREIGN KEY (owner_id) REFERENCES auth_user(id)
            )
        """)
        cursor.execute("CREATE INDEX IF NOT EXISTS documents_paperlesstask_task_id ON documents_paperlesstask(task_id)")
        cursor.execute("CREATE INDEX IF NOT EXISTS documents_paperlesstask_owner_id ON documents_paperlesstask(owner_id)")
        connection.commit()
        print("✓ Created documents_paperlesstask table")
    except Exception as e:
        print(f"✗ Error creating documents_paperlesstask: {e}")
        connection.rollback()
else:
    print("✓ documents_paperlesstask table already exists")

# Check and create django_celery_results_taskresult
if 'django_celery_results_taskresult' not in existing_tables:
    print("\nCreating django_celery_results_taskresult table...")
    try:
        from django.core.management import call_command
        call_command('migrate', 'django_celery_results', verbosity=1, interactive=False)
        print("✓ Created django_celery_results_taskresult table")
    except Exception as e:
        print(f"✗ Error creating django_celery_results_taskresult: {e}")
        # Try to create it manually
        try:
            cursor.execute("""
                CREATE TABLE django_celery_results_taskresult (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    task_id VARCHAR(255) NOT NULL UNIQUE,
                    status VARCHAR(50) NOT NULL,
                    content_type VARCHAR(128),
                    content_encoding VARCHAR(64),
                    result TEXT,
                    date_done DATETIME NOT NULL,
                    traceback TEXT,
                    meta TEXT,
                    task_name VARCHAR(255),
                    worker VARCHAR(100),
                    date_created DATETIME NOT NULL,
                    date_started DATETIME,
                    periodic_task_name VARCHAR(255)
                )
            """)
            cursor.execute("CREATE INDEX IF NOT EXISTS django_celery_results_taskresult_task_id ON django_celery_results_taskresult(task_id)")
            cursor.execute("CREATE INDEX IF NOT EXISTS django_celery_results_taskresult_status ON django_celery_results_taskresult(status)")
            cursor.execute("CREATE INDEX IF NOT EXISTS django_celery_results_taskresult_worker ON django_celery_results_taskresult(worker)")
            cursor.execute("CREATE INDEX IF NOT EXISTS django_celery_results_taskresult_date_done ON django_celery_results_taskresult(date_done)")
            connection.commit()
            print("✓ Created django_celery_results_taskresult table manually")
        except Exception as e2:
            print(f"✗ Error creating table manually: {e2}")
            connection.rollback()
else:
    print("✓ django_celery_results_taskresult table already exists")

print("\nDatabase fix complete!")
PYTHON_SCRIPT

echo ""
echo "Now running migrations to ensure everything is in sync..."
python manage.py migrate --fake-initial

echo ""
echo "Verifying migrations..."
python manage.py migrate

echo ""
echo "Done! You can now try uploading a document."

