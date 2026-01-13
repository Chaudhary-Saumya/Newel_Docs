#!/bin/bash
set -e

echo "=== PAPERLESS-NGX TABLE FIX ==="
echo ""

cd ~/paperless-ngx || exit 1
source venv/bin/activate

# Get the actual database path Django uses
cd src
DB_PATH=$(python3 << 'PYEOF'
import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'paperless.settings')
django.setup()
from django.conf import settings
print(settings.DATABASES['default']['NAME'])
PYEOF
)

echo "[1/5] Database path: $DB_PATH"
echo ""

# Check if database file exists
if [ ! -f "$DB_PATH" ]; then
    echo "ERROR: Database file does not exist at $DB_PATH"
    exit 1
fi

# Check if tables exist
echo "[2/5] Checking if tables exist..."
TABLES=$(sqlite3 "$DB_PATH" "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('documents_paperlesstask', 'django_celery_results_taskresult');" 2>/dev/null || echo "")

if echo "$TABLES" | grep -q "documents_paperlesstask" && echo "$TABLES" | grep -q "django_celery_results_taskresult"; then
    echo "✓ Both tables exist!"
else
    echo "✗ Tables missing. Creating them..."
    
    # Run migrations
    echo "[3/5] Running migrations..."
    python manage.py migrate documents --noinput || echo "Documents migration failed, continuing..."
    python manage.py migrate django_celery_results --noinput || echo "Celery results migration failed, continuing..."
    
    # Check again
    TABLES_AFTER=$(sqlite3 "$DB_PATH" "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('documents_paperlesstask', 'django_celery_results_taskresult');" 2>/dev/null || echo "")
    
    if echo "$TABLES_AFTER" | grep -q "documents_paperlesstask" && echo "$TABLES_AFTER" | grep -q "django_celery_results_taskresult"; then
        echo "✓ Tables created successfully!"
    else
        echo "[4/5] Migrations didn't create tables. Creating manually..."
        
        # Create documents_paperlesstask table
        sqlite3 "$DB_PATH" << 'SQL'
CREATE TABLE IF NOT EXISTS documents_paperlesstask (
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
    created_at DATETIME,
    updated_at DATETIME
);
CREATE INDEX IF NOT EXISTS documents_paperlesstask_task_id ON documents_paperlesstask(task_id);
CREATE INDEX IF NOT EXISTS documents_paperlesstask_owner_id ON documents_paperlesstask(owner_id);
SQL
        
        # Create django_celery_results_taskresult table
        sqlite3 "$DB_PATH" << 'SQL'
CREATE TABLE IF NOT EXISTS django_celery_results_taskresult (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id VARCHAR(255) NOT NULL UNIQUE,
    status VARCHAR(50) NOT NULL,
    content_type VARCHAR(128),
    content_encoding VARCHAR(64),
    result TEXT,
    date_done DATETIME NOT NULL,
    traceback TEXT,
    hidden BOOLEAN NOT NULL DEFAULT 0,
    meta TEXT
);
CREATE INDEX IF NOT EXISTS django_celery_results_taskresult_task_id ON django_celery_results_taskresult(task_id);
CREATE INDEX IF NOT EXISTS django_celery_results_taskresult_status ON django_celery_results_taskresult(status);
CREATE INDEX IF NOT EXISTS django_celery_results_taskresult_date_done ON django_celery_results_taskresult(date_done);
SQL
        
        echo "✓ Tables created manually!"
    fi
fi

# Verify final state
echo "[5/5] Final verification..."
FINAL_TABLES=$(sqlite3 "$DB_PATH" "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('documents_paperlesstask', 'django_celery_results_taskresult');" 2>/dev/null || echo "")

if echo "$FINAL_TABLES" | grep -q "documents_paperlesstask" && echo "$FINAL_TABLES" | grep -q "django_celery_results_taskresult"; then
    echo ""
    echo "✅ SUCCESS! Both tables exist and are ready."
    echo ""
    echo "Table structure:"
    sqlite3 "$DB_PATH" ".schema documents_paperlesstask" | head -5
    echo ""
    sqlite3 "$DB_PATH" ".schema django_celery_results_taskresult" | head -5
else
    echo ""
    echo "❌ ERROR: Tables still missing after all attempts!"
    exit 1
fi

echo ""
echo "=== DONE ==="

