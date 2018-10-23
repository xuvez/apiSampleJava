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
   
"""
  ) {

  node(label) {
    stage('Build with Kaniko') {
      checkout scm
      container(name: 'kaniko', shell: '/busybox/sh') {
        withEnv(['PATH+EXTRA=/busybox']) {
            withCredentials([usernamePassword(credentialsId: '90fca861-088a-4043-a43b-acb4d97ea826', passwordVariable: 'password', usernameVariable: 'username')]) {
    // some block

          sh '''#!/busybox/sh
          /kaniko/executor -f `pwd`/Dockerfile -c `pwd`  --no-push
          '''
            }
        }
      }
    }
  }
}
}
