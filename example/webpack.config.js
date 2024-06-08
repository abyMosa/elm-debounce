const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const openBrowser = require("react-dev-utils/openBrowser");

const DEVELOPMENT = "development";
const PORT = 8080;

module.exports = (env, args) => {

  return {
    entry: './index.ts',
    output: {
      path: path.resolve(__dirname, 'dist'),
      filename: '[name].js',
    },
    module: {
      rules: [
        {
          test: /\.elm$/,
          exclude: [/elm-stuff/, /node_modules/],
          use: {
            loader: 'elm-webpack-loader',
            options: {
              verbose: true,
              debug: args.mode === DEVELOPMENT,
            },
          },
        },
        {
          test: /\.(p?css)$/,
          use: [
            { loader: MiniCssExtractPlugin.loader },
            { loader: 'css-loader', options: { importLoaders: 1 } },
            { loader: 'postcss-loader' }
          ],
        },
      ],
    },
    resolve: {
      extensions: ['.tsx', '.ts', '.js'],
    },
    plugins: [
      new HtmlWebpackPlugin({
        template: 'index.html',
      }),
      new MiniCssExtractPlugin({
        filename: `css/[name]${args.mode === DEVELOPMENT ? '' : '[hash]'}.css`,
        chunkFilename: `css/[id]${args.mode === DEVELOPMENT ? '' : '[hash]'}.css`,
      }),
    ],
    devServer: {
      open: false,
      port: PORT,
      hot: false,
      historyApiFallback: true,
      onListening: function(devServer) {
        console.log('devServer', devServer.server.address());
        // const { port } = server.listeningApp.address();
        const addr = devServer.server.address();
        openBrowser(`http://localhost:${addr.port}`)
      },
    },
  }
};
