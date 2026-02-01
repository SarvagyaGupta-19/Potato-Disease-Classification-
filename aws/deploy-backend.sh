#!/bin/bash

# AWS Deployment Script for Potato Disease Classification
# This script automates the deployment process to AWS ECS Fargate

set -e  # Exit on error

# Configuration
PROJECT_NAME="potato-disease-api"
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPOSITORY_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_NAME}"
GEMINI_API_KEY=""  # Set this or pass as environment variable

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Potato Disease API - AWS Deployment  ${NC}"
echo -e "${GREEN}========================================${NC}"

# Check prerequisites
echo -e "\n${YELLOW}Checking prerequisites...${NC}"

command -v aws >/dev/null 2>&1 || { echo -e "${RED}AWS CLI not found. Please install it first.${NC}"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo -e "${RED}Docker not found. Please install it first.${NC}"; exit 1; }

echo -e "${GREEN}✓ AWS CLI and Docker are installed${NC}"

# Verify AWS credentials
echo -e "\n${YELLOW}Verifying AWS credentials...${NC}"
aws sts get-caller-identity > /dev/null || { echo -e "${RED}AWS credentials not configured. Run 'aws configure' first.${NC}"; exit 1; }
echo -e "${GREEN}✓ AWS credentials verified${NC}"
echo -e "Account ID: ${AWS_ACCOUNT_ID}"
echo -e "Region: ${AWS_REGION}"

# Step 1: Create ECR repository if it doesn't exist
echo -e "\n${YELLOW}Step 1: Setting up ECR repository...${NC}"
aws ecr describe-repositories --repository-names ${PROJECT_NAME} --region ${AWS_REGION} 2>/dev/null || \
    aws ecr create-repository --repository-name ${PROJECT_NAME} --region ${AWS_REGION} && \
    echo -e "${GREEN}✓ ECR repository created/verified${NC}"

# Step 2: Build Docker image
echo -e "\n${YELLOW}Step 2: Building Docker image...${NC}"
docker build -f Dockerfile.aws -t ${PROJECT_NAME}:latest .
echo -e "${GREEN}✓ Docker image built successfully${NC}"

# Step 3: Login to ECR
echo -e "\n${YELLOW}Step 3: Authenticating with ECR...${NC}"
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPOSITORY_URI}
echo -e "${GREEN}✓ Logged in to ECR${NC}"

# Step 4: Tag and push image
echo -e "\n${YELLOW}Step 4: Pushing image to ECR...${NC}"
docker tag ${PROJECT_NAME}:latest ${ECR_REPOSITORY_URI}:latest
docker push ${ECR_REPOSITORY_URI}:latest
echo -e "${GREEN}✓ Image pushed to ECR${NC}"

# Step 5: Create/Update secret in Secrets Manager
echo -e "\n${YELLOW}Step 5: Setting up secrets...${NC}"
if [ -z "$GEMINI_API_KEY" ]; then
    echo -e "${YELLOW}GEMINI_API_KEY not set. Please enter it now:${NC}"
    read -s GEMINI_API_KEY
fi

# Check if secret exists
SECRET_ARN=$(aws secretsmanager describe-secret --secret-id potato-disease/gemini-api-key --region ${AWS_REGION} --query ARN --output text 2>/dev/null || echo "")

if [ -z "$SECRET_ARN" ]; then
    # Create new secret
    SECRET_ARN=$(aws secretsmanager create-secret \
        --name potato-disease/gemini-api-key \
        --secret-string "{\"GEMINI_API_KEY\":\"${GEMINI_API_KEY}\"}" \
        --region ${AWS_REGION} \
        --query ARN --output text)
    echo -e "${GREEN}✓ Secret created${NC}"
else
    # Update existing secret
    aws secretsmanager update-secret \
        --secret-id potato-disease/gemini-api-key \
        --secret-string "{\"GEMINI_API_KEY\":\"${GEMINI_API_KEY}\"}" \
        --region ${AWS_REGION} > /dev/null
    echo -e "${GREEN}✓ Secret updated${NC}"
fi

echo -e "Secret ARN: ${SECRET_ARN}"

# Step 6: Deploy CloudFormation stack
echo -e "\n${YELLOW}Step 6: Deploying CloudFormation stack...${NC}"
echo -e "${YELLOW}This will take 5-10 minutes...${NC}"

aws cloudformation deploy \
    --template-file aws/cloudformation-ecs-stack.yaml \
    --stack-name ${PROJECT_NAME}-stack \
    --parameter-overrides \
        ProjectName=${PROJECT_NAME} \
        ECRImageURI=${ECR_REPOSITORY_URI}:latest \
        GeminiSecretArn=${SECRET_ARN} \
        Environment=production \
    --capabilities CAPABILITY_IAM \
    --region ${AWS_REGION}

echo -e "${GREEN}✓ CloudFormation stack deployed${NC}"

# Step 7: Get outputs
echo -e "\n${YELLOW}Step 7: Retrieving deployment information...${NC}"
ALB_URL=$(aws cloudformation describe-stacks \
    --stack-name ${PROJECT_NAME}-stack \
    --region ${AWS_REGION} \
    --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' \
    --output text)

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Deployment Complete! 🎉            ${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "\n${GREEN}API URL:${NC} ${ALB_URL}"
echo -e "${GREEN}API Docs:${NC} ${ALB_URL}/docs"
echo -e "${GREEN}Health Check:${NC} ${ALB_URL}/docs"
echo -e "\n${YELLOW}Note: It may take 1-2 minutes for the service to become healthy.${NC}"
echo -e "\n${YELLOW}Next Steps:${NC}"
echo -e "1. Update frontend config.js with the API URL above"
echo -e "2. Deploy frontend using: ./deploy-frontend.sh"
echo -e "3. Configure custom domain (optional)"
echo -e "4. Set up CloudWatch alarms for monitoring"

# Save deployment info
cat > deployment-info.txt <<EOF
Deployment Information
=====================
Date: $(date)
Region: ${AWS_REGION}
ECR Repository: ${ECR_REPOSITORY_URI}
API URL: ${ALB_URL}
Secret ARN: ${SECRET_ARN}
CloudFormation Stack: ${PROJECT_NAME}-stack
EOF

echo -e "\n${GREEN}✓ Deployment info saved to deployment-info.txt${NC}"
