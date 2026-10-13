# ansible
[![Molecule E2E](https://github.com/thaim/ansible-roles/actions/workflows/molecule-e2e.yml/badge.svg?branch=main)](https://github.com/thaim/ansible-roles/actions/workflows/molecule-e2e.yml?query=branch%3Amain)

My ansible playbooks

## setup python environment
- install dependencies
  - Ubuntu: `sudo apt install build-essential libssl-dev libffi-dev libbz2-dev libncurses-dev libsqlite3-dev python3-tk liblzma-dev`
- [install poetry](https://python-poetry.org/docs/)
- run `poetry install --sync` to ansible and related dev dependencies

Then, run `poetry shell` for interactive environment or run `poetry run ansible-playbook ...` for executing command.

## required modules
Run `ansible-galaxy install -r requirements.yml` to install modules.

## run playbook
Copy `inventories/workstation.example` to `inventories/workstation` and assign hosts to groups, then run:

```sh
poetry run ansible-playbook -i inventories/workstation playbook-workstation.yml
```

Options: `--tags git,shell` to run specific roles, `--limit webapp` to limit hosts, `--check` for dry run.

See [docs/inventory.md](docs/inventory.md) for how playbooks and host groups are organized.

## development
### lint
- `poetry run ansible-lint` — lint the whole repository (same as CI)
- `poetry run ansible-lint roles/ROLE_NAME` — lint a specific role
- `poetry run ansible-playbook --syntax-check playbook-workstation.yml` — syntax check

Settings: `.ansible-lint`, `.yamllint`

### test (Molecule)
Molecule runs roles/playbooks in an Ubuntu container and requires Docker.

- `MOLECULE_TARGET_ROLE=git poetry run molecule test -s role` — test a single role
- `poetry run molecule test -s SCENARIO` — E2E test of a playbook; scenarios are split by host group combination (see `molecule/`)
- comment `/e2e` on a PR to run the E2E test on the PR branch
  - the `Molecule E2E` status on a PR shows whether E2E is required and its result; it is reset to pending on each push to a PR that changes E2E targets
  - PRs that change dependency files (`pyproject.toml`, `poetry.lock`, `requirements.yml`) run E2E automatically

Shared settings are in `.config/molecule/config.yml`. Each scenario's host groups and skipped roles are in `molecule/*/molecule.yml`, and CI workflows are in `.github/workflows/`.
