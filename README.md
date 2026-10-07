# Cloud-Native Two-Tier Application Platform

A production-style two-tier web application deployed on **AWS EKS**, with infrastructure provisioned using **Terraform** and application deployment and validation automated with **Ansible**.

## Business Problem

Manual infrastructure provisioning and application deployment can introduce configuration inconsistencies, deployment errors, and operational overhead.

This project demonstrates an automated approach for provisioning cloud infrastructure and deploying a containerized application with Kubernetes while keeping the database isolated from public access.

## Solution

The platform uses:

* **Terraform** — Infrastructure as Code for AWS
* **Ansible** — Deployment and operational automation
* **Amazon EKS** — Kubernetes orchestration
* **Docker / ECR** — Containerization and image management
* **Application Load Balancer** — Public application access
* **Amazon RDS PostgreSQL** — Private database layer
* **IAM / IRSA** — AWS identity and access control

## Architecture

```text
                         Internet
                            │
                            ▼
                 ┌─────────────────────┐
                 │   AWS ALB :80       │
                 └──────────┬──────────┘
                            │
                            ▼
                 ┌─────────────────────┐
                 │      AWS EKS        │
                 │                     │
                 │  Kubernetes Service │
                 │          │          │
                 │     Flask Pods      │
                 └──────────┬──────────┘
                            │
                            │ TCP 5432
                            ▼
                 ┌─────────────────────┐
                 │   Private RDS       │
                 │     PostgreSQL      │
                 └─────────────────────┘

        Terraform → Infrastructure
        Ansible   → Deployment & Verification
        Kubernetes → Application Orchestration
```

## Automation Flow

```text
Terraform
   │
   ▼
AWS Infrastructure
   │
   ▼
Ansible Bootstrap
   │
   ▼
EKS Access
   │
   ▼
Ansible Deployment
   │
   ▼
Kubernetes Application
   │
   ▼
Automated Verification
```

### Ansible automation

Ansible automates:

1. AWS/EKS access validation
2. EKS kubeconfig configuration
3. Kubernetes manifest deployment
4. Deployment readiness checks
5. Application pod verification

The deployment was validated with **2/2 application replicas ready**.

## Infrastructure

Terraform provisions the core AWS environment including:

* VPC and subnet architecture
* Public and private subnets
* Internet Gateway
* NAT Gateways
* Route tables
* Security groups
* Amazon EKS cluster
* Managed node group
* Amazon RDS PostgreSQL
* Amazon ECR
* AWS Load Balancer Controller
* IAM/IRSA configuration

## Security Design

* Application workloads run inside private EKS subnets.
* PostgreSQL is deployed in private RDS subnets.
* The database is not publicly accessible.
* Security groups restrict application-to-database communication.
* IAM roles and IRSA provide controlled AWS access.
* Kubernetes Secrets and ConfigMaps are used for application configuration.
* Sensitive local files and Terraform state are excluded through `.gitignore`.

## Project Structure

```text
cloudnative-two-tier-platform/
├── ansible/
│   ├── ansible.cfg
│   ├── inventory/
│   ├── playbooks/
│   │   ├── bootstrap.yml
│   │   ├── deploy.yml
│   │   └── verify.yml
│   └── roles/
│       └── kubernetes/
├── backend/
│   ├── app.py
│   ├── Dockerfile
│   ├── requirements.txt
│   └── init.sql
├── k8s/
│   ├── deployment.yml
│   ├── service.yml
│   ├── alb-ingress.yml
│   ├── configmap.yml
│   ├── sa.yml
│   └── alb-controller-sa.tf
└── terraform/
    ├── main.tf
    ├── providers.tf
    ├── eks-cluster.tf
    ├── ecr-repo.tf
    ├── alb-controller.tf
    └── irsa-secrets.tf
```

## Technologies

**AWS | Terraform | Ansible | Kubernetes | Amazon EKS | Docker | Amazon ECR | Amazon RDS | PostgreSQL | ALB | IAM | IRSA | Linux**

## Skills Demonstrated

* Infrastructure as Code
* AWS cloud architecture
* Kubernetes administration
* Containerization
* Ansible automation
* Network and security design
* IAM and workload identity
* Application deployment automation
* Operational validation and troubleshooting

## Project Outcome

Built and validated a complete cloud-native application platform that demonstrates the separation of responsibilities between:

**Terraform → Infrastructure**

**Ansible → Automation**

**Kubernetes → Application orchestration**

The AWS environment was subsequently destroyed using Terraform after validation to avoid unnecessary ongoing infrastructure costs.

> **Note:** This is a portfolio project demonstrating a production-style architecture and automation workflow. It is not intended to represent a production system.

## Author

**Yasir Zafar**
