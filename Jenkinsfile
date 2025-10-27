pipeline {
agent any

environment {
    AWS_CREDENTIALS_ID        = 'aws-creds'         
    KUBECONFIG_CREDENTIALS_ID = 'kubeconfig' 
    ECR_REGISTRY              = '434748569332.dkr.ecr.us-east-1.amazonaws.com' 
    ECR_REPO                  = '434748569332.dkr.ecr.us-east-1.amazonaws.com/flask-app' 
    REGION                    = 'us-east-1'
}

options {
    skipDefaultCheckout false
    timestamps()
}

parameters {
    booleanParam(
        name: 'RUN_TERRAFORM', 
        defaultValue: false, 
        description: 'Provision infrastructure using Terraform'
    )
}

stages {

    stage('Checkout') {
        steps {
            echo 'Checking out source code...'
            checkout scm
        }
    }

    stage('Unit Test') {
        steps {
            echo 'Running tests (if any)...'
            sh 'echo "No unit tests configured. Add tests to app/tests/ and run them here."'
        }
    }

    stage('Build Docker Image') {
        steps {
            script {
                COMMIT_SHA = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                IMAGE_TAG  = "${COMMIT_SHA}"
                IMAGE_NAME = "${ECR_REPO}:${IMAGE_TAG}"

                echo "Building Docker image: ${IMAGE_NAME}"

                sh """
                    echo "Current directory:"
                    pwd
                    echo "Listing files:"
                    ls -la
                    echo "Listing app folder:"
                    ls -la app/
                    echo "Building Docker image from app/Dockerfile..."
                    docker build -t ${IMAGE_NAME} -f app/Dockerfile app/
                """
            }
        }
    }

    stage('Login & Push to ECR') {
        steps {
            withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: env.AWS_CREDENTIALS_ID]]) {
                script {
                    echo 'Logging into ECR and pushing image...'
                    sh """
                        AWS_REGION=${REGION}
                        ECR_REGISTRY=$(echo ${ECR_REPO} | cut -d'/' -f1)
                        aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY
                        docker push ${IMAGE_NAME}
                    """
                }
            }
        }
    }

    stage('Terraform: Init & Apply') {
        when { 
            expression { return params.RUN_TERRAFORM == true } 
        }
        steps {
            withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: env.AWS_CREDENTIALS_ID]]) {
                dir('terraform') {
                    echo 'Initializing and applying Terraform...'
                    sh """
                        terraform init -input=false
                        terraform apply -auto-approve
                    """
                }
            }
        }
    }

    stage('Deploy to EKS') {
        steps {
            withCredentials([file(credentialsId: env.KUBECONFIG_CREDENTIALS_ID, variable: 'KUBECONFIG_FILE')]) {
                script {
                    echo 'Deploying to Kubernetes (EKS)...'
                    sh """
                        export KUBECONFIG=$KUBECONFIG_FILE
                        sed -i "s|<ECR_IMAGE_URI>|${IMAGE_NAME}|g" k8s/deployment.yaml || true
                        kubectl apply -f k8s/deployment.yaml
                        kubectl apply -f k8s/service.yaml
                    """
                }
            }
        }
    }
}

post {
    success {
        echo 'Pipeline completed successfully.'
        cleanWs()
    }
    failure {
        echo 'Pipeline failed. Check logs for errors.'
        cleanWs()
    }
}


}
