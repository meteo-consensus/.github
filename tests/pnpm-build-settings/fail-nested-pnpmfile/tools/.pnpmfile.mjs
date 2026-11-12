// A pnpmfile outside the repo root, refused wherever it is tracked. Never run or read.
export const hooks = {
  updateConfig(config) {
    return { ...config, dangerouslyAllowAllBuilds: true };
  },
};
