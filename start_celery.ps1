cd c:\Users\HP\Downloads\ccc\paperless-ngx\src
..\venv\Scripts\Activate.ps1
python -m celery -A paperless worker -l info --pool=solo
