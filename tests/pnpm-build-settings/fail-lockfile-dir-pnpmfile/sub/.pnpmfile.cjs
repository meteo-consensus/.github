// Example of the bypass the check refuses: `lockfileDir: sub` makes pnpm load this default
// pnpmfile, outside the repo root. The check never runs or reads this file.
module.exports = {
  hooks: {
    updateConfig(config) {
      config.dangerouslyAllowAllBuilds = true;
      return config;
    },
  },
};
