# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
Ansible roles collection for automating development environment setup across Ubuntu, macOS, and Debian. Contains ~78 roles for installing/configuring dev tools, languages, and applications.

## Common Commands

### Setup
- `poetry install --sync` — install Python dependencies
- `ansible-galaxy install -r requirements.yml` — install Ansible collections
- `poetry shell` — enter virtual environment

### Running Playbooks
- `poetry run ansible-playbook -i inventories/workstation playbook-workstation.yml` (copy `inventories/workstation.example` to `inventories/workstation` first; real inventories are git-ignored)
- Run specific roles: `--tags git,shell`
- Dry run: `--check`

### Linting
- **IMPORTANT**: Always run `poetry run ansible-lint` on modified roles before committing
- Lint specific role: `poetry run ansible-lint roles/ROLE_NAME/tasks/main.yml`
- Syntax check: `ansible-playbook --syntax-check playbook-workstation.yml`
- CI runs ansible-lint on the whole repository (playbooks and roles) via GitHub Actions on every PR and fails on any violation

### Testing (Molecule)
Molecule runs roles/playbooks in an Ubuntu 24.04 container (requires Docker). Shared settings live in `.config/molecule/config.yml`; install collections first with `ansible-galaxy collection install -r requirements.yml`.
- Role test: `MOLECULE_TARGET_ROLE=git poetry run molecule test -s role` — CI runs it on PRs for changed roles listed in `molecule/role/targets.txt`
- Playbook E2E: `poetry run molecule test -s desktop` (or `-s devel`) — CI runs it on pushes to main and manually via workflow_dispatch. Comment `/e2e` on a PR (OWNER/MEMBER/COLLABORATOR only, branches of this repository only) to dispatch it on the PR branch; the comment gets a :+1: reaction and the result is posted as a PR comment
- Scenarios are split by host group combination, not by playbook; both `desktop` and `devel` run `playbook-workstation.yml`
- `molecule/desktop` puts the container in `desktop` and skips roles that cannot run in a container (`homenas_client`, `fluentd`, `dropbox`)
- `molecule/devel` puts the container in `devel`, `webapp`, `devos`, `terraform` and skips `docker` (needs Docker in Docker) and `ansible` (ansible-language-server needs a newer node than nodenv provides)

## Architecture

### Playbooks
- `playbook-workstation.yml` — Workstations: desktops and development servers. Purpose is expressed by inventory groups (`desktop`, `devel` with children `webapp` / `devos` / `terraform`)

Roles are assigned in playbooks with: `{ role: NAME, tags: TAG, VAR: VALUE }`

### Playbooks vs. host groups
Design is documented in `docs/inventory.md`. Key rules:
- Playbook = kind of environment; host group = purpose within a playbook; OS differences are handled inside roles, not by groups
- Split into a new playbook only when a host could not belong to both (conflicting role parameters, different baseline, cross-host ordering such as a future k8s playbook)
- Control groups only via play `hosts:`; never put `group_names` checks in `when`
- Each role appears in exactly one play of a playbook; roles shared by several groups go in a play targeting a union pattern (e.g. `desktop:devel`, `webapp:terraform`)

### Custom Filter Plugin
`filter_plugins/shell_config.py` provides the `shell_config` filter. Usage:
```yaml
- ansible.builtin.set_fact:
    shell_info: "{{ ansible_facts.user_shell | shell_config }}"
# Returns: { name: 'bash', rc_file: '.bashrc', profile_path: '.bash_profile' }
# Or for zsh: { name: 'zsh', rc_file: '.zshrc', profile_path: '.zprofile' }
```

## Coding Conventions

### Module Names
Always use fully qualified collection names (FQCN): `ansible.builtin.command`, `ansible.builtin.apt`, etc.

### Variable Naming
- `UPPER_SNAKE_CASE` with role name as prefix: `GOLANG_VERSION`, `DOCKER_USER`, `GIT_INSTALLER`
- Lint enforces: `^[a-z_][a-z0-9_]*$|[A-Z][A-Z0-9_]*$`

### OS-Specific Task Dispatch
Roles split OS-specific logic into separate files dispatched from `tasks/main.yml`:
```yaml
- ansible.builtin.include_tasks: install_{{ ansible_facts.distribution }}.yml
```
File naming: `install_Ubuntu.yml`, `install_MacOSX.yml` (or `install_MacOS.yml`), `install_Debian.yml`

### Install-Check Pattern
Check if a tool is installed before running install tasks:
```yaml
- name: Check if TOOL installed
  ansible.builtin.command: which TOOL
  register: status_tool
  changed_when: false
  failed_when: false

- name: Install TOOL
  ansible.builtin.include_tasks: install_{{ ansible_facts.distribution }}.yml
  when: status_tool.rc != 0
```

### Version Comparison Pattern
For roles that manage tool versions (golang, nodejs, terraform, etc.):
```yaml
- name: Check installed version
  ansible.builtin.shell: /bin/bash -lc 'TOOL --version'
  changed_when: false
  failed_when: false
  register: version_check
  when: status_tool.rc == 0

- name: Install TOOL
  ansible.builtin.include_tasks: install_{{ ansible_facts.distribution }}.yml
  when: status_tool.rc != 0 or
        version_check.stdout is version(TOOL_VERSION, '<')
```

### Privileged Tasks
Use `become: yes` on tasks requiring root (package installs, system config). Do not set `become` at play level.

### Lint Exceptions
When `shell` is required instead of `command` (e.g., for PATH-aware login shell execution), use inline noqa:
```yaml
# noqa: command-instead-of-shell
```

## Lint Configuration
- `.ansible-lint`: skips multiple legacy rules (see file), excludes `roles/*/files/*`
- `.yamllint`: line length max 160, truthy values `["true", "false", "yes", "no"]`

## Python Environment
- Poetry for dependency management
- Python 3.12+ (< 3.14), ansible-core ~2.20.0
- Required collections: `community.general` 10.0.0, `ansible.posix` 2.0.0
