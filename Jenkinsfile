pipeline {
agent any

environment {
    REGION = 'ap-south-1'
    ECR_REPO = 'git-docker-k8s-terraform-repo'
    IMAGE_NAME = 'app-image'
}

stages {
    stage('Checkout Code') {
        steps {
            git branch: 'main', url: 'https://github.com/assign-stone/Git-Docker-k8s-terraform-jenkins-project.git'
        }
    }

    stage('Build Docker Image') {
        steps {
            script {
                sh '''
                echo "Building Docker image..."
                docker build -t ${IMAGE_NAME}:latest .
                '''
            }
        }
    }

    stage('Login & Push to ECR') {
        steps {
            withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                script {
                    sh '''
                    echo "=== Checking required environment variables ==="
                    if [ -z "$REGION" ] || [ -z "$ECR_REPO" ] || [ -z "$IMAGE_NAME" ]; then
                      echo "❌ One or more required environment variables are missing!"
                      echo "REGION=$REGION"
                      echo "ECR_REPO=$ECR_REPO"
                      echo "IMAGE_NAME=$IMAGE_NAME"
                      exit 1
                    fi
                    
                    echo "✅ All environment variables are set."
                    
                    AWS_REGION=${REGION}
                    ECR_REGISTRY=$(aws sts get-caller-identity --query 'Account' --output text).dkr.ecr.${AWS_REGION}.amazonaws.com
                    
                    echo "Logging into ECR..."
                    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY
                    
                    echo "Tagging and pushing image..."
                    docker tag ${IMAGE_NAME}:latest $ECR_REGISTRY/${ECR_REPO}:latest
                    docker push $ECR_REGISTRY/${ECR_REPO}:latest
                    '''
                }
            }
        }
    }

    stage('Terraform: Init & Apply') {
        steps {
            sh '''
            cd terraform
            terraform init
            terraform apply -auto-approve
            '''
        }
    }

    stage('Deploy to EKS') {
        steps {
            sh '''
            aws eks update-kubeconfig --name my-eks-cluster --region ${REGION}
            kubectl apply -f k8s/
            '''
        }
    }
}


}
