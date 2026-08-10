import subprocess
import sys

REMAINING_SERVICES = [
    {"name": "auth-service", "jar": "auth-service.jar"},
    {"name": "broadcast-service", "jar": "broadcast-service.jar"},
    {"name": "consumer", "jar": "consumer.jar"},
    {"name": "distribution-service", "jar": "distribution-service.jar"},
    {"name": "goods-service", "jar": "goods-service.jar"},
    {"name": "order-service", "jar": "order-service.jar"},
    {"name": "payment-service", "jar": "payment-service.jar"},
    {"name": "promotion-service", "jar": "promotion-service.jar"},
    {"name": "resource-service", "jar": "resource-service.jar"},
    {"name": "statistics-service", "jar": "statistics-service.jar"},
    {"name": "supplier-service", "jar": "supplier-service.jar"},
    {"name": "system-service", "jar": "system-service.jar"},
    {"name": "user-service", "jar": "user-service.jar"},
    {"name": "xianzhu-service", "jar": "xianzhu-service.jar"}
]

ECR_REPO = "580857941574.dkr.ecr.ap-southeast-1.amazonaws.com/datablue-test/backend-api"

def run_cmd(cmd):
    print(f"==> Running: {cmd}")
    res = subprocess.run(cmd, shell=True)
    return res.returncode

def main():
    for svc in REMAINING_SERVICES:
        name = svc["name"]
        jar = svc["jar"]
        image_tag = f"{ECR_REPO}:{name}-v1"

        print(f"\n==========================================")
        print(f" Building & Pushing Service: {name}")
        print(f"==========================================")

        build_cmd = f"docker build --provenance=false --platform linux/arm64 --build-arg JAR_FILE=backend/{jar} -t {image_tag} -f apps/xianzhu/Dockerfile apps/xianzhu"
        run_cmd(build_cmd)

        push_cmd = f"docker push {image_tag}"
        run_cmd(push_cmd)

        # Force rollout update in EKS
        rollout_cmd = f"kubectl rollout restart deployment/xianzhu-{name} -n datablue-test"
        run_cmd(rollout_cmd)

    print("\nAll 14 remaining microservices built and pushed successfully!")

if __name__ == "__main__":
    main()
