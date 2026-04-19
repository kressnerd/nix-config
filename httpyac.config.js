// httpyac.config.js — workspace-root entry point
//
// httpYac VS Code extension always looks for httpyac.config.js in the
// workspace root. This file delegates to the actual config in infra/http/.
const path = require('path');

module.exports = require(path.join(__dirname, 'infra', 'http', 'httpyac.config.js'));
