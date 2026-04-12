#!/bin/bash

echo "🧹 Cleaning port 3001..."
fuser -k 3001/tcp 2>/dev/null

echo "🚀 Starting server..."
npm start
