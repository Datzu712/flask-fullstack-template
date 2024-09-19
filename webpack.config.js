const path = require('path');
const fs = require('fs');
const ESLintPlugin = require('eslint-webpack-plugin');

const isProduction = process.env.NODE_ENV == 'production';
const TS_FILES = './src/ts';

const entries = fs.readdirSync(TS_FILES)
    .filter((filename) => fs.lstatSync(path.resolve(TS_FILES, filename)).isFile())
    .map((filename) => ({
        [filename.replace('.ts', '').replace('.js', '')]: [path.resolve(TS_FILES, filename), ...(filename === 'main.ts' ? [] : [path.resolve(`${TS_FILES}/main.ts`)])],
    })).reduce((acc, entry) => ({ ...acc, ...entry }), {});

    console.log(entries)
const config = {
    entry: entries,
    context: path.resolve(__dirname, TS_FILES),
    output: {
        filename: '[name].bundle.js',
        path: path.resolve(__dirname, 'app/static/js')
    },
    plugins: [
        new ESLintPlugin({
            extensions: ['ts'],
            exclude: ['node_modules'],
            fix: false,
        }),
    ],
    module: {
        rules: [
            {
                test: /\.(ts|tsx)$/i,
                loader: 'ts-loader',
                exclude: ['/node_modules/'],
            },
            {
                test: /\.css$/,
                use: ['style-loader', 'css-loader']
            },
            {
                test: /\.(eot|svg|ttf|woff|woff2|png|jpg|gif)$/i,
                type: 'asset',
            },
        ],
    },
    resolve: {
        extensions: ['.ts', '.js'],
    },
    watchOptions: {
        ignored: /node_modules/
    },
    devtool: false,
};

module.exports = () => {
    if (isProduction) {
        config.mode = 'production';
    } else {
        config.mode = 'development';
    }
    return config;
};
