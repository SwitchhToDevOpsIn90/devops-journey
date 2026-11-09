// Runs only on an agent labelled docker-agent. Changing the label to one no agent has
// (e.g. 'windows') leaves the build waiting in the queue.
pipeline {
    agent { label 'docker-agent' }
    stages {
        stage('Where am I?') {
            steps {
                sh 'hostname'
                sh 'pwd'
                sh 'whoami'
            }
        }
    }
}
