# Dev Environment Setup (Fedora 44)

Personal development environment configuration. Everything is installed **at user level** (no root); binaries live in `~/.local/bin`, already on `PATH` via `~/.bashrc`.

> No secrets are stored in this repo. Credentials live in local files under `~/.config` with `600` permissions and are never committed.

## Tools

| Tool | What it is | Install method |
|---|---|---|
| **Terraform** | Infrastructure as Code (`.tf` files). | Official binary → `~/.local/bin` |
| **kubectl** | Kubernetes cluster CLI. | Official binary → `~/.local/bin` |
| **Azure CLI** (`az`) | Manage Microsoft Azure resources. | `pipx` (isolated venv) |
| **GitHub CLI** (`gh`) | GitHub from the terminal (PRs, auth, packages). | Official tarball → `~/.local/bin` |
| **pnpm** | Fast Node package manager. | Official standalone script |
| **Freelens** | Visual IDE/dashboard for Kubernetes (free Lens fork). | Flatpak `--user` (Flathub) |

## Isolated Python tooling

| Tool | What it is |
|---|---|
| **pipx** | Installs Python apps each in their own venv (keeps the system Python clean). Used for `az`. |
| **uv** / **uvx** | Ultra-fast Python manager (Astral). Better dependency resolution than pip and can provision isolated Python versions on demand. `uvx` runs tools without installing them. |

### Why `uv` is great
- `uv pip install ...` — much faster than pip.
- `uv tool install --python 3.13 <pkg>` — installs a CLI with its own dedicated Python, untouched from the system one.
- `uvx <pkg>` — run a tool on the fly without installing.
- Manages Python versions itself (`uv python install 3.13`).

### Terraform credentials wrapper

A wrapper **script** on `PATH` at `~/.local/bin/terraform` loads these credentials and execs the real binary (kept at `~/.local/libexec/terraform`). Because it lives on `PATH` — not as a shell function in `~/.bashrc` — it works in **every** shell: interactive, non-interactive, scripts, CI, and tools like Claude Code. A bash function would only load in interactive shells and silently run unauthenticated everywhere else. Each call is its own process, so the variables never leak into the calling shell.

```bash
#!/usr/bin/env bash
[ -f "$HOME/.config/azure/terraform.env" ] && source "$HOME/.config/azure/terraform.env"
[ -f "$HOME/.config/cloudflare/credentials.env" ] && source "$HOME/.config/cloudflare/credentials.env"
exec "$HOME/.local/libexec/terraform" "$@"
```

Usage: just run `terraform init` / `plan` / `apply` in any project — authentication is automatic.

The `azurerm` and `cloudflare` providers read these env vars automatically; no credentials go in `.tf` files.

---

## Updating (all without root)

```bash
pipx upgrade azure-cli                          # Azure CLI
pnpm self-update                                # pnpm
flatpak update --user app.freelens.Freelens     # Freelens
uv tool upgrade markitdown-mcp                   # MarkItDown MCP
uv self update                                   # uv
# kubectl, gh: re-download the binary into ~/.local/bin
# Terraform: re-download into ~/.local/libexec/terraform (NOT ~/.local/bin — that holds the creds wrapper)
```
