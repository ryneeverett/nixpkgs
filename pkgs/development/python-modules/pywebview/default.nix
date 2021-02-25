{ lib, buildPythonPackage, fetchFromGitHub, pythonOlder
, importlib-resources, pytest, xvfb_run, qt5, pyqt5, pyqtwebengine }:

buildPythonPackage rec {
  pname = "pywebview";
  version = "3.4";
  disabled = pythonOlder "3.5";

  src = fetchFromGitHub {
    owner = "r0x0r";
    repo = "pywebview";
    rev = version;
    sha256 = "1vqcfdy61na9x16n4n8zv4c9aq7cdp3z292y28jyli981yvz14fw";
  };

  nativeBuildInputs = [ qt5.wrapQtAppsHook ];

  propagatedBuildInputs = [
    pyqt5
    pyqtwebengine
  ] ++ lib.optionals (pythonOlder "3.7") [ importlib-resources ];

  checkInputs = [ pytest xvfb_run ];

  checkPhase = ''
    export HOME=$(mktemp -d)
    export QT_QPA_PLATFORM_PLUGIN_PATH="${qt5.qtbase.bin}/lib/qt-${qt5.qtbase.version}/plugins";
    pushd tests
    patchShebangs run.sh
    substituteInPlace run.sh --replace PYTHONPATH=.. PYTHONPATH="$PYTHONPATH:.."
    xvfb-run -s '-screen 0 800x600x24' ./run.sh
    popd
  '';

  meta = with lib; {
    homepage = "https://github.com/r0x0r/pywebview";
    description = "Lightweight cross-platform wrapper around a webview";
    license = licenses.bsd3;
    maintainers = with maintainers; [ jojosch ];
  };
}
