module.exports = {
  env: {
    es2022: true,
    node: true,
  },
  parserOptions: {
    ecmaVersion: 2022,
    sourceType: 'module',
  },
  extends: ['eslint:recommended', 'google'],
  rules: {
    'quotes': 'off',
    'eol-last': 'off',
    'require-jsdoc': 'off',
    'max-len': 'off',
    'indent': 'off',
    'object-curly-spacing': 'off',
    'comma-dangle': 'off',
    'no-restricted-globals': 'off',
    'prefer-arrow-callback': 'off',
    'quote-props': 'off',
  },
};