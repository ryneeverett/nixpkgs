{ stdenv, lib, fetchFromGitHub
, gobject-introspection, makeWrapper, wrapGAppsHook
, gtk3, gst_all_1, python3
, gettext ? null, gnome3 ? null, help2man ? null, keybinder3 ? null, libnotify ? null, streamripper ? null, udisks ? null, webkitgtk ? null
, iconTheme ? gnome3.adwaita-icon-theme
, deviceDetectionSupport ? true
, documentationSupport ? true
, notificationSupport ? true
, scalableIconSupport ? true
, translationSupport ? true
, bpmCounterSupport ? false
, ipythonSupport ? false
, lastfmSupport ? false
, lyricsManiaSupport ? false
, lyricsWikiSupport ? false
, multimediaKeySupport ? false
, musicBrainzSupport ? false
, podcastSupport ? false
, streamripperSupport ? false
, wikipediaSupport ? false
}:

assert translationSupport -> gettext != null;
assert scalableIconSupport -> gnome3 != null;
assert documentationSupport -> help2man != null;
assert multimediaKeySupport -> keybinder3 != null;
assert notificationSupport -> libnotify != null;
assert streamripperSupport -> streamripper != null;
assert deviceDetectionSupport -> udisks != null;
assert wikipediaSupport -> webkitgtk != null;

let
  inherit (lib) optional optionals optionalString;
in stdenv.mkDerivation rec {
  pname = "exaile";
  version = "4.1.1";

  src = fetchFromGitHub {
    owner = "exaile";
    repo = pname;
    rev = version;
    sha256 = "0s29lm0i4slgaw5l5s9a2zx0b83xac43rnil5cvyi210dxm5s048";
  };

  nativeBuildInputs = [
    gobject-introspection
    makeWrapper
    wrapGAppsHook
  ] ++ optionals documentationSupport [
    help2man
    python3.pkgs.sphinx
    python3.pkgs.sphinx_rtd_theme
  ] ++ optional translationSupport gettext;

  buildInputs = [
    iconTheme
    gtk3
  ] ++ (with gst_all_1; [
    gstreamer
    gst-plugins-base
    gst-plugins-good
  ]) ++ (with python3.pkgs; [
    bsddb3
    dbus-python
    mutagen
    pygobject3
    pycairo
    gst-python
  ]) ++ optional deviceDetectionSupport udisks
  ++ optional notificationSupport libnotify
  ++ optional scalableIconSupport gnome3.librsvg
  ++ optional bpmCounterSupport gst_all_1.gst-plugins-bad
  ++ optional ipythonSupport python3.pkgs.ipython
  ++ optional lastfmSupport python3.pkgs.pylast
  ++ optional (lyricsManiaSupport || lyricsWikiSupport) python3.pkgs.lxml
  ++ optional lyricsWikiSupport python3.pkgs.beautifulsoup4
  ++ optional multimediaKeySupport keybinder3
  ++ optional musicBrainzSupport python3.pkgs.musicbrainzngs
  ++ optional podcastSupport python3.pkgs.feedparser
  ++ optional wikipediaSupport webkitgtk;

  checkInputs = with python3.pkgs; [
    mox3
    pytest
  ];

  makeFlags = [
    "PREFIX=${placeholder "out"}"
  ];

  doCheck = true;
  checkPhase = ''
    runHook preCheck
    XDG_CACHE_HOME=$(mktemp -d) EXAILE_DIR="$(pwd)" PYTHONPATH="$PYTHONPATH:$(pwd)" py.test tests
    runHook postCheck
  '';

  postInstall = ''
    wrapProgram $out/bin/exaile \
      --set PYTHONPATH $PYTHONPATH \
      ${optionalString streamripperSupport "--prefix PATH : ${lib.makeBinPath [ streamripper ]}"}
  '';

  meta = with lib; {
    homepage = "https://www.exaile.org/";
    description = "A music player with a simple interface and powerful music management capabilities";
    license = licenses.gpl2Only;
    maintainers = with maintainers; [ ryneeverett ];
  };
}
