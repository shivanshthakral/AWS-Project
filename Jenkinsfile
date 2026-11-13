pipeline {
    agent any
    options {
        timestamps()
        skipDefaultCheckout(true)
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 60, unit: 'MINUTES')
    }
    parameters {
        booleanParam(name: 'DEPLOY_AWS', defaultValue: true, description: 'Provision AWS resources and deploy the application (incurs AWS charges).')
    }
    triggers { githubPush() }
    stages {
        stage('Load source') {
            steps {
                script {
                    if (fileExists('/run/project/github-repository-url')) {
                        checkout scm
                    } else {
                        sh '''
                    rsync -a --delete --exclude=.runtime --exclude=.env --exclude=.git \
                      --exclude=.terraform --exclude=.venv --exclude=__pycache__ \
                      --exclude=.pytest_cache --exclude=tfplan --exclude=terraform.tfstate* \
                      /workspace-source/ ./
                '''
                    }
                }
            }
        }
        stage('Test') {
            steps {
                sh 'python3 -m venv .venv'
                retry(3) {
                    sh '.venv/bin/pip install --retries 8 --timeout 60 -r backend/requirements.txt'
                }
                sh '.venv/bin/pytest backend/tests -v --junitxml=test-results.xml'
            }
            post { always { junit allowEmptyResults: true, testResults: 'test-results.xml' } }
        }
        stage('Terraform validate') {
            steps {
                sh '''
                    terraform -chdir=terraform init -backend=false -input=false
                    terraform -chdir=terraform validate
                '''
            }
        }
        stage('Terraform plan') {
            when { expression { params.DEPLOY_AWS } }
            steps {
                sh '''
                    set +x
                    . /run/project/cloud.env
                    terraform -chdir=terraform init -reconfigure -input=false -backend-config=/run/project/backend.tfbackend
                    SSH_IP=$(curl --fail --silent --retry 3 https://checkip.amazonaws.com | tr -d '\\r\\n')
                    terraform -chdir=terraform plan -input=false -var-file=/run/project/deploy.tfvars.json "-var=ssh_allowed_cidr=$SSH_IP/32" -out=tfplan
                '''
            }
        }
        stage('Terraform apply') {
            when { expression { params.DEPLOY_AWS } }
            steps { sh 'terraform -chdir=terraform apply -input=false -auto-approve tfplan' }
        }
        stage('Ansible deploy') {
            when { expression { params.DEPLOY_AWS } }
            steps {
                sh '''
                    set +x
                    . /run/project/cloud.env
                    mkdir -p .deployment
                    tar --exclude=__pycache__ --exclude=.pytest_cache --exclude=.env -czf .deployment/application.tar.gz backend frontend
                    terraform -chdir=terraform output -json > .deployment/outputs.json
                    .venv/bin/python tools/deploy_config.py .deployment/outputs.json /run/project .deployment
                    install -m 600 /run/project/deploy-key .deployment/deploy-key
                    export ANSIBLE_CONFIG="$WORKSPACE/ansible/ansible.cfg"
                    ansible-playbook -i .deployment/hosts.ini ansible/site.yml \
                      --private-key .deployment/deploy-key \
                      -e deployment_vars_file="$WORKSPACE/.deployment/vars.json"
                '''
            }
        }
        stage('Verify AWS application') {
            when { expression { params.DEPLOY_AWS } }
            steps {
                sh '''
                    APP_URL=$(terraform -chdir=terraform output -raw app_url)
                    curl --fail --retry 30 --retry-delay 10 --retry-all-errors "$APP_URL/"
                    printf '\\nApplication URL: %s\\n' "$APP_URL"
                '''
            }
        }
    }
    post {
        always { sh 'rm -f .deployment/vars.json .deployment/deploy-key .deployment/application.tar.gz terraform/tfplan' }
    }
}
