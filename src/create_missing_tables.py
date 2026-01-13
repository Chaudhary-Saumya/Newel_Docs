#!/usr/bin/env python3
"""
Script to create missing database tables for paperless-ngx
This will create documents_paperlesstask and django_celery_results_taskresult tables
"""
import os
import sys
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'paperless.settings')
django.setup()

from django.db import connection
from django.core.management import call_command

def create_missing_tables():
    cursor = connection.cursor()
    
    # Check existing tables
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
    existing_tables = {row[0] for row in cursor.fetchall()}
    
    print(f"Found {len(existing_tables)} existing tables")
    
    # Check and create documents_paperlesstask
    if 'documents_paperlesstask' not in existing_tables:
        print("\n[1/2] Creating documents_paperlesstask table...")
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
            cursor.execute("CREATE INDEX documents_paperlesstask_task_id ON documents_paperlesstask(task_id)")
            cursor.execute("CREATE INDEX documents_paperlesstask_owner_id ON documents_paperlesstask(owner_id)")
            connection.commit()
            print("✓ Successfully created documents_paperlesstask table")
        except Exception as e:
            print(f"✗ Error creating documents_paperlesstask: {e}")
            connection.rollback()
            return False
    else:
        print("✓ documents_paperlesstask table already exists")
    
    # Check and create django_celery_results_taskresult
    if 'django_celery_results_taskresult' not in existing_tables:
        print("\n[2/2] Creating django_celery_results_taskresult table...")
        try:
            # First try using Django migrations
            call_command('migrate', 'django_celery_results', verbosity=0, interactive=False)
            # Verify it was created
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='django_celery_results_taskresult'")
            if cursor.fetchone():
                print("✓ Successfully created django_celery_results_taskresult table via migrations")
            else:
                raise Exception("Migration didn't create the table")
        except Exception as e:
            print(f"  Migration failed: {e}")
            print("  Creating table manually...")
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
                cursor.execute("CREATE INDEX django_celery_results_taskresult_task_id ON django_celery_results_taskresult(task_id)")
                cursor.execute("CREATE INDEX django_celery_results_taskresult_status ON django_celery_results_taskresult(status)")
                cursor.execute("CREATE INDEX django_celery_results_taskresult_worker ON django_celery_results_taskresult(worker)")
                cursor.execute("CREATE INDEX django_celery_results_taskresult_date_done ON django_celery_results_taskresult(date_done)")
                cursor.execute("CREATE INDEX django_celery_results_taskresult_django_cele_periodi_1993cf_idx ON django_celery_results_taskresult(periodic_task_name, date_done)")
                connection.commit()
                print("✓ Successfully created django_celery_results_taskresult table manually")
            except Exception as e2:
                print(f"✗ Error creating table manually: {e2}")
                connection.rollback()
                return False
    else:
        print("✓ django_celery_results_taskresult table already exists")
    
    # Final verification
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
    final_tables = {row[0] for row in cursor.fetchall()}
    
    if 'documents_paperlesstask' in final_tables and 'django_celery_results_taskresult' in final_tables:
        print("\n✓ All required tables exist!")
        return True
    else:
        print("\n✗ Some tables are still missing!")
        return False

if __name__ == '__main__':
    success = create_missing_tables()
    sys.exit(0 if success else 1)

