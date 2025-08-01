{
  lib,
  rustPlatform,
  fetchCrate,
}:

rustPlatform.buildRustPackage rec {
  pname = "cargo-binutils";
  version = "0.3.6";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-tRh3+X6QCdkkJE1O60ZRkDBRbznGZ1aB1AOmcz0EINI=";
  };

  cargoHash = "sha256-QdW0HiVhKFuXj7hWZw1lkrFmvVIqbeMKRF2qnBX9wRI=";

  meta = {
    description = "Cargo subcommands to invoke the LLVM tools shipped with the Rust toolchain";
    longDescription = ''
      In order for this to work, you either need to run `rustup component add llvm-tools-preview` or install the `llvm-tools-preview` component using your Nix library (e.g. fenix or rust-overlay)
    '';
    homepage = "https://github.com/rust-embedded/cargo-binutils";
    changelog = "https://github.com/rust-embedded/cargo-binutils/blob/v${version}/CHANGELOG.md";
    license = with lib.licenses; [
      asl20
      mit
    ];
    maintainers = with lib.maintainers; [
      stupremee
      matthiasbeyer
    ];
  };
}
