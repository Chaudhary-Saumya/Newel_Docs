
import os
import django
from django.conf import settings

# Setup django to access settings
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "paperless.settings")
django.setup()

print(f"os.name: {os.name}")
print(f"PAPERLESS_CONVERT_BINARY (env): {os.getenv('PAPERLESS_CONVERT_BINARY')}")
print(f"settings.CONVERT_BINARY: {settings.CONVERT_BINARY}")
print(f"settings.GS_BINARY: {settings.GS_BINARY}")
