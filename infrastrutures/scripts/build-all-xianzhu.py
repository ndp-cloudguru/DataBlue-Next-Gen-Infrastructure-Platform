import os
import subprocess
import sys

# Resolve repo root based on script location
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(SCRIPT_DIR)

SERVICES = [
    {"name": "gateway",              "jar": "gateway.jar",              "port": 8888},
    {"name": "auth-service",         "jar": "auth-service.jar",         "port": 11100},
    {"name": "broadcast-service",    "jar": "broadcast-service.jar",    "port": 11111},
    {"name": "distribution-service", "jar": "distribution-service.jar", "port": 11112},
    {"name": "goods-service",        "jar": "goods-service.jar",        "port": 11113},
    {"name": "user-service",         "jar": "user-service.jar",         "port": 11114},
    {"name": "order-service",        "jar": "order-service.jar",        "port": 11115},
    {"name": "payment-service",      "jar": "payment-service.jar",      "port": 11116},
    {"name": "promotion-service",    "jar": "promotion-service.jar",    "port": 11117},
    {"name": "statistics-service",   "jar": "statistics-service.jar",   "port": 11118},
    {"name": "system-service",       "jar": "system-service.jar",       "port": 11119},
    {"name": "resource-service",     "jar": "resource-service.jar",     "port": 11120},
    {"name": "supplier-service",     "jar": "supplier-service.jar",     "port": 11121},
    {"name": "xianzhu-service",      "jar": "xianzhu-service.jar",      "port": 11122},
    {"name": "im-service",           "jar": "im-service.jar",           "port": 11130},
    {"name": "consumer",             "jar": "consumer.jar",             "port": 12000},
]

ECR_REPO = "580857941574.dkr.ecr.ap-southeast-1.amazonaws.com/datablue-test/backend-api"

DOCKERFILE = os.path.join(REPO_ROOT, "apps", "xianzhu", "Dockerfile")
BUILD_CONTEXT = os.path.join(REPO_ROOT, "apps", "xianzhu")
MANIFEST_PATH = os.path.join(REPO_ROOT, "apps", "xianzhu", "k8s-manifest.yaml")


def run_cmd(cmd, cwd=None):
    print(f"==> {cmd}")
    res = subprocess.run(cmd, shell=True, cwd=cwd or REPO_ROOT)
    if res.returncode != 0:
        print(f"[WARN] Command exited {res.returncode}: {cmd}")
    return res.returncode


def build_and_push(name, jar):
    image_tag = f"{ECR_REPO}:{name}-v1"
    jar_rel = f"backend/{jar}"  # relative to BUILD_CONTEXT (apps/xianzhu)
    build_cmd = (
        f"docker build --platform linux/arm64 "
        f"--build-arg JAR_FILE={jar_rel} "
        f"-t {image_tag} "
        f"-f \"{DOCKERFILE}\" "
        f"\"{BUILD_CONTEXT}\""
    )
    rc = run_cmd(build_cmd)
    if rc != 0:
        print(f"[ERROR] Build failed for {name}, skipping push.")
        return False

    push_cmd = f"docker push {image_tag}"
    run_cmd(push_cmd)
    return True


def generate_manifests():
    header = """apiVersion: v1
kind: Service
metadata:
  name: redis
  namespace: datablue-test
spec:
  type: ExternalName
  externalName: master.datablue-test-redis.ihjx1q.apse1.cache.amazonaws.com
---
apiVersion: v1
kind: Service
metadata:
  name: mysql
  namespace: datablue-test
spec:
  type: ExternalName
  externalName: datablue-test-mysql.cdw6qg4eg8qw.ap-southeast-1.rds.amazonaws.com
---
apiVersion: v1
kind: Service
metadata:
  name: rabbitmq
  namespace: datablue-test
spec:
  type: ExternalName
  externalName: b-fb078dff-6d79-4f3e-b997-08445dd7b3d5.mq.ap-southeast-1.on.aws
"""

    blocks = [header]
    for svc in SERVICES:
        name = svc["name"]
        port = svc["port"]
        image_tag = f"{ECR_REPO}:{name}-v1"
        block = f"""apiVersion: apps/v1
kind: Deployment
metadata:
  name: xianzhu-{name}
  namespace: datablue-test
  labels:
    app: xianzhu-{name}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: xianzhu-{name}
  template:
    metadata:
      labels:
        app: xianzhu-{name}
    spec:
      serviceAccountName: app-core-sa
      containers:
      - name: {name}
        image: {image_tag}
        imagePullPolicy: Always
        ports:
        - containerPort: {port}
          name: http
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "dev"
        - name: SPRING_CLOUD_NACOS_DISCOVERY_SERVER_ADDR
          value: "nacos-service.datablue-test.svc.cluster.local:8848"
        - name: SPRING_CLOUD_NACOS_CONFIG_SERVER_ADDR
          value: "nacos-service.datablue-test.svc.cluster.local:8848"
        - name: SPRING_CLOUD_NACOS_CONFIG_NAMESPACE
          value: "middle"
        - name: SPRING_CLOUD_NACOS_DISCOVERY_NAMESPACE
          value: "middle"
        - name: SPRING_CLOUD_NACOS_DISCOVERY_USERNAME
          value: "nacos"
        - name: SPRING_CLOUD_NACOS_DISCOVERY_PASSWORD
          value: "nacos"
        - name: SPRING_CLOUD_NACOS_CONFIG_USERNAME
          value: "nacos"
        - name: SPRING_CLOUD_NACOS_CONFIG_PASSWORD
          value: "nacos"
        - name: MYSQL_HOST
          value: "datablue-test-mysql.cdw6qg4eg8qw.ap-southeast-1.rds.amazonaws.com"
        - name: MYSQL_PORT
          value: "3306"
        - name: MYSQL_USER
          valueFrom:
            secretKeyRef:
              name: nacos-rds-secret
              key: username
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: nacos-rds-secret
              key: password
        - name: REDIS_HOST
          value: "master.datablue-test-redis.ihjx1q.apse1.cache.amazonaws.com"
        - name: REDIS_PORT
          value: "6379"
        - name: REDIS_PASSWORD
          value: ""
        - name: RABBITMQ_HOST
          value: "b-fb078dff-6d79-4f3e-b997-08445dd7b3d5.mq.ap-southeast-1.on.aws"
        - name: RABBITMQ_PORT
          value: "5671"
        resources:
          requests:
            cpu: "50m"
            memory: "256Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
---
apiVersion: v1
kind: Service
metadata:
  name: xianzhu-{name}-service
  namespace: datablue-test
spec:
  type: ClusterIP
  selector:
    app: xianzhu-{name}
  ports:
  - name: http
    port: {port}
    targetPort: {port}
"""
        blocks.append(block)

    with open(MANIFEST_PATH, "w", encoding="utf-8") as f:
        f.write("\n---\n".join(blocks))
    print(f"\nWritten K8s manifests -> {MANIFEST_PATH}")


def main():
    print(f"Repo root: {REPO_ROOT}")
    print(f"Dockerfile: {DOCKERFILE}")
    print(f"Build context: {BUILD_CONTEXT}\n")

    failed = []
    for svc in SERVICES:
        name = svc["name"]
        jar  = svc["jar"]
        print(f"\n{'='*50}")
        print(f" {name}")
        print(f"{'='*50}")
        ok = build_and_push(name, jar)
        if not ok:
            failed.append(name)

    print("\n\n=== Generating K8s manifests ===")
    generate_manifests()

    print("\n=== Applying manifests to EKS ===")
    run_cmd(f"kubectl apply -f \"{MANIFEST_PATH}\"")

    print("\n=== Rolling restart for all deployments ===")
    for svc in SERVICES:
        run_cmd(f"kubectl rollout restart deployment/xianzhu-{svc['name']} -n datablue-test")

    if failed:
        print(f"\n[WARN] These services had build errors: {failed}")
    else:
        print("\nAll 16 xianzhu microservices built, pushed, and deployed successfully!")


if __name__ == "__main__":
    main()
