def curlUp (url) {
    script {
        echo "Waiting for response on ${url}"
        def result = sh (
            returnStatus: true,
            script: "curl --output /dev/null --silent --connect-timeout 5 --max-time 5 --retry 5 --retry-delay 5 --retry-max-time 30 --write-out \"%{http_code}\" ${url}"
        )
        echo "Result (return_code): ${result}"
        return (result == 0)
    }
}

def curlResponseCode (url) {
    script {
        echo "Getting HTTP response code on ${url}"
        def result = sh (
            returnStdout: true,
            script: "curl --output /dev/null --silent --connect-timeout 5 --max-time 5 --retry 5 --retry-delay 5 --retry-max-time 30 --write-out \"%{http_code}\" ${url}"
        )
        echo "Result (http_code): ${result}"
        if (result != 200) {
            error "Response Code is not 200"
        }
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
        CONTAINER_PORT = 8080
        TEST_PORT = 8081

        GIT_URL = 'https://github.com/xuvez/apiSampleJava.git'

        DOCKER_REG = 'eu.gcr.io/bq-it-1358'
        CONTAINER_NAME = 'adidas'

        URL_DEV = 'http://'
        URL_STA = ''
        URL_PROD = ''
    }

    parameters {
        string (name: 'GIT_BRANCH', defaultValue: 'origin/testing',  description: 'Git branch to build')
    }

    agent any

    // Pipeline stages
    stages {

        stage('Git clone') {
            steps {
                script {
                    // Remove "origin/" from branch
                    BRANCH = "${GIT_BRANCH}".split('/', 2)[1]
                }
                // git branch: "${GIT_BRANCH}",
                git branch: "${BRANCH}",
                        url: "${GIT_URL}"

                echo "Finished"
            }
        }

        stage('Build and tests') {
            steps {
                echo "Building application and Docker image"
                sh "docker build -t ${DOCKER_REG}/${IMAGE_NAME}:${BUILD_ID} ."

                echo "Running tests"

                // Delete previous running container
                sh "[ -z \"\$(docker ps -a | grep ${CONTAINER_NAME} 2>/dev/null)\" ] || docker rm -f ${CONTAINER_NAME}"

                echo "Starting ${IMAGE_NAME} container"
                sh "docker run --detach --name ${CONTAINER_NAME} --rm --publish ${TEST_PORT}:${CONTAINER_PORT} ${DOCKER_REG}/${IMAGE_NAME}:${BUILD_ID}"

                script {
                    // host_ip = sh(returnStdout: true, script: '/sbin/ip route | awk \'/default/ { print $3 ":${TEST_PORT}" }\'')
                    host_ip = "localhost:${TEST_PORT}"
                }
            }
        }

        stage('Local tests') {

            steps {
                timeout(time: 1, unit: 'MINUTES') {
                    waitUntil {
                        curlUp ("http://${host_ip}")
                    }
                }

                curlResponseCode("http://${host_ip}")
            }
        }

        stage('Publish Docker') {
            steps {
                echo "Stop and remove container"
                sh "docker stop ${CONTAINER_NAME}"

                echo "Pushing ${DOCKER_REG}/${IMAGE_NAME}:${BUILD_ID} image to registry"
                sh "${WORKSPACE}/build.sh --push --registry ${DOCKER_REG} --tag ${BUILD_ID} --docker_usr ${DOCKER_USR} --docker_psw ${DOCKER_PSW}"
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
