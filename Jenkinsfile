pipeline {
    agent any

    // Make credentials and key settings configurable via pipeline parameters so the
    // job doesn't fail if the Jenkins instance doesn't have a credential with a
    // hard-coded ID.
    parameters {
        string(name: 'AWS_CREDENTIALS_ID', defaultValue: '', description: 'Jenkins AWS credentials id (leave blank to skip ECR push)')
        string(name: 'KUBECONFIG_CREDENTIALS_ID', defaultValue: '', description: 'Jenkins kubeconfig file credential id (leave blank to skip k8s deploy)')
        string(name: 'AWS_REGION', defaultValue: 'us-east-1', description: 'AWS Region')
        string(name: 'ECR_REPO', defaultValue: '434748569332.dkr.ecr.us-east-1.amazonaws.com/flask-app', description: 'ECR repo (registry/repo)')
        booleanParam(name: 'RUN_TERRAFORM', defaultValue: false, description: 'Run terraform apply in the pipeline')
    }

    environment {
        AWS_CREDENTIALS_ID = "${params.AWS_CREDENTIALS_ID}"
        REGION             = "${params.AWS_REGION}"
        ECR_REPO           = "${params.ECR_REPO}"
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
                    // use local defs to avoid creating pipeline script fields
                    def imageTag = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                    def imageName = "${env.ECR_REPO}:${imageTag}"
                    // export into env for later stages
                    env.IMAGE_TAG = imageTag
                    env.IMAGE_NAME = imageName
                    echo "Image name: ${env.IMAGE_NAME}"
                }
            }
        }

        stage('Validate Environment Variables') {
            steps {
                script {
                    if (!env.REGION?.trim() || !env.ECR_REPO?.trim()) {
                        error "Missing one or more required environment variables: REGION or ECR_REPO"
                    }
                    if (!env.AWS_CREDENTIALS_ID?.trim()) {
                        echo "WARNING: AWS_CREDENTIALS_ID not set - push to ECR will be skipped."
                    } else {
                        echo "AWS credentials id provided. ECR push will be attempted."
                    }
                    echo "Environment validated."
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
            when {
                expression { return env.AWS_CREDENTIALS_ID?.trim() }
            }
            steps {
                script {
                    // use the credential id supplied to the job; if it fails to exist the
                    // withCredentials call will fail -- this stage is skipped when empty.
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: env.AWS_CREDENTIALS_ID]]) {
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
