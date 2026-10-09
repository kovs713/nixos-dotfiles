{ ... }:
let
  images = [
    "image/x-farbfeld"
    "image/tiff"
    "image/tiff-fx"
    "image/png"
    "image/x-png"
    "image/jpeg"
    "image/jpg"
    "image/pjpeg"
    "image/svg+xml"
    "image/gif"
    "image/bmp"
    "image/x-bmp"
    "image/heif"
    "image/avif"
    "image/jxl"
    "image/webp"
    "image/qoi"
  ];

  apps = {
    "x-scheme-handler/http" = "zen-beta.desktop";
    "x-scheme-handler/https" = "zen-beta.desktop";
    "x-scheme-handler/chrome" = "zen-beta.desktop";
    "x-scheme-handler/tg" = "userapp-AyuGram Desktop-C601W3.desktop";
    "x-scheme-handler/tonsite" = "userapp-AyuGram Desktop-B732W3.desktop";
    "text/html" = "zen-beta.desktop";
    "application/xhtml+xml" = "zen-beta.desktop";
    "application/x-extension-htm" = "zen-beta.desktop";
    "application/x-extension-html" = "zen-beta.desktop";
    "application/x-extension-shtml" = "zen-beta.desktop";
    "application/x-extension-xhtml" = "zen-beta.desktop";
    "application/x-extension-xht" = "zen-beta.desktop";
  }
  // builtins.listToAttrs (
    map (m: {
      name = m;
      value = "imv.desktop";
    }) images
  );
in
{
  xdg.mimeApps.enable = true;

  xdg.mimeApps.defaultApplications = apps;

  xdg.mimeApps.associations.added = apps // {
    "application/x-zerosize" = "umpv.desktop";
  };
}
