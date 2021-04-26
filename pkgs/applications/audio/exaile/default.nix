{ stdenv, lib, fetchFromGitHub
, gobject-introspection, makeWrapper, wrapGAppsHook
, gtk3, gst_all_1, python3
, gettext, gnome3, help2man, keybinder3, libnotify, streamripper, udisks, webkitgtk
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

stdenv.mkDerivation rec {
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
  ] ++ lib.optionals documentationSupport [
    help2man
    python3.pkgs.sphinx
    python3.pkgs.sphinx_rtd_theme
  ] ++ lib.optional translationSupport gettext;

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
  ]) ++ lib.optional deviceDetectionSupport udisks
  ++ lib.optional notificationSupport libnotify
  ++ lib.optional scalableIconSupport gnome3.librsvg
  ++ lib.optional bpmCounterSupport gst_all_1.gst-plugins-bad
  ++ lib.optional ipythonSupport python3.pkgs.ipython
  ++ lib.optional lastfmSupport python3.pkgs.pylast
  ++ lib.optional (lyricsManiaSupport || lyricsWikiSupport) python3.pkgs.lxml
  ++ lib.optional lyricsWikiSupport python3.pkgs.beautifulsoup4
  ++ lib.optional multimediaKeySupport keybinder3
  ++ lib.optional musicBrainzSupport python3.pkgs.musicbrainzngs
  ++ lib.optional podcastSupport python3.pkgs.feedparser
  ++ lib.optional wikipediaSupport webkitgtk;

  checkInputs = with python3.pkgs; [
    mox3
    pytest
  ];

  makeFlags = [
    "PREFIX=${placeholder "out"}"
  ];

  doCheck = true;
  preCheck = ''
    substituteInPlace Makefile --replace "PYTHONPATH=$(shell pwd)" "PYTHONPATH=$PYTHONPATH:$(shell pwd)"
    export PYTEST="py.test"
    export XDG_CACHE_HOME=$(mktemp -d)
  '';

  postInstall = ''
    wrapProgram $out/bin/exaile \
      --set PYTHONPATH $PYTHONPATH \
      ${lib.optionalString streamripperSupport "--prefix PATH : ${lib.makeBinPath [ streamripper ]}"}
  '';

  meta = with lib; {
    homepage = "https://www.exaile.org/";
    description = "A music player with a simple interface and powerful music management capabilities";
    license = licenses.gpl2Only;
    maintainers = with maintainers; [ ryneeverett ];
  };
}
