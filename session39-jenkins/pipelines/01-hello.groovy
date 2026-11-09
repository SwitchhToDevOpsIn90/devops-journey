pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                echo 'Building DockerApp...'
                sh 'uname -a'
            }
        }
        stage('Test') {
            steps {
                echo 'Running tests...'
                sh 'echo "2 + 2 = $((2 + 2))"'
            }
        }
        stage('Package') {
            steps {
                echo 'Packaging...'
                sh 'date'
            }
        }
    }
}
