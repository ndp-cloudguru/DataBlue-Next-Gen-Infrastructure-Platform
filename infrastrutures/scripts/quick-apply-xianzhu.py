"""
Quick-apply: regenerate K8s manifests from build-all-xianzhu.py and apply to EKS.
Does NOT rebuild Docker images — images are already in ECR.
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'scripts'))

import importlib.util, subprocess

SCRIPT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'scripts', 'build-all-xianzhu.py')
spec = importlib.util.spec_from_file_location("bax", SCRIPT)
bax = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bax)

print("=== Regenerating K8s manifests ===")
bax.generate_manifests()

print("\n=== Applying to EKS ===")
bax.run_cmd(f'kubectl apply -f "{bax.MANIFEST_PATH}"')

print("\n=== Rolling restart for all deployments ===")
for svc in bax.SERVICES:
    bax.run_cmd(f"kubectl rollout restart deployment/xianzhu-{svc['name']} -n datablue-test")

print("\nDone!")
