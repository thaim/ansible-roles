# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

This file describes only stable conventions. Facts that change with routine work (role/playbook lists, versions, CI/Molecule details, lint rule lists) and anything derivable from the files themselves are intentionally left out — read the referenced files instead. Do not update this file as part of ordinary role, playbook, CI, or dependency changes.

## Project Overview
Ansible roles collection for automating development environment setup on Ubuntu, macOS, and Debian. Roles live in `roles/`, and playbooks (`playbook-*.yml`) at the repository root assign them to hosts.

## Work Rules
- **Always run `poetry run ansible-lint` on modified files before committing**; CI fails on any violation
- Commands (setup, playbook runs, lint, Molecule tests): see `README.md`

Sources of truth:
- Dependencies/versions: `pyproject.toml`, `requirements.yml`
- Lint settings: `.ansible-lint`, `.yamllint`
- Molecule scenarios and skipped roles (with reasons): `molecule/*/molecule.yml`, `.config/molecule/config.yml`
- CI behavior: `.github/workflows/`

## Architecture
- Roles are assigned in playbooks with: `{ role: NAME, tags: TAG, VAR: VALUE }`
- Playbooks vs. host groups: design is in `docs/inventory.md`. Key rules:
  - Playbook = kind of environment; host group = purpose within a playbook; OS differences are handled inside roles, not by groups
  - Split into a new playbook only when a host could not belong to both (conflicting role parameters, different baseline, cross-host ordering)
  - Control groups only via play `hosts:`; never put `group_names` checks in `when`
  - Each role appears in exactly one play of a playbook; roles shared by several groups go in a play targeting a union pattern (e.g. `hosts: webapp:terraform`)
- `filter_plugins/shell_config.py` provides the `shell_config` filter, which maps the user's shell to its rc/profile file names:
  ```yaml
  - ansible.builtin.set_fact:
      shell_info: "{{ ansible_facts.user_shell | shell_config }}"
  # => { name: 'bash', rc_file: '.bashrc', profile_path: '.bash_profile' }
  ```

## Coding Conventions

### Module Names
Always use fully qualified collection names (FQCN): `ansible.builtin.command`, `ansible.builtin.apt`, etc.

### Variable Naming
`UPPER_SNAKE_CASE` with the role name as prefix: `GOLANG_VERSION`, `DOCKER_USER`, `GIT_INSTALLER`

### OS-Specific Task Dispatch
Split OS-specific logic into separate files dispatched from `tasks/main.yml`:
```yaml
- ansible.builtin.include_tasks: install_{{ ansible_facts.distribution }}.yml
```
File naming: `install_Ubuntu.yml`, `install_MacOSX.yml`, `install_Debian.yml`

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
For roles that manage tool versions:
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
