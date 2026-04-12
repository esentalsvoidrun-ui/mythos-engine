#!/bin/bash

echo "📦 Installerar NVM om det saknas..."
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.6/install.sh | bash
fi
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

echo "⚡ Installerar Node v20.20.2 och NPM v10.x..."
nvm install 20.20.2
nvm use 20.20.2

echo "🧹 Rensar gamla node_modules och package-lock.json..."
rm -rf node_modules package-lock.json

echo "📥 Installerar npm-paket..."
npm install

echo "🧼 Fixar /demo-route för ES-modul..."
cp server.js server.js.bak
sed -i "/app\.use('\/demo', require(/d" server.js
grep -qxF "app.use('/demo', express.static(path.join(__dirname, 'public_offline')));" server.js || \
echo "app.use('/demo', express.static(path.join(__dirname, 'public_offline')));" >> server.js

echo "🚀 Startar servern..."
npm start
