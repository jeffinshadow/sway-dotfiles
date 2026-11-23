// user.js — Shadow Materia (ligado em cada perfil pelo install.sh).
// O Firefox reaplica estas prefs a cada abertura.

// Carrega chrome/userChrome.css e chrome/userContent.css
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
// Interface e páginas em modo escuro (sites que respeitam prefers-color-scheme)
user_pref("browser.theme.toolbar-theme", 0);
user_pref("browser.theme.content-theme", 0);
user_pref("layout.css.prefers-color-scheme.content-override", 0);
// Tema base "System theme — auto": o userChrome.css pinta por cima
user_pref("extensions.activeThemeID", "default-theme@mozilla.org");

// Vídeo por hardware (VA-API na RX 9050: H.264, HEVC, VP9, AV1) — no AMD já é o
// padrão; forçado pra não cair no software se algum bloqueio mudar.
user_pref("media.ffmpeg.vaapi.enabled", true);
user_pref("media.hardware-video-decoding.force-enabled", true);
