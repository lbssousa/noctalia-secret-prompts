# Security policy

This plugin answers GnuPG `pinentry` and OpenSSH `SSH_ASKPASS` prompts, so it handles
passphrases and PINs. Fixes go to `main`. Report problems against the latest commit.

## Reporting a vulnerability

Use **Security → Report a vulnerability** on this repository, which opens a private advisory:
<https://github.com/lbssousa/noctalia-secret-prompts/security/advisories/new>.
Please don't open a public issue for a vulnerability.

A useful report includes:

- the commit;
- your Noctalia version;
- what you expected and what happened;
- a minimal reproduction.

Never include real passphrases, keys or unredacted logs. This is a personal project: there is
no guaranteed response time.

## What is in scope

- A secret reaching the shell's IPC, its logs, the plugin's shared state, a command line or the
  environment. The only path a secret may take is the reply file: a new `0600` file in the
  client's private `0700` directory,
  `$XDG_RUNTIME_DIR/noctalia-secret-prompts/<id>/`.
- Request ids or reply paths that the plugin accepts from outside. The service accepts only
  alphanumeric ids and builds the reply path itself.
- A GnuPG prompt shown unmasked.
- The Assuan or askpass clients mishandling hostile input from `gpg-agent`, `ssh` or the reply
  file: overflows, injection into the Assuan stream, answering the wrong request.
- A prompt left open, or a secret written, after `gpg-agent` or `ssh` gave up.

The model this relies on: the clients, the shell and the plugin run as you, with no privileges.
Anyone who can already run code as you can read your session.

## Automated checks

Every push and pull request runs:

- **Checks:** `nix flake check`, which builds the clients and runs their tests; Nix formatting;
  and a gitleaks scan of the tree and the whole history, with a pinned version and SHA-256.
- **CodeQL:** C/C++, traced while the clients build with meson and GCC 14, plus the workflows,
  with the `security-extended` queries.
- **zizmor:** a static audit of the GitHub Actions workflows.
- **Dependency review** on pull requests.

The OpenSSF Scorecard runs weekly and on pushes to `main`. Dependabot updates the actions
weekly, after a seven-day cooldown. Every action is pinned to a commit SHA.

These checks catch known classes of problems. They don't replace review.
