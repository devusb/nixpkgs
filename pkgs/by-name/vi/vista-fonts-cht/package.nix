{
  lib,
  stdenvNoCC,
  fetchurl,
  cabextract,
}:

stdenvNoCC.mkDerivation {
  pname = "vista-fonts-cht";
  version = "1";

  src = fetchurl {
    url = "https://download.microsoft.com/download/7/6/b/76bd7a77-be02-47f3-8472-fa1de7eda62f/VistaFont_CHT.EXE";
    hash = "sha256-fSnbbxlMPzbhFSQyKxQaS5paiWji8njK7tS8Eppsj6g=";
  };

  nativeBuildInputs = [ cabextract ];

  unpackPhase = ''
    runHook preUnpack

    cabextract --lowercase --filter '*.TTF' $src

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fonts/truetype
    cp *.ttf $out/share/fonts/truetype

    # Set up no-op font configs to override any aliases set up by
    # other packages.
    mkdir -p $out/etc/fonts/conf.d
    substitute ${./no-op.conf} $out/etc/fonts/conf.d/30-msjhenghei.conf \
      --subst-var-by fontname "Microsoft JhengHei"

    runHook postInstall
  '';

  meta = {
    description = "TrueType fonts from Microsoft Windows Vista For Traditional Chinese (Microsoft JhengHei)";
    homepage = "https://www.microsoft.com/typography/fonts/family.aspx";
    license = lib.licenses.unfree;
    maintainers = with lib.maintainers; [ atkinschang ];

    # Set a non-zero priority to allow easy overriding of the
    # fontconfig configuration files.
    priority = 5;
    platforms = lib.platforms.all;
  };
}
