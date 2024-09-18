const path = require('path');
const fs = require('fs');

const isProduction = process.env.NODE_ENV == 'production';
const TS_FILES = './src/ts';

const entries = fs.readdirSync(TS_FILES)
    .filter((filename) => fs.lstatSync(path.resolve(TS_FILES, filename)).isFile())
    .map((filename) => ({
        [filename.replace('.ts', '').replace('.js', '')]: path.resolve(TS_FILES, filename),
    })).reduce((acc, entry) => ({ ...acc, ...entry }), {});

const config = {
    entry: entries,
    output: {
        filename: '[name].bundle.js',
        path: path.resolve(__dirname, 'app/static/js')
    },
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
};

module.exports = () => {
    if (true || isProduction) {
        config.mode = 'production';
    } else {
        config.mode = 'development';
    }
    return config;
};
