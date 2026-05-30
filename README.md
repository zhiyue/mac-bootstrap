# mac-bootstrap

One-shot bootstrap for a fresh macOS dev machine. Installs the minimal toolchain
that everything else assumes, then (optionally) hands off to
[chezmoi](https://www.chezmoi.io/).

## What it installs (idempotent)

1. Xcode Command Line Tools (`git`, `clang`)
2. Homebrew
3. `chezmoi`, `git`, `gh`, `1password-cli`

Re-running is safe — each step is skipped if it is already present.

## Usage

Always read a script before piping it into your shell:

```bash
curl -fsSL https://raw.githubusercontent.com/zhiyue/mac-bootstrap/main/bootstrap.sh | less
```

Then run it:

```bash
curl -fsSL https://raw.githubusercontent.com/zhiyue/mac-bootstrap/main/bootstrap.sh | bash
```

By default it installs the toolchain and then **stops**, printing the manual clone
+ chezmoi steps. To also clone your dotfiles repo and run chezmoi automatically,
set `DEV_SETUP_REPO`:

```bash
curl -fsSL https://raw.githubusercontent.com/zhiyue/mac-bootstrap/main/bootstrap.sh \
  | DEV_SETUP_REPO=git@github.com:zhiyue/<your-repo>.git bash
```

## Environment overrides

| Variable | Default | Meaning |
|---|---|---|
| `DEV_SETUP_REPO` | _(unset)_ | If set, clone this repo and run `chezmoi init` + `apply`. If unset, install the toolchain only. |
| `DEV_SETUP_DIR` | `~/workspace/dev-setup` | Clone target directory. |
