import * as mdx from 'eslint-plugin-mdx';

export default [
  {
    ignores: ['node_modules/**', '**/node_modules/**'],
  },
  {
    ...mdx.flat,
    files: ['**/*.md', '**/*.mdx'],
    processor: mdx.createRemarkProcessor({
      lintCodeBlocks: false,
    }),
    rules: {
      ...mdx.flat.rules,
      'mdx/remark': 'error',
    },
  },
  {
    ...mdx.flatCodeBlocks,
    files: ['**/*.md', '**/*.mdx'],
    rules: {
      ...mdx.flatCodeBlocks.rules,
    },
  },
];
