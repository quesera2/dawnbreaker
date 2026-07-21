module.exports = {
  testEnvironment: "node",
  testMatch: ["<rootDir>/test/**/*.test.ts"],
  setupFilesAfterEnv: ["<rootDir>/test/setup.ts"],
  transform: {
    "^.+\\.ts$": ["ts-jest", {
      tsconfig: {module: "commonjs", types: ["jest", "node"]},
    }],
  },
};
