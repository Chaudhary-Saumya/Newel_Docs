#!/usr/bin/env python3
import os
import sys
import django

sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'paperless.settings')
django.setup()

from django.db import connection

cursor = connection.cursor()

# Check existing tables
cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
existing = {r[0] for r in cursor.fetchall()}

print(f"Found {len(existing)} existing tables")

# Create documents_paperlesstask if missing
if 'documents_paperlesstask' not in existing:
    print("\nCreating documents_paperlesstask table...")
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
    cursor.execute("CREATE INDEX documents_paperlesstask_task_id ON documents_paperlesstask(task_id)")
    cursor.execute("CREATE INDEX documents_paperlesstask_owner_id ON documents_paperlesstask(owner_id)")
    connection.commit()
    print("✓ Created documents_paperlesstask")
else:
    print("✓ documents_paperlesstask already exists")

# Create django_celery_results_taskresult if missing
if 'django_celery_results_taskresult' not in existing:
    print("\nCreating django_celery_results_taskresult table...")
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
    cursor.execute("CREATE INDEX django_celery_results_taskresult_task_id ON django_celery_results_taskresult(task_id)")
    cursor.execute("CREATE INDEX django_celery_results_taskresult_status ON django_celery_results_taskresult(status)")
    cursor.execute("CREATE INDEX django_celery_results_taskresult_worker ON django_celery_results_taskresult(worker)")
    cursor.execute("CREATE INDEX django_celery_results_taskresult_date_done ON django_celery_results_taskresult(date_done)")
    cursor.execute("CREATE INDEX django_celery_results_taskresult_django_cele_periodi_1993cf_idx ON django_celery_results_taskresult(periodic_task_name, date_done)")
    connection.commit()
    print("✓ Created django_celery_results_taskresult")
else:
    print("✓ django_celery_results_taskresult already exists")

# Verify
cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
final = {r[0] for r in cursor.fetchall()}

if 'documents_paperlesstask' in final and 'django_celery_results_taskresult' in final:
    print("\n✓✓✓ SUCCESS: All required tables are now created!")
    sys.exit(0)
else:
    print("\n✗✗✗ ERROR: Tables still missing!")
    sys.exit(1)

