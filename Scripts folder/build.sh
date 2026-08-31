#!/bin/bash

set -e

echo "=============================="
echo "Frontend Build"
echo "=============================="

cd frontend

npm ci
npm run build

cd ..

echo "=============================="
echo "Backend Build"
echo "=============================="

cd backend

go mod download
go test ./...
go build -o server main.go

cd ..

echo "Build completed successfully."
