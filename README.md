# helm-inspector

Render Helm charts and browse the resources interactively.

> NOTE:
> The script `./helm-inspector.sh` is designed to work both as a standalone
> utility and as a Helm plugin (no modifications required)
>
> The file 'config.sh' is optional and used for custom configuration.

> NOTE:
> This plugin only work in **Unix-based systems** (Linux/macOS).

## Requirements
- `helm`
- `fzf`
- `yq` (optional: for enhanced preview of formated and colored `YAML`)


## Install

As `standalone script`:
```bash
curl -Lo /usr/local/bin/helm-inspector \
    https://raw.githubusercontent.com/numen-0/helm-inspector/main/helm-inspector.sh 
chmod +x /usr/local/bin/helm-inspector
```

As `helm plugin`:
```bash
helm plugin install https://github.com/numen-0/helm-inspector
```

## Run

Under the hood, the script uses `helm template` to render the charts. So all 
valid arguments are directly used in it.

As `standalone script`:
```bash
helm-inspector ./my-app -f values.yaml
```

As `helm plugin`:
```bash
helm inspector ./my-app -f values.yaml
```

> NOTE:
> In both use --help to get more info about the script/plugin

```bash
helm-inspector --help
# or
helm inspector --help
```

## Configuration

You can customize the `fzf` preview behavior by creating a `config.sh` file in
the same directory as the `helm-inspector` script or plugin. This allows you to
override default commands without modifying the main script directly.

Example `config.sh`:
```bash
#!/bin/sh

YQ_PREVIEW_CMD='cat {} | yq -P'
PREVIEW_CMD='bat --style=plain --color=always {}'

CHART_NAME='preview'
```

## License
All the repo falls under the [MIT License](/LICENSE).
