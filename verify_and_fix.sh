#!/bin/bash
set -e

echo "=== VERIFYING DATABASE AND TABLES ==="
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

echo "Database: $DB_PATH"
echo ""

# Test database connection and table access
echo "Testing database connection..."
python3 << 'PYEOF'
import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'paperless.settings')
django.setup()

from django.db import connection
from django.core.management import call_command

# Test connection
with connection.cursor() as cursor:
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='documents_paperlesstask';")
    result = cursor.fetchone()
    if result:
        print("✓ documents_paperlesstask table exists")
    else:
        print("✗ documents_paperlesstask table MISSING")
        print("Running migrations...")
        call_command('migrate', 'documents', verbosity=2, interactive=False)
    
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='django_celery_results_taskresult';")
    result = cursor.fetchone()
    if result:
        print("✓ django_celery_results_taskresult table exists")
    else:
        print("✗ django_celery_results_taskresult table MISSING")
        print("Running migrations...")
        call_command('migrate', 'django_celery_results', verbosity=2, interactive=False)

# Verify both tables exist now
with connection.cursor() as cursor:
    cursor.execute("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name IN ('documents_paperlesstask', 'django_celery_results_taskresult');")
    count = cursor.fetchone()[0]
    if count == 2:
        print("")
        print("✅ SUCCESS: Both tables verified!")
    else:
        print("")
        print(f"❌ ERROR: Only {count} tables found (expected 2)")
        exit(1)
PYEOF

echo ""
echo "=== Database verification complete ==="
echo ""
echo "⚠️  IMPORTANT: Restart your Celery worker now!"
echo "   The worker may have a stale database connection."
echo ""
echo "   Stop the worker (Ctrl+C) and restart with:"
echo "   cd ~/paperless-ngx"
echo "   source venv/bin/activate"
echo "   celery -A paperless worker -l info --pool=solo"

