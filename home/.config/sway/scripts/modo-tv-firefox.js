// Perfil do Firefox do modo TV (copiado pra ~/.local/share/modo-tv/firefox/user.js pelo modo-tv.sh)
user_pref("media.eme.enabled", true);                        // DRM (HBO Max)
user_pref("media.gmp-widevinecdm.enabled", true);
user_pref("media.gmp-widevinecdm.visible", true);
user_pref("media.autoplay.default", 0);
user_pref("media.ffmpeg.vaapi.enabled", true);
user_pref("media.hardware-video-decoding.force-enabled", true);
user_pref("full-screen-api.warning.timeout", 0);
user_pref("full-screen-api.transition-duration.enter", "0 0");
user_pref("full-screen-api.transition-duration.leave", "0 0");
user_pref("browser.aboutwelcome.enabled", false);
user_pref("browser.startup.homepage_override.mstone", "ignore");
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.sessionstore.resume_from_crash", false);
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("toolkit.telemetry.reportingpolicy.firstRun", false);
user_pref("layout.css.prefers-color-scheme.content-override", 0);
user_pref("intl.accept_languages", "pt-BR, pt, en-US, en");
user_pref("signon.rememberSignons", true);
