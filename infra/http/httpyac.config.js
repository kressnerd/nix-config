// httpyac.config.js — gnome-keyring integration for netcup SCP tokens
//
// Reads the shared "netcup-scp credentials" secret from gnome-keyring
// (same entry used by scripts/netcup_firewall.py --keyring).
//
// Provides: refresh_token (for token refresh requests)
// The access_token from keyring is NOT injected here because $global
// takes precedence after a fresh refresh — see 00-auth.http request 3.
const { execSync } = require('child_process');

let _cachedCredentials = null;

function loadFromKeyring() {
  if (_cachedCredentials !== null) {
    return _cachedCredentials;
  }
  try {
    const raw = execSync(
      'secret-tool lookup service netcup-scp username default',
      { encoding: 'utf8', timeout: 5000 }
    ).trim();
    _cachedCredentials = JSON.parse(raw);
    return _cachedCredentials;
  } catch (e) {
    _cachedCredentials = {};
    return _cachedCredentials;
  }
}

module.exports = {
  configureHooks: function (api) {
    api.hooks.provideVariables.addHook('gnome-keyring', function () {
      const creds = loadFromKeyring();
      const vars = {};
      if (creds.refresh_token) {
        vars.refresh_token = creds.refresh_token;
      }
      if (creds.user_id) {
        vars.user_id = creds.user_id;
      }
      return vars;
    });
  },
};
