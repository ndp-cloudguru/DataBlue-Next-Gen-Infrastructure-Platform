#!/usr/bin/env python3
import json
import subprocess
import sys

def run_cmd(cmd):
    try:
        res = subprocess.run(cmd, shell=True, capture_output=True, text=True, check=True)
        return res.stdout.strip()
    except subprocess.CalledProcessError as e:
        return f"ERR: {e.stderr.strip()}"

def print_header(title):
    print("\n" + "=" * 70)
    print(f" 🚀 {title}")
    print("=" * 70)

def check_nodes():
    print_header("EKS CLUSTER NODES STATUS")
    out = run_cmd("kubectl get nodes -o json")
    if out.startswith("ERR"):
        print(f"❌ Failed to get nodes: {out}")
        return
    data = json.loads(out)
    nodes = data.get("items", [])
    print(f"Total Nodes: {len(nodes)}")
    for n in nodes:
        name = n["metadata"]["name"]
        status = "NotReady"
        for cond in n["status"]["conditions"]:
            if cond["type"] == "Ready" and cond["status"] == "True":
                status = "Ready"
        addresses = {a["type"]: a["address"] for a in n["status"]["addresses"]}
        internal_ip = addresses.get("InternalIP", "N/A")
        print(f"  • Node: {name:<35} | Status: {status:<8} | IP: {internal_ip}")

def check_pods_and_endpoints():
    print_header("KUBERNETES PODS & ENDPOINTS (datablue-test)")
    pods_out = run_cmd("kubectl get pods -n datablue-test -o json")
    ep_out = run_cmd("kubectl get endpoints -n datablue-test -o json")
    
    if pods_out.startswith("ERR") or ep_out.startswith("ERR"):
        print(f"❌ Failed to query K8s pods or endpoints")
        return

    pods_data = json.loads(pods_out).get("items", [])
    ep_data = json.loads(ep_out).get("items", [])
    
    endpoints_map = {}
    for ep in ep_data:
        name = ep["metadata"]["name"]
        subsets = ep.get("subsets", [])
        ips = []
        if subsets:
            for s in subsets:
                for add in s.get("addresses", []):
                    ips.append(add.get("ip"))
        endpoints_map[name] = ", ".join(ips) if ips else "No Endpoints"

    running_count = 0
    total_count = len(pods_data)
    
    print(f"{'SERVICE / POD NAME':<42} | {'STATUS':<15} | {'RESTARTS':<8} | {'ENDPOINTS'}")
    print("-" * 90)
    
    for p in pods_data:
        name = p["metadata"]["name"]
        status = p["status"].get("phase", "Unknown")
        
        # Check container statuses
        container_statuses = p["status"].get("containerStatuses", [])
        restarts = 0
        ready = False
        if container_statuses:
            restarts = container_statuses[0].get("restartCount", 0)
            ready = container_statuses[0].get("ready", False)
            if not ready and status == "Running":
                status = "NotReady"
            elif ready:
                status = "1/1 Running"
                running_count += 1

        # Match service endpoint
        ep_ip = "N/A"
        for ep_name, ips in endpoints_map.items():
            clean_svc_name = ep_name.replace("-service", "")
            if clean_svc_name in name or ep_name in name:
                ep_ip = ips
                break
                
        status_icon = "✅" if ready else "⚠️"
        print(f"{status_icon} {name:<40} | {status:<15} | {restarts:<8} | {ep_ip}")

    print(f"\n📊 Summary: {running_count}/{total_count} pods are Healthy & Ready.")

def check_nacos_services():
    print_header("NACOS REGISTERED MICROSERVICES (Namespace: middle)")
    login_cmd = "kubectl exec nacos-0 -n datablue-test -- curl -s -X POST 'http://127.0.0.1:8848/nacos/v1/auth/login' -d 'username=nacos&password=nacos'"
    login_res = run_cmd(login_cmd)
    if "accessToken" not in login_res:
        print("❌ Failed to log in to Nacos API")
        return
    token = json.loads(login_res).get("accessToken")
    
    list_cmd = f"kubectl exec nacos-0 -n datablue-test -- curl -s 'http://127.0.0.1:8848/nacos/v1/ns/service/list?pageNo=1&pageSize=100&namespaceId=middle&accessToken={token}'"
    svc_res = run_cmd(list_cmd)
    
    if "doms" in svc_res:
        data = json.loads(svc_res)
        services = data.get("doms", [])
        print(f"Total Registered Microservices in Nacos: {len(services)}")
        for s in sorted(services):
            print(f"  🟢 {s}")
    else:
        print("⚠️ Could not retrieve Nacos service list")

def main():
    print("\n🔍 XIANZHU S2B2C - EKS HEALTH CHECK DASHBOARD")
    check_nodes()
    check_pods_and_endpoints()
    check_nacos_services()
    print_header("CHECK COMPLETED")

if __name__ == "__main__":
    main()
