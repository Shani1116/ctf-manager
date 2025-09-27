pipeline {
    agent any
    environment {
        DOCKER_IMAGE = "ctf-manager"
        SCANNER_HOME = tool 'SonarScanner'
        DD_API_KEY = credentials('DD_API_KEY')
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
                    docker.build("${DOCKER_IMAGE}:${env.BUILD_ID}")

                    sh "aws ecr get-login-password --region ap-southeast-2 | docker login --username AWS --password-stdin ${env.AWS_ACCOUNT_ID}.dkr.ecr.ap-southeast-2.amazonaws.com"

                    sh """
                        docker tag ${DOCKER_IMAGE}:${env.BUILD_ID} ${env.AWS_ACCOUNT_ID}.dkr.ecr.ap-southeast-2.amazonaws.com/${DOCKER_IMAGE}:${env.BUILD_ID}
                        docker push ${env.AWS_ACCOUNT_ID}.dkr.ecr.ap-southeast-2.amazonaws.com/${DOCKER_IMAGE}:${env.BUILD_ID}
                    """
                }
            }
        }
        stage('Test') {
            steps {
                script {
                    docker.image("${DOCKER_IMAGE}:${env.BUILD_ID}").inside {
                    // Ensure the environment is set up correctly
                    sh 'cp .env.example .env'

                    //Set application encryption key
                    sh 'php artisan key:generate --force'
            
                    // Run tests with the correct PHPUnit version
                    sh './vendor/bin/phpunit --configuration phpunit.xml'
                    }
                }
            }
        }
        stage('Code Quality') {
            steps {
                withSonarQubeEnv('Sonarcloud') {
                    script {
                        sh """
                            ${SCANNER_HOME}/bin/sonar-scanner \
                            -Dsonar.projectKey=Shani1116_ctf-manager \
                            -Dsonar.organization=shani1116 \
                            -Dsonar.sources=. \
                            -Dsonar.host.url=https://sonarcloud.io
                        """
                        // Wait for SonarCloud Quality Gate result
                        // timeout(time: 5, unit: 'MINUTES') {
                        // def qg = waitForQualityGate()
                        //     if (qg.status != 'OK') {
                        //         echo "SonarQube Quality Gate failed: ${qg.status}"
                        //         currentBuild.result = 'UNSTABLE'
                        //     }
                        // }
                    }
                }    
            }
        }
        stage('Security') {
            steps {
                script {
                    docker.image("${DOCKER_IMAGE}:${env.BUILD_ID}").inside {
                        // Run security analysis with the correct PHPStan version
                        sh 'composer --version'
                        sh 'composer audit || true'
                    }

                    //Run Trivy scan
                    sh """
                        trivy image --exit-code 0 --severity LOW,MEDIUM,HIGH,CRITICAL ${DOCKER_IMAGE}:${env.BUILD_ID}
                    """
                    //trivy image --exit-code 1 --severity HIGH,CRITICAL ${DOCKER_IMAGE}:${env.BUILD_ID}
                }
            }
        }
        stage('Deploy to Staging') {
            steps {
                script {
                    echo "Deploying app to EC2 at ${env.STG_EC2_IP}"

                    sshagent(['ec2-staging-key']) {
                        sh """
                            ssh -o StrictHostKeyChecking=no ubuntu@${env.STG_EC2_IP} '                             
                                docker pull ${env.AWS_ACCOUNT_ID}.dkr.ecr.ap-southeast-2.amazonaws.com/ctf-manager:${env.BUILD_ID}
                                docker run -d --name ctf-manager-${env.BUILD_ID} -p 8000:8000 ${env.AWS_ACCOUNT_ID}.dkr.ecr.ap-southeast-2.amazonaws.com/ctf-manager:${env.BUILD_ID}
                            '
                        """
                    }
                }
            }
        }
        stage('Deploy to Production') {
            steps {
                script {
                    echo "Deploying app to EC2 at ${env.PROD_EC2_IP}"
                    sh """
                        echo "AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID}" > .env
                        echo "BUILD_ID=${env.BUILD_ID}" >> .env
                        echo "DD_API_KEY=${DD_API_KEY}" >> .env
                    """
                    
                    sshagent(['ec2-staging-key']) {
                        sh """
                        scp -o StrictHostKeyChecking=no \
                        docker-compose.yml .env ubuntu@${env.PROD_EC2_IP}:/home/ubuntu/ctf-manager/

                        ssh -o StrictHostKeyChecking=no ubuntu@${env.PROD_EC2_IP} '
                            cd /home/ubuntu/ctf-manager &&
                            docker compose down &&
                            docker compose pull &&
                            docker compose up -d
                            '
                        """
                    }
                }
            }
        }
    }
}