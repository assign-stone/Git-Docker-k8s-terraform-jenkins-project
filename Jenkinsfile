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
                    // ensure we have a non-null registry value (fallback to the default used in repo)
                    def registry = (env.ECR_REPO?.trim()) ?: '434748569332.dkr.ecr.us-east-1.amazonaws.com/flask-app'
                    def imageName = "${registry}:${imageTag}"
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
                    echo "Building Docker image: ${env.IMAGE_NAME}"
                    echo "Current directory:"
                    sh "pwd"
                    echo "Listing files:"
                    sh "ls -la"
                    echo "Listing app folder:"
                    sh "ls -la app/"
                    echo "Attempting to build Docker image from app/Dockerfile..."

                    // Try to build only if docker is available on the agent. Capture exit codes
                    // to decide whether to skip push later.
                    def rc = sh(returnStatus: true, script: "if command -v docker >/dev/null 2>&1; then docker build -t ${env.IMAGE_NAME} -f app/Dockerfile app/; else exit 2; fi")
                    if (rc == 0) {
                        env.IMAGE_BUILD_OK = 'true'
                        echo "Docker build succeeded."
                    } else if (rc == 2) {
                        env.IMAGE_BUILD_OK = 'false'
                        echo "Docker CLI not found on this agent; skipping image build."
                    } else {
                        error("Docker build failed with exit code ${rc}")
                    }
                }
            }
        }

        stage('Login & Push to ECR') {
            when {
                expression { return env.AWS_CREDENTIALS_ID?.trim() }
            }
            steps {
                script {
                    if (env.IMAGE_BUILD_OK != 'true') {
                        echo "Image was not built on this agent; skipping push to ECR."
                        return
                    }

                    boolean pushed = false

                    // First, try the AWS-specific credentials binding (if the plugin/credential type exists)
                    try {
                        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: env.AWS_CREDENTIALS_ID]]) {
                            echo 'Using AmazonWebServicesCredentialsBinding to push to ECR.'
                            sh """
                                AWS_REGION=\${REGION}
                                ECR_REGISTRY=\$(echo \${ECR_REPO} | cut -d'/' -f1)
                                if ! command -v aws >/dev/null 2>&1; then echo 'aws CLI not found on agent; cannot push to ECR'; exit 1; fi
                                aws ecr get-login-password --region \$AWS_REGION | docker login --username AWS --password-stdin \$ECR_REGISTRY
                                docker push ${env.IMAGE_NAME}
                            """
                            pushed = true
                        }
                    } catch (Exception e) {
                        echo "AmazonWebServicesCredentialsBinding failed or not available: ${e.getMessage()}"
                        echo 'Attempting fallback to username/password credential binding...'
                        // Fallback to usernamePassword binding (common credential type)
                        try {
                            withCredentials([usernamePassword(credentialsId: env.AWS_CREDENTIALS_ID, usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                                echo 'Using username/password binding to push to ECR.'
                                sh """
                                    export AWS_ACCESS_KEY_ID=\$AWS_ACCESS_KEY_ID
                                    export AWS_SECRET_ACCESS_KEY=\$AWS_SECRET_ACCESS_KEY
                                    AWS_REGION=\${REGION}
                                    ECR_REGISTRY=\$(echo \${ECR_REPO} | cut -d'/' -f1)
                                    if ! command -v aws >/dev/null 2>&1; then echo 'aws CLI not found on agent; cannot push to ECR'; exit 1; fi
                                    aws ecr get-login-password --region \$AWS_REGION | docker login --username AWS --password-stdin \$ECR_REGISTRY
                                    docker push ${env.IMAGE_NAME}
                                """
                                pushed = true
                            }
                        } catch (Exception e2) {
                            error("Failed to push image using both credential bindings: ${e2.getMessage()}")
                        }
                    }

                    if (pushed) {
                        echo 'Image pushed to ECR successfully.'
                    }
                }
            }
        }

        stage('Post-build Cleanup') {
            steps {
                script {
                    if (env.IMAGE_BUILD_OK == 'true') {
                        echo 'Cleaning up local Docker images...'
                        sh "docker rmi ${env.IMAGE_NAME} || true"
                    } else {
                        echo 'No local image to cleanup.'
                    }
                }
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
