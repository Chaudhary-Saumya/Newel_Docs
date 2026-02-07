import requests
import base64

url = "http://127.0.0.1:8000/api/documents/post_document/"
auth = ("admin", "admin")

files = {'document': open('test_doc.txt', 'rb')}

try:
    print(f"Uploading to {url}...")
    response = requests.post(url, files=files, auth=auth)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.text}")
except Exception as e:
    print(f"Request failed: {e}")
