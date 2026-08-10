import urllib.request
import urllib.parse
import json

NACOS = "http://127.0.0.1:8848/nacos"

def get_token():
    data = urllib.parse.urlencode({"username": "nacos", "password": "nacos"}).encode()
    req = urllib.request.Request(f"{NACOS}/v1/auth/login", data=data, method="POST")
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read())["accessToken"]

def list_services(token, ns=""):
    url = f"{NACOS}/v1/ns/service/list?pageNo=1&pageSize=100&namespaceId={ns}&accessToken={token}"
    with urllib.request.urlopen(url) as r:
        return json.loads(r.read())

def main():
    token = get_token()
    print(f"Login OK. Token prefix: {token[:30]}...")

    print("\n=== Services in namespace: public ===")
    r = list_services(token, "")
    print(f"Count: {r['count']}, Services: {r['doms']}")

    print("\n=== Services in namespace: middle ===")
    r = list_services(token, "middle")
    print(f"Count: {r['count']}, Services: {r['doms']}")

if __name__ == "__main__":
    main()
