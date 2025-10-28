# 🚀 Git-Docker-K8s-Terraform-Jenkins Project

![Build](https://img.shields.io/badge/Build-Passing-brightgreen?style=for-the-badge)
![Docker](https://img.shields.io/badge/Docker-Enabled-blue?style=for-the-badge\&logo=docker)
![Terraform](https://img.shields.io/badge/Terraform-Infrastructure%20as%20Code-623CE4?style=for-the-badge\&logo=terraform)
![AWS](https://img.shields.io/badge/AWS-EKS%20%7C%20ECR-orange?style=for-the-badge\&logo=amazonaws)
![Kubernetes](https://img.shields.io/badge/Kubernetes-Deployed-326ce5?style=for-the-badge\&logo=kubernetes)
![License](https://img.shields.io/badge/License-MIT-lightgrey?style=for-the-badge)

---

An **end-to-end DevOps pipeline** that automates application deployment using **Git, Jenkins, Docker, Terraform, AWS ECR, and EKS**.
This project demonstrates **continuous integration and continuous deployment (CI/CD)** of a Flask application running on Kubernetes (EKS), provisioned via Terraform.

---

## 🧩 Project Overview

**Workflow:**
Git → Jenkins → Docker → AWS ECR → Kubernetes (EKS)

Jenkins automates:

* Building a Docker image from source code
* Pushing it to AWS ECR
* Deploying the containerized app to AWS EKS

---

## 🏗️ Architecture Diagram

![Architecture Diagram](https://raw.githubusercontent.com/assign-stone/Git-Docker-k8s-terraform-jenkins-project/main/assets/architecture-diagram.png)

```
 Developer → GitHub Repo
      ↓
  Jenkins Pipeline (on EC2)
      ↓
  Docker Build & Push → AWS ECR
      ↓
  Deploy → AWS EKS Cluster via kubectl
```

*(If the image doesn’t render, ensure `assets/architecture-diagram.png` exists in your repo.)*

---

## 🛠️ Tech Stack

| Tool             | Purpose                     |
| ---------------- | --------------------------- |
| **Git & GitHub** | Source control              |
| **Jenkins**      | CI/CD automation            |
| **Docker**       | Containerization            |
| **Terraform**    | Infrastructure provisioning |
| **AWS ECR**      | Docker image registry       |
| **AWS EKS**      | Kubernetes orchestration    |
| **Flask**        | Application framework       |

---

## 🌟 Features

* Automated build and deploy pipeline
* AWS-native infrastructure (ECR + EKS)
* Terraform-managed cluster provisioning
* Scalable Kubernetes deployment
* Centralized CI/CD via Jenkins

---

## 📁 Project Structure

```
Git-Docker-k8s-terraform-jenkins-project/
├── app/
│   ├── Dockerfile
│   ├── app.py
│   ├── requirements.txt
│   ├── static/
│   └── templates/
├── k8s/
│   ├── deployment.yaml
│   └── service.yaml
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── versions.tf
├── scripts/
│   └── helper-scripts.sh (optional)
└── Jenkinsfile
```

---

## ⚙️ Jenkins Pipeline Summary

1. **Checkout Code** from GitHub
2. **Build Docker Image** → `app/Dockerfile`
3. **Tag & Push** to AWS ECR (`flask-app-repo`)
4. **Deploy** image to AWS EKS using manifests in `/k8s`

---

## 🧠 Step-by-Step Setup Guide

### 1. Launch EC2 Instance (Jenkins + Tools)

Install core utilities:

```bash
sudo yum install -y git docker awscli terraform java-17-amazon-corretto
sudo systemctl enable docker && sudo systemctl start docker
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

---

### 2. Install Jenkins

```bash
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo dnf install -y jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins
```

Access Jenkins:
`http://<EC2-Public-IP>:8080`

---

### 3. Setup Terraform Infrastructure

```bash
cd terraform
terraform init -upgrade
terraform validate
terraform apply -auto-approve
```

Terraform provisions:

* AWS VPC, Subnets, Security Groups
* EKS Cluster & Node Group
* ECR Repository (`flask-app-repo`)

---

### 4. Configure kubectl with EKS

```bash
aws eks update-kubeconfig --region us-east-1 --name demo-eks-cluster
kubectl get nodes
```

Ensure your worker nodes are in the **Ready** state.

---

### 5. Build and Push Docker Image

Manually (for testing):

```bash
cd app
docker build -t flask-app-repo .
docker tag flask-app-repo:latest 434748569332.dkr.ecr.us-east-1.amazonaws.com/flask-app-repo:latest
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 434748569332.dkr.ecr.us-east-1.amazonaws.com
docker push 434748569332.dkr.ecr.us-east-1.amazonaws.com/flask-app-repo:latest
```

---

### 6. Kubernetes Deployment

```bash
cd k8s
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl get pods -o wide
kubectl get svc
```

Once service type = **LoadBalancer**, access your app via:

```
http://<elb-dns-name>
```

---

### 7. Jenkins Pipeline Configuration

* Job Type: **Pipeline**
* Pipeline Definition: **Pipeline script from SCM**
* GitHub Repo: `https://github.com/assign-stone/Git-Docker-k8s-terraform-jenkins-project.git`
* Branch: `main`

The pipeline automates:

* Build → Tag → Push (ECR)
* Deploy to EKS

---

## ✅ Verification

Run:

```bash
kubectl get pods
kubectl get svc
```

Access your app at the **LoadBalancer URL**.

---

## 🧾 Outputs

* ECR Repo: `flask-app-repo`
* EKS Cluster: `demo-eks-cluster`
* Region: `us-east-1`
* App URL: `<LoadBalancer-DNS>`

---

## 🧩 Improvements & Next Steps

* Integrate SonarQube for code quality
* Add Prometheus + Grafana for monitoring
* Configure Blue/Green deployment with ArgoCD
* Implement Slack notifications in Jenkins pipeline

---

## 👩‍💻 Author

**Shivani Joshi**
DevOps Engineer | AWS | Docker | Kubernetes | Terraform | Jenkins
🔗 [GitHub: assign-stone](https://github.com/assign-stone)
