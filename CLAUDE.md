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
- `poetry run ansible-playbook -i inventories/localhost playbook-desktop.yml`
- Run specific roles: `--tags git,shell`
- Dry run: `--check`

### Linting
- **IMPORTANT**: Always run `poetry run ansible-lint` on modified roles before committing
- Lint specific role: `poetry run ansible-lint roles/ROLE_NAME/tasks/main.yml`
- Syntax check: `ansible-playbook --syntax-check playbook-desktop.yml`
- CI runs ansible-lint on `roles/` via GitHub Actions on every PR

## Architecture

### Playbooks
- `playbook-desktop.yml` — Desktop environment (GUI apps, personal tools)
- `playbook-devel.yml` — Development environment (multi-play, uses host groups: `all`, `webapp`, `devos`, `terraform`)
- `playbook-docker-service.yml` — Docker-based services
- `playbook-gitlab.yml` — GitLab server configuration

Roles are assigned in playbooks with: `{ role: NAME, tags: TAG, VAR: VALUE }`

### Custom Filter Plugin
`filter_plugins/shell_config.py` provides the `shell_config` filter. Usage:
```yaml
- ansible.builtin.set_fact:
    shell_info: "{{ ansible_user_shell | shell_config }}"
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
- ansible.builtin.include_tasks: install_{{ ansible_distribution }}.yml
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
  ansible.builtin.include_tasks: install_{{ ansible_distribution }}.yml
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
  ansible.builtin.include_tasks: install_{{ ansible_distribution }}.yml
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
- `.ansible-lint`: skips `git-latest` rule, excludes `roles/*/files/*`
- `.yamllint`: line length max 160, truthy values `["true", "false", "yes", "no"]`

## Python Environment
- Poetry for dependency management
- Python 3.9+ (< 3.12), ansible-core ^2.15.13
- Required collections: `community.general` 7.4.0, `ansible.posix` 1.5.2
