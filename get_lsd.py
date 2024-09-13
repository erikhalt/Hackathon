import json
import jwt
import time

import requests

# Load saved key from filesystem
service_key = json.load(open('tok.json', 'rb'))

private_key = service_key['private_key'].encode('utf-8')

claim_set = {
    "iss": service_key['client_id'],
    "sub": service_key['user_id'],
    "aud": service_key['token_uri'],
    "iat": int(time.time()),
    "exp": int(time.time() + (60 * 60)),
}
grant = jwt.encode(claim_set, private_key, algorithm='RS256')

response = requests.post('https://land.copernicus.eu/@@oauth2-token',
                         headers={'Accept': 'application/json', 'Content-Type': 'application/x-www-form-urlencoded'},
                         data={'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer', 'assertion': grant})

bearer = json.loads(response.content)['access_token']
print(bearer)

response = requests.get(
    'https://land.copernicus.eu/api/@search?b_start=100&portal_type=DataSet&metadata_fields=UID&metadata_fields=dataset_full_format&&metadata_fields=dataset_download_information',
    headers={'Accept': 'application/json', 'Authorization': f'Bearer {bearer}'})

with open('datasets.json', 'w') as f:
    f.write(json.dumps(json.loads(response.content)))
