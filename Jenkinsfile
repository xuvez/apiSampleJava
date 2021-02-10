/*
    Run a curl against a given url
 */
def curlRun (url) {
    script {
        echo "Getting HTTP response code on ${url}"
            def result = sh (
                returnStdout: true,
                script: "curl --output /dev/null --silent --connect-timeout 5 --max-time 5 --retry 5 --retry-delay 5 --retry-max-time 30 --write-out \"%{http_code}\" ${url}"
        )
        echo "Result (http_code): ${result}"
    }
}

pipeline {

    options {
        // Build auto timeout
        timeout(time: 60, unit: 'MINUTES')
    }


    triggers {
        // Poll every minute for commits
        pollSCM '* * * * *'
    }

    // Some global default variables
    environment {
        IMAGE_NAME = 'adidas'
        TEST_LOCAL_PORT = 8817

        GIT_URL = 'https://github.com/xuvez/apiSampleJava.git'

        DOCKER_REG = 'eu.gcr.io/bq-it-1358'

        URL_DEV = 'http://'
        URL_STA = ''
        URL_PROD = ''
    }

    parameters {
        string (name: 'GIT_BRANCH', defaultValue: 'testing',  description: 'Git branch to build')
    }

    agent any

    // Pipeline stages
    stages {

        stage('Git clone') {
            steps {
                echo "${GIT_URL} - ${GIT_BRANCH}"
                git branch: "${GIT_BRANCH}",
                        url: "${GIT_URL}"
            }
        }

        stage('Build and tests') {
            steps {
                echo "Building application and Docker image"
                sh "docker build -t ${DOCKER_REG}/${IMAGE_NAME}:${DOCKER_TAG} ."

                echo "Running tests"

                echo "Starting ${IMAGE_NAME} container"
                sh "docker run --detach --name ${ID} --rm --publish ${TEST_LOCAL_PORT}:80 ${DOCKER_REG}/${IMAGE_NAME}:${DOCKER_TAG}"

                script {
                    host_ip = sh(returnStdout: true, script: '/sbin/ip route | awk \'/default/ { print $3 ":${TEST_LOCAL_PORT}" }\'')
                }
            }
        }

        stage('Local tests') {
            steps {
                curlRun ("http://${host_ip}")
            }
        }

        stage('Publish Docker') {
            steps {
                echo "Stop and remove container"
                sh "docker stop ${ID}"

                echo "Pushing ${DOCKER_REG}/${IMAGE_NAME}:${DOCKER_TAG} image to registry"
                sh "${WORKSPACE}/build.sh --push --registry ${DOCKER_REG} --tag ${DOCKER_TAG} --docker_usr ${DOCKER_USR} --docker_psw ${DOCKER_PSW}"
            }
        }

        stage('Deploy to dev') {
            steps {
                script {
                    namespace = 'test-dev'


                }
            }
        }

        stage('Dev tests') {
            steps {
                curlTest (namespace)
            }
        }

        stage('Deploy to staging') {
            steps {
                script {
                    namespace = 'test-sta'

                    echo "Deploying application ${IMAGE_NAME}:${DOCKER_TAG} to ${namespace} namespace"

                }
            }
        }

        // Run the 3 tests on the deployed Kubernetes pod and service
        stage('Staging tests') {
            steps {
                curlTest (namespace)
            }
        }

        // Wait for user manual approval
        stage('Go for Production?') {
            when {
                environment name: 'GIT_BRANCH', value: 'master'
            }

            steps {
                // Prevent any older builds from deploying to production
                milestone(1)
                input 'Proceed and deploy to Production?'
                milestone(2)

                script {
                    DEPLOY_PROD = true
                }
            }
        }

        stage('Deploy to Production') {
            when {
                expression { DEPLOY_PROD == true }
            }

            steps {
                script {
                    DEPLOY_PROD = true
                    namespace = 'test-prod'

                    echo "Deploying application ${IMAGE_NAME}:${DOCKER_TAG} to ${namespace} namespace"
                }
            }
        }

        // Run the 3 tests on the deployed Kubernetes pod and service
        stage('Production tests') {
            when {
                expression { DEPLOY_PROD == true }
            }

            steps {
                curlTest (namespace)
            }
        }
    }
}