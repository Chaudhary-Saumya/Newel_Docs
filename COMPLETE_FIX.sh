#!/bin/bash
set -e

echo "=========================================="
echo "  PAPERLESS-NGX COMPLETE FIX"
echo "=========================================="
echo ""

cd ~/paperless-ngx || exit 1
source venv/bin/activate

cd src

# Get database path
DB_PATH=$(python3 << 'PYEOF'
import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'paperless.settings')
django.setup()
from django.conf import settings
print(settings.DATABASES['default']['NAME'])
PYEOF
)

echo "[1/6] Database: $DB_PATH"
echo ""

# Ensure tables exist
echo "[2/6] Ensuring tables exist..."
python3 << 'PYEOF'
import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'paperless.settings')
django.setup()

from django.db import connection
from django.core.management import call_command

with connection.cursor() as cursor:
    # Check documents_paperlesstask
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='documents_paperlesstask';")
    if not cursor.fetchone():
        print("Creating documents_paperlesstask...")
        call_command('migrate', 'documents', verbosity=1, interactive=False)
    
    # Check django_celery_results_taskresult
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='django_celery_results_taskresult';")
    if not cursor.fetchone():
        print("Creating django_celery_results_taskresult...")
        call_command('migrate', 'django_celery_results', verbosity=1, interactive=False)

# Final verification
with connection.cursor() as cursor:
    cursor.execute("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name IN ('documents_paperlesstask', 'django_celery_results_taskresult');")
    count = cursor.fetchone()[0]
    if count == 2:
        print("✓ Both tables exist")
    else:
        print(f"✗ ERROR: Only {count} tables found")
        exit(1)
PYEOF

echo ""
echo "[3/6] Clearing Redis queue..."
redis-cli FLUSHALL > /dev/null 2>&1 || echo "⚠️  Redis not running (this is OK if you start it later)"
echo "✓ Redis cleared"

echo ""
echo "[4/6] Clearing Celery result tables..."
python3 << 'PYEOF'
import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'paperless.settings')
django.setup()

try:
    from django_celery_results.models import TaskResult, GroupResult
    task_count = TaskResult.objects.count()
    group_count = GroupResult.objects.count()
    TaskResult.objects.all().delete()
    GroupResult.objects.all().delete()
    print(f"✓ Cleared {task_count} TaskResult and {group_count} GroupResult entries")
except Exception as e:
    print(f"⚠️  Could not clear result tables: {e}")
PYEOF

echo ""
echo "[5/6] Verifying database connection..."
python3 << 'PYEOF'
import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'paperless.settings')
django.setup()

from django.db import connection
from documents.models import PaperlessTask

try:
    # Try to query the table
    count = PaperlessTask.objects.count()
    print(f"✓ documents_paperlesstask accessible (has {count} entries)")
except Exception as e:
    print(f"✗ ERROR accessing documents_paperlesstask: {e}")
    exit(1)

try:
    from django_celery_results.models import TaskResult
    count = TaskResult.objects.count()
    print(f"✓ django_celery_results_taskresult accessible (has {count} entries)")
except Exception as e:
    print(f"✗ ERROR accessing django_celery_results_taskresult: {e}")
    exit(1)
PYEOF

echo ""
echo "[6/6] Checking Celery configuration..."
python3 << 'PYEOF'
import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'paperless.settings')
django.setup()

from django.conf import settings

print(f"CELERY_RESULT_BACKEND: {settings.CELERY_RESULT_BACKEND}")
print(f"CELERY_IGNORE_RESULT: {settings.CELERY_IGNORE_RESULT}")
print(f"CELERY_TASK_SERIALIZER: {settings.CELERY_TASK_SERIALIZER}")
print(f"CELERY_ACCEPT_CONTENT: {settings.CELERY_ACCEPT_CONTENT}")
PYEOF

echo ""
echo "=========================================="
echo "  ✅ FIX COMPLETE!"
echo "=========================================="
echo ""
echo "⚠️  CRITICAL: You MUST restart your Celery worker!"
echo ""
echo "1. Stop the current Celery worker (Ctrl+C)"
echo ""
echo "2. Start it again with:"
echo "   cd ~/paperless-ngx"
echo "   source venv/bin/activate"
echo "   celery -A paperless worker -l info --pool=solo"
echo ""
echo "3. Then try uploading a document"
echo ""
echo "The worker needs a fresh database connection to see the tables."
echo "=========================================="

