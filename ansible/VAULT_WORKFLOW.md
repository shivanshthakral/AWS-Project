# Ansible Vault Workflow

## 1. Prepare the plaintext secrets file

Edit `ansible/vault.yml` with your real values:

- `flask_secret_key`
- `database_url`
- `repo_url`
- `cloudwatch_log_group`

## 2. Encrypt the secrets file

Run from project root:

```bash
ansible-vault encrypt ansible/vault.yml
```

## 3. Edit encrypted secrets later

```bash
ansible-vault edit ansible/vault.yml
```

## 4. Decrypt only when absolutely necessary

```bash
ansible-vault decrypt ansible/vault.yml
```

## 5. Re-encrypt after changes

```bash
ansible-vault encrypt ansible/vault.yml
```

## 6. Local deploy using vault prompt

```bash
ansible-playbook -i ansible/inventory/hosts.ini ansible/site.yml --ask-vault-pass
```

## 7. Jenkins integration (vault password as Secret File)

1. In Jenkins, add credential:
   - Kind: `Secret file`
   - ID: `ansible-vault-password`
   - File content: a single-line file containing your vault password
2. Pipeline uses this credential as a temporary file path and runs:

```bash
ansible-playbook -i ansible/inventory/hosts.ini ansible/site.yml --vault-password-file "$VAULT_FILE"
```

## 8. Rotate vault password (recommended periodically)

```bash
ansible-vault rekey ansible/vault.yml
```
