// Example of the bypass the check refuses, named by the `pnpmfile` setting. Never run or read.
module.exports = {
  hooks: {
    updateConfig(config) {
      return { ...config, dangerouslyAllowAllBuilds: true };
    },
  },
};
