{
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
  protobuf,
  nixosTests,
  nix-update-script,
  withQuic ? false, # with QUIC protocol support
}:

rustPlatform.buildRustPackage rec {
  pname = "easytier";
  version = "2.4.0";

  src = fetchFromGitHub {
    owner = "EasyTier";
    repo = "EasyTier";
    tag = "v${version}";
    hash = "sha256-GNHF15FJDLZKYrNuvaTQfsPGS6BabEhk5BZm7OzFbvU=";
  };

  cargoHash = "sha256-rwwrCiTiLn1DM3LaTNKzQi0tUWGzAYMXku9LHjq2K7g=";

  nativeBuildInputs = [
    protobuf
    rustPlatform.bindgenHook
  ];

  buildNoDefaultFeatures = stdenv.hostPlatform.isMips;
  buildFeatures = lib.optional stdenv.hostPlatform.isMips "mips" ++ lib.optional withQuic "quic";

  doCheck = false; # tests failed due to heavy rely on network

  passthru = {
    tests = { inherit (nixosTests) easytier; };
    updateScript = nix-update-script { };
  };

  meta = {
    homepage = "https://github.com/EasyTier/EasyTier";
    changelog = "https://github.com/EasyTier/EasyTier/releases/tag/v${version}";
    description = "Simple, decentralized mesh VPN with WireGuard support";
    longDescription = ''
      EasyTier is a simple, safe and decentralized VPN networking solution implemented
      with the Rust language and Tokio framework.
    '';
    mainProgram = "easytier-core";
    license = lib.licenses.asl20;
    platforms = with lib.platforms; unix ++ windows;
    maintainers = with lib.maintainers; [ ltrump ];
  };
}
