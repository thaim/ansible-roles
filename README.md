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
