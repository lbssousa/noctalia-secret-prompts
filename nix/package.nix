# noctalia-pinentry (gpg-agent pinentry-program) and noctalia-askpass (SSH_ASKPASS),
# the clients of the lbssousa/secret-prompts Noctalia plugin.
{
  lib,
  stdenv,
  meson,
  ninja,
}:

stdenv.mkDerivation {
  pname = "noctalia-secret-prompts";
  version = "1.0.0";

  src = lib.fileset.toSource {
    root = ../client;
    fileset = lib.fileset.unions [
      ../client/meson.build
      ../client/src
      ../client/tests
    ];
  };

  strictDeps = true;
  __structuredAttrs = true;

  nativeBuildInputs = [
    meson
    ninja
  ];

  doCheck = true;

  meta = {
    description = "pinentry and SSH_ASKPASS clients drawn by the Noctalia shell through a plugin";
    homepage = "https://github.com/lbssousa/noctalia-secret-prompts";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "noctalia-pinentry";
  };
}
