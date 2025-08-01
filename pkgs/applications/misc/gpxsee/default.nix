{
  lib,
  stdenv,
  fetchFromGitHub,
  qmake,
  nix-update-script,
  qtbase,
  qttools,
  qtlocation ? null, # qt5 only
  qtpositioning ? null, # qt6 only
  qtserialport,
  qtsvg,
  wrapQtAppsHook,
  wrapGAppsHook3,
}:

let
  isQt6 = lib.versions.major qtbase.version == "6";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "gpxsee";
  version = "13.45";

  src = fetchFromGitHub {
    owner = "tumic0";
    repo = "GPXSee";
    tag = finalAttrs.version;
    hash = "sha256-3GPpr8L+oMHCGXo3RVaky6EjDrEiBERRU6w56o17Xhc=";
  };

  buildInputs = [
    qtserialport
  ]
  ++ (
    if isQt6 then
      [
        qtbase
        qtpositioning
        qtsvg
      ]
    else
      [
        qtlocation
      ]
  );

  nativeBuildInputs = [
    qmake
    qttools
    wrapQtAppsHook
    wrapGAppsHook3
  ];

  dontWrapGApps = true;

  preFixup = ''
    qtWrapperArgs+=(''${gappsWrapperArgs[@]})
  '';

  preConfigure = ''
    lrelease gpxsee.pro
  '';

  postInstall = lib.optionalString stdenv.hostPlatform.isDarwin ''
    mkdir -p $out/Applications
    mv GPXSee.app $out/Applications
    mkdir -p $out/bin
    ln -s $out/Applications/GPXSee.app/Contents/MacOS/GPXSee $out/bin/gpxsee
  '';

  passthru = {
    updateScript = nix-update-script { };
  };

  meta = {
    changelog = "https://build.opensuse.org/package/view_file/home:tumic:GPXSee/gpxsee/gpxsee.changes";
    description = "GPS log file viewer and analyzer";
    mainProgram = "gpxsee";
    homepage = "https://www.gpxsee.org/";
    license = lib.licenses.gpl3Only;
    longDescription = ''
      GPXSee is a Qt-based GPS log file viewer and analyzer that supports
      all common GPS log file formats.
    '';
    maintainers = with lib.maintainers; [
      womfoo
      sikmir
    ];
    platforms = lib.platforms.unix;
  };
})
