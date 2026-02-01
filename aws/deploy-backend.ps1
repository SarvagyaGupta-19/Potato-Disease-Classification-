# AWS Deployment Scripts for Potato Disease Classification
# PowerShell version for Windows users

# deploy-backend.ps1 - Backend deployment to ECS Fargate
# Usage: .\aws\deploy-backend.ps1

$ErrorActionPreference = "Stop"

# Configuration
$PROJECT_NAME = "potato-disease-api"
$AWS_REGION = "us-east-1"
$AWS_ACCOUNT_ID = (aws sts get-caller-identity --query Account --output text)
$ECR_REPOSITORY_URI = "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$PROJECT_NAME"

Write-Host "========================================" -ForegroundColor Green
Write-Host "  Potato Disease API - AWS Deployment  " -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

# Check prerequisites
Write-Host "`nChecking prerequisites..." -ForegroundColor Yellow
if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Host "AWS CLI not found. Please install it first." -ForegroundColor Red
    exit 1
}
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "Docker not found. Please install it first." -ForegroundColor Red
    exit 1
}
Write-Host "✓ AWS CLI and Docker are installed" -ForegroundColor Green

# Verify AWS credentials
Write-Host "`nVerifying AWS credentials..." -ForegroundColor Yellow
try {
    aws sts get-caller-identity | Out-Null
    Write-Host "✓ AWS credentials verified" -ForegroundColor Green
    Write-Host "Account ID: $AWS_ACCOUNT_ID"
    Write-Host "Region: $AWS_REGION"
} catch {
    Write-Host "AWS credentials not configured. Run 'aws configure' first." -ForegroundColor Red
    exit 1
}

# Step 1: Create ECR repository
Write-Host "`nStep 1: Setting up ECR repository..." -ForegroundColor Yellow
try {
    aws ecr describe-repositories --repository-names $PROJECT_NAME --region $AWS_REGION 2>$null
} catch {
    aws ecr create-repository --repository-name $PROJECT_NAME --region $AWS_REGION
}
Write-Host "✓ ECR repository created/verified" -ForegroundColor Green

# Step 2: Build Docker image
Write-Host "`nStep 2: Building Docker image..." -ForegroundColor Yellow
docker build -f Dockerfile.aws -t "${PROJECT_NAME}:latest" .
Write-Host "✓ Docker image built successfully" -ForegroundColor Green

# Step 3: Login to ECR
Write-Host "`nStep 3: Authenticating with ECR..." -ForegroundColor Yellow
$password = aws ecr get-login-password --region $AWS_REGION
$password | docker login --username AWS --password-stdin $ECR_REPOSITORY_URI
Write-Host "✓ Logged in to ECR" -ForegroundColor Green

# Step 4: Tag and push image
Write-Host "`nStep 4: Pushing image to ECR..." -ForegroundColor Yellow
docker tag "${PROJECT_NAME}:latest" "${ECR_REPOSITORY_URI}:latest"
docker push "${ECR_REPOSITORY_URI}:latest"
Write-Host "✓ Image pushed to ECR" -ForegroundColor Green

# Step 5: Create/Update secret
Write-Host "`nStep 5: Setting up secrets..." -ForegroundColor Yellow
$GEMINI_API_KEY = Read-Host "Enter your GEMINI_API_KEY" -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($GEMINI_API_KEY)
$GEMINI_KEY_PLAIN = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

try {
    $SECRET_ARN = aws secretsmanager describe-secret --secret-id potato-disease/gemini-api-key --region $AWS_REGION --query ARN --output text 2>$null
    if ($SECRET_ARN) {
        aws secretsmanager update-secret --secret-id potato-disease/gemini-api-key --secret-string "{`"GEMINI_API_KEY`":`"$GEMINI_KEY_PLAIN`"}" --region $AWS_REGION | Out-Null
        Write-Host "✓ Secret updated" -ForegroundColor Green
    }
} catch {
    $SECRET_ARN = aws secretsmanager create-secret --name potato-disease/gemini-api-key --secret-string "{`"GEMINI_API_KEY`":`"$GEMINI_KEY_PLAIN`"}" --region $AWS_REGION --query ARN --output text
    Write-Host "✓ Secret created" -ForegroundColor Green
}
Write-Host "Secret ARN: $SECRET_ARN"

# Step 6: Deploy CloudFormation stack
Write-Host "`nStep 6: Deploying CloudFormation stack..." -ForegroundColor Yellow
Write-Host "This will take 5-10 minutes..." -ForegroundColor Yellow

aws cloudformation deploy `
    --template-file aws/cloudformation-ecs-stack.yaml `
    --stack-name "$PROJECT_NAME-stack" `
    --parameter-overrides ProjectName=$PROJECT_NAME ECRImageURI="${ECR_REPOSITORY_URI}:latest" GeminiSecretArn=$SECRET_ARN Environment=production `
    --capabilities CAPABILITY_IAM `
    --region $AWS_REGION

Write-Host "✓ CloudFormation stack deployed" -ForegroundColor Green

# Step 7: Get outputs
Write-Host "`nStep 7: Retrieving deployment information..." -ForegroundColor Yellow
$ALB_URL = aws cloudformation describe-stacks --stack-name "$PROJECT_NAME-stack" --region $AWS_REGION --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' --output text

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "  Deployment Complete! 🎉            " -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "`nAPI URL: $ALB_URL" -ForegroundColor Green
Write-Host "API Docs: $ALB_URL/docs" -ForegroundColor Green
Write-Host "`nNote: It may take 1-2 minutes for the service to become healthy." -ForegroundColor Yellow

# Save deployment info
@"
Deployment Information
=====================
Date: $(Get-Date)
Region: $AWS_REGION
ECR Repository: $ECR_REPOSITORY_URI
API URL: $ALB_URL
Secret ARN: $SECRET_ARN
CloudFormation Stack: $PROJECT_NAME-stack
"@ | Out-File -FilePath deployment-info.txt

Write-Host "`n✓ Deployment info saved to deployment-info.txt" -ForegroundColor Green
