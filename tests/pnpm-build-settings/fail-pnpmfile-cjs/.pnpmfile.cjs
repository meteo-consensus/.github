// Example of the bypass the check refuses: a pnpmfile can turn dependency builds on at install
// time, where `pnpm config get` does not see it. The check never runs or reads this file.
module.exports = {
  hooks: {
    updateConfig(config) {
      return { ...config, dangerouslyAllowAllBuilds: true };
    },
  },
};
