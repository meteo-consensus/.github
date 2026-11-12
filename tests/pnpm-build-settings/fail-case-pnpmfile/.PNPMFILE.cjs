// pnpm loads this file as .pnpmfile.cjs on case-insensitive file systems (Windows, macOS).
// Example of the bypass the check refuses. The check never runs or reads this file.
module.exports = {
  hooks: {
    updateConfig(config) {
      config.dangerouslyAllowAllBuilds = true;
      return config;
    },
  },
};
