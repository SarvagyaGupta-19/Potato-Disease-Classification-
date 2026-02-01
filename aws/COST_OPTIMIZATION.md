# AWS Cost Optimization Guide
# Potato Disease Classification Project

## 📊 Current Architecture Costs (Monthly Estimates)

### ECS Fargate Deployment
| Service | Configuration | Cost/Month |
|---------|--------------|------------|
| ECS Fargate | 1 task (0.5 vCPU, 1GB) 24/7 | $15.00 |
| Application Load Balancer | Standard ALB | $16.20 |
| NAT Gateway | 1 NAT Gateway + data transfer | $32.85 |
| S3 (Frontend) | 5GB storage + 100GB transfer | $8.62 |
| CloudFront | 100GB data transfer | $8.50 |
| ECR | 1GB image storage | $0.10 |
| CloudWatch Logs | 5GB/month | $2.50 |
| Secrets Manager | 1 secret | $0.40 |
| **TOTAL** | | **~$84/month** |

**High-cost items**: NAT Gateway ($32.85) and ALB ($16.20)

---

## 💡 Cost Optimization Strategies

### 🥇 Option 1: Remove NAT Gateway (Save ~$33/month)
**Target Cost**: $51/month

Move ECS tasks to public subnets with public IPs:

```yaml
# In cloudformation-ecs-stack.yaml, modify ECS Service:
NetworkConfiguration:
  AwsvpcConfiguration:
    AssignPublicIp: ENABLED  # Changed from DISABLED
    Subnets:
      - !Ref PublicSubnet1   # Changed from PrivateSubnet1
      - !Ref PublicSubnet2   # Changed from PrivateSubnet2
    SecurityGroups:
      - !Ref ECSSecurityGroup
```

**Pros**: Significant cost savings
**Cons**: Less secure (tasks directly on internet), not production best-practice

---

### 🥈 Option 2: Use AWS Lightsail (Save ~$64/month)
**Target Cost**: $20/month

Migrate to Lightsail container service:

```bash
# Create Lightsail container service
aws lightsail create-container-service \
    --service-name potato-disease-api \
    --power small \
    --scale 1 \
    --region us-east-1

# Deploy container
aws lightsail push-container-image \
    --service-name potato-disease-api \
    --label potato-api \
    --image potato-disease-api:latest

# Create deployment
aws lightsail create-container-service-deployment \
    --service-name potato-disease-api \
    --containers file://lightsail-containers.json \
    --public-endpoint file://lightsail-endpoint.json
```

**Lightsail Pricing**:
- Micro (512MB RAM, 0.25 vCPU): $7/month
- Small (1GB RAM, 0.5 vCPU): $10/month ✅ **Recommended**
- Medium (2GB RAM, 1 vCPU): $20/month

**Pros**: Simple, fixed pricing, includes load balancer
**Cons**: Limited scaling, less control

---

### 🥉 Option 3: AWS Lambda + API Gateway (Variable Cost)
**Target Cost**: $5-15/month (for low-moderate traffic)

Serverless deployment using Lambda:

**Challenges for this project**:
- Model size (best_model.keras) may exceed Lambda limits
- Need to use Lambda Layers or S3 for model storage
- Cold start latency (3-5 seconds)

**Best for**: Low traffic (<10k requests/month)

---

### 🔧 Option 4: Optimize Current Setup (Save ~$40/month)
**Target Cost**: $44/month

#### 4a. Replace NAT Gateway with NAT Instance
```bash
# Launch t4g.nano instance ($3/month) as NAT
aws ec2 run-instances \
    --image-id ami-0c55b159cbfafe1f0 \
    --instance-type t4g.nano \
    --key-name your-key \
    --subnet-id subnet-xxx \
    --security-group-ids sg-xxx \
    --user-data file://nat-instance-setup.sh
```

**Savings**: $32.85 → $3 = **Save $29.85/month**

#### 4b. Use Application Load Balancer Savings Plan
- Commit to 1 year: 20% savings
- Commit to 3 years: 40% savings

**Savings**: $16.20 → $9.72 = **Save $6.48/month**

#### 4c. Use Fargate Spot (70% savings on compute)
```yaml
# In task definition
CapacityProviderStrategy:
  - CapacityProvider: FARGATE_SPOT
    Weight: 100
    Base: 0
```

**Savings**: $15 → $4.50 = **Save $10.50/month**

**Total Savings with 4a+4b+4c**: ~$47/month → **New total: $37/month**

---

## 🌟 Recommended Strategy for Your Project

### For Development/Testing: Use Lightsail
```bash
# Quick setup
aws lightsail create-container-service \
    --service-name potato-dev \
    --power small \
    --scale 1 \
    --region us-east-1
```
**Cost**: $10/month + CloudFront (~$5) = **$15/month total**

### For Production: Optimized ECS Fargate
1. Use Fargate Spot (Option 4c)
2. Replace NAT with NAT instance (Option 4a)
3. Keep ALB for reliability
4. Use CloudFront for frontend (already doing)

**Cost**: ~$37/month

### For Very Low Budget: Railway Alternative
If AWS is still too expensive, consider:
- **Render.com**: $7/month for web service
- **Fly.io**: ~$5/month for small app
- **Railway** (if you get credits): Pay-as-you-go

---

## 📋 Step-by-Step: Implement Cost Optimizations

### Immediate Actions (Save $10.50/month in 5 minutes)

#### 1. Enable Fargate Spot
Edit [aws/cloudformation-ecs-stack.yaml](aws/cloudformation-ecs-stack.yaml):

```yaml
ECSService:
  Type: AWS::ECS::Service
  Properties:
    # ... existing properties ...
    CapacityProviderStrategy:
      - CapacityProvider: FARGATE_SPOT
        Weight: 100
        Base: 0
```

Redeploy:
```bash
aws cloudformation update-stack \
    --stack-name potato-disease-api-stack \
    --template-body file://aws/cloudformation-ecs-stack.yaml \
    --capabilities CAPABILITY_IAM
```

#### 2. Reduce CloudWatch Log Retention (Save $1.50/month)
```bash
aws logs put-retention-policy \
    --log-group-name /ecs/potato-disease-api \
    --retention-in-days 3  # Changed from 7
```

#### 3. Optimize Docker Image (Reduce storage costs)
```dockerfile
# In Dockerfile.aws, use multi-stage build
FROM python:3.10-slim as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user -r requirements.txt

FROM python:3.10-slim
COPY --from=builder /root/.local /root/.local
# ... rest of Dockerfile
```

**Image size**: 2GB → 800MB (save on ECR storage and pull time)

---

## 🔍 Monitor Your Costs

### Enable AWS Cost Explorer
```bash
# Get current month costs
aws ce get-cost-and-usage \
    --time-period Start=2026-02-01,End=2026-02-28 \
    --granularity MONTHLY \
    --metrics "BlendedCost" \
    --group-by Type=DIMENSION,Key=SERVICE
```

### Set Up Billing Alarms
```bash
# Alert when costs exceed $50
aws cloudwatch put-metric-alarm \
    --alarm-name potato-disease-cost-alert \
    --alarm-description "Alert when monthly cost exceeds $50" \
    --metric-name EstimatedCharges \
    --namespace AWS/Billing \
    --statistic Maximum \
    --period 86400 \
    --evaluation-periods 1 \
    --threshold 50 \
    --comparison-operator GreaterThanThreshold \
    --dimensions Name=Currency,Value=USD
```

### Use AWS Budgets (Free)
1. Go to AWS Billing Console
2. Create Budget
3. Set threshold: $50/month
4. Configure email alerts at 80%, 100%

---

## 💰 Cost Comparison: AWS vs Alternatives

| Platform | Monthly Cost | Pros | Cons |
|----------|-------------|------|------|
| **AWS ECS (Full)** | $84 | Production-grade, scalable | Expensive |
| **AWS ECS (Optimized)** | $37 | Good balance | Some complexity |
| **AWS Lightsail** | $10-20 | Simple, predictable | Limited scaling |
| **AWS Lambda** | $5-15 | Pay per use | Cold starts, size limits |
| **Render.com** | $7 | Easy setup | Less control |
| **Railway** | $5-20 | Dev-friendly | Removed free tier |
| **Fly.io** | $5-10 | Fast edge network | Learning curve |
| **Digital Ocean** | $12 | Simple VPS | Manual setup |

---

## 🎯 Final Recommendation

**For your project (Potato Disease Classification):**

### Phase 1: Start with AWS Lightsail ($10-20/month)
- Fastest to deploy
- Predictable costs
- Good for MVP and testing

### Phase 2: Move to Optimized ECS if you get traction ($37/month)
- Use Fargate Spot
- NAT instance instead of NAT Gateway
- Production-ready with auto-scaling

### Phase 3: Consider Savings Plans if staying long-term
- 1-year commitment: Save 20%
- 3-year commitment: Save 40%

---

## 📞 Need Help?

For specific questions about cost optimization:
1. Use AWS Cost Explorer to identify high costs
2. Check AWS Trusted Advisor for recommendations (requires Business support)
3. Review AWS Well-Architected Framework for cost optimization

**Remember**: Start small, monitor costs, scale as needed!
