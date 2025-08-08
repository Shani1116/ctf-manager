pipeline {
    agent any
    environment {
        DOCKER_IMAGE = "ctf-manager"
        // DOCKER_REGISTRY = "your-registry/ctf-manager"  // ECR/Docker Hub
    }
    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/Shani1116/ctf-manager.git', branch: 'master'
            }
        }
        stage('Build') {
            steps {
                script {
                    // Build using host Docker (if socket bound)
                    docker.build("${DOCKER_IMAGE}:${env.BUILD_ID}")
                }
            }
        }
        stage('Test') {
            steps {
                script {
                    docker.image("${DOCKER_IMAGE}:${env.BUILD_ID}").inside {
                        sh 'php artisan test'
                    }
                }
            }
        }
    }
}