# Database Fix Instructions

Your database is missing some required tables. Run these commands in WSL to fix it:

## Step 1: Check current state
```bash
cd ~/paperless-ngx/src
source ../venv/bin/activate
python manage.py shell
```

Then in the Python shell:
```python
from django.db import connection
cursor = connection.cursor()
cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
tables = [row[0] for row in cursor.fetchall()]
print('documents_paperlesstask' in tables)
print('django_celery_results_taskresult' in tables)
exit()
```

## Step 2: Create missing tables manually

If the tables don't exist, run this Python script:

```bash
cd ~/paperless-ngx/src
source ../venv/bin/activate
python << 'EOF'
import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'paperless.settings')
django.setup()

from django.db import connection
from django.core.management.sql import sql_create_index

cursor = connection.cursor()

# Check if table exists
cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='documents_paperlesstask'")
if not cursor.fetchone():
    print("Creating documents_paperlesstask table...")
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
    print("✓ Created documents_paperlesstask table")
else:
    print("✓ documents_paperlesstask table already exists")

# Check django_celery_results_taskresult
cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='django_celery_results_taskresult'")
if not cursor.fetchone():
    print("Creating django_celery_results_taskresult table...")
    # Run the migration for django_celery_results
    from django.core.management import call_command
    call_command('migrate', 'django_celery_results', verbosity=1)
    print("✓ Created django_celery_results_taskresult table")
else:
    print("✓ django_celery_results_taskresult table already exists")

print("Done!")
EOF
```

## Step 3: Mark migrations as applied

```bash
python manage.py migrate --fake
```

## Step 4: Verify

```bash
python manage.py migrate
```

If you see "No migrations to apply", you're good to go!

