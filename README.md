# mac-bootstrap

One-shot bootstrap for a fresh macOS dev machine. Installs the minimal toolchain
that everything else assumes, then (optionally) hands off to
the dotfiles repository’s `setup.sh`.

## What it installs (idempotent)

1. Xcode Command Line Tools (`git`, `clang`)
2. Homebrew
3. `git`, `gh`, `python`, `age`, `1password-cli`

Re-running is safe — each step is skipped if it is already present.

## Usage

Always read a script before piping it into your shell:

```bash
curl -fsSL https://raw.githubusercontent.com/zhiyue/mac-bootstrap/refs/heads/main/bootstrap.sh | less
```

Then run it:

```bash
curl -fsSL https://raw.githubusercontent.com/zhiyue/mac-bootstrap/refs/heads/main/bootstrap.sh | bash
```

By default it installs the toolchain and then **stops**, printing the manual clone
+ setup steps. To also clone your dotfiles repo into
`~/workspace/dev-setup/mac-dotfiles` and apply it automatically, set
`DEV_SETUP_REPO`:

```bash
curl -fsSL https://raw.githubusercontent.com/zhiyue/mac-bootstrap/refs/heads/main/bootstrap.sh \
  | DEV_SETUP_REPO=https://github.com/zhiyue/mac-dotfiles.git bash
```

## Environment overrides

| Variable | Default | Meaning |
|---|---|---|
| `DEV_SETUP_REPO` | _(unset)_ | If set, clone this repo and run its `setup.sh`. If unset, install the toolchain only. |
| `DEV_SETUP_DIR` | `~/workspace/dev-setup` | Workspace root. |
| `DEV_SETUP_SOURCE` | `$DEV_SETUP_DIR/mac-dotfiles` | Checkout directory and clone target for `DEV_SETUP_REPO`. |
| `DOTFILES_AGE_IDENTITY` | _(unset)_ | Local age identity file passed to `setup.sh --identity`; needed when restoring encrypted configuration. |

The dotfiles checkout must contain the migrated `setup.sh` and `dotfiles.py`.
Use compatible revisions of both repositories when running the hosted
bootstrap command.

The setup process keeps the existing installers and application-registration
steps, excluding agent skills. Configuration conflicts stop the process; it does
not force an overwrite. There are no scheduled Git commits or cross-machine sync.

## Verification

```bash
bash -n bootstrap.sh
shellcheck bootstrap.sh
python3 -m unittest discover -s tests -v
```

Tests use command substitutes and temporary directories; they do not install
software or change the real machine configuration.
