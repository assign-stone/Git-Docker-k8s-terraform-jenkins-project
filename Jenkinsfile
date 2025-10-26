pipeline {
  agent any
  environment {
    // Jenkins credentials: create a credential of type 'Username with password' or use 'AWS Credentials' plugin
    // Credentials IDs referenced below must exist in Jenkins credentials store
    AWS_CREDENTIALS_ID = 'aws-creds' // set in Jenkins
    KUBECONFIG_CREDENTIALS_ID = 'kubeconfig' // secret file or text containing kubeconfig
    ECR_REPO = '' // will be populated by terraform output or set as pipeline param
  }

  options {
    skipDefaultCheckout false
    timestamps()
    ansiColor('xterm')
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Unit test') {
      steps {
        sh 'echo "No unit tests configured. Add tests to app/tests/ and run them here."'
      }
    }

    stage('Build Docker Image') {
      steps {
        script {
          // Use git commit SHA for tagging
          COMMIT_SHA = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
          IMAGE_TAG = "${COMMIT_SHA}"
          imageName = "${ECR_REPO}:${IMAGE_TAG}"
          echo "Building ${imageName}"
          sh "docker build -t ${imageName} -f app/Dockerfile app/"
        }
      }
    }

    stage('Login & Push to ECR') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: env.AWS_CREDENTIALS_ID]]) {
          script {
            // region must match Terraform's region
            sh '''
              AWS_REGION=${region:-us-east-1}
              aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin ${ECR_REGISTRY}
              docker push ${imageName}
            '''
          }
        }
      }
    }

    stage('Terraform: Plan & Apply (Provision infra)') {
      when { expression { return params.RUN_TERRAFORM == true || env.RUN_TERRAFORM == 'true' } }
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: env.AWS_CREDENTIALS_ID]]) {
          dir('terraform') {
            sh 'terraform init -input=false'
            sh 'terraform apply -auto-approve'
          }
        }
      }
    }

    stage('Deploy to EKS') {
      steps {
        script {
          // stash the kubeconfig if stored in credentials
          withCredentials([file(credentialsId: env.KUBECONFIG_CREDENTIALS_ID, variable: 'KUBECONFIG_FILE')]) {
            sh 'export KUBECONFIG=$KUBECONFIG_FILE'
            // Update k8s manifest with new image
            sh "sed -i 's|<ECR_IMAGE_URI>|${imageName}|g' k8s/deployment.yaml || true"
            sh './scripts/deploy_k8s.sh'
          }
        }
      }
    }
  }

  post {
    success {
      echo 'Pipeline completed successfully.'
    }
    failure {
      echo 'Pipeline failed. Inspect logs and fix.'
    }
  }
}
