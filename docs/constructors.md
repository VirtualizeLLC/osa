# Constructors: init / final overrides and private injections

The repository supports lightweight constructor hooks so you can run per-machine or private initialization steps without committing secrets to the repo.

Key files and variables

- `OSA_CONFIG` — repo root (provided by the repo's constants). Do not override this in the constructor files.
- `OSA_ZSH_CONSTRUCTORS` — path to the constructors directory: `$OSA_CONFIG/src/zsh/constructors`
- Constructor files (ignored by git):
  - `src/zsh/constructors/init.zsh` — run *before* the main zsh initialization. Good for injecting environment variables, private credentials, or mounting private repos.
  - `src/zsh/constructors/final.zsh` — run *after* the main initialization. Good for tweaks that rely on the repo's scripts being in place.
  - `src/zsh/constructors/__local__*.zsh` — pattern for machine-specific local overrides. These are ignored via `.gitignore`.

Note on safety and repo checks

- The repository contains a pre-commit checker (see `repo-scripts/check-no-double-underscore.zsh`) that blocks files with path segments beginning with `__` by default. The constructor entrypoints `init.zsh` and `final.zsh` are explicitly excluded from that blocking rule so they are never flagged by the "__" filename check (they remain intended as machine-local entrypoints). However, this exclusion does not change the security guidance below — do not commit secrets into constructor files.

Why constructors exist

- Keep machine-specific secrets and settings out of source control.
- Allow safe per-machine bootstrapping (for example, cloning private helper repos, loading secret keys or setting PATHs that are unique to a machine).

Security and recommended patterns

- Do NOT commit secrets into this repo. Use the `constructors` directory for secrets which should be present on the machine only.
- Prefer environment variables and files with restrictive permissions (600) when handling private keys.
- If you need to store private repo access tokens, prefer using an OS-native secret store (Keychain on macOS) and fetch them from the constructor instead of hard-coding tokens.

Example: `init.zsh` — load machine secrets

```zsh
# src/zsh/constructors/init.zsh
# load machine-level secrets from a private file
if [ -f "$HOME/.secrets/machine_env" ]; then
  # file should be chmod 600
  source "$HOME/.secrets/machine_env"
fi

# e.g., set a private repo URL (read-only token stored in keychain or file)
if [ -n "$MY_PRIVATE_REPO_URL" ]; then
  export MY_PRIVATE_REPO_URL
fi
```

Example: `final.zsh` — clone a private helper repo after setup

```zsh
# src/zsh/constructors/final.zsh
# clone private helper repo into ~/.local if missing
PRIVATE_DIR="$HOME/.local/private-tools"
if [ ! -d "$PRIVATE_DIR" ]; then
  git clone "$MY_PRIVATE_REPO_URL" "$PRIVATE_DIR"
fi

# make sure the tools are on PATH
export PATH="$PRIVATE_DIR/bin:$PATH"
```

Using constructor overrides for CI or automation

- Constructors are intended for interactive/machine-local use. For CI, prefer to inject secrets via CI provider mechanisms and not rely on `constructors` files.
- Keep constructor logic idempotent: safe to run multiple times without side effects.

Troubleshooting

- If a constructor script fails, the setup runs should print the error. Make constructors robust with guard checks.
- Verify file permissions for private files (use `chmod 600`).

Advanced: inject private repos/secrets via a helper

If you'd like a small helper to bootstrap private content, include a `scripts/bootstrap-private.sh` (ignored) that uses the platform's secret store or prompts the user for credentials interactively. That helper can be invoked from `init.zsh`.

## Community Scripts vs Constructors

- **[OSA Scripts](https://github.com/VirtualizeLLC/osa-scripts)** - Shared productivity helpers and shell functions for the community
- **Constructors** (`init.zsh`, `final.zsh`) - Machine-specific configuration, secrets, and local overrides

Use constructors when your code is sensitive or machine-specific. Use osa-scripts when you want to share productivity helpers with the community!

````
