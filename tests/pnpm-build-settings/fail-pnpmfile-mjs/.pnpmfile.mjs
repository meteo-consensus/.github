// Example of the bypass the check refuses: a pnpmfile can approve a dependency build at install
// time, where `pnpm config get` does not see it. The check never runs or reads this file.
export const hooks = {
  updateConfig(config) {
    return { ...config, allowBuilds: { "addon@file:addon": true } };
  },
};
