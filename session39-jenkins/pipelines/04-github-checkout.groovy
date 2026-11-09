pipeline {
    agent { label 'docker-agent' }
    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/SwitchhToDevOpsIn90/devops-journey.git', branch: 'main'
            }
        }
        stage('Inspect') {
            steps {
                sh 'git log --oneline -3'
                sh 'ls'
                sh 'ls session38-helm-advanced'
            }
        }
    }
}
