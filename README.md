# Secret Prompts for Noctalia

A [Noctalia](https://github.com/noctalia-dev/noctalia) plugin that answers GnuPG
`pinentry` and OpenSSH `SSH_ASKPASS` prompts in a shell panel instead of a separate
GTK/Qt dialog.

Noctalia keeps secrets out of the shell core
([noctalia#4951](https://github.com/noctalia-dev/noctalia/pull/4951)). In this plugin
the shell only draws the panel. Two small clients speak the protocols and keep the
secret out of the shell's IPC:

- `noctalia-pinentry`: an Assuan pinentry for `gpg-agent`. It supports `GETPIN`,
  `CONFIRM`, `MESSAGE`, `SETREPEAT` (passphrase changes) and `SETTIMEOUT`.
- `noctalia-askpass`: `SSH_ASKPASS` for `ssh`, `ssh-add` and `git`. It covers the
  secret, `confirm` and `none` modes of `SSH_ASKPASS_PROMPT`.

## How it works

1. The client creates a private directory,
   `$XDG_RUNTIME_DIR/noctalia-secret-prompts/<random id>/`, with mode `0700`.
2. It sends only the prompt text over the shell's IPC socket. This is the same as
   `noctalia msg plugin lbssousa/secret-prompts:service all request <json>`.
3. The plugin's service queues the request, writes `ack` into that directory and opens
   the panel. The panel writes the answer to `reply`, a new file with mode `0600`.
4. The client reads the answer, removes the directory and returns the answer to
   `gpg-agent` or `ssh`.

If `gpg-agent` or `ssh` gives up, the client tells the plugin, which closes the prompt.
The client also handles the shell going away mid-prompt.

The shell might not be running, or the plugin might not answer within 3 seconds. In
that case:

- `noctalia-pinentry` runs `$NOCTALIA_PINENTRY_FALLBACK`, for example
  `pinentry-curses`. If that variable is not set, it reports an error to `gpg-agent`.
- `noctalia-askpass` runs `$NOCTALIA_ASKPASS_FALLBACK`. If that variable is not set,
  it exits with status 1.

## Installation

### The plugin

```sh
noctalia msg plugins source add secret-prompts git https://github.com/lbssousa/noctalia-secret-prompts
noctalia msg plugins enable lbssousa/secret-prompts
```

The plugin needs Noctalia with plugin API 42 or newer.

### The clients

These need meson, ninja and a C++23 compiler. They have no other dependencies.

```sh
meson setup build client
meson test -C build
meson install -C build
```

With Nix, use `nix build github:lbssousa/noctalia-secret-prompts`, or add
`overlays.default` to your nixpkgs to get `pkgs.noctalia-secret-prompts`.

### Wiring

`~/.gnupg/gpg-agent.conf`:

```
pinentry-program /path/to/noctalia-pinentry
```

Then run `gpg-connect-agent reloadagent /bye`. To keep a terminal fallback, point
`pinentry-program` at a wrapper that exports
`NOCTALIA_PINENTRY_FALLBACK=/usr/bin/pinentry-curses`.

For SSH, set `SSH_ASKPASS=/path/to/noctalia-askpass` in your session environment. Add
`SSH_ASKPASS_REQUIRE=prefer` to use the panel even when a terminal is attached.

On NixOS:

```nix
programs.gnupg.agent.pinentryPackage = pkgs.noctalia-secret-prompts; # mainProgram: noctalia-pinentry
programs.ssh = {
  enableAskPassword = true;
  askPassword = "${pkgs.noctalia-secret-prompts}/bin/noctalia-askpass";
};
```

## Security notes

- The secret never goes through the shell's IPC, its logs or the plugin's shared state.
  It goes only into the `0600` reply file inside the client's `0700` directory.
- The service accepts only alphanumeric request ids, and the plugin builds the reply
  path itself. The client cannot choose the path.
- GnuPG prompts are always masked, whatever the request says.

## License

MIT
