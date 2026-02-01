# AWS Deployment Files - Summary

This directory contains all necessary files for deploying the Potato Disease Classification system to AWS.

## 📁 File Structure

```
aws/
├── QUICK_START.md                    # ⭐ Start here! 30-minute deployment guide
├── AWS_DEPLOYMENT_GUIDE.md           # Comprehensive deployment documentation (in root)
├── COST_OPTIMIZATION.md              # Cost reduction strategies
├── cloudformation-ecs-stack.yaml     # Backend infrastructure (ECS Fargate)
├── cloudformation-frontend.yaml      # Frontend infrastructure (S3 + CloudFront)
├── elastic-beanstalk-config.yaml     # Alternative: Elastic Beanstalk config
├── deploy-backend.sh                 # Automated deployment script (Linux/Mac)
├── deploy-backend.ps1                # Automated deployment script (Windows)
├── deploy-frontend.sh                # Frontend deployment script (Linux/Mac)
└── README.md                         # This file
```

## 🚀 Quick Start

### Windows Users:
```powershell
aws configure  # Configure AWS credentials first
.\aws\deploy-backend.ps1
.\aws\deploy-frontend.ps1
```

### Linux/Mac Users:
```bash
aws configure  # Configure AWS credentials first
chmod +x aws/*.sh
./aws/deploy-backend.sh
./aws/deploy-frontend.sh
```

## 📖 Documentation Guide

1. **New to AWS?** → Start with [QUICK_START.md](QUICK_START.md)
2. **Need details?** → Read [AWS_DEPLOYMENT_GUIDE.md](../AWS_DEPLOYMENT_GUIDE.md)
3. **Concerned about costs?** → Check [COST_OPTIMIZATION.md](COST_OPTIMIZATION.md)
4. **Want simple setup?** → Use `deploy-backend.ps1` or `deploy-backend.sh`

## 🏗️ Deployment Options

### Option 1: ECS Fargate (Recommended)
- **Cost**: $37-84/month
- **Complexity**: Medium
- **Scalability**: Excellent
- **Files**: `cloudformation-ecs-stack.yaml`, `deploy-backend.sh`

### Option 2: Elastic Beanstalk
- **Cost**: $20-40/month
- **Complexity**: Low
- **Scalability**: Good
- **Files**: `elastic-beanstalk-config.yaml`

### Option 3: AWS Lightsail (Budget-friendly)
- **Cost**: $10-20/month
- **Complexity**: Very Low
- **Scalability**: Limited
- **Setup**: Manual via AWS Console or CLI

## 💰 Monthly Cost Estimates

| Setup | Monthly Cost | Best For |
|-------|-------------|----------|
| ECS Fargate (Full) | $84 | Production with high availability |
| ECS Fargate (Optimized) | $37 | Production on budget |
| AWS Lightsail | $10-20 | Development/Low traffic |
| Elastic Beanstalk | $20-40 | Easy production setup |

See [COST_OPTIMIZATION.md](COST_OPTIMIZATION.md) for detailed cost breakdown and savings strategies.

## 🔧 Infrastructure Components

### Backend (ECS Fargate):
- VPC with public and private subnets
- Application Load Balancer (ALB)
- ECS Fargate cluster with auto-scaling
- CloudWatch logging
- AWS Secrets Manager for API keys
- ECR for Docker images

### Frontend (S3 + CloudFront):
- S3 bucket for static files
- CloudFront CDN distribution
- HTTPS support
- Origin Access Control (OAC)

## 📊 Architecture Diagram

```
Internet
   ↓
CloudFront (Frontend) ──API calls──→ ALB (HTTPS)
                                      ↓
                               ECS Fargate Tasks
                                      ↓
                            Secrets Manager (API Keys)
```

## 🛠️ Prerequisites

Before deployment, ensure you have:

- [ ] AWS Account
- [ ] AWS CLI installed and configured (`aws configure`)
- [ ] Docker installed
- [ ] Gemini API key
- [ ] Basic understanding of AWS services (optional)

## 📝 Step-by-Step Deployment

1. **Configure AWS credentials**:
   ```bash
   aws configure
   ```

2. **Deploy backend**:
   - Windows: `.\aws\deploy-backend.ps1`
   - Linux/Mac: `./aws/deploy-backend.sh`

3. **Get API URL** from output or `deployment-info.txt`

4. **Update frontend config** with API URL

5. **Deploy frontend**:
   - Windows: `.\aws\deploy-frontend.ps1`
   - Linux/Mac: `./aws/deploy-frontend.sh`

6. **Test your deployment**:
   - Open CloudFront URL
   - Upload a potato leaf image
   - Verify prediction works

## 🔄 CI/CD Integration

GitHub Actions workflows are available in `.github/workflows/`:
- `deploy-aws.yml`: Auto-deploy backend on push to main
- `deploy-frontend.yml`: Auto-deploy frontend on changes to frontend/

**Setup**:
1. Add AWS credentials to GitHub Secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `BACKEND_API_URL`

2. Push to main branch → Automatic deployment!

## 🧹 Cleanup / Tear Down

To avoid AWS charges, delete all resources when done:

```bash
# Delete stacks
aws cloudformation delete-stack --stack-name potato-disease-api-stack
aws cloudformation delete-stack --stack-name potato-disease-frontend-stack

# Delete secrets
aws secretsmanager delete-secret --secret-id potato-disease/gemini-api-key --force-delete-without-recovery

# Delete ECR images and repository
aws ecr batch-delete-image --repository-name potato-disease-api --image-ids imageTag=latest
aws ecr delete-repository --repository-name potato-disease-api
```

## 🆘 Troubleshooting

### Common Issues:

1. **"Stack creation failed"**
   - Check CloudFormation console for error details
   - Verify your AWS account has necessary permissions
   - Ensure you're in the correct region

2. **"Task failed to start"**
   - Check CloudWatch logs: `aws logs tail /ecs/potato-disease-api --follow`
   - Verify Gemini API key is correct
   - Check ECS task definition

3. **"502 Bad Gateway"**
   - Wait 2-3 minutes for tasks to become healthy
   - Check target group health in EC2 console

4. **"High AWS bills"**
   - Review [COST_OPTIMIZATION.md](COST_OPTIMIZATION.md)
   - Set up billing alarms
   - Consider Fargate Spot or Lightsail

## 📚 Additional Resources

- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [AWS CloudFormation Documentation](https://docs.aws.amazon.com/cloudformation/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [FastAPI on AWS Guide](https://aws.amazon.com/blogs/compute/)

## 🔐 Security Best Practices

✅ **Implemented**:
- Secrets in AWS Secrets Manager (not in code)
- Private subnets for ECS tasks
- Security groups with least privilege
- HTTPS on CloudFront
- Non-root Docker user

⚠️ **Recommended additions**:
- Use AWS WAF on CloudFront/ALB
- Enable VPC Flow Logs
- Set up AWS Config for compliance
- Use AWS GuardDuty for threat detection

## 📈 Monitoring

### View logs:
```bash
aws logs tail /ecs/potato-disease-api --follow
```

### Check costs:
```bash
aws ce get-cost-and-usage \
    --time-period Start=2026-02-01,End=2026-02-28 \
    --granularity MONTHLY \
    --metrics "BlendedCost"
```

### Set up alerts:
```bash
aws cloudwatch put-metric-alarm \
    --alarm-name high-cpu-alert \
    --metric-name CPUUtilization \
    --namespace AWS/ECS \
    --statistic Average \
    --period 300 \
    --threshold 80 \
    --comparison-operator GreaterThanThreshold
```

---

**Need help?** See [QUICK_START.md](QUICK_START.md) for detailed instructions or [AWS_DEPLOYMENT_GUIDE.md](../AWS_DEPLOYMENT_GUIDE.md) for comprehensive documentation.
