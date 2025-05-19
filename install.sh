#!/bin/sh

# NOTE: It’s unclear whether the delete hook is supposed to remove files we use
#       inside our 'HELM_PLUGIN_DIR'. I supose helm will delete the dir after
#       the hook.

set -eu

case "${1:-install}" in
    install) true ;;
    delete)  true ;;
    update)
        cd "${HELM_PLUGIN_DIR}" || {
            echo "helm-inspector:update:error: could not change directory to '$HELM_PLUGIN_DIR'" >&2
            exit 1
        }

        git pull origin main
        ;;
    *)
        echo "helm-inspector:install:error: unknown argument '${1:-}'" >&2
        exit 1
        ;;
esac

