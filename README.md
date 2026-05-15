# AWS Infrastructure Provisioning

This repository contains the declarative configuration for a highly available, multi-tier AWS architecture. The infrastructure is provisioned using Terraform and spans networking, compute, storage, container orchestration, backup management, and monitoring services. The design strictly adheres to the principles of infrastructure as code, ensuring idempotent deployments and reproducible environments.

## Architecture Overview

The network topology consists of two distinct Virtual Private Clouds. The core services environment hosts the primary application logic, shared utilities, and relational data stores. The manufacturing environment is isolated for sensor data collection and processing. A Virtual Private Cloud peering connection bridges the two networks, allowing routed traffic between them while maintaining strict security group boundaries.

Compute resources are deployed across multiple Availability Zones to guarantee fault tolerance. An Auto Scaling Group manages the lifecycle of the application instances, dynamically scaling horizontally based on CPU utilization metrics. An Application Load Balancer distributes incoming traffic across the scaling group, offloading health checks and balancing requests based on predefined URL paths.

Containerized workloads are orchestrated through Amazon Elastic Container Service utilizing the Fargate launch type. This provides a serverless execution model for isolated tasks. Additionally, an AWS Elastic Beanstalk environment provisions a fully managed PHP platform for rapid application deployment, configuring the underlying resources automatically.

Storage persistence is achieved through a combination of Amazon S3 and Amazon Elastic File System. The S3 configuration enforces data immutability via Object Lock and automates cost optimization through Lifecycle Policies that transition older objects to infrequent access storage. The Elastic File System provides scalable, shared block storage mounted concurrently by multiple instances.

Disaster recovery and data protection are managed by AWS Backup. A centralized backup vault captures daily snapshots of critical instances, retaining them for two months. To ensure resilience against regional failures, the backup plan includes an automated cross-region copy action, synchronizing recovery points to a secondary geographic location.

Monitoring and observability are implemented via Amazon EventBridge and Amazon Simple Notification Service. State changes in the compute fleet, such as instance terminations, trigger event rules that immediately dispatch notifications to the operations team, ensuring proactive incident response.

## Prerequisites

The deployment requires the Terraform binary and the AWS Command Line Interface to be installed on the deployment machine. Administrative credentials must be configured locally. An SSH key pair must be generated and stored in the default location for instance access.

```bash
apt-get update
apt-get install curl unzip gnupg software-properties-common lsb-release
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf awscliv2.zip aws
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt-get update
apt-get install terraform
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
aws configure
```

## Deployment

Initialize the working directory to download the required provider plugins.

```bash
terraform init
```

Validate the configuration syntax and internal consistency.

```bash
terraform validate
```

Generate an execution plan to preview the infrastructure changes.

```bash
terraform plan -out=tfplan
```

Apply the execution plan to provision the resources in the AWS account.

```bash
terraform apply "tfplan"
```

## Post Provisioning

Once the infrastructure is successfully deployed, several administrative tasks must be completed manually. The Simple Notification Service topic requires explicit email subscription confirmation to begin routing alerts. The Identity and Access Management users created by the configuration require console passwords to be generated through the AWS Management Console, as credential generation is excluded from the declarative state for security purposes.

To test the auto scaling configuration, establish an SSH session with an instance in the scaling group and execute a synthetic load test to trigger the target tracking policy.

```bash
amazon-linux-extras install epel -y
yum install stress -y
stress --cpu 4 --timeout 600
```

To test the application load balancer routing, retrieve the DNS name from the Terraform output and navigate to the configured paths via a web browser.

## Teardown

To permanently destroy all provisioned infrastructure and avoid incurring further charges, execute the destroy command and confirm the operation.

```bash
terraform destroy -auto-approve
```
