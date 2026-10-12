# ansible
My ansible playbooks

## setup python environment
- install dependencies
  - Ubuntu: `sudo apt install build-essential libssl-dev libffi-dev libbz2-dev libncurses-dev libsqlite3-dev python3-tk liblzma-dev`
- [install poetry](https://python-poetry.org/docs/)
- run `poetry install --sync` to ansible and related dev dependencies

Then, run `poetry shell` for interactive environment or run `poetry run ansible-playbook ...` for executing command.

## required modules
Run `ansible-galaxy install -r requirements.yml` to install modules.

## run playbooks
- `poetry run ansible-playbook -i inventories/localhost playbook-desktop.yml`
- run specific roles: `--tags git,shell`
- dry run: `--check`

## development
### lint
- `poetry run ansible-lint` — lint the whole repository (same as CI)
- `poetry run ansible-lint roles/ROLE_NAME` — lint a specific role
- `poetry run ansible-playbook --syntax-check playbook-desktop.yml` — syntax check

Settings: `.ansible-lint`, `.yamllint`

### test (Molecule)
Molecule runs roles/playbooks in an Ubuntu container and requires Docker.

- `MOLECULE_TARGET_ROLE=git poetry run molecule test -s role` — test a single role
- `poetry run molecule test -s desktop` — E2E test of `playbook-desktop.yml` (`-s devel` for `playbook-devel.yml`)
- comment `/e2e` on a PR to run the E2E test on the PR branch

Shared settings are in `.config/molecule/config.yml`. Each scenario's settings and skipped roles are in `molecule/*/molecule.yml`, and CI workflows are in `.github/workflows/`.
