/**
 * This pipeline will build and deploy a Docker image with Kaniko
 * https://github.com/GoogleContainerTools/kaniko
 * without needing a Docker host
 *
 * You need to create a jenkins-docker-cfg secret with your docker config
 * as described in
 * https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/#create-a-secret-in-the-cluster-that-holds-your-authorization-token
 */

def label = "kaniko-${UUID.randomUUID().toString()}"

podTemplate(name: 'kaniko', label: label, yaml: """
kind: Pod
metadata:
  name: kaniko
spec:
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    imagePullPolicy: Always
    command:
    - /busybox/cat
    tty: true
    volumeMounts:
      - name: kaniko-secret
        mountPath: /secret
    env:
      - name: GOOGLE_APPLICATION_CREDENTIALS
        value: /secret/enginneringday-2bc3ba3b65ba.json   
  volumes:
    - name: kaniko-secret
      secret:
        secretName: kaniko-secret        
   
"""
  ) {

  node(label) {
    stage('Build with Kaniko') {
      checkout scm
      container(name: 'kaniko', shell: '/busybox/sh') {
        withEnv(['PATH+EXTRA=/busybox:/kaniko/']) {
            withCredentials([usernamePassword(credentialsId: '90fca861-088a-4043-a43b-acb4d97ea826', passwordVariable: 'password', usernameVariable: 'username')]) {
    // some block

          sh '''#!/busybox/sh
          export PATH=$PATH:/kaniko/dockder-credential-gcr
          /kaniko/executor -f `pwd`/Dockerfile -c `pwd`  --destination=eu.gcr.io/enginneringday/apisample:latest
          '''
            }
        }
      }
    }
  }
}
