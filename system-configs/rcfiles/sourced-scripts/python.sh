#!/bin/bash

CONFIGROOT_DIR_SCRIPT="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || echo ~/.vim )"
if [ -f "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh" ]; then
  # shellcheck disable=SC1091
  source "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh"
fi

function venv-find-from-pwd() {
  find $(pwd) -name 'activate' -maxdepth 3 | grep '/bin/activate$'
}

# shellcheck disable=SC1090
## [venv-create]
#  Create a new venv
function venv-create() {
  local VENV_DIR="$(pwd)/.venv"
  if [[ -n $1 ]]; then
    VENV_DIR="$1"
  fi

  local VENV=
  # VENV="$(find . -name activate | grep -F '/bin/activate')"
  VENV="$(venv-find-from-pwd)"

  if [[ $(wc -l <<< "${VENV}") -gt 1 ]]; then
    echo "Already a venv here, skipping"
    return 1
  else
    echo "Creating a venv here in: ${VENV_DIR}"
    echo "Enter to continue,  CTRL-C to cancel"
    read -r _
    python3 -m venv "${VENV_DIR}"
    source "$(find . -name activate | grep -F '/bin/activate')"
  fi
}

# shellcheck disable=SC1090
## [venv-activate]
#  Finds a venv and activates it
function venv-activate() {
  local VENV=
  #if ! VENV="$(find . -name activate | grep -F '/bin/activate')"; then
  if ! VENV="$(venv-find-from-pwd)"; then
    echo "No virtual env found."
    return 1
  fi

  if [[ $(wc -l <<< "${VENV}") -gt 1 ]]; then
    source "$(echo "${VENV}" | sort -u | fzf)"
  else
    source "${VENV}"
  fi
}

## [venv-deactivate]
#  Because I always forget... and I'm like: how do I deactivate this
function venv-deactivate() {
  if [[ -n $VIRTUAL_ENV ]]; then
    echo "Just type [deactivate] next time"
    echo "Deactivating"
    deactivate
  else
    echo "Not in a venv"
  fi
}

# shellcheck disable=SC1090
## [venv-vscode]
#  Finds a venv and prints helpful commands to remember how to set it for VSCode
function venv-vscode() {
  local VENV=
  if ! VENV="$(find "$(pwd)" -name activate | grep -F '/bin/activate')"; then
    echo "No virtual env found."
    return 1
  fi

  if [[ $(wc -l <<< "${VENV}") -gt 1 ]]; then
    echo "Choose VENV"
    VENV="$(echo "${VENV}" | sort -u | fzf)"
  fi

  VENV="$(sed 's/\/activate$/\/python3/' <<< "${VENV}")"

  echo "Set the Python interpreter in VS Code."
  echo "You need to explicitly copy the path, not select it from the file picker or it follows the symlink"
  echo ""
  echo "CMD+SHIFT+P -> Python: Select Interpreter"
  echo "Use this path:"
  echo "${VENV}"
}

function venv-activate-in-tmux() {
  if ! am-i-in-tmux; then
    # Do nothing
    return 0
  fi
  local TMUX_SESSION_NAME=
  local VENV=

  if ! TMUX_SESSION_NAME="$(tmux display-message -p '#S')"; then
    # Can't get the session name, do nothing
    return 0
  fi

  if [[ "$TMUX_SESSION_NAME" == "py-"* ]]; then
    if VENV="$(venv-find-from-pwd)" && [[ -n "$VENV" ]]; then
      if ! venv-activate; then
        echo "Tried to activate a venv and failed."
      fi
    fi
  fi
}

function vscode-debug-launch-json() {
  cat<< 'EOM'
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Python Debugger: main.py [using venv]",
            "type": "debugpy",
            "request": "launch",
            "program": "${workspaceFolder}/main.py",
            "python": "${workspaceFolder}/.venv/bin/python",
            "justMyCode": false,
            "args": [],
            "env": {},
            "console": "integratedTerminal",
            "cwd": "${workspaceFolder}"
        },
        {
            "name": "Python Debugger: Current File [using venv]",
            "type": "debugpy",
            "request": "launch",
            "program": "${file}",
            "python": "${workspaceFolder}/.venv/bin/python",
            "justMyCode": false,
            "args": [],
            "env": {},
            "console": "integratedTerminal",
            "cwd": "${workspaceFolder}"
        },
    ]
}
EOM
}

function poetry-create-poetry-toml() {
  local POETRY_TOML=
  POETRY_TOML="$(cat<<EOM
[virtualenvs]
in-project = true
EOM
)"
  if [[ -f "poetry.toml" ]]; then
    if yn_prompt "poetry.toml file already exists, overwrite?"; then
      echo "${POETRY_TOML}" > poetry.toml
    fi
  else
      echo "${POETRY_TOML}" > poetry.toml
  fi
}

function poetry-create-pyproject-toml() {
  local PYPROJECT_TOML=
  PYPROJECT_TOML="$(cat<<EOM
[tool.poetry]
name = "my-new-project"
version = "0.1.0"
description = "Add your description here"
readme = "README.md"
package-mode = false

[tool.poetry.dependencies]
python = "^3.12"
ruff = "^0.14.0"
pyright = "^1.1.406"


## Example for private source
# [[tool.poetry.source]]
# name = "private-gcp-repo"
# url = "https://us-central1-python.pkg.dev/GCP_PROJECT/ARTIFACT_REPO/simple/"
# priority = "explicit"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"
EOM
)"

  if [[ -f "pyproject.toml" ]]; then
    if yn_prompt "pyproject.toml file already exists, overwrite?"; then
      echo "${PYPROJECT_TOML}" > pyproject.toml
    fi
  else
      echo "${PYPROJECT_TOML}" > pyproject.toml
  fi
}

function poetry-create-makefile() {
  local MAKEFILE=
  MAKEFILE="$(cat<<EOM
.PHONY: setup-with-keyring-verbose
setup-verbose:
	@if [ -z "$${GOOGLE_APPLICATION_CREDENTIALS}" ] && [ ! -f ~/.config/gcloud/application_default_credentials.json ]; then \
		echo "GOOGLE_APPLICATION_CREDENTIALS is not set and default file not found. Logging in..."; \
		gcloud auth application-default login; \
	fi
	gcloud auth configure-docker us-central1-docker.pkg.dev
	uv python install 3.12
	uv tool install poetry==2.0.1
	uv tool update-shell
	poetry self update 2.0.1
	poetry env use python3.12
	poetry self add keyrings.google-artifactregistry-auth
	poetry install --verbose

.PHONY: setup-with-keyring
setup:
	@if [ -z "$${GOOGLE_APPLICATION_CREDENTIALS}" ] && [ ! -f ~/.config/gcloud/application_default_credentials.json ]; then \
		echo "GOOGLE_APPLICATION_CREDENTIALS is not set and default file not found. Logging in..."; \
		gcloud auth application-default login; \
	fi
	gcloud auth configure-docker us-central1-docker.pkg.dev
	uv python install 3.12
	uv tool install poetry==2.0.1
	uv tool update-shell
	poetry self update 2.0.1
	poetry env use python3.12
	poetry self add keyrings.google-artifactregistry-auth
	poetry install

.PHONY: setup-with-keyring-verbose
setup-verbose:
	uv python install 3.12
	uv tool install poetry==2.0.1
	uv tool update-shell
	poetry self update 2.0.1
	poetry env use python3.12
	poetry install --verbose

.PHONY: setup-with-keyring
setup:
	uv python install 3.12
	uv tool install poetry==2.0.1
	uv tool update-shell
	poetry self update 2.0.1
	poetry env use python3.12
	poetry install

.PHONY: typecheck
typecheck:
	poetry run pyright

.PHONY: lint
lint:
	poetry run ruff check

.PHONY: format
format:
	poetry run ruff format --check

.PHONY: format-fix
format-fix:
	poetry run ruff format

.PHONY: lint-fix
lint-fix:
	poetry run ruff check --fix

# .PHONY: up
# up:
# 	docker compose pull
# 	docker compose up -d
#
# PHONY: down
# down:
# 	docker compose down

EOM
)"

  if [[ -f "Makefile" ]]; then
    if yn_prompt "Makefile file already exists, overwrite?"; then
      echo "${MAKEFILE}" > Makefile
    fi
  else
      echo "${MAKEFILE}" > Makefile
  fi
}

function poetry-init() {
    clear;
    cat <<EOM
## Init Setup ##

# 1. poetry.toml to make sure venvs are created in local dir
# 2. Boilerplate pyproject.toml with python3.12, ruff and pyright (consider updating)
# 3. Make file with some useful/handy stanzas

EOM

    echo "Enter to continue, CTRL-C to exit"
    read -r _;
    # clear;
    echo ""
    if yn_prompt "Create poetry.toml?"; then
      poetry-create-poetry-toml
    fi
    echo ""
    if yn_prompt "Create pyproject.toml?"; then
      poetry-create-pyproject-toml
    fi
    echo ""
    if yn_prompt "Create makefile?"; then
      poetry-create-makefile
    fi


    echo "Enter to continue, CTRL-C to exit"
    read -r _;
    clear;
    cat <<EOM
## Notes ##

Setup complete! Review the pyproject.toml and make sure versions are correct
- Update python, default to 3.12
- Update ruff, default to 0.14.0
- Update pyright, default to 1.1.406

Go through the Makefile, right now it pins poetry to 2.0.1. Consider updating to a newer version

EOM
}

function serena-uvx() {
  uvx --from git+https://github.com/oraios/serena serena
}

function serena-uvx-create-project-cwd() {
  uvx --from git+https://github.com/oraios/serena serena project create
}

function ffpython() {
  eval "${BASH_FZF_IN_SOURCED_SCRIPT}"
}
eval "${BASH_COMMON_SCRIPT_FOOTER}"

