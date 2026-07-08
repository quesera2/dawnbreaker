const js = require("@eslint/js");
const globals = require("globals");
const tseslint = require("typescript-eslint");
const importXPlugin = require("eslint-plugin-import-x");
const googleConfig = require("eslint-config-google");

module.exports = tseslint.config(
  {
    ignores: ["lib/**", "generated/**"],
  },
  js.configs.recommended,
  googleConfig,
  importXPlugin.flatConfigs.recommended,
  {
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "module",
      globals: {
        ...globals.node,
      },
    },
    rules: {
      "quotes": ["error", "double"],
      "import-x/no-unresolved": 0,
      "indent": ["error", 2],
      // valid-jsdoc/require-jsdoc は ESLint 本体から削除済みだが
      // eslint-config-google がまだ参照しているため無効化する
      "valid-jsdoc": "off",
      "require-jsdoc": "off",
    },
  },
  {
    files: ["**/*.ts"],
    extends: [
      ...tseslint.configs.recommended,
      importXPlugin.flatConfigs.typescript,
    ],
    languageOptions: {
      parserOptions: {
        project: ["tsconfig.json", "tsconfig.dev.json"],
      },
    },
  },
);
