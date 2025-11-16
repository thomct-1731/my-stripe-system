#!/bin/bash
set -e

ENV=${1:-dev}
SERVICE=${2:-order-processing}

echo "🔨 Building Lambda packages for ${ENV}/3.${SERVICE}..."

LAMBDA_SRC="terraform-dependencies/lambda-function"
LAMBDA_DEST="terraform/envs/${ENV}/3.${SERVICE}"

# Build each Lambda function
for func in webhook-handler email-processor inventory-processor database-processor; do
    echo "📦 Building ${func}..."

    cd ${LAMBDA_SRC}/${func}

    # Install dependencies if requirements.txt exists
    if [ -f requirements.txt ]; then
        pip install -r requirements.txt -t . --no-cache-dir --quiet
    fi

    # Create zip package with proper naming
    PACKAGE_NAME=$(echo ${func} | tr '-' '_')
    zip -r ../../../${LAMBDA_DEST}/${PACKAGE_NAME}.zip . \
        -x "*.pyc" \
        -x "__pycache__/*" \
        -x "*.dist-info/*" \
        -x "requirements.txt" \
        -q

    echo "✅ ${func} packaged as ${PACKAGE_NAME}.zip"

    cd ../../..
done

echo ""
echo "✨ All Lambda packages built successfully!"
echo ""
echo "Packages location:"
ls -lh ${LAMBDA_DEST}/*.zip
