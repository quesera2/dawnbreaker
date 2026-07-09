module.exports = {
  testEnvironment: "node",
  testMatch: ["<rootDir>/test/**/*.test.ts"],
  transform: {
    "^.+\\.ts$": ["ts-jest", {
      tsconfig: {module: "commonjs", types: ["jest", "node"]},
    }],
  },
};
