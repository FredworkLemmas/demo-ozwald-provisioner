import time
from os.path import basename
from typing import Any, Dict, Optional
from pathlib import Path

from invocate import task


@task(namespace='env', name='reinstall-ozwald')
def reinstall_ozwald(c):
    """
    Reinstall ozwald
    """
    c.run('pip uninstall ozwald -y')
    c.run('pip install -r requirements.txt')

@task(namespace='env', name='start-services')
def start_services(c):
    """
    Start all services required for ozwald
    """
    c.run('ozwald start_provisioner')

@task(namespace='test', name='footprint', pre=[start_services])
def footprint(c):
    """
    test simple footprint request
    """

    time.sleep(2)
    service = 'qwen1.5-vllm'
    profile='small-context-window'
    variety='nvidia'

    # c.run(f'ozwald footprint_services {service} --profile {profile} --variety {variety}')
    #c.run('rm -f footprint.yml')
    c.run(f'ozwald footprint_services {service}[{profile}][{variety}]')

@task(namespace='test', name='footprint-runner-logs')
def footprint_logs(c):
    service = 'qwen1.5-vllm'
    profile='small-context-window'
    variety='nvidia'
    c.run(f'ozwald get_footprint_logs --log-type runner {service} --profile {profile} --variety {variety}')

@task(namespace='test', name='footprint-container-logs')
def footprint_logs(c):
    service = 'qwen1.5-vllm'
    profile='small-context-window'
    variety='nvidia'
    c.run(f'ozwald get_footprint_logs --log-type container {service} --profile {profile} --variety {variety}')

@task(namespace="dev", name="build-containers")
def build_containers(c, name=None):
    """Build Docker images"""
    dockerfiles_dir = Path("dockerfiles")
    if not dockerfiles_dir.exists():
        print(f"Error: {dockerfiles_dir} directory not found")
        return

    if name:
        dockerfile_path = dockerfiles_dir / f"Dockerfile.{name}"
        if not dockerfile_path.exists():
            print(f"Error: Dockerfile.{name} not found in {dockerfiles_dir}")
            print("\nAvailable Dockerfiles:")
            for df in sorted(dockerfiles_dir.glob("Dockerfile.*")):
                print(f"  - {df.name.replace('Dockerfile.', '')}")
            return
        dockerfiles = [dockerfile_path]
    else:
        dockerfiles = sorted(dockerfiles_dir.glob("Dockerfile.*"))
        if not dockerfiles:
            print(f"No Dockerfiles found in {dockerfiles_dir}")
            return

    print(f"\nBuilding {len(dockerfiles)} container(s)...\n")
    with c.cd(dockerfiles_dir):
        for relpath_dockerfile in dockerfiles:
            dockerfile = basename(relpath_dockerfile)
            container_name = dockerfile.replace("Dockerfile.", "")
            image_tag = f"ozwald-{container_name}:latest"
            print("=" * 70)
            print(f"Building: {container_name}")
            print(f"Image tag: {image_tag}")
            print(f"Dockerfile: {dockerfile}")
            print("=" * 70)

            result = c.run(f"docker build -f {dockerfile} -t {image_tag} .", warn=True)
            if result.exited == 0:
                print(f"\n✓ Successfully built {image_tag}\n")
            else:
                print(f"\n✗ Failed to build {image_tag}\n")

    print("\nBuild complete!")


@task(namespace='containers', name='start')
def start_containers(c):
    """Start all containers defined in dockerfiles"""
    c.run('docker compose up -d --remove-orphans')


@task(namespace='containers', name='stop')
def stop_containers(c):
    """Stop all the containers"""
    c.run('docker compose down --remove-orphans')