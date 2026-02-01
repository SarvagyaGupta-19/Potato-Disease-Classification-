# 🎯 AWS Deployment Checklist

Use this checklist to track your deployment progress.

---

## 📋 Pre-Deployment (5-10 minutes)

### AWS Account Setup
- [ ] Created AWS account
- [ ] Verified email address
- [ ] Added payment method
- [ ] Set up MFA (Multi-Factor Authentication) - recommended
- [ ] Created IAM user (not using root account) - recommended

### Local Setup
- [ ] Installed AWS CLI
  ```powershell
  winget install Amazon.AWSCLI
  ```
- [ ] Verified AWS CLI installation
  ```powershell
  aws --version
  ```
- [ ] Installed Docker
- [ ] Verified Docker is running
  ```powershell
  docker --version
  docker ps
  ```
- [ ] Have Gemini API key ready

### AWS CLI Configuration
- [ ] Ran `aws configure`
- [ ] Entered AWS Access Key ID
- [ ] Entered AWS Secret Access Key
- [ ] Set region to `us-east-1` (or your preferred region)
- [ ] Set output format to `json`
- [ ] Verified configuration works
  ```powershell
  aws sts get-caller-identity
  ```

### Decision Making
- [ ] Read `aws/DEPLOYMENT_DECISION_GUIDE.md`
- [ ] Chose deployment option:
  - [ ] AWS Lightsail ($10-20/month) - Budget-friendly
  - [ ] ECS Fargate ($37-84/month) - Production-grade
  - [ ] Elastic Beanstalk ($20-40/month) - Managed platform
- [ ] Read corresponding deployment guide

---

## 🚀 Backend Deployment

### Option A: ECS Fargate Deployment (30 minutes)

#### ECR Setup
- [ ] Created ECR repository
- [ ] Built Docker image locally
- [ ] Tested Docker image locally
  ```powershell
  docker run -p 8000:8000 -e GEMINI_API_KEY=your-key potato-disease-api:latest
  # Test: http://localhost:8000/docs
  ```
- [ ] Authenticated to ECR
- [ ] Pushed image to ECR
- [ ] Verified image in ECR console

#### Secrets Management
- [ ] Created secret in AWS Secrets Manager
- [ ] Stored Gemini API key
- [ ] Noted Secret ARN

#### Infrastructure Deployment
- [ ] Reviewed CloudFormation template
- [ ] Ran deployment script:
  - Windows: `.\aws\deploy-backend.ps1`
  - Linux/Mac: `./aws/deploy-backend.sh`
- [ ] Waited for stack creation (10-15 minutes)
- [ ] Verified stack creation succeeded
  ```powershell
  aws cloudformation describe-stacks --stack-name potato-disease-api-stack
  ```
- [ ] Noted ALB URL from outputs
- [ ] Saved deployment info from `deployment-info.txt`

#### Verification
- [ ] Tested API health endpoint
  ```powershell
  curl http://YOUR-ALB-URL/docs
  ```
- [ ] Tested prediction endpoint
  ```powershell
  curl -X POST http://YOUR-ALB-URL/predict -F "file=@test-image.jpg"
  ```
- [ ] Checked CloudWatch logs
  ```powershell
  aws logs tail /ecs/potato-disease-api --follow
  ```
- [ ] Verified ECS tasks are running
  ```powershell
  aws ecs describe-services --cluster potato-disease-api-cluster --services potato-disease-api-service
  ```

### Option B: AWS Lightsail Deployment (15 minutes)

- [ ] Created Lightsail container service
- [ ] Chose service size (Small recommended)
- [ ] Pushed Docker image to Lightsail
- [ ] Created deployment configuration
- [ ] Deployed container
- [ ] Noted public URL
- [ ] Tested API endpoint
- [ ] Verified health check passes

---

## 🌐 Frontend Deployment (15 minutes)

### Configuration Update
- [ ] Updated `frontend/config.js` with backend URL
- [ ] Tested frontend locally with backend
- [ ] Verified no CORS errors

### S3 + CloudFront Setup
- [ ] Created S3 bucket via CloudFormation
- [ ] Created CloudFront distribution
- [ ] Uploaded frontend files to S3
  ```powershell
  # Or use script
  .\aws\deploy-frontend.ps1
  ```
- [ ] Noted CloudFront URL
- [ ] Waited for distribution to deploy (10-15 minutes)

### Verification
- [ ] Opened CloudFront URL in browser
- [ ] Verified frontend loads correctly
- [ ] Tested image upload functionality
- [ ] Tested disease prediction
- [ ] Tested chatbot feature
- [ ] Checked browser console for errors
- [ ] Tested on mobile device (optional)

---

## 🔒 Security & Best Practices (10 minutes)

### CORS Configuration
- [ ] Updated CORS settings in `backend/main_free.py`
  ```python
  allow_origins=[
      "https://your-cloudfront-url.cloudfront.net",
  ]
  ```
- [ ] Redeployed backend with CORS fix
- [ ] Tested from frontend - no CORS errors

### SSL/TLS (Optional but Recommended)
- [ ] Requested SSL certificate from ACM
- [ ] Validated domain ownership
- [ ] Attached certificate to ALB
- [ ] Updated frontend to use HTTPS
- [ ] Forced HTTPS redirect on CloudFront

### Security Groups
- [ ] Reviewed security group rules
- [ ] Ensured ALB only accepts 80/443
- [ ] Ensured ECS tasks only accept from ALB
- [ ] No unnecessary ports open

---

## 💰 Cost Management (5 minutes)

### Billing Setup
- [ ] Set up billing alerts
  ```powershell
  aws cloudwatch put-metric-alarm --alarm-name cost-alert --threshold 50 --comparison-operator GreaterThanThreshold
  ```
- [ ] Created AWS Budget ($50/month recommended)
- [ ] Enabled Cost Explorer
- [ ] Set up billing email notifications

### Cost Optimization
- [ ] Reviewed `aws/COST_OPTIMIZATION.md`
- [ ] Implemented relevant optimizations:
  - [ ] Enabled Fargate Spot (70% savings)
  - [ ] Reduced CloudWatch log retention
  - [ ] Set up CloudFront caching
  - [ ] Right-sized ECS tasks (0.5 vCPU, 1GB RAM)

### Monitoring
- [ ] Checked current month's costs
  ```powershell
  aws ce get-cost-and-usage --time-period Start=2026-02-01,End=2026-02-28 --granularity MONTHLY --metrics "BlendedCost"
  ```
- [ ] Understand where costs are coming from
- [ ] Planned cost review schedule (weekly/monthly)

---

## 📊 Monitoring & Logging (5 minutes)

### CloudWatch Setup
- [ ] Verified logs are being collected
- [ ] Set up log retention policy
- [ ] Created custom dashboard (optional)
- [ ] Set up alarms for:
  - [ ] High CPU usage (>80%)
  - [ ] High memory usage (>80%)
  - [ ] ECS task failures
  - [ ] ALB 5xx errors

### Application Monitoring
- [ ] Tested logging locally
- [ ] Verified logs appear in CloudWatch
- [ ] Set up error alerting
- [ ] Documented how to access logs

---

## 🔄 CI/CD Setup (Optional, 20 minutes)

### GitHub Actions
- [ ] Read `aws/CICD_SETUP_GUIDE.md`
- [ ] Created IAM user for GitHub Actions
- [ ] Generated access keys
- [ ] Added secrets to GitHub:
  - [ ] AWS_ACCESS_KEY_ID
  - [ ] AWS_SECRET_ACCESS_KEY
  - [ ] BACKEND_API_URL
- [ ] Updated workflow files with correct values
- [ ] Tested deployment by pushing to main
- [ ] Verified auto-deployment works
- [ ] Documented deployment process

---

## 📱 Domain & DNS (Optional, 30 minutes)

### Custom Domain Setup
- [ ] Purchased domain (or using existing)
- [ ] Requested SSL certificate in ACM
- [ ] Validated certificate via DNS/Email
- [ ] Created Route 53 hosted zone
- [ ] Added DNS records:
  - [ ] A record for ALB
  - [ ] CNAME for CloudFront
- [ ] Updated ALB listener for HTTPS
- [ ] Updated CloudFront with custom domain
- [ ] Updated CORS settings with new domain
- [ ] Tested HTTPS access
- [ ] Set up www redirect (optional)

---

## 🧪 Testing & Validation (15 minutes)

### Functional Testing
- [ ] Uploaded test images for each disease class
- [ ] Verified correct predictions
- [ ] Tested chatbot with disease context
- [ ] Tested error handling (invalid files)
- [ ] Tested API rate limiting (if implemented)
- [ ] Tested from different browsers
- [ ] Tested from mobile devices

### Performance Testing
- [ ] Measured response times
- [ ] Tested with large images
- [ ] Tested concurrent requests (optional)
- [ ] Verified CloudFront caching works
- [ ] Checked page load times

### Security Testing
- [ ] Verified HTTPS works
- [ ] Checked for exposed secrets
- [ ] Tested CORS protection
- [ ] Verified API authentication (if implemented)

---

## 📝 Documentation (10 minutes)

### Project Documentation
- [ ] Updated main README.md with AWS deployment info
- [ ] Documented API endpoints
- [ ] Added architecture diagram
- [ ] Documented deployment process
- [ ] Added troubleshooting section

### Deployment Documentation
- [ ] Created deployment runbook
- [ ] Documented rollback procedure
- [ ] Listed all AWS resources created
- [ ] Documented cost breakdown
- [ ] Added contact information for support

---

## 🎉 Post-Deployment (5 minutes)

### Final Checks
- [ ] All services are healthy
- [ ] No errors in logs
- [ ] Frontend works perfectly
- [ ] Backend API responds correctly
- [ ] Chatbot functions properly
- [ ] Cost monitoring is active

### Sharing & Promotion
- [ ] Added deployment link to README
- [ ] Updated portfolio/resume
- [ ] Shared on LinkedIn (optional)
- [ ] Added to project showcase
- [ ] Prepared demo for presentations

### Maintenance Planning
- [ ] Scheduled monthly cost reviews
- [ ] Planned feature updates
- [ ] Set up uptime monitoring (optional)
- [ ] Documented backup strategy (optional)

---

## 🧹 Optional: Clean Up Resources

If you want to tear down everything to avoid costs:

### Backend Resources
- [ ] Deleted CloudFormation stack
  ```powershell
  aws cloudformation delete-stack --stack-name potato-disease-api-stack
  ```
- [ ] Deleted ECR images
- [ ] Deleted ECR repository
- [ ] Deleted Secrets Manager secret
- [ ] Verified ECS cluster is deleted
- [ ] Verified ALB is deleted
- [ ] Verified NAT Gateway is deleted

### Frontend Resources
- [ ] Deleted CloudFormation stack
  ```powershell
  aws cloudformation delete-stack --stack-name potato-disease-frontend-stack
  ```
- [ ] Emptied and deleted S3 bucket
- [ ] Verified CloudFront distribution is deleted

### Final Verification
- [ ] Checked AWS console - no running resources
- [ ] Checked billing - no ongoing charges
- [ ] Saved deployment documentation for future reference

---

## 📊 Deployment Summary

Once complete, fill in:

### Deployment Information
- **Deployment Date**: _______________
- **Deployment Type**: [ ] Lightsail [ ] ECS Fargate [ ] Elastic Beanstalk
- **AWS Region**: _______________
- **Backend URL**: _______________
- **Frontend URL**: _______________
- **Estimated Monthly Cost**: $_______________
- **Deployment Time**: _______________ minutes

### Resources Created
- **CloudFormation Stacks**: _______________
- **ECR Repository**: _______________
- **ECS Cluster**: _______________
- **S3 Bucket**: _______________
- **CloudFront Distribution ID**: _______________
- **Secrets Manager Secret**: _______________

### Next Actions
- [ ] Monitor for 1 week
- [ ] Optimize costs based on usage
- [ ] Add custom domain
- [ ] Set up CI/CD
- [ ] Implement additional features
- [ ] Share deployment link

---

## 🆘 Help & Support

If stuck at any step:

1. **Check documentation**: Each guide has troubleshooting section
2. **View logs**: CloudWatch logs have detailed error messages
3. **AWS Console**: Visual confirmation of resource status
4. **Cost concerns**: See `aws/COST_OPTIMIZATION.md`
5. **CI/CD issues**: See `aws/CICD_SETUP_GUIDE.md`

---

**Congratulations on completing your AWS deployment! 🎉**

Save this checklist for future deployments or updates!
