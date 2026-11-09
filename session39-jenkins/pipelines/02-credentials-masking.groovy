// Uses the practice credential "demo-token" (fake value). Shows that masking only
// hides exact matches: the spaced version is NOT masked. Never do this with a real secret.
pipeline {
    agent any
    stages {
        stage('Masking test') {
            steps {
                withCredentials([string(credentialsId: 'demo-token', variable: 'TOKEN')]) {
                    sh 'echo "Plain: $TOKEN"'
                    sh 'echo "Token length: ${#TOKEN}"'
                    sh 'echo "Spaced: $(echo $TOKEN | sed "s/./& /g")"'
                }
            }
        }
    }
}
