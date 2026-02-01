#!/bin/bash

# Frontend Deployment Script for S3 + CloudFront
# This script deploys the frontend to AWS S3 and CloudFront

set -e

# Configuration
PROJECT_NAME="potato-disease-frontend"
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BACKEND_API_URL=""  # Will be set from CloudFormation output or user input

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Frontend - AWS S3 + CloudFront      ${NC}"
echo -e "${GREEN}========================================${NC}"

# Check if backend deployment info exists
if [ -f "deployment-info.txt" ]; then
    BACKEND_API_URL=$(grep "API URL:" deployment-info.txt | cut -d' ' -f3)
    echo -e "${GREEN}Found backend API URL: ${BACKEND_API_URL}${NC}"
else
    echo -e "${YELLOW}Enter your backend API URL (e.g., http://potato-alb-xxx.us-east-1.elb.amazonaws.com):${NC}"
    read BACKEND_API_URL
fi

# Step 1: Update frontend configuration
echo -e "\n${YELLOW}Step 1: Updating frontend configuration...${NC}"
cat > frontend/config.js <<EOF
// Configuration for different environments
const CONFIG = {
    development: {
        BACKEND_URL: 'http://localhost:8000',
        API_TIMEOUT: 30000,
        ENABLE_ANALYTICS: false
    },
    production: {
        BACKEND_URL: '${BACKEND_API_URL}',
        API_TIMEOUT: 30000,
        ENABLE_ANALYTICS: true
    }
};

// Auto-detect environment
const ENVIRONMENT = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1' 
    ? 'development' 
    : 'production';

// Export active configuration
const APP_CONFIG = CONFIG[ENVIRONMENT];

console.log(\`🚀 Running in \${ENVIRONMENT} mode\`);
console.log(\`📡 API URL: \${APP_CONFIG.BACKEND_URL}\`);
EOF

echo -e "${GREEN}✓ Frontend configuration updated${NC}"

# Step 2: Deploy CloudFormation stack for S3 + CloudFront
echo -e "\n${YELLOW}Step 2: Creating S3 bucket and CloudFront distribution...${NC}"
echo -e "${YELLOW}This will take 10-15 minutes (CloudFront is slow to provision)...${NC}"

aws cloudformation deploy \
    --template-file aws/cloudformation-frontend.yaml \
    --stack-name ${PROJECT_NAME}-stack \
    --parameter-overrides \
        ProjectName=${PROJECT_NAME} \
        BackendAPIURL=${BACKEND_API_URL} \
    --region ${AWS_REGION}

echo -e "${GREEN}✓ CloudFormation stack deployed${NC}"

# Step 3: Get bucket name and CloudFront info
echo -e "\n${YELLOW}Step 3: Retrieving deployment information...${NC}"

BUCKET_NAME=$(aws cloudformation describe-stacks \
    --stack-name ${PROJECT_NAME}-stack \
    --region ${AWS_REGION} \
    --query 'Stacks[0].Outputs[?OutputKey==`FrontendBucketName`].OutputValue' \
    --output text)

CLOUDFRONT_ID=$(aws cloudformation describe-stacks \
    --stack-name ${PROJECT_NAME}-stack \
    --region ${AWS_REGION} \
    --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontDistributionId`].OutputValue' \
    --output text)

WEBSITE_URL=$(aws cloudformation describe-stacks \
    --stack-name ${PROJECT_NAME}-stack \
    --region ${AWS_REGION} \
    --query 'Stacks[0].Outputs[?OutputKey==`WebsiteURL`].OutputValue' \
    --output text)

echo -e "Bucket: ${BUCKET_NAME}"
echo -e "CloudFront ID: ${CLOUDFRONT_ID}"

# Step 4: Upload frontend files to S3
echo -e "\n${YELLOW}Step 4: Uploading frontend files to S3...${NC}"

aws s3 sync frontend/ s3://${BUCKET_NAME}/ \
    --delete \
    --cache-control "max-age=31536000,public" \
    --exclude "*.html" \
    --region ${AWS_REGION}

# Upload HTML files with shorter cache (they may reference updated assets)
aws s3 sync frontend/ s3://${BUCKET_NAME}/ \
    --cache-control "max-age=3600,must-revalidate" \
    --exclude "*" \
    --include "*.html" \
    --region ${AWS_REGION}

echo -e "${GREEN}✓ Files uploaded to S3${NC}"

# Step 5: Invalidate CloudFront cache
echo -e "\n${YELLOW}Step 5: Invalidating CloudFront cache...${NC}"
aws cloudfront create-invalidation \
    --distribution-id ${CLOUDFRONT_ID} \
    --paths "/*" \
    --region ${AWS_REGION} > /dev/null

echo -e "${GREEN}✓ CloudFront cache invalidated${NC}"

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Frontend Deployment Complete! 🎉    ${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "\n${GREEN}Website URL:${NC} ${WEBSITE_URL}"
echo -e "\n${YELLOW}Note: CloudFront invalidation takes 5-10 minutes to complete.${NC}"

# Append to deployment info
cat >> deployment-info.txt <<EOF

Frontend Deployment
===================
S3 Bucket: ${BUCKET_NAME}
CloudFront ID: ${CLOUDFRONT_ID}
Website URL: ${WEBSITE_URL}
EOF

echo -e "\n${GREEN}✓ Deployment info updated${NC}"
