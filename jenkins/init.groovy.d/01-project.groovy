import jenkins.model.Jenkins
import hudson.security.HudsonPrivateSecurityRealm
import hudson.security.FullControlOnceLoggedInAuthorizationStrategy
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition
import hudson.model.ParametersDefinitionProperty
import hudson.model.BooleanParameterDefinition
import hudson.plugins.git.GitSCM
import hudson.plugins.git.UserRemoteConfig
import hudson.plugins.git.BranchSpec
import org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition
import com.cloudbees.plugins.credentials.SystemCredentialsProvider
import com.cloudbees.plugins.credentials.CredentialsScope
import com.cloudbees.plugins.credentials.domains.Domain
import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl
import com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl
import hudson.util.Secret
import org.jenkinsci.plugins.github.config.GitHubPluginConfig
import org.jenkinsci.plugins.github.config.HookSecretConfig
import com.cloudbees.jenkins.GitHubPushTrigger

def instance = Jenkins.get()
def realm = new HudsonPrivateSecurityRealm(false)
def username = System.getenv('JENKINS_ADMIN_ID') ?: 'admin'
def password = new File('/run/secrets/jenkins_admin_password').text.trim()
realm.createAccount(username, password)
instance.setSecurityRealm(realm)
def authorization = new FullControlOnceLoggedInAuthorizationStrategy()
authorization.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(authorization)
instance.setNumExecutors(2)
def job = instance.getItem('infra-monitor') ?: instance.createProject(WorkflowJob, 'infra-monitor')
job.setDefinition(new CpsFlowDefinition(new File('/workspace-source/Jenkinsfile').text, true))
def repositoryFile = new File('/run/project/github-repository-url')
if (repositoryFile.exists()) {
    def store = SystemCredentialsProvider.getInstance().getStore()
    def saveCredential = { credential ->
        def old = store.getCredentials(Domain.global()).find { it.id == credential.id }
        if (old != null) { store.updateCredentials(Domain.global(), old, credential) }
        else { store.addCredentials(Domain.global(), credential) }
    }
    def tokenFile = new File('/run/project/github-token')
    if (tokenFile.exists()) {
        saveCredential(new UsernamePasswordCredentialsImpl(CredentialsScope.GLOBAL, 'github-repository', 'GitHub repository checkout', 'x-access-token', tokenFile.text.trim()))
    }
    def secretFile = new File('/run/project/webhook-secret')
    if (secretFile.exists()) {
        saveCredential(new StringCredentialsImpl(CredentialsScope.GLOBAL, 'github-webhook-secret', 'GitHub webhook HMAC secret', Secret.fromString(secretFile.text.trim())))
        def githubConfig = jenkins.model.GlobalConfiguration.all().get(GitHubPluginConfig.class)
        githubConfig.setHookSecretConfigs([new HookSecretConfig('github-webhook-secret', 'SHA256')])
        githubConfig.save()
    }
    def scm = new GitSCM([new UserRemoteConfig(repositoryFile.text.trim(), null, null, tokenFile.exists() ? 'github-repository' : null)], [new BranchSpec('*/main')], false, [], null, null, [])
    job.setDefinition(new CpsScmFlowDefinition(scm, 'Jenkinsfile'))
    job.addTrigger(new GitHubPushTrigger())
}
job.addProperty(new ParametersDefinitionProperty(new BooleanParameterDefinition('DEPLOY_AWS', repositoryFile.exists(), 'Provision AWS resources and deploy the application (incurs AWS charges).')))
job.setDescription('Tests this local source snapshot and optionally deploys it to AWS using Terraform and Ansible.')
job.save()
instance.save()
