
pipeline {

    agent any

    environment {

        // ==============================
        // AWS CONFIGURATION
        // ==============================
        AWS_REGION = 'ap-south-1'

        AWS_ACCOUNT_ID = 'YOUR_AWS_ACCOUNT_ID'

        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

        FRONTEND_REPO = 'front-backend-frontend'
        BACKEND_REPO  = 'front-backend-backend'

        // Docker image tag
        IMAGE_TAG = "${BUILD_NUMBER}"

        // ==============================
        // EKS CONFIGURATION
        // ==============================
        EKS_CLUSTER_NAME = 'front-backend-cluster'

        K8S_NAMESPACE = 'front-backend'
    }


    stages {


        // ============================================
        // 1. CLONE REPOSITORY
        // ============================================
        stage('Clone Repository') {

            steps {

                checkout scmGit(
                    branches: [[name: '*/main']],
                    extensions: [],
                    userRemoteConfigs: [[
                        credentialsId: 'git',
                        url: 'https://github.com/Hemanthsrk/End_to_End_project.git'
                    ]]
                )
            }
        }


        // ============================================
        // 2. FRONTEND BUILD
        // ============================================
        stage('Frontend Build') {

            steps {

                dir('frontend') {

                    sh '''
                        echo "Installing frontend dependencies..."

                        npm ci

                        echo "Building frontend..."

                        npm run build
                    '''
                }
            }
        }


        // ============================================
        // 3. BACKEND BUILD
        // ============================================
        stage('Backend Build') {

            steps {

                dir('backend') {

                    sh '''
                        echo "Downloading Go dependencies..."

                        go mod download

                        echo "Running Go tests..."

                        go test ./...

                        echo "Building Go application..."

                        go build -o server main.go
                    '''
                }
            }
        }


        // ============================================
        // 4. BUILD DOCKER IMAGES
        // ============================================
        stage('Build Docker Images') {

            steps {

                sh """
                    echo "Building frontend Docker image..."

                    docker build \
                    -t ${ECR_REGISTRY}/${FRONTEND_REPO}:${IMAGE_TAG} \
                    -t ${ECR_REGISTRY}/${FRONTEND_REPO}:latest \
                    -f docker/frontend/Dockerfile .
                """


                sh """
                    echo "Building backend Docker image..."

                    docker build \
                    -t ${ECR_REGISTRY}/${BACKEND_REPO}:${IMAGE_TAG} \
                    -t ${ECR_REGISTRY}/${BACKEND_REPO}:latest \
                    -f docker/backend/Dockerfile .
                """
            }
        }


        // ============================================
        // 5. ECR LOGIN
        // ============================================
        stage('ECR Login') {

            steps {

                sh """
                    echo "Logging into Amazon ECR..."

                    aws ecr get-login-password \
                    --region ${AWS_REGION} | \
                    docker login \
                    --username AWS \
                    --password-stdin ${ECR_REGISTRY}
                """
            }
        }


        // ============================================
        // 6. PUSH DOCKER IMAGES
        // ============================================
        stage('Push Docker Images') {

            steps {

                sh """
                    echo "Pushing frontend image..."

                    docker push \
                    ${ECR_REGISTRY}/${FRONTEND_REPO}:${IMAGE_TAG}

                    docker push \
                    ${ECR_REGISTRY}/${FRONTEND_REPO}:latest
                """


                sh """
                    echo "Pushing backend image..."

                    docker push \
                    ${ECR_REGISTRY}/${BACKEND_REPO}:${IMAGE_TAG}

                    docker push \
                    ${ECR_REGISTRY}/${BACKEND_REPO}:latest
                """
            }
        }


        // ============================================
        // 7. TERRAFORM INIT
        // ============================================
        stage('Terraform Init') {

            steps {

                dir('terraform') {

                    sh '''
                        echo "Initializing Terraform..."

                        terraform init
                    '''
                }
            }
        }


        // ============================================
        // 8. TERRAFORM VALIDATE
        // ============================================
        stage('Terraform Validate') {

            steps {

                dir('terraform') {

                    sh '''
                        echo "Validating Terraform..."

                        terraform validate
                    '''
                }
            }
        }


        // ============================================
        // 9. TERRAFORM PLAN
        // ============================================
        stage('Terraform Plan') {

            steps {

                dir('terraform') {

                    sh '''
                        echo "Creating Terraform plan..."

                        terraform plan
                    '''
                }
            }
        }


        // ============================================
        // 10. TERRAFORM APPLY
        // ============================================
        stage('Deploy using Terraform') {

            steps {

                dir('terraform') {

                    sh '''
                        echo "Deploying AWS infrastructure..."

                        terraform apply -auto-approve
                    '''
                }
            }
        }


        // ============================================
        // 11. CONFIGURE EKS
        // ============================================
        stage('Configure EKS') {

            steps {

                sh """
                    echo "Configuring kubectl..."

                    aws eks update-kubeconfig \
                    --region ${AWS_REGION} \
                    --name ${EKS_CLUSTER_NAME}
                """

                sh '''
                    echo "Checking EKS nodes..."

                    kubectl get nodes
                '''
            }
        }


        // ============================================
        // 12. APPLY KUBERNETES MANIFESTS
        // ============================================
        stage('Deploy to Kubernetes') {

            steps {

                sh '''
                    echo "Creating namespace..."

                    kubectl apply \
                    -f k8s/namespace.yaml


                    echo "Deploying backend configuration..."

                    kubectl apply \
                    -f k8s/backend/configmap.yaml

                    kubectl apply \
                    -f k8s/backend/secret.yaml


                    echo "Deploying backend..."

                    kubectl apply \
                    -f k8s/backend/deployment.yaml

                    kubectl apply \
                    -f k8s/backend/service.yaml


                    echo "Deploying frontend..."

                    kubectl apply \
                    -f k8s/frontend/deployment.yaml

                    kubectl apply \
                    -f k8s/frontend/service.yaml


                    echo "Deploying ingress..."

                    kubectl apply \
                    -f k8s/ingress.yaml
                '''
            }
        }


        // ============================================
        // 13. UPDATE FRONTEND IMAGE
        // ============================================
        stage('Update Frontend Image') {

            steps {

                sh """
                    kubectl set image deployment/frontend \
                    frontend=${ECR_REGISTRY}/${FRONTEND_REPO}:${IMAGE_TAG} \
                    -n ${K8S_NAMESPACE}
                """
            }
        }


        // ============================================
        // 14. UPDATE BACKEND IMAGE
        // ============================================
        stage('Update Backend Image') {

            steps {

                sh """
                    kubectl set image deployment/backend \
                    backend=${ECR_REGISTRY}/${BACKEND_REPO}:${IMAGE_TAG} \
                    -n ${K8S_NAMESPACE}
                """
            }
        }


        // ============================================
        // 15. VERIFY DEPLOYMENT
        // ============================================
        stage('Verify Deployment') {

            steps {

                sh """
                    echo "Checking pods..."

                    kubectl get pods \
                    -n ${K8S_NAMESPACE}
                """


                sh """
                    echo "Checking services..."

                    kubectl get svc \
                    -n ${K8S_NAMESPACE}
                """


                sh """
                    echo "Checking ingress..."

                    kubectl get ingress \
                    -n ${K8S_NAMESPACE}
                """


                sh """
                    echo "Waiting for frontend deployment..."

                    kubectl rollout status \
                    deployment/frontend \
                    -n ${K8S_NAMESPACE} \
                    --timeout=180s
                """


                sh """
                    echo "Waiting for backend deployment..."

                    kubectl rollout status \
                    deployment/backend \
                    -n ${K8S_NAMESPACE} \
                    --timeout=180s
                """
            }
        }
    }


    // ============================================
    // POST ACTIONS
    // ============================================
    post {

        success {

            echo '''
            ==========================================
                    PIPELINE SUCCESS
            ==========================================

            Frontend image pushed successfully.
            Backend image pushed successfully.
            Terraform deployment completed.
            Kubernetes deployment completed.

            ==========================================
            '''
        }


        failure {

            echo '''
            ==========================================
                    PIPELINE FAILED
            ==========================================

            Please check the Jenkins console logs.

            ==========================================
            '''
        }


        always {

            echo 'Cleaning unused Docker images...'

            sh '''
                docker image prune -f || true
            '''
        }
    }
}
