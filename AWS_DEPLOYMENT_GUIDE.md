# 🚀 AWS Deployment Guide for Potato Disease Classification

## 📋 Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Deployment Options Comparison](#deployment-options-comparison)
3. [Recommended: AWS ECS Fargate Deployment](#recommended-aws-ecs-fargate-deployment)
4. [Alternative: AWS Elastic Beanstalk](#alternative-aws-elastic-beanstalk)
5. [Frontend Deployment with S3 & CloudFront](#frontend-deployment-with-s3--cloudfront)
6. [Cost Optimization](#cost-optimization)
7. [Security Best Practices](#security-best-practices)
8. [Monitoring & Logging](#monitoring--logging)

---

## 🏗️ Architecture Overview

### Recommended AWS Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         AWS Cloud                            │
│                                                              │
│  ┌──────────────┐         ┌─────────────────────────────┐  │
│  │ CloudFront   │────────▶│  S3 Static Website          │  │
│  │  (CDN)       │         │  (Frontend - HTML/CSS/JS)   │  │
│  └──────────────┘         └─────────────────────────────┘  │
│         │                                                    │
│         │ API Requests                                      │
│         ▼                                                    │
│  ┌──────────────────────────────────────────────────────┐  │
│  │        Application Load Balancer (ALB)               │  │
│  │           HTTPS with SSL/TLS Certificate             │  │
│  └──────────────────────────────────────────────────────┘  │
│         │                                                    │
│         ▼                                                    │
│  ┌─────────────────────────────────────────┐               │
│  │        AWS ECS Fargate Cluster          │               │
│  │  ┌─────────────────────────────────┐   │               │
│  │  │  FastAPI Backend (Container)     │   │               │
│  │  │  - TensorFlow Model              │   │               │
│  │  │  - Disease Detection API         │   │               │
│  │  │  - Chatbot Endpoint              │   │               │
│  │  └─────────────────────────────────┘   │               │
│  │         Auto Scaling (1-3 tasks)        │               │
│  └─────────────────────────────────────────┘               │
│         │                                                    │
│         ▼                                                    │
│  ┌──────────────┐         ┌─────────────┐                  │
│  │  AWS Secrets │         │  CloudWatch │                  │
│  │   Manager    │         │   Logs      │                  │
│  │ (GEMINI_KEY) │         │             │                  │
│  └──────────────┘         └─────────────┘                  │
│         │                         │                         │
│         ▼                         ▼                         │
│  ┌──────────────────────────────────────┐                  │
│  │  S3 Bucket (Model Storage - Optional)│                  │
│  │  - best_model.keras                  │                  │
│  └──────────────────────────────────────┘                  │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 Deployment Options Comparison

| Feature | ECS Fargate | Elastic Beanstalk | Lambda + API Gateway |
|---------|-------------|-------------------|----------------------|
| **Cost (Monthly)** | $15-30 | $20-40 | $5-15 (for low traffic) |
| **Scalability** | Excellent | Good | Excellent |
| **Cold Start** | None | None | Yes (3-5s) |
| **ML Model Support** | ✅ Perfect | ✅ Good | ⚠️ Limited (package size) |
| **Setup Complexity** | Medium | Easy | Complex |
| **Best For** | Production ML apps | Quick deployments | Serverless/Low traffic |
| **Free Tier** | Limited | Limited | Generous |

**Recommendation**: **AWS ECS Fargate** for production-grade ML applications.

---

## 🎯 Recommended: AWS ECS Fargate Deployment

### Prerequisites
- AWS Account (Free Tier eligible)
- AWS CLI installed and configured
- Docker installed locally
- Domain name (optional but recommended)

### Step-by-Step Deployment

#### 1. **Prepare Docker Image**

Your existing `Dockerfile.free` needs minor modifications for AWS.

#### 2. **Create ECR Repository**

```bash
# Create Elastic Container Registry repository
aws ecr create-repository --repository-name potato-disease-api --region us-east-1

# Authenticate Docker to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <YOUR_AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com

# Build and tag image
docker build -f Dockerfile.aws -t potato-disease-api:latest .
docker tag potato-disease-api:latest <YOUR_AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/potato-disease-api:latest

# Push to ECR
docker push <YOUR_AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/potato-disease-api:latest
```

#### 3. **Store Secrets in AWS Secrets Manager**

```bash
# Store your Gemini API key securely
aws secretsmanager create-secret \
    --name potato-disease/gemini-api-key \
    --secret-string '{"GEMINI_API_KEY":"your-actual-api-key-here"}' \
    --region us-east-1
```

#### 4. **Deploy Using CloudFormation**

Use the provided `cloudformation-ecs-stack.yaml` template.

```bash
aws cloudformation create-stack \
    --stack-name potato-disease-app \
    --template-body file://aws/cloudformation-ecs-stack.yaml \
    --parameters ParameterKey=GeminiSecretArn,ParameterValue=arn:aws:secretsmanager:us-east-1:xxx:secret:potato-disease/gemini-api-key \
    --capabilities CAPABILITY_IAM \
    --region us-east-1
```

#### 5. **Configure Auto Scaling**

Auto-scaling is included in the CloudFormation template:
- **Min tasks**: 1
- **Max tasks**: 3
- **Target CPU**: 70%
- **Scale-out**: Add task when CPU > 70%
- **Scale-in**: Remove task when CPU < 30%

---

## 🔄 Alternative: AWS Elastic Beanstalk

For simpler deployment with less control but faster setup.

### Deployment Steps

```bash
# Install EB CLI
pip install awsebcli

# Initialize Elastic Beanstalk
eb init -p docker potato-disease-app --region us-east-1

# Create environment
eb create potato-disease-prod --instance-type t3.small --envvars GEMINI_API_KEY=your-key

# Deploy
eb deploy

# Open in browser
eb open
```

---

## 🌐 Frontend Deployment with S3 & CloudFront

### Step 1: Create S3 Bucket for Static Website

```bash
# Create bucket
aws s3 mb s3://potato-disease-frontend --region us-east-1

# Configure for static website
aws s3 website s3://potato-disease-frontend --index-document index.html

# Upload frontend files
aws s3 sync frontend/ s3://potato-disease-frontend --acl public-read
```

### Step 2: Create CloudFront Distribution

Use the provided `cloudformation-frontend.yaml` or AWS Console:

1. Origin: S3 bucket
2. Enable HTTPS
3. Enable gzip compression
4. Cache policy: CachingOptimized
5. Custom domain (optional)

---

## 💰 Cost Optimization

### Monthly Cost Estimate (AWS)

| Service | Usage | Est. Cost |
|---------|-------|-----------|
| **ECS Fargate** | 1 task (0.5 vCPU, 1GB) running 24/7 | $15 |
| **Application Load Balancer** | 1 ALB with low traffic | $16 |
| **S3** | Frontend hosting + model storage (5GB) | $0.12 |
| **CloudFront** | 100GB data transfer | $8.50 |
| **Secrets Manager** | 1 secret | $0.40 |
| **CloudWatch Logs** | 5GB logs | $2.50 |
| **ECR** | 1GB image storage | $0.10 |
| **Total** | | **~$42/month** |

### Cost Reduction Strategies

1. **Use Free Tier Wisely**:
   - First 12 months: Some services free
   - Always free: Lambda (1M requests), S3 (5GB), CloudWatch (10 metrics)

2. **Optimize Container Resources**:
   ```yaml
   # In task definition
   cpu: 512  # 0.5 vCPU instead of 1
   memory: 1024  # 1GB instead of 2GB
   ```

3. **Use Spot Instances for ECS** (70% savings):
   - Not recommended for production but great for dev/staging

4. **CloudFront Caching**:
   - Set high TTL for static assets
   - Reduces origin requests

5. **Schedule Task Scaling**:
   - Scale down during low-traffic hours (night)
   - Use AWS Lambda to schedule

6. **Alternative: AWS Lightsail**:
   - Fixed pricing: $10/month for 1GB RAM container
   - Simpler but less scalable

---

## 🔒 Security Best Practices

### 1. **Network Security**

```yaml
# Security Group Configuration
VPC:
  - Private subnet for ECS tasks
  - Public subnet for ALB only
  
Security Groups:
  ALB:
    Inbound: 443 (HTTPS) from 0.0.0.0/0
    Outbound: All to ECS security group
  
  ECS:
    Inbound: 8000 from ALB security group only
    Outbound: All (for downloading model weights if needed)
```

### 2. **IAM Roles**

- **ECS Task Role**: Access to Secrets Manager, S3 (if model stored there)
- **ECS Execution Role**: Pull images from ECR, write logs to CloudWatch
- **Principle of Least Privilege**: Only necessary permissions

### 3. **SSL/TLS Certificate**

```bash
# Request certificate with AWS Certificate Manager (FREE)
aws acm request-certificate \
    --domain-name api.yourdomain.com \
    --validation-method DNS \
    --region us-east-1
```

### 4. **Secrets Management**

✅ **DO**: Store in AWS Secrets Manager
❌ **DON'T**: Hardcode in environment variables or Dockerfile

### 5. **CORS Configuration**

Update [backend/main_free.py](backend/main_free.py):
```python
allow_origins=[
    "https://yourdomain.com",  # Your CloudFront domain
    "https://www.yourdomain.com"
]
```

---

## 📊 Monitoring & Logging

### CloudWatch Dashboard

Create custom dashboard to monitor:

1. **ECS Metrics**:
   - CPU utilization
   - Memory utilization
   - Task count

2. **ALB Metrics**:
   - Request count
   - Target response time
   - HTTP 5xx errors

3. **Application Logs**:
   - API errors
   - Model prediction requests
   - Response times

### CloudWatch Alarms

```bash
# CPU Alarm
aws cloudwatch put-metric-alarm \
    --alarm-name potato-disease-high-cpu \
    --alarm-description "Alert when CPU exceeds 80%" \
    --metric-name CPUUtilization \
    --namespace AWS/ECS \
    --statistic Average \
    --period 300 \
    --threshold 80 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 2
```

### AWS X-Ray (Optional)

For distributed tracing and performance analysis:

```python
# Add to requirements.txt
aws-xray-sdk>=2.12.0

# Instrument FastAPI
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.ext.flask.middleware import XRayMiddleware

xray_recorder.configure(service='potato-disease-api')
```

---

## 🚀 Deployment Checklist

- [ ] AWS account created and CLI configured
- [ ] Docker image built and tested locally
- [ ] ECR repository created
- [ ] Docker image pushed to ECR
- [ ] Secrets stored in AWS Secrets Manager
- [ ] VPC and subnets configured
- [ ] Security groups created
- [ ] ECS cluster and service deployed
- [ ] Application Load Balancer configured
- [ ] SSL certificate created and attached
- [ ] Frontend uploaded to S3
- [ ] CloudFront distribution created
- [ ] Frontend config updated with ALB URL
- [ ] CORS configured in backend
- [ ] CloudWatch alarms set up
- [ ] Cost budgets configured
- [ ] Domain DNS configured (if using custom domain)
- [ ] Testing completed (API endpoints, frontend)
- [ ] Documentation updated

---

## 📚 Additional Resources

- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/intro.html)
- [AWS Cost Optimization](https://aws.amazon.com/pricing/cost-optimization/)
- [FastAPI on AWS](https://aws.amazon.com/blogs/compute/hosting-a-fastapi-application-on-aws-fargate/)
- [Deploying ML Models on AWS](https://aws.amazon.com/machine-learning/ml-use-cases/)

---

## 🆘 Troubleshooting

### Issue: Container fails to start

**Solution**: Check CloudWatch logs for errors
```bash
aws logs tail /ecs/potato-disease-api --follow
```

### Issue: High costs

**Solution**: 
1. Check CloudWatch metrics for unused resources
2. Enable Cost Explorer
3. Set up billing alarms

### Issue: Slow response times

**Solution**:
1. Enable CloudFront caching
2. Increase ECS task count
3. Use Application Auto Scaling
4. Consider model optimization (quantization)

---

**Next Steps**: Use the provided CloudFormation templates and deployment scripts to get started!
