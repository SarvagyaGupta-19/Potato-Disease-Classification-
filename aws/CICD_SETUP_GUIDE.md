# GitHub Actions CI/CD Setup Guide

This guide will help you set up automated deployments to AWS using GitHub Actions.

## 🎯 What You'll Get

- ✅ Auto-deploy backend when you push to `main` branch
- ✅ Auto-deploy frontend when frontend files change
- ✅ No manual deployment needed after setup
- ✅ Deployment history in GitHub Actions tab

---

## 📋 Prerequisites

Before setting up CI/CD:

- [ ] Successfully deployed to AWS manually once
- [ ] Have AWS Access Key ID and Secret Access Key
- [ ] GitHub repository for your project
- [ ] Backend deployed and have ALB URL

---

## 🔐 Step 1: Create AWS IAM User for GitHub Actions

### 1.1 Create IAM User

```bash
# Via AWS CLI
aws iam create-user --user-name github-actions-deploy

# Or via AWS Console:
# 1. Go to IAM → Users → Create user
# 2. User name: github-actions-deploy
# 3. Next
```

### 1.2 Attach Required Policies

For full deployment access (ECS + ECR + CloudFormation):

```bash
# Attach policies
aws iam attach-user-policy \
    --user-name github-actions-deploy \
    --policy-arn arn:aws:iam::aws:policy/AmazonECS_FullAccess

aws iam attach-user-policy \
    --user-name github-actions-deploy \
    --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser

aws iam attach-user-policy \
    --user-name github-actions-deploy \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

aws iam attach-user-policy \
    --user-name github-actions-deploy \
    --policy-arn arn:aws:iam::aws:policy/CloudFrontFullAccess
```

**Alternative: Custom Policy (More Secure)**

Create a custom policy with only needed permissions:

<details>
<summary>Click to see custom policy JSON</summary>

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:BatchGetImage"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecs:UpdateService",
                "ecs:DescribeServices",
                "ecs:DescribeTaskDefinition",
                "ecs:RegisterTaskDefinition"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:ListBucket",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::potato-disease-frontend-*",
                "arn:aws:s3:::potato-disease-frontend-*/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudfront:CreateInvalidation",
                "cloudfront:GetDistribution"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:PassRole"
            ],
            "Resource": "arn:aws:iam::*:role/ecsTaskExecutionRole"
        }
    ]
}
```

</details>

### 1.3 Create Access Keys

```bash
# Create access key
aws iam create-access-key --user-name github-actions-deploy

# Save the output! You won't see it again.
# Output contains:
# - AccessKeyId: AKIA...
# - SecretAccessKey: secret...
```

**Or via Console**:
1. IAM → Users → github-actions-deploy
2. Security credentials tab
3. Create access key
4. Choose "Application running on AWS compute service"
5. Download .csv file (keep it safe!)

---

## 🔑 Step 2: Add Secrets to GitHub

### 2.1 Navigate to Repository Settings

1. Go to your GitHub repository
2. Click **Settings**
3. Click **Secrets and variables** → **Actions**
4. Click **New repository secret**

### 2.2 Add Required Secrets

Add the following secrets one by one:

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `AWS_ACCESS_KEY_ID` | AKIA... | From step 1.3 |
| `AWS_SECRET_ACCESS_KEY` | secret... | From step 1.3 |
| `BACKEND_API_URL` | http://your-alb... | Your ALB URL from deployment |
| `GEMINI_API_KEY` | your-gemini-key | Optional: For rebuilds |

**To add each secret**:
1. Click "New repository secret"
2. Name: (e.g., AWS_ACCESS_KEY_ID)
3. Secret: (paste value)
4. Click "Add secret"

---

## 🔄 Step 3: Update Workflow Files

The workflow files are already created. You just need to update some values:

### 3.1 Update Backend Workflow

Edit `.github/workflows/deploy-aws.yml`:

Find and update these lines with your actual values:

```yaml
env:
  AWS_REGION: us-east-1  # Your region
  ECR_REPOSITORY: potato-disease-api  # Your ECR repo name
  ECS_CLUSTER: potato-disease-api-cluster  # Your cluster name
  ECS_SERVICE: potato-disease-api-service  # Your service name
  CONTAINER_NAME: potato-disease-api  # Your container name
```

**How to find these values**:
```bash
# Get cluster name
aws ecs list-clusters

# Get service name
aws ecs list-services --cluster potato-disease-api-cluster

# Get ECR repository
aws ecr describe-repositories
```

### 3.2 Update Frontend Workflow

Edit `.github/workflows/deploy-frontend.yml`:

```yaml
env:
  AWS_REGION: us-east-1
  S3_BUCKET: potato-disease-frontend-YOUR_ACCOUNT_ID  # Update this
  CLOUDFRONT_DISTRIBUTION_ID: E1234567890ABC  # Update this
```

**How to find these values**:
```bash
# Get S3 bucket name
aws s3 ls | grep potato

# Get CloudFront distribution ID
aws cloudfront list-distributions \
    --query 'DistributionList.Items[*].[Id,DomainName]' \
    --output table
```

---

## ✅ Step 4: Test Your CI/CD

### 4.1 Make a Test Change

```bash
# Make a small change to trigger deployment
echo "# CI/CD Test" >> README.md

git add .
git commit -m "test: trigger CI/CD deployment"
git push origin main
```

### 4.2 Monitor Deployment

1. Go to your GitHub repository
2. Click **Actions** tab
3. You should see a workflow running
4. Click on it to see real-time logs

### 4.3 Verify Deployment

After workflow completes (5-10 minutes):

```bash
# Check if new version is deployed
curl http://your-alb-url/docs

# Check ECS task
aws ecs describe-services \
    --cluster potato-disease-api-cluster \
    --services potato-disease-api-service \
    --query 'services[0].deployments'
```

---

## 🔧 Workflow Behavior

### Backend Workflow Triggers:
- ✅ Push to `main` branch
- ✅ Manual trigger (workflow_dispatch)

### Frontend Workflow Triggers:
- ✅ Push to `main` branch with changes in `frontend/` directory
- ✅ Manual trigger

### What Happens:
1. Code is checked out
2. Docker image is built
3. Image is pushed to ECR
4. ECS task definition is updated
5. ECS service is redeployed
6. (Frontend) Files uploaded to S3
7. (Frontend) CloudFront cache invalidated

---

## 🎯 Advanced: Manual Deployment Trigger

You can manually trigger deployments from GitHub:

1. Go to **Actions** tab
2. Select "Deploy to AWS ECS" workflow
3. Click **Run workflow**
4. Choose branch (usually `main`)
5. Click **Run workflow**

---

## 🔒 Security Best Practices

### ✅ DO:
- Use IAM user with minimal required permissions
- Rotate access keys regularly (every 90 days)
- Enable AWS CloudTrail to log API calls
- Use GitHub's dependency scanning
- Review workflow logs for sensitive data

### ❌ DON'T:
- Commit AWS credentials to repository
- Use root AWS account credentials
- Share access keys in public channels
- Log secrets in workflow files
- Use overly permissive IAM policies

---

## 📊 Monitoring CI/CD

### GitHub Actions Dashboard

View deployment history:
1. **Actions** tab shows all workflow runs
2. Green ✅ = successful
3. Red ❌ = failed
4. Click on run to see detailed logs

### AWS CloudWatch

View application logs:
```bash
# View recent logs
aws logs tail /ecs/potato-disease-api --follow

# View logs from specific time
aws logs tail /ecs/potato-disease-api \
    --since 1h \
    --format short
```

### Deployment Notifications (Optional)

Add Slack/Discord notifications to workflows:

<details>
<summary>Example: Slack Notification</summary>

Add to workflow file:

```yaml
- name: Notify Slack
  if: always()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

</details>

---

## 🐛 Troubleshooting

### Issue: Workflow fails with "Unable to locate credentials"

**Solution**: 
- Verify secrets are added correctly in GitHub
- Secret names must match exactly (case-sensitive)

### Issue: "Failed to push image to ECR"

**Solution**:
- Check IAM permissions include ECR access
- Verify ECR repository exists
- Check repository name in workflow file

### Issue: "ECS service not updating"

**Solution**:
```bash
# Check service exists
aws ecs describe-services \
    --cluster YOUR_CLUSTER \
    --services YOUR_SERVICE

# Force new deployment manually
aws ecs update-service \
    --cluster YOUR_CLUSTER \
    --service YOUR_SERVICE \
    --force-new-deployment
```

### Issue: "CloudFront invalidation fails"

**Solution**:
- Verify CloudFront distribution ID is correct
- Check IAM permissions include CloudFront access
- Ensure distribution exists:
  ```bash
  aws cloudfront get-distribution --id YOUR_DIST_ID
  ```

### Issue: Workflow runs but deployment is slow

**Reason**: Normal behavior
- ECS deployment: 5-10 minutes
- CloudFront invalidation: 5-15 minutes

---

## 🔄 Rollback Strategy

If a deployment goes wrong:

### Option 1: Revert Git Commit

```bash
git revert HEAD
git push origin main
# This triggers new deployment with old code
```

### Option 2: Manual Rollback

```bash
# List recent task definitions
aws ecs list-task-definitions \
    --family-prefix potato-disease-api-task \
    --sort DESC

# Update service to use previous task definition
aws ecs update-service \
    --cluster potato-disease-api-cluster \
    --service potato-disease-api-service \
    --task-definition potato-disease-api-task:PREVIOUS_VERSION
```

### Option 3: Disable Auto-Deploy Temporarily

1. Go to workflow file
2. Comment out the trigger:
   ```yaml
   # on:
   #   push:
   #     branches:
   #       - main
   on:
     workflow_dispatch:  # Only manual triggers
   ```
3. Commit and push

---

## 📈 Cost Impact of CI/CD

GitHub Actions costs:
- **Public repositories**: FREE unlimited
- **Private repositories**: 2,000 minutes/month free

Each deployment uses ~5-10 minutes, so:
- 200-400 free deployments per month for private repos
- Unlimited for public repos

AWS costs:
- No additional cost for deployments
- ECR storage: ~$0.10/month per image
- Data transfer: Negligible for small projects

---

## ✅ CI/CD Setup Checklist

- [ ] Created IAM user for GitHub Actions
- [ ] Generated access keys
- [ ] Added secrets to GitHub repository
- [ ] Updated workflow files with correct values
- [ ] Tested deployment by pushing to main
- [ ] Verified application works after auto-deploy
- [ ] Set up billing alerts
- [ ] Documented deployment process for team

---

## 🎉 Success!

Your CI/CD is now set up! From now on:

1. Make code changes locally
2. Commit and push to `main` branch
3. GitHub Actions automatically deploys
4. Check Actions tab for deployment status
5. Application is updated in 5-10 minutes

**No more manual deployments needed!** 🚀

---

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS ECS Deployment Actions](https://github.com/aws-actions)
- [GitHub Actions Marketplace](https://github.com/marketplace?type=actions)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)

---

Need help? Check the workflow logs in GitHub Actions tab for detailed error messages!
