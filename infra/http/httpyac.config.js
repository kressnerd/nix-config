// httpyac.config.js — gnome-keyring integration for netcup SCP tokens
//
// Reads/writes the shared "netcup-scp credentials" secret from gnome-keyring
// (same entry used by scripts/netcup_firewall.py --keyring).
//
// Provides: refresh_token, user_id (when present in keyring)
// The access_token from keyring is NOT injected here because $global
// takes precedence after a fresh refresh — see 00-auth.http request 3.
const { execSync } = require('child_process');

const KEYRING_LABEL = 'netcup-scp credentials';
const KEYRING_LOOKUP = 'secret-tool lookup service netcup-scp username default';
const KEYRING_STORE = 'secret-tool store --label="netcup-scp credentials" service netcup-scp username default';

let _cachedCredentials = null;

function loadFromKeyring() {
  if (_cachedCredentials !== null) {
    return _cachedCredentials;
  }
  try {
    const raw = execSync(KEYRING_LOOKUP, {
      encoding: 'utf8',
      timeout: 5000,
    }).trim();
    if (!raw) {
      console.warn('[httpyac] gnome-keyring: no entry found for netcup-scp');
      _cachedCredentials = {};
      return _cachedCredentials;
    }
    _cachedCredentials = JSON.parse(raw);
    return _cachedCredentials;
  } catch (e) {
    console.warn('[httpyac] gnome-keyring lookup failed:', e.message);
    _cachedCredentials = {};
    return _cachedCredentials;
  }
}

function saveToKeyring(data) {
  try {
    const secret = JSON.stringify(data);
    execSync(KEYRING_STORE, {
      input: secret,
      encoding: 'utf8',
      timeout: 5000,
    });
    _cachedCredentials = data;
  } catch (e) {
    console.warn('[httpyac] Failed to save to gnome-keyring:', e.message);
  }
}

function mergeAndSave(newFields) {
  const existing = loadFromKeyring();
  const merged = Object.assign({}, existing, newFields);
  saveToKeyring(merged);
  return merged;
}

function resetCache() {
  _cachedCredentials = null;
}

module.exports = {
  loadFromKeyring,
  saveToKeyring,
  mergeAndSave,
  resetCache,
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
