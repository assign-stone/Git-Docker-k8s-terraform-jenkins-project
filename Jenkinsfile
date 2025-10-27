pipeline {
    agent any

    environment {
        AWS_CREDENTIALS_ID = 'aws-credentials'       // Jenkins credentials ID
        REGION             = 'us-east-1'
        ECR_REPO           = '434748569332.dkr.ecr.us-east-1.amazonaws.com/flask-app'
        IMAGE_TAG          = ''
        IMAGE_NAME         = ''
    }

    stages {
        stage('Checkout Code') {
            steps {
                echo 'Cloning repository...'
                git branch: 'main', url: 'https://github.com/assign-stone/Git-Docker-k8s-terraform-jenkins-project.git'
            }
        }

        stage('Set Image Tag') {
            steps {
                script {
                    IMAGE_TAG  = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                    IMAGE_NAME = "${ECR_REPO}:${IMAGE_TAG}"
                    echo "Image name: ${IMAGE_NAME}"
                }
            }
        }

        stage('Validate Environment Variables') {
            steps {
                script {
                    if (!env.REGION?.trim() || !env.ECR_REPO?.trim() || !env.AWS_CREDENTIALS_ID?.trim()) {
                        error "Missing one or more required environment variables: REGION, ECR_REPO, or AWS_CREDENTIALS_ID"
                    }
                    echo "All required environment variables are set."
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "Building Docker image: ${IMAGE_NAME}"
                    echo "Current directory:"
                    sh "pwd"
                    echo "Listing files:"
                    sh "ls -la"
                    echo "Listing app folder:"
                    sh "ls -la app/"
                    echo "Building Docker image from app/Dockerfile..."
                    sh "docker build -t ${IMAGE_NAME} -f app/Dockerfile app/"
                }
            }
        }

        stage('Login & Push to ECR') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: env.AWS_CREDENTIALS_ID]]) {
                    script {
                        echo 'Logging into ECR and pushing image...'
                        sh """
                            AWS_REGION=\${REGION}
                            ECR_REGISTRY=\$(echo \${ECR_REPO} | cut -d'/' -f1)
                            aws ecr get-login-password --region \$AWS_REGION | docker login --username AWS --password-stdin \$ECR_REGISTRY
                            docker push \${IMAGE_NAME}
                        """
                    }
                }
            }
        }

        stage('Post-build Cleanup') {
            steps {
                echo 'Cleaning up local Docker images...'
                sh "docker rmi ${IMAGE_NAME} || true"
            }
        }
    }

    post {
        success {
            echo 'Build and push completed successfully.'
        }
        failure {
            echo 'Build failed. Please check the Jenkins logs for details.'
        }
    }
}
