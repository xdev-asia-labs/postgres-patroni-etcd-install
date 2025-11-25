# GitHub Actions Workflows

This directory contains CI/CD workflows for the PostgreSQL HA cluster project.

## Available Workflows

### 1. Ansible Lint (`ansible-lint.yml`)

**Triggers**: Push/PR to main or develop branch

**Purpose**: Validates Ansible playbooks and roles for best practices and syntax errors.

**Jobs**:
- Install Ansible and ansible-lint
- Run ansible-lint on playbooks and roles
- Check Ansible syntax for all playbooks

**Badge**: [![Ansible Lint](https://github.com/xdev-asia-labs/postgres-patroni-etcd-install/actions/workflows/ansible-lint.yml/badge.svg)](https://github.com/xdev-asia-labs/postgres-patroni-etcd-install/actions/workflows/ansible-lint.yml)

---

### 2. CI Pipeline (`ci.yml`)
**Triggers**: Push/PR to main or develop branch

**Purpose**: Comprehensive validation of configuration files and security scanning.

**Jobs**:
- **Validate Configuration**:
  - YAML validation for inventory, playbooks, and roles
  - Inventory structure validation
  - Playbook syntax checking
  - Role structure verification

- **Security Scan**:
  - Trivy vulnerability scanner for infrastructure-as-code
  - TruffleHog for secret detection in code

**Badge**: [![CI Pipeline](https://github.com/xdev-asia-labs/postgres-patroni-etcd-install/actions/workflows/ci.yml/badge.svg)](https://github.com/xdev-asia-labs/postgres-patroni-etcd-install/actions/workflows/ci.yml)

---

### 3. Documentation Check (`docs-check.yml`)
**Triggers**: Push/PR to main or develop branch (only when .md or .env.example files change)

**Purpose**: Ensures documentation quality and configuration completeness.

**Jobs**:
- **Markdown Lint**: Validates Markdown formatting
- **Link Check**: Verifies all links in documentation
- **ENV Check**: Validates .env.example structure and required variables

**Badge**: [![Documentation](https://github.com/xdev-asia-labs/postgres-patroni-etcd-install/actions/workflows/docs-check.yml/badge.svg)](https://github.com/xdev-asia-labs/postgres-patroni-etcd-install/actions/workflows/docs-check.yml)

---

### 4. Security Scan (`security.yml`)

**Triggers**: Push/PR to main or develop branch, Weekly schedule (Monday 00:00 UTC), Manual dispatch

**Purpose**: Comprehensive security scanning for vulnerabilities, secrets, and security best practices.

**Jobs**:
- **Secret Detection**: TruffleHog and Gitleaks for hardcoded secrets
- **Dependency Scan**: Safety and pip-audit for vulnerable dependencies
- **Infrastructure Scan**: Trivy and Checkov for IaC security issues
- **Ansible Security**: Check for hardcoded passwords, sudo usage, SSH keys
- **SAST Scan**: Semgrep for static code analysis
- **Security Summary**: Consolidated security recommendations

**Badge**: [![Security Scan](https://github.com/xdev-asia-labs/postgres-patroni-etcd-install/actions/workflows/security.yml/badge.svg)](https://github.com/xdev-asia-labs/postgres-patroni-etcd-install/actions/workflows/security.yml)

---

### 5. Release (`release.yml`)

**Triggers**: Git tags (v*.*.*), Manual dispatch with version input

**Purpose**: Automated release creation with changelog generation and artifact packaging.

**Jobs**:
- **Create Release**: 
  - Generate changelog from git history
  - Create release archive (tar.gz)
  - Upload release assets (archive, README, LICENSE)
  - Publish GitHub release
  
- **Validate Release**:
  - Validate Ansible playbooks
  - Check required files
  - Ensure release integrity

**Badge**: [![Release](https://github.com/xdev-asia-labs/postgres-patroni-etcd-install/actions/workflows/release.yml/badge.svg)](https://github.com/xdev-asia-labs/postgres-patroni-etcd-install/actions/workflows/release.yml)

**Creating a Release**:
```bash
# Via Git tag
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0

# Or trigger manually from GitHub Actions UI
# Go to Actions → Release → Run workflow → Enter version
```

---

## Workflow Status

All workflows are configured to run automatically on push and pull request events. You can view the status of each workflow in the Actions tab of the repository or via the badges in the main README.

## Configuration Files

Supporting configuration files for workflows:

- `.markdownlint.json` - Markdown linting rules
- `.markdown-link-check.json` - Link checker configuration

## Adding New Workflows

To add a new workflow:

1. Create a new YAML file in `.github/workflows/`
2. Define triggers, jobs, and steps
3. Test the workflow by pushing to a branch
4. Add workflow badge to README files if needed

## Workflow Badges

All workflow badges are displayed at the top of README.md and README-vi.md files. They provide real-time status of the CI/CD pipelines.

## Local Testing

Before pushing, you can test workflows locally using:

```bash
# Install act (GitHub Actions local runner)
brew install act  # macOS
# or
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash  # Linux

# Run workflows locally
act push
act pull_request
```

## Troubleshooting

If a workflow fails:

1. Check the workflow logs in the Actions tab
2. Review the specific job that failed
3. Fix the issue locally and test
4. Push the fix and verify the workflow passes

## Further Reading

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Ansible Lint Documentation](https://ansible-lint.readthedocs.io/)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [TruffleHog Documentation](https://github.com/trufflesecurity/trufflehog)
