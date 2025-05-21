#!/bin/sh

# NOTE: This script is designed to work both as a standalone utility and
#       as a Helm plugin without requiring any changes.
#
#       The file 'config.sh' is optional and used for custom configuration.

set -eu

###############################################################################
# config ######################################################################

SRC_PATH="$(dirname "$0")"
DEF_CHART_NAME='preview'
DEF_PREVIEW_CMD='cat {}'
DEF_YQ_PREVIEW_CMD='cat {} | yq -I4 -PC'
[ -f "${HELM_PLUGIN_DIR:-$SRC_PATH}/config.sh" ] && . "${HELM_PLUGIN_DIR:-$SRC_PATH}/config.sh"

###############################################################################
# help ########################################################################

if [ -z "${1:-}" ] || [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    cat <<EOF
Description:
    helm-inspector renders a Helm chart and lets you browse its rendered
    resources using fzf.

    Internally runs the next command to render the chart:
        helm template ${CHART_NAME:-$DEF_CHART_NAME} [CHART_PATH] [OPTIONS]...

Usage:
    helm inspector [CHART_PATH] [OPTIONS]...

Requires:
    - helm
    - fzf
    - yq (optional: for enhanced preview of formated and colored YAML)

Options:
    -h, --help:
        print this text

    Other options are passed through to:
        helm template
    for more info do:
        helm template --help

Examples:
    helm inspector ./

    helm inspector my-app -f values.yaml

    helm inspector ./ -f values.yaml -f values-db.yaml

Config:
    To override configuration variables, create or modify:
        ${HELM_PLUGIN_DIR:-$SRC_PATH}/config.sh
EOF
    exit 0
fi

###############################################################################
# setup #######################################################################

# Check dependencies
command -v helm >/dev/null   || {
    echo "helm-inspector:error: helm is required. Please install it." >&2
    exit 1
}; command -v fzf >/dev/null || {
    echo "helm-inspector:error: fzf is required. Please install it." >&2
    exit 1
}; command -v csplit >/dev/null || {
    echo "helm-inspector:error: csplit is required. Please install it." >&2
    exit 1
}

# Check for yq
if command -v yq >/dev/null; then
    PREVIEW_CMD="${YQ_PREVIEW_CMD:-$DEF_YQ_PREVIEW_CMD}"
else
    PREVIEW_CMD="${PREVIEW_CMD:-$DEF_PREVIEW_CMD}"
fi

# variables
CHART_PATH=${1:-./}; shift || true
TMP_DIR=$(mktemp -d)
RENDER_FILE="$TMP_DIR/rendered.yaml"

[ -d "$TMP_DIR" ] || {
    echo "helm-inspector:error: Failed to make a tempdir." >&2
    exit 1
}

# Cleanup on exit
trap 'rm -rf $TMP_DIR' EXIT

###############################################################################
# script ######################################################################

# Render chart
if ! helm template "${CHART_NAME:-$DEF_CHART_NAME}" "$CHART_PATH" "$@" |\
        sed "/^\.\.\./d" > "$RENDER_FILE"; then
    echo "helm-inspector:error: Helm render failed. Fix your templates first."
    exit 1
fi

# Split rendered output into individual resources
csplit --quiet --prefix="$TMP_DIR/resource_" --suppress-matched -z \
    --suffix-format="%03d.yaml" "$RENDER_FILE" '/^---.*$/' '{*}'

i=0
for f in $(find "$TMP_DIR" -type f -name 'resource_*.yaml'); do
    kind="$(grep "^kind: .*$" "$f")"
    kind="${kind#* }"
    path="$(head -n 1 "$f")"
    path="${path##* }"

    dir="${TMP_DIR}/$(dirname "$path")"
    [ -d "$dir" ] || mkdir -p "${dir}"

    mv "$f" "${TMP_DIR}/${path%.yaml}-${kind}-${i}.yaml"
    i="$((i + 1))"
done

while true; do
    FILE="$(find "$TMP_DIR" -type f -name '*.yaml' |\
        fzf --preview="$PREVIEW_CMD" --preview-window=up,90%,wrap,border-bottom \
        --border=bottom --color=dark)"

    [ -f "$FILE" ] || exit 0

    ${EDITOR:-vim} "$FILE"
done

