import typescriptEslint from '@typescript-eslint/eslint-plugin';
import prettier from 'eslint-plugin-prettier';
import globals from 'globals';
import tsParser from '@typescript-eslint/parser';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import js from '@eslint/js';
import { FlatCompat } from '@eslint/eslintrc';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const compat = new FlatCompat({
    baseDirectory: __dirname,
    recommendedConfig: js.configs.recommended,
    allConfig: js.configs.all,
});

export default [
    ...compat.extends('eslint:recommended', 'plugin:@typescript-eslint/recommended', 'prettier'),
    {
        plugins: {
            '@typescript-eslint': typescriptEslint,
            prettier,
        },
        languageOptions: {
            globals: {
                ...globals.browser,
            },

            parser: tsParser,
            ecmaVersion: 2021,
            sourceType: 'module',
        },
        rules: {
            '@typescript-eslint/no-unused-vars': 'warn',
            'array-callback-return': 1,
            semi: ['warn', 'always'],
            'no-void': 0,
            '@typescript-eslint/no-confusing-void-expression': 0,
            '@typescript-eslint/no-explicit-any': 'warn',
            'prettier/prettier': 1,
            '@typescript-eslint/adjacent-overload-signatures': 'warn',
            '@typescript-eslint/ban-ts-comment': 'warn',
            'no-case-declarations': 'warn',
            'no-sparse-arrays': 'warn',
            'no-regex-spaces': 'warn',
            'use-isnan': 'warn',
            'no-fallthrough': 'warn',
            'no-empty-pattern': 'warn',
            'no-redeclare': 'warn',
            'no-self-assign': 'warn',
            '@typescript-eslint/semi': 0,
            '@typescript-eslint/indent': 0,
            'eslint@typescript-eslint/member-delimiter-style': 0,
            strict: 'error',
            '@typescript-eslint/strict-boolean-expressions': 0,
            '@typescript-eslint/prefer-nullish-coalescing': 0,
            '@typescript-eslint/explicit-function-return-type': 0,
            '@typescript-eslint/no-non-null-assertion': 0,
            'sort-imports': [
                'warn',
                {
                    ignoreCase: true,
                    ignoreDeclarationSort: true,
                },
            ],
            'no-undef': 'off',
        },
    },
];
