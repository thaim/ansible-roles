# ansible
My ansible playbooks

## setup python environment
- [install poetry](https://python-poetry.org/docs/)
- run `poetry install --sync` to ansible and related dev dependencies

Then, run `poetry shell` for interactive environment or run `poetry run ansible-playbook ...` for executing command.

## required modules
Run `ansible-galaxy install -r requirements.yml` to install modules.
