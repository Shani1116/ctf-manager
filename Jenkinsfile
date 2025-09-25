pipeline {
    agent any
    environment {
        DOCKER_IMAGE = "ctf-manager"
        SCANNER_HOME = tool 'SonarScanner'
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
        // stage('Test') {
        //     steps {
        //         script {
        //             docker.image("${DOCKER_IMAGE}:${env.BUILD_ID}").inside {
        //             // Ensure the environment is set up correctly
        //             sh 'cp .env.example .env'

        //             //Set application encryption key
        //             sh 'php artisan key:generate --force'
            
        //             // Run tests with the correct PHPUnit version
        //             sh './vendor/bin/phpunit --configuration phpunit.xml'
        //             }
        //         }
        //     }
        // }
        // stage('Code Quality') {
        //     steps {
        //         withSonarQubeEnv('Sonarcloud') {
        //             script {
        //                 sh """
        //                     ${SCANNER_HOME}/bin/sonar-scanner \
        //                     -Dsonar.projectKey=Shani1116_ctf-manager \
        //                     -Dsonar.organization=shani1116 \
        //                     -Dsonar.sources=. \
        //                     -Dsonar.host.url=https://sonarcloud.io
        //                 """
        //             }  
        //         }
        //     }
        // }
        // stage('Security') {
        //     steps {
        //         script {
        //             docker.image("${DOCKER_IMAGE}:${env.BUILD_ID}").inside {
        //                 // Run security analysis with the correct PHPStan version
        //                 sh 'composer --version'
        //                 sh 'composer audit || true'
        //             }

        //             //Run Trivy scan
        //             sh """
        //                 trivy image --exit-code 0 --severity LOW,MEDIUM,HIGH,CRITICAL ${DOCKER_IMAGE}:${env.BUILD_ID}
        //             """
        //         }
        //     }
        // }
        stage('Provision Staging Server') {
            steps {
                script {
                    dir('terraform') {
                        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws_creds']]) {
                            sh 'terraform init -input=false'
                            sh 'terraform plan -out=tfplan -input=false > plan.txt'
                        }
                    }
                    archiveArtifacts artifacts: 'terraform/plan.txt', allowEmptyArchive: true
                }
            }
        }
        stage('Approve Terraform Apply') {
            steps {
                input message: 'Review the Terraform plan and approve to apply?', ok: 'Apply'
            }
        }
        stage('Apply Terraform') {
            steps {
                script {
                    dir('terraform') {
                        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws_creds']]) {
                            sh 'terraform apply -input=false tfplan'
                        }
                    }
                }
            }
        }

        stage('Deploy to Staging') {
            steps {
                script {
                    def EC2_IP = sh(script: "cd terraform && terraform output -raw staging_public_ip", returnStdout: true).trim()
                    echo "Deploying app to EC2 at ${EC2_IP}"

                    sshagent(['ec2-staging-key']) {
                        sh """
                            ssh -o StrictHostKeyChecking=no ubuntu@${EC2_IP} '
                                docker rm -f ctf-manager-staging || true &&
                                docker pull <dockerhub-username>/ctf-manager:latest &&
                                docker run -d --name ctf-manager-staging -p 8000:8000 <dockerhub-username>/ctf-manager:latest
                            '
                        """
                    }
                }
            }
        }
    }
}