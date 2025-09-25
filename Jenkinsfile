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

    }
}