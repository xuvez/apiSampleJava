node('incubation'){
    checkout scm
    container('kaniko') {
        sh 'executor --no-push -f ./Dockerfile --context=dir://.'
    }
}
