# 🚀 Quick Start: AWS Deployment

This guide will help you deploy your Potato Disease Classification project to AWS in under 30 minutes.

## 📋 Prerequisites

Before starting, ensure you have:

- [ ] AWS Account ([Create one here](https://aws.amazon.com/))
- [ ] AWS CLI installed ([Installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html))
- [ ] Docker installed ([Get Docker](https://docs.docker.com/get-docker/))
- [ ] Your Gemini API key from Google AI Studio
- [ ] Git configured on your machine

## ⚡ Fast Track Deployment

### Option 1: Automated Script (Recommended - Windows)

```powershell
# Navigate to your project directory
cd Potato-Disease-Classification-

# Configure AWS credentials (first time only)
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter default region: us-east-1
# Enter default output format: json

# Run the deployment script
.\aws\deploy-backend.ps1
```

The script will:
1. ✅ Create ECR repository
2. ✅ Build and push Docker image
3. ✅ Store your Gemini API key securely
4. ✅ Deploy complete infrastructure
5. ✅ Provide you with API URL

**Expected time**: 10-15 minutes

### Option 2: Automated Script (Linux/Mac)

```bash
# Make scripts executable
chmod +x aws/deploy-backend.sh
chmod +x aws/deploy-frontend.sh

# Run backend deployment
./aws/deploy-backend.sh

# After backend is deployed, deploy frontend
./aws/deploy-frontend.sh
```

### Option 3: Manual CloudFormation Deployment

If you prefer more control:

```bash
# 1. Configure AWS CLI
aws configure

# 2. Create ECR repository
aws ecr create-repository --repository-name potato-disease-api --region us-east-1

# 3. Build and push Docker image
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
docker build -f Dockerfile.aws -t potato-disease-api:latest .
docker tag potato-disease-api:latest YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/potato-disease-api:latest
docker push YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/potato-disease-api:latest

# 4. Store API key in Secrets Manager
aws secretsmanager create-secret \
    --name potato-disease/gemini-api-key \
    --secret-string '{"GEMINI_API_KEY":"your-key-here"}' \
    --region us-east-1

# 5. Deploy CloudFormation stack
aws cloudformation create-stack \
    --stack-name potato-disease-api-stack \
    --template-body file://aws/cloudformation-ecs-stack.yaml \
    --parameters \
        ParameterKey=ECRImageURI,ParameterValue=YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/potato-disease-api:latest \
        ParameterKey=GeminiSecretArn,ParameterValue=YOUR_SECRET_ARN \
    --capabilities CAPABILITY_IAM \
    --region us-east-1

# 6. Wait for stack creation (10-15 minutes)
aws cloudformation wait stack-create-complete --stack-name potato-disease-api-stack --region us-east-1

# 7. Get your API URL
aws cloudformation describe-stacks \
    --stack-name potato-disease-api-stack \
    --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' \
    --output text
```

---

## 🌐 Frontend Deployment

### After backend deployment:

1. **Update frontend configuration** with your API URL:
   
   Edit `frontend/config.js`:
   ```javascript
   production: {
       BACKEND_URL: 'http://your-alb-url-here.us-east-1.elb.amazonaws.com',
       // ...
   }
   ```

2. **Deploy frontend**:
   
   **Windows**:
   ```powershell
   .\aws\deploy-frontend.ps1
   ```
   
   **Linux/Mac**:
   ```bash
   ./aws/deploy-frontend.sh
   ```

3. **Access your application**:
   - Your CloudFront URL will be displayed
   - Example: `https://d1234567890.cloudfront.net`

---

## 🔍 Verify Deployment

### Check Backend Health

```bash
# Test health endpoint
curl http://your-alb-url/docs

# Test prediction endpoint
curl -X POST http://your-alb-url/predict \
  -F "file=@path/to/potato-image.jpg"
```

### Check Frontend

Open the CloudFront URL in your browser and:
1. Upload a potato leaf image
2. Check that prediction works
3. Try the chatbot feature

---

## 💰 Cost Monitoring

### Set up billing alert immediately:

```bash
# Alert when costs exceed $50
aws cloudwatch put-metric-alarm \
    --alarm-name potato-disease-cost-alert \
    --metric-name EstimatedCharges \
    --namespace AWS/Billing \
    --statistic Maximum \
    --period 86400 \
    --threshold 50 \
    --comparison-operator GreaterThanThreshold
```

### Check current costs:

```bash
aws ce get-cost-and-usage \
    --time-period Start=2026-02-01,End=2026-02-28 \
    --granularity MONTHLY \
    --metrics "BlendedCost"
```

**Expected monthly cost**: $40-84/month depending on optimization

See [COST_OPTIMIZATION.md](COST_OPTIMIZATION.md) for ways to reduce costs.

---

## 🛠️ Troubleshooting

### Issue: "Unable to locate credentials"

**Solution**:
```bash
aws configure
# Enter your credentials
```

### Issue: "Task failed to start"

**Solution**: Check CloudWatch logs
```bash
aws logs tail /ecs/potato-disease-api --follow
```

### Issue: "High costs"

**Solution**: 
1. Check [COST_OPTIMIZATION.md](COST_OPTIMIZATION.md)
2. Consider using Fargate Spot (70% savings)
3. Or migrate to Lightsail ($10/month)

### Issue: "502 Bad Gateway"

**Solution**: ECS tasks may still be starting. Wait 2-3 minutes and try again.

### Issue: "CORS errors in frontend"

**Solution**: Update CORS settings in `backend/main_free.py`:
```python
allow_origins=[
    "https://your-cloudfront-url.cloudfront.net",
]
```

---

## 🔄 Update Your Deployment

### Update backend code:

```bash
# Rebuild and push image
docker build -f Dockerfile.aws -t potato-disease-api:latest .
docker tag potato-disease-api:latest YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/potato-disease-api:latest
docker push YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/potato-disease-api:latest

# Force ECS to pull new image
aws ecs update-service \
    --cluster potato-disease-api-cluster \
    --service potato-disease-api-service \
    --force-new-deployment
```

### Update frontend:

```bash
# Sync to S3
aws s3 sync frontend/ s3://your-bucket-name/ --delete

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
    --distribution-id YOUR_DISTRIBUTION_ID \
    --paths "/*"
```

---

## 📊 Monitoring

### View logs:

```bash
# Backend logs
aws logs tail /ecs/potato-disease-api --follow

# Access logs
aws logs tail /aws/elasticloadbalancing/potato-disease-api-alb
```

### Check metrics:

```bash
# CPU utilization
aws cloudwatch get-metric-statistics \
    --namespace AWS/ECS \
    --metric-name CPUUtilization \
    --dimensions Name=ServiceName,Value=potato-disease-api-service \
    --start-time 2026-02-01T00:00:00Z \
    --end-time 2026-02-02T00:00:00Z \
    --period 3600 \
    --statistics Average
```

---

## 🧹 Clean Up (Delete Everything)

**To avoid charges**, delete all resources when done testing:

```bash
# Delete CloudFormation stacks (this deletes most resources)
aws cloudformation delete-stack --stack-name potato-disease-api-stack
aws cloudformation delete-stack --stack-name potato-disease-frontend-stack

# Delete ECR images
aws ecr batch-delete-image \
    --repository-name potato-disease-api \
    --image-ids imageTag=latest

# Delete secrets
aws secretsmanager delete-secret \
    --secret-id potato-disease/gemini-api-key \
    --force-delete-without-recovery

# Empty and delete S3 bucket
aws s3 rm s3://your-bucket-name --recursive
aws s3 rb s3://your-bucket-name
```

---

## 📚 Next Steps

1. **Set up custom domain**: See [AWS_DEPLOYMENT_GUIDE.md](AWS_DEPLOYMENT_GUIDE.md)
2. **Enable HTTPS**: Use AWS Certificate Manager (free SSL)
3. **Set up CI/CD**: Use GitHub Actions (already configured)
4. **Optimize costs**: See [COST_OPTIMIZATION.md](COST_OPTIMIZATION.md)
5. **Monitor performance**: Set up CloudWatch dashboards

---

## 🆘 Need Help?

- 📖 Full documentation: [AWS_DEPLOYMENT_GUIDE.md](AWS_DEPLOYMENT_GUIDE.md)
- 💰 Cost optimization: [COST_OPTIMIZATION.md](COST_OPTIMIZATION.md)
- 🐛 Issues: Check CloudWatch logs first
- 📧 Contact: AWS Support or create GitHub issue

---

**Congratulations! 🎉** Your application is now running on AWS!
