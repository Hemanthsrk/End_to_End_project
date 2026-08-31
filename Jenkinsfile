```groovy
pipeline {

    agent any

    // =========================================================
    // ENVIRONMENT VARIABLES
    // =========================================================
    environment {

        // AWS
        AWS_REGION = 'ap-south-1'

        // AWS Account ID
        AWS_ACCOUNT_ID = '123456789012'

        // ECR repositories
        FRONTEND_REPO = 'front-backend-frontend'
        BACKEND_REPO  = 'front-backend-backend'

        // Docker image tag
        IMAGE_TAG = "${BUILD_NUMBER}"

        // Kubernetes
        K8S_NAMESPACE = 'front-backend'

        // EKS cluster
        EKS_CLUSTER_NAME = 'front-backend-cluster'

        // Kubernetes deployment names
        FRONTEND_DEPLOYMENT = 'frontend'
        BACKEND_DEPLOYMENT  = 'backend'
    }


    // =========================================================
    // PARAMETERS
    // =========================================================
    parameters {

        choice(
            name: 'DEPLOY_ENV',
            choices: ['dev', 'staging', 'prod'],
            description: 'Select deployment environment'
        )

        booleanParam(
            name: 'RUN_TRIVY_SCAN',
            defaultValue: true,
            description: 'Run Trivy vulnerability scan'
        )

        booleanParam(
            name: 'DEPLOY_TO_EKS',
            defaultValue: true,
            description: 'Deploy application to EKS'
        )
    }


    // =========================================================
    // PIPELINE STAGES
    // =========================================================
    stages {


        // =====================================================
        // 1. CHECKOUT
        // =====================================================
        stage('Checkout') {

            steps {

                echo "Checking out source code..."

                checkout scm
            }
        }


        // =====================================================
        // 2. FRONTEND INSTALL
        // =====================================================
        stage('Frontend Dependencies') {

            steps {

                dir('frontend') {

                    echo "Installing frontend dependencies..."

                    sh '''
                        npm ci
                    '''
                }
            }
        }


        // =====================================================
        // 3. FRONTEND TEST
        // =====================================================
        stage('Frontend Test') {

            steps {

                dir('frontend') {

                    echo "Running frontend tests..."

                    sh '''
                        CI=true npm test -- --watchAll=false
                    '''
                }
            }
        }


        // =====================================================
        // 4. FRONTEND BUILD
        // =====================================================
        stage('Frontend Build') {

            steps {

                dir('frontend') {

                    echo "Building React application..."

                    sh '''
                        npm run build
                    '''
                }
            }
        }


        // =====================================================
        // 5. BACKEND DEPENDENCIES
        // =====================================================
        stage('Backend Dependencies') {

            steps {

                dir('backend') {

                    echo "Downloading Go dependencies..."

                    sh '''
                        go mod download
                    '''
                }
            }
        }


        // =====================================================
        // 6. BACKEND TEST
        // =====================================================
        stage('Backend Test') {

            steps {

                dir('backend') {

                    echo "Running Go tests..."

                    sh '''
                        go test ./...
                    '''
                }
            }
        }


        // =====================================================
        // 7. BACKEND BUILD
        // =====================================================
        stage('Backend Build') {

            steps {

                dir('backend') {

                    echo "Building Go application..."

                    sh '''
                        CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
                        go build -o server main.go
                    '''
                }
            }
        }


        // =====================================================
        // 8. DOCKER LOGIN CHECK
        // =====================================================
        stage('Docker Check') {

            steps {

                echo "Checking Docker installation..."

                sh '''
                    docker --version
                '''
            }
        }


        // =====================================================
        // 9. BUILD FRONTEND DOCKER IMAGE
        // =====================================================
        stage('Build Frontend Docker Image') {

            steps {

                echo "Building frontend Docker image..."

                sh """
                    docker build \
                      -t ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${FRONTEND_REPO}:${IMAGE_TAG} \
                      -t ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${FRONTEND_REPO}:latest \
                      -f docker/frontend/Dockerfile .
                """
            }
        }


        // =====================================================
        // 10. BUILD BACKEND DOCKER IMAGE
        // =====================================================
        stage('Build Backend Docker Image') {

            steps {

                echo "Building backend Docker image..."

                sh """
                    docker build \
                      -t ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${BACKEND_REPO}:${IMAGE_TAG} \
                      -t ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${BACKEND_REPO}:latest \
                      -f docker/backend/Dockerfile .
                """
            }
        }


        // =====================================================
        // 11. TRIVY SCAN
        // =====================================================
        stage('Trivy Security Scan') {

            when {
                expression {
                    return params.RUN_TRIVY_SCAN
                }
            }

            steps {

                echo "Scanning Docker images with Trivy..."

                sh """
                    trivy image \
                      --severity HIGH,CRITICAL \
                      --exit-code 1 \
                      ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${FRONTEND_REPO}:${IMAGE_TAG}
                """

                sh """
                    trivy image \
                      --severity HIGH,CRITICAL \
                      --exit-code 1 \
                      ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${BACKEND_REPO}:${IMAGE_TAG}
                """
            }
        }


        // =====================================================
        // 12. AWS ECR LOGIN
        // =====================================================
        stage('ECR Login') {

            steps {

                echo "Logging into Amazon ECR..."

                sh """
                    aws ecr get-login-password \
                    --region ${AWS_REGION} |
                    docker login \
                    --username AWS \
                    --password-stdin \
                    ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                """
            }
        }


        // =====================================================
        // 13. PUSH FRONTEND IMAGE
        // =====================================================
        stage('Push Frontend Image') {

            steps {

                echo "Pushing frontend image to ECR..."

                sh """
                    docker push \
                    ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${FRONTEND_REPO}:${IMAGE_TAG}
                """

                sh """
                    docker push \
                    ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${FRONTEND_REPO}:latest
                """
            }
        }


        // =====================================================
        // 14. PUSH BACKEND IMAGE
        // =====================================================
        stage('Push Backend Image') {

            steps {

                echo "Pushing backend image to ECR..."

                sh """
                    docker push \
                    ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${BACKEND_REPO}:${IMAGE_TAG}
                """

                sh """
                    docker push \
                    ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${BACKEND_REPO}:latest
                """
            }
        }


        // =====================================================
        // 15. CONFIGURE KUBECTL
        // =====================================================
        stage('Configure Kubernetes') {

            when {
                expression {
                    return params.DEPLOY_TO_EKS
                }
            }

            steps {

                echo "Configuring kubectl for EKS..."

                sh """
                    aws eks update-kubeconfig \
                    --region ${AWS_REGION} \
                    --name ${EKS_CLUSTER_NAME}
                """

                sh '''
                    kubectl get nodes
                '''
            }
        }


        // =====================================================
        // 16. UPDATE FRONTEND IMAGE
        // =====================================================
        stage('Deploy Frontend') {

            when {
                expression {
                    return params.DEPLOY_TO_EKS
                }
            }

            steps {

                echo "Deploying frontend to Kubernetes..."

                sh """
                    kubectl set image deployment/${FRONTEND_DEPLOYMENT} \
                    frontend=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${FRONTEND_REPO}:${IMAGE_TAG} \
                    -n ${K8S_NAMESPACE}
                """
            }
        }


        // =====================================================
        // 17. UPDATE BACKEND IMAGE
        // =====================================================
        stage('Deploy Backend') {

            when {
                expression {
                    return params.DEPLOY_TO_EKS
                }
            }

            steps {

                echo "Deploying backend to Kubernetes..."

                sh """
                    kubectl set image deployment/${BACKEND_DEPLOYMENT} \
                    backend=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${BACKEND_REPO}:${IMAGE_TAG} \
                    -n ${K8S_NAMESPACE}
                """
            }
        }


        // =====================================================
        // 18. APPLY KUBERNETES CONFIGURATION
        // =====================================================
        stage('Apply Kubernetes Manifests') {

            when {
                expression {
                    return params.DEPLOY_TO_EKS
                }
            }

            steps {

                echo "Applying Kubernetes manifests..."

                sh '''
                    kubectl apply -f k8s/namespace.yaml

                    kubectl apply -f k8s/backend/configmap.yaml
                    kubectl apply -f k8s/backend/secret.yaml
                    kubectl apply -f k8s/backend/service.yaml

                    kubectl apply -f k8s/frontend/service.yaml

                    kubectl apply -f k8s/ingress.yaml
                '''
            }
        }


        // =====================================================
        // 19. ROLLOUT STATUS
        // =====================================================
        stage('Verify Deployment') {

            when {
                expression {
                    return params.DEPLOY_TO_EKS
                }
            }

            steps {

                echo "Checking frontend deployment..."

                sh """
                    kubectl rollout status \
                    deployment/${FRONTEND_DEPLOYMENT} \
                    -n ${K8S_NAMESPACE} \
                    --timeout=180s
                """

                echo "Checking backend deployment..."

                sh """
                    kubectl rollout status \
                    deployment/${BACKEND_DEPLOYMENT} \
                    -n ${K8S_NAMESPACE} \
                    --timeout=180s
                """
            }
        }


        // =====================================================
        // 20. KUBERNETES STATUS
        // =====================================================
        stage('Kubernetes Status') {

            when {
                expression {
                    return params.DEPLOY_TO_EKS
                }
            }

            steps {

                sh """
                    kubectl get pods \
                    -n ${K8S_NAMESPACE} \
                    -o wide
                """

                sh """
                    kubectl get services \
                    -n ${K8S_NAMESPACE}
                """

                sh """
                    kubectl get ingress \
                    -n ${K8S_NAMESPACE}
                """
            }
        }
    }


    // =========================================================
    // POST ACTIONS
    // =========================================================
    post {

        success {

            echo """
            ==========================================
            PIPELINE SUCCESS
            ==========================================

            Build Number : ${BUILD_NUMBER}
            Environment  : ${params.DEPLOY_ENV}

            Frontend Image:
            ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${FRONTEND_REPO}:${IMAGE_TAG}

            Backend Image:
            ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${BACKEND_REPO}:${IMAGE_TAG}

            Kubernetes Namespace:
            ${K8S_NAMESPACE}

            ==========================================
            """
        }


        failure {

            echo """
            ==========================================
            PIPELINE FAILED
            ==========================================

            Build Number : ${BUILD_NUMBER}
            Environment  : ${params.DEPLOY_ENV}

            Check Jenkins console logs.

            ==========================================
            """
        }


        always {

            echo "Cleaning Docker images..."

            sh """
                docker image prune -f || true
            """
        }
    }
}
```

