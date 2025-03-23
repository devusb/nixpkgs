{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nixosTests,
  bash,
  which,
  ffmpeg,
  makeBinaryWrapper,
}:

let
  version = "0.2.1";
in
buildGoModule {
  pname = "owncast";
  inherit version;
  src = fetchFromGitHub {
    owner = "owncast";
    repo = "owncast";
    tag = "v${version}";
    hash = "sha256-9Fbu0zm8TBNVU2TOSFyDP2TIfDLdNdEIcAu24PqF7lM=";
  };
  vendorHash = "sha256-ERilQZ8vnhGW1IEcLA4CcmozDooHKbnmASMw87tjYD4=";

  propagatedBuildInputs = [ ffmpeg ];

  nativeBuildInputs = [ makeBinaryWrapper ];

  postInstall = ''
    wrapProgram $out/bin/owncast \
      --prefix PATH : ${
        lib.makeBinPath [
          bash
          which
          ffmpeg
        ]
      }
  '';

  installCheckPhase = ''
    runHook preCheck
    $out/bin/owncast --help
    runHook postCheck
  '';

  passthru.tests.owncast = nixosTests.owncast;

  meta = with lib; {
    description = "self-hosted video live streaming solution";
    homepage = "https://owncast.online";
    license = licenses.mit;
    platforms = platforms.unix;
    maintainers = with maintainers; [ MayNiklas ];
    mainProgram = "owncast";
  };

}
