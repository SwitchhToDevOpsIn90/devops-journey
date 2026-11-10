// Polls GitHub every minute and builds when the branch changes.
// Used because Jenkins is bound to 127.0.0.1, so GitHub webhooks cannot reach it.
// In real setups prefer H/5 * * * * so many jobs do not poll at the same second.
pipeline {
    agent { label 'docker-agent' }
    triggers {
        pollSCM('* * * * *')
    }
    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/SwitchhToDevOpsIn90/devops-journey.git', branch: 'jenkins-poll-test'
            }
        }
        stage('Show latest commit') {
            steps {
                sh 'git log --oneline -1'
            }
        }
    }
}
