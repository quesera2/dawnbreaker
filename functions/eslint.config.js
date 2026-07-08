const {FlatCompat} = require("@eslint/eslintrc");
const js = require("@eslint/js");
const globals = require("globals");
const tseslint = require("typescript-eslint");
const importXPlugin = require("eslint-plugin-import-x");

const compat = new FlatCompat({
  baseDirectory: __dirname,
  recommendedConfig: js.configs.recommended,
});

module.exports = tseslint.config(
  {
    ignores: ["lib/**", "generated/**"],
  },
  js.configs.recommended,
  ...compat.extends("google"),
  ...tseslint.configs.recommended,
  importXPlugin.flatConfigs.recommended,
  importXPlugin.flatConfigs.typescript,
  {
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "module",
      globals: {
        ...globals.node,
      },
      parser: tseslint.parser,
      parserOptions: {
        project: ["tsconfig.json", "tsconfig.dev.json"],
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
    files: ["eslint.config.js", "jest.config.js"],
    rules: {
      "@typescript-eslint/no-require-imports": "off",
    },
  },
);
