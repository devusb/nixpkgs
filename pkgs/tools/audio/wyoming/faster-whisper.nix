{ lib
, python3
, fetchFromGitHub
}:

python3.pkgs.buildPythonApplication rec {
  pname = "wyoming-faster-whisper";
  version = "1.1.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "rhasspy";
    repo = "wyoming-faster-whisper";
    rev = "refs/tags/v${version}";
    hash = "sha256-RD6J/Q7kvd+sgTpR6ERyV+D8gpm0fF38L3U/Jp7gOgk=";
  };

  nativeBuildInputs = with python3.pkgs; [
    setuptools
  ];

  propagatedBuildInputs = with python3.pkgs; [
    ctranslate2
    tokenizers
    wyoming
  ];

  postPatch = ''
    substituteInPlace setup.py --replace \
      "name=module_dir" 'name="wyoming_faster_whisper"'
  '';

  pythonImportsCheck = [
    "wyoming_faster_whisper"
  ];

  # no tests
  doCheck = false;

  meta = with lib; {
    description = "Wyoming Server for Faster Whisper";
    homepage = "https://github.com/rhasspy/wyoming-faster-whisper";
    license = licenses.mit;
    maintainers = with maintainers; [ hexa ];
  };
}
