// httpyac.config.js — gnome-keyring integration for netcup SCP tokens
//
// Reads/writes the shared "netcup-scp credentials" secret from gnome-keyring
// (same entry used by scripts/netcup_firewall.py --keyring).
//
// Provides: access_token, refresh_token, user_id (when present in keyring)
// No in-memory caching — every provideVariables call reads fresh from secret-tool
// (<100ms) so Request 3's newly saved access_token is immediately visible to
// Request 4 without any manual cache invalidation.
const { execSync } = require('child_process');

const KEYRING_LABEL = 'netcup-scp credentials';
const KEYRING_LOOKUP = 'secret-tool lookup service netcup-scp username default';
const KEYRING_STORE = 'secret-tool store --label="netcup-scp credentials" service netcup-scp username default';

function loadFromKeyring() {
  try {
    const raw = execSync(KEYRING_LOOKUP, {
      encoding: 'utf8',
      timeout: 5000,
    }).trim();
    if (!raw) {
      console.warn('[httpyac] gnome-keyring: no entry found for netcup-scp — run device auth flow first (requests 1+2).');
      return {};
    }
    return JSON.parse(raw);
  } catch (e) {
    if (e.message && e.message.includes('not found')) {
      console.error('[httpyac] secret-tool not found — install libsecret (pkgs.libsecret) and rebuild home-manager.');
    } else {
      console.warn('[httpyac] gnome-keyring lookup failed:', e.message);
    }
    return {};
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

module.exports = {
  loadFromKeyring,
  saveToKeyring,
  mergeAndSave,
  configureHooks: function (api) {
    api.hooks.provideVariables.addHook('gnome-keyring', function () {
      const creds = loadFromKeyring();
      const vars = {};
      if (creds.access_token) {
        vars.access_token = creds.access_token;
      }
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
