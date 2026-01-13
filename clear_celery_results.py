#!/usr/bin/env python3
import os
import sys
import django

sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'paperless.settings')
django.setup()

from django_celery_results.models import TaskResult, GroupResult

print("Clearing Celery result tables...")
task_count = TaskResult.objects.count()
group_count = GroupResult.objects.count()

TaskResult.objects.all().delete()
GroupResult.objects.all().delete()

print(f"✓ Deleted {task_count} TaskResult entries")
print(f"✓ Deleted {group_count} GroupResult entries")
print("✓ Celery result tables cleared successfully!")

