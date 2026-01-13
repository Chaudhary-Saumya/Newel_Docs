#!/bin/bash
# FINAL FIX SCRIPT - Run this to completely fix your Paperless setup
# This script will:
# 1. Create missing database tables
# 2. Clear stale Redis tasks
# 3. Clear Celery result tables
# 4. Verify everything is ready

set -e  # Exit on error

echo "=========================================="
echo "PAPERLESS-NGX FINAL FIX SCRIPT"
echo "=========================================="
echo ""

cd ~/paperless-ngx

# Step 1: Create missing tables if they don't exist
echo "[1/4] Creating missing database tables..."
sqlite3 data/db.sqlite3 <<'SQL'
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
  FOREIGN KEY (owner_id) REFERENCES auth_user(id)
);
CREATE INDEX IF NOT EXISTS documents_paperlesstask_task_id ON documents_paperlesstask(task_id);
CREATE INDEX IF NOT EXISTS documents_paperlesstask_owner_id ON documents_paperlesstask(owner_id);

CREATE TABLE IF NOT EXISTS django_celery_results_taskresult (
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
);
CREATE INDEX IF NOT EXISTS django_celery_results_taskresult_task_id ON django_celery_results_taskresult(task_id);
CREATE INDEX IF NOT EXISTS django_celery_results_taskresult_status ON django_celery_results_taskresult(status);
CREATE INDEX IF NOT EXISTS django_celery_results_taskresult_worker ON django_celery_results_taskresult(worker);
CREATE INDEX IF NOT EXISTS django_celery_results_taskresult_date_done ON django_celery_results_taskresult(date_done);
SQL
echo "✓ Database tables created/verified"

# Step 2: Clear Redis queues
echo ""
echo "[2/4] Clearing Redis queues (removes stale tasks)..."
redis-cli FLUSHALL > /dev/null 2>&1 || echo "⚠ Redis not running - that's OK if you'll start it later"
echo "✓ Redis cleared"

# Step 3: Clear Celery result tables
echo ""
echo "[3/4] Clearing Celery result tables..."
cd src
source ../venv/bin/activate
python3 << 'PYEOF'
import os, sys, django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'paperless.settings')
django.setup()
from django_celery_results.models import TaskResult, GroupResult
task_count = TaskResult.objects.count()
group_count = GroupResult.objects.count()
TaskResult.objects.all().delete()
GroupResult.objects.all().delete()
print(f"✓ Deleted {task_count} TaskResult entries")
print(f"✓ Deleted {group_count} GroupResult entries")
PYEOF
echo "✓ Celery result tables cleared"

# Step 4: Verify tables exist
echo ""
echo "[4/4] Verifying database tables..."
cd ..
TABLES=$(sqlite3 data/db.sqlite3 "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('documents_paperlesstask', 'django_celery_results_taskresult');")
if echo "$TABLES" | grep -q "documents_paperlesstask" && echo "$TABLES" | grep -q "django_celery_results_taskresult"; then
    echo "✓ All required tables exist!"
else
    echo "✗ ERROR: Some tables are missing!"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ FIX COMPLETE!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Make sure Redis is running: redis-server (or it's already running)"
echo "2. Start Celery worker:"
echo "   cd ~/paperless-ngx"
echo "   source venv/bin/activate"
echo "   celery -A paperless worker -l info --pool=solo"
echo ""
echo "3. In another terminal, start Django:"
echo "   cd ~/paperless-ngx/src"
echo "   source ../venv/bin/activate"
echo "   python manage.py runserver"
echo ""
echo "4. Try uploading a document - it should work now!"
echo ""

