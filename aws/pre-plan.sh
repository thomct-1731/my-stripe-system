#!/bin/bash
ENV=$1
SERVICE=$2

echo "🔍 Pre-plan validation..."

# Check Lambda packages
REQUIRED_PACKAGES=(
    "webhook_handler.zip"
    "email_processor.zip"
    "inventory_processor.zip"
    "database_processor.zip"
)

SERVICE_DIR="terraform/envs/${ENV}/3.${SERVICE}"

for package in "${REQUIRED_PACKAGES[@]}"; do
    if [ ! -f "${SERVICE_DIR}/${package}" ]; then
        echo "❌ Missing: ${package}"
        echo "Run: ./build-lambda-packages.sh ${ENV} ${SERVICE}"
        exit 1
    fi
done

echo "✅ All Lambda packages found"
