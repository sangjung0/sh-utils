#!/usr/bin/env bash
set -euo pipefail

# usage
usage() {
    echo "Usage: $0 <workdir> <home> [group1] [group2,group3...]" >&2
    echo "  - <workdir>, <home>: Required directories" >&2
    echo "  - [groups...]: Optional. Can be space-separated or comma-separated" >&2
    exit 1
}

# check args
if [[ $# -lt 2 ]]; then
    usage
fi

# args
CONTAINER_WORK_DIR="${1}"
CONTAINER_HOME="${2}"
CONTAINER_VENV_DIR="${CONTAINER_WORK_DIR}/.venv"
shift 2 # Remove the first two args, the rest are groups

# check home directory
if [[ ! -d "${CONTAINER_HOME}" ]]; then
    echo "[ERROR] home directory '${CONTAINER_HOME}' does not exist" >&2
    exit 1
fi

# check uv installation
if ! command -v uv &> /dev/null; then
    echo "[ERROR] uv is not installed" >&2
    exit 1
fi

cd "${CONTAINER_WORK_DIR}"

# parse optional groups
UV_GROUPS=()
for group_arg in "$@"; do
    IFS=',' read -r -a parsed_groups <<< "${group_arg}"
    for g in "${parsed_groups[@]}"; do
        # Add non-empty group names to the array
        [[ -n "${g}" ]] && UV_GROUPS+=("${g}")
    done
done

# Always run the base sync
echo "[INFO] Running base uv sync..."
if ! uv sync; then
    echo "[ERROR] base uv sync failed." >&2
    exit 1
fi
echo "[INFO] Base uv sync succeeded."

# Run sync for optional groups if they exist
if [[ ${#UV_GROUPS[@]} -gt 0 ]]; then
    echo "[INFO] Syncing optional groups: ${UV_GROUPS[*]}"
    for g in "${UV_GROUPS[@]}"; do
        echo "[INFO] ==> uv sync --group ${g}"
        if ! uv sync --group "${g}"; then
            echo "[ERROR] uv sync for group '${g}' failed." >&2
            exit 1
        fi
    done
    echo "[INFO] Successfully synced groups: ${UV_GROUPS[*]}"
fi

echo "[INFO] Setup complete."
