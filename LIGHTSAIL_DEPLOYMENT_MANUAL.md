# 🚀 AWS Lightsail Deployment Guide - Manual Steps

## Complete Step-by-Step Guide for Students

**Estimated Time**: 20-30 minutes  
**Cost**: $10/month  
**Difficulty**: Easy

---

## 📋 What You'll Need

- [ ] AWS Account (we'll create this)
- [ ] Gemini API Key (you should have this)
- [ ] Docker Desktop running on your computer
- [ ] This project folder

---

## Step 1: Create AWS Account (5 minutes)

### 1.1 Sign Up

1. Go to: https://aws.amazon.com/
2. Click **"Create an AWS Account"** (top right)
3. Enter your email address
4. Choose account name: `potato-disease-student` (or your name)
5. Click **"Verify email address"**

### 1.2 Verify Email

1. Check your email inbox
2. Copy the verification code
3. Enter it on AWS page

### 1.3 Create Password

1. Create a strong password
2. Save it securely (use password manager)

### 1.4 Add Contact Information

1. Choose **"Personal"** account type
2. Enter your full name
3. Enter phone number
4. Enter address
5. Read and accept AWS Customer Agreement

### 1.5 Add Payment Method

1. Enter credit/debit card details
2. AWS will charge $1 for verification (refunded)
3. Complete verification

### 1.6 Identity Verification

1. Enter phone number for SMS verification
2. Enter 4-digit code received via SMS

### 1.7 Choose Support Plan

1. Select **"Basic Support - Free"**
2. Click **"Complete sign up"**

🎉 **Your AWS account is ready!**

---

## Step 2: Access AWS Console (2 minutes)

1. Go to: https://console.aws.amazon.com/
2. Sign in with your email and password
3. You'll see the AWS Management Console

### 2.1 Navigate to Lightsail

1. In the search bar at the top, type: **"Lightsail"**
2. Click on **"Amazon Lightsail"**
3. Or go directly to: https://lightsail.aws.amazon.com/

---

## Step 3: Build Your Docker Image (10 minutes)

### 3.1 Open PowerShell in Your Project Folder

1. Open File Explorer
2. Navigate to: `C:\Users\sarva\Downloads\Potato-Disease-Classification-`
3. Type `powershell` in the address bar
4. Press Enter

### 3.2 Verify Docker is Running

```powershell
docker --version
```

You should see: `Docker version 29.1.3, build f52814d`

### 3.3 Build the Docker Image

Copy and paste this command:

```powershell
docker build -f Dockerfile.aws -t potato-disease-api:latest .
```

**This will take 10-15 minutes.** You'll see lots of text scrolling. Wait until you see:
```
Successfully built xxxxx
Successfully tagged potato-disease-api:latest
```

### 3.4 Test the Image Locally (Optional but Recommended)

Replace `YOUR_GEMINI_KEY` with your actual key:

```powershell
docker run -d -p 8000:8000 -e GEMINI_API_KEY=YOUR_GEMINI_KEY potato-disease-api:latest
```

Then open browser and go to: http://localhost:8000/docs

If it works, stop the container:
```powershell
docker ps
# Copy the CONTAINER ID from the output
docker stop CONTAINER_ID
```

---

## Step 4: Create Lightsail Container Service (5 minutes)

### 4.1 Go to Lightsail Console

1. Visit: https://lightsail.aws.amazon.com/
2. Make sure you're in **US East (N. Virginia)** region (top right)
3. Click **"Containers"** in the left menu
4. Click **"Create container service"**

### 4.2 Choose Container Service Location

- **Region**: US East (N. Virginia)
- Leave as is

### 4.3 Choose Container Service Capacity

Select **"Small"** plan:
- **Price**: $10/month
- **Power**: 1 GB RAM, 0.5 vCPU
- **Scale**: 1 instance

### 4.4 Name Your Service

- **Service name**: `potato-disease-api`
- (Must be lowercase, no spaces, can use hyphens)

### 4.5 Click "Create container service"

**Wait 2-3 minutes** for the service to be created.

You'll see a green checkmark when ready.

---

## Step 5: Push Your Docker Image to Lightsail (15 minutes)

This is the tricky part, but I'll make it simple!

### 5.1 Install AWS CLI (if not done)

Download and install from:
https://awscli.amazonaws.com/AWSCLIV2.msi

**After installation**:
1. Close PowerShell
2. Open a NEW PowerShell window
3. Test: `aws --version`

### 5.2 Configure AWS CLI

In PowerShell, run:

```powershell
aws configure
```

You'll be asked for:

1. **AWS Access Key ID**: 
   - Go to: https://console.aws.amazon.com/iam/home#/security_credentials
   - Click "Create access key"
   - Choose "Command Line Interface (CLI)"
   - Check the box "I understand..."
   - Click "Create access key"
   - Copy the **Access key ID** and paste in PowerShell

2. **AWS Secret Access Key**: 
   - Copy from the same page and paste in PowerShell

3. **Default region name**: Type `us-east-1`

4. **Default output format**: Type `json`

### 5.3 Push Image to Lightsail

This requires a special command. Let me give you the exact steps:

#### 5.3.1 Get Push Commands

1. Go back to Lightsail console
2. Click on your service name: `potato-disease-api`
3. Look for **"Push commands"** or similar
4. You'll see commands like these

#### 5.3.2 Run the Commands

In PowerShell, in your project folder, run:

```powershell
# 1. Authenticate to Lightsail
aws lightsail get-container-images --service-name potato-disease-api

# 2. Push your local image
aws lightsail push-container-image --service-name potato-disease-api --label potato-api --image potato-disease-api:latest
```

**This will take 5-10 minutes** to upload your Docker image.

When done, you'll see output like:
```
:potato-disease-api.potato-api.1
```

**Copy this full image name!** You'll need it in the next step.

---

## Step 6: Deploy Your Container (3 minutes)

### 6.1 Create Deployment Configuration

In Lightsail console:

1. Click on your service: `potato-disease-api`
2. Go to **"Deployments"** tab
3. Click **"Create your first deployment"**

### 6.2 Configure Container

Fill in these details:

**Container name**: `potato-api` (lowercase, no spaces)

**Image**: Paste the image name from step 5.3.2, like:
`:potato-disease-api.potato-api.1`

**Add environment variables**:
- Click **"Add environment variable"**
- **Key**: `PORT`
- **Value**: `8000`

- Click **"Add environment variable"** again
- **Key**: `GEMINI_API_KEY`
- **Value**: Your actual Gemini API key

**Open ports**:
- **Port**: `8000`
- **Protocol**: HTTP

### 6.3 Public Endpoint

- **Container name**: Select `potato-api`
- **Container port**: `8000`

**Health check path**: `/docs`

### 6.4 Deploy

Click **"Save and deploy"**

**Wait 5-10 minutes** for deployment to complete.

---

## Step 7: Test Your Deployment (2 minutes)

### 7.1 Get Your URL

1. In Lightsail console, click on your service
2. You'll see **"Public domain"** at the top
3. It looks like: `potato-disease-api.xxxxx.us-east-1.cs.amazonlightsail.com`

### 7.2 Test the API

Open your browser and go to:
```
https://potato-disease-api.xxxxx.us-east-1.cs.amazonlightsail.com/docs
```

You should see the FastAPI documentation page! 🎉

### 7.3 Test Prediction

1. On the `/docs` page
2. Find the `/predict` endpoint
3. Click **"Try it out"**
4. Upload a potato leaf image
5. Click **"Execute"**
6. You should get a prediction result!

---

## Step 8: Deploy Frontend (10 minutes)

Now let's deploy your frontend to access it properly.

### 8.1 Update Frontend Configuration

1. In your project folder, open: `frontend/config.js`
2. Find the line with `BACKEND_URL`
3. Replace it with your Lightsail URL:

```javascript
production: {
    BACKEND_URL: 'https://potato-disease-api.xxxxx.us-east-1.cs.amazonlightsail.com',
    API_TIMEOUT: 30000,
    ENABLE_ANALYTICS: true
}
```

4. Save the file

### 8.2 Deploy Frontend to S3 (via Console)

#### Create S3 Bucket

1. Go to S3 Console: https://s3.console.aws.amazon.com/
2. Click **"Create bucket"**
3. **Bucket name**: `potato-disease-frontend-yourname` (must be globally unique)
4. **Region**: US East (N. Virginia) us-east-1
5. **Uncheck** "Block all public access"
6. Check the box "I acknowledge..."
7. Click **"Create bucket"**

#### Enable Static Website Hosting

1. Click on your bucket name
2. Go to **"Properties"** tab
3. Scroll down to **"Static website hosting"**
4. Click **"Edit"**
5. Choose **"Enable"**
6. **Index document**: `index.html`
7. **Error document**: `index.html`
8. Click **"Save changes"**
9. **Copy the website URL** shown (like: http://potato-disease-frontend-yourname.s3-website-us-east-1.amazonaws.com)

#### Upload Frontend Files

1. Go to **"Objects"** tab
2. Click **"Upload"**
3. Click **"Add folder"**
4. Select your `frontend/` folder
5. Click **"Upload"**

#### Make Files Public

1. Select all uploaded files
2. Click **"Actions"** → **"Make public using ACL"**
3. Confirm

### 8.3 Test Your Website

Open the S3 website URL in your browser. You should see your application!

---

## 🎉 Success! Your App is Live!

**Your URLs**:
- **Backend API**: `https://potato-disease-api.xxxxx.us-east-1.cs.amazonlightsail.com`
- **Frontend**: `http://potato-disease-frontend-yourname.s3-website-us-east-1.amazonaws.com`

---

## 📝 What to Put on Your Resume

**Project**: Potato Disease Classification System

**Tech Stack**: 
- FastAPI, TensorFlow, Google Gemini AI
- Deployed on AWS Lightsail (Backend) and AWS S3 (Frontend)
- Containerized with Docker
- RESTful API with real-time image classification
- 96%+ accuracy on disease detection

**Links**:
- Live Demo: [Your S3 URL]
- GitHub: https://github.com/SarvagyaGupta-19/Potato-Disease-Classification-
- API Docs: [Your Lightsail URL]/docs

---

## 💰 Cost Breakdown

- **Lightsail Container**: $10/month
- **S3 Storage**: ~$0.50/month (for frontend)
- **Total**: **~$10.50/month**

---

## 🔧 Troubleshooting

### Issue: "Can't access my Lightsail URL"

**Solution**: 
1. Check deployment status in Lightsail console
2. Look for errors in container logs
3. Verify environment variables are set correctly

### Issue: "CORS error in browser"

**Solution**:
1. Update `backend/main_free.py`
2. Add your S3 URL to `allow_origins`:
```python
allow_origins=[
    "http://potato-disease-frontend-yourname.s3-website-us-east-1.amazonaws.com",
]
```
3. Rebuild and redeploy Docker image

### Issue: "Image not uploading to Lightsail"

**Solution**:
- Check your internet connection
- Try pushing again
- If very slow, compress your Docker image

### View Logs

In Lightsail console:
1. Click on your service
2. Go to **"Metrics"** tab
3. Click **"View logs"**

---

## 📊 For Interviews

**Be ready to explain**:

1. **Architecture**: "Containerized FastAPI backend on Lightsail, static frontend on S3"

2. **Why Lightsail?**: "Cost-effective for student projects, fixed pricing, includes SSL certificate"

3. **Challenges**: "Learned about container deployment, environment variable management, CORS configuration"

4. **Scalability**: "Can easily scale to ECS Fargate if traffic increases"

5. **Security**: "Used environment variables for API keys, HTTPS enabled"

---

## 🎯 Next Steps (Optional)

1. **Custom Domain**: Buy domain ($12/year) and point it to your Lightsail service
2. **HTTPS for S3**: Set up CloudFront for HTTPS (free)
3. **Monitoring**: Set up AWS CloudWatch alerts
4. **CI/CD**: Set up GitHub Actions for auto-deployment

---

**Congratulations! You've deployed a production ML application to AWS!** 🎊

Save your URLs and add them to your resume and GitHub README!
