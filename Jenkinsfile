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
        if (result != '200' ) {
            error "Response Code is not 200"
        }
    }
}

def deployEnvironment(namespace, deployment_name, container_name, image) {
    echo "Deploying application ${image} to ${namespace} namespace"
    sh script: "kubectl --namespace=${namespace} set image deployment/${deployment_name} ${container_name}=${image}"

    // Wait until deployed or timeout
    timeout(time: 1, unit: 'MINUTES') {
        sh script: "kubectl --namespace=${namespace} rollout status deployment ${deployment_name}"
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

    // Some global default variabless
    environment {
        IMAGE_NAME = 'test'
        CONTAINER_PORT = 8080
        TEST_PORT = 8081

        GIT_URL = 'https://github.com/xuvez/apiSampleJava.git'

        DOCKER_REG = 'eu.gcr.io/bq-it-1358'
        CONTAINER_NAME = 'test'
        DEPLOYMENT_NAME = 'test'

        URL_DEV  = 'http://dev.test'
        URL_STA  = 'http://sta.test'
        URL_PROD = 'http://prod.test'

        NAMESPACE_DEV  = 'test-dev'
        NAMESPACE_STA  = 'test-sta'
        NAMESPACE_PROD = 'test-prod'

        DEPLOY_PROD = false
    }

    parameters {
        string (name: 'GIT_BRANCH', defaultValue: 'origin/master',  description: 'Git branch to build')
    }

    agent any

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
                script {
                    IMAGE = "${DOCKER_REG}/${IMAGE_NAME}:${BUILD_ID}"
                }
                echo "Building application and Docker image"
                sh "docker build -t ${IMAGE} ."

                echo "Running tests"

                // Delete previous running container
                sh "[ -z \"\$(docker ps -a | grep ${CONTAINER_NAME} 2>/dev/null)\" ] || docker rm -f ${CONTAINER_NAME}"

                echo "Starting ${IMAGE_NAME} container"
                sh "docker run --detach --name ${CONTAINER_NAME} --rm --publish ${TEST_PORT}:${CONTAINER_PORT} ${IMAGE}"
            }
        }

        stage('Local tests') {

            steps {
                timeout(time: 1, unit: 'MINUTES') {
                    waitUntil {
                        curlUp ("localhost:${TEST_PORT}")
                    }
                }

                curlResponseCode("localhost:${TEST_PORT}")
            }
        }

        stage('Publish Docker') {
            steps {
                echo "Stop and remove container"
                sh "docker stop ${CONTAINER_NAME}"

                echo "Pushing ${IMAGE} image to registry"
                sh "docker push ${IMAGE}"
            }
        }

        stage('Deploy to dev') {
            steps {
                deployEnvironment(NAMESPACE_DEV, DEPLOYMENT_NAME, CONTAINER_NAME, IMAGE)
            }
        }

        stage('Dev tests') {
            steps {
                curlResponseCode(URL_DEV)
            }
        }

        stage('Deploy to staging') {
            steps {
                deployEnvironment(NAMESPACE_STA, DEPLOYMENT_NAME, CONTAINER_NAME, IMAGE)
            }
        }

        stage('Staging tests') {
            steps {
                curlResponseCode(URL_STA)
            }
        }

        // Wait for user manual approval
        stage('Go for Production?') {
            when {
                expression { BRANCH == 'master' }
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
                deployEnvironment(NAMESPACE_PROD, DEPLOYMENT_NAME, CONTAINER_NAME, IMAGE)
            }
        }

        stage('Production tests') {
            when {
                expression { DEPLOY_PROD == true }
            }

            steps {
                curlResponseCode(URL_PROD)
            }
        }
    }
}
