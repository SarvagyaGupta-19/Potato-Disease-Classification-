# Potato Disease Classification - Deployment Guide

This guide will help you deploy the **Backend** (API & Model) to **Render** and the **Frontend** (Website) to **Vercel**.

## Prerequisites
- GitHub Account (The code must be pushed to a GitHub repository).
- [Render Account](https://render.com/) (Free).
- [Vercel Account](https://vercel.com/) (Free).
- Google Gemini API Key (for the chatbot).

---

## Part 1: Deploy Backend to Render
The backend uses TensorFlow, which requires a containerized environment (Docker).

1.  **Log in to Render** and click **New +** -> **Web Service**.
2.  **Connect your GitHub repository**.
3.  **Configure the Service**:
    - **Name**: `potato-disease-backend` (or any name).
    - **Runtime**: **Docker** (Important!).
    - **Region**: Choose one close to you (e.g., Singapore, Frankfurt, Oregon).
    - **Instance Type**: **Free**.
4.  **Environment Variables** (Click "Advanced" or "Environment"):
    - Add `GEMINI_API_KEY`: Paste your actual Gemini API key here.
    - Add `PORT`: `8000` (Render usually detects this, but good to be safe).
    - Add `MODEL_PATH`: `models/best_model.keras`
5.  **Click "Create Web Service"**.
6.  **Wait for Deployment**: It may take 5-10 minutes to build the Docker image.
7.  **Copy the Backend URL**: Once deployed, you will see a URL like `https://potato-disease-backend-xyz.onrender.com`. **Copy this URL**.

---

## Part 2: Connect Frontend to Backend
1.  Open the file `frontend/config.js` in your codebase.
2.  Look for the `production` section:
    ```javascript
    production: {
        // TODO: Replace with your actual Render backend URL after deployment
        BACKEND_URL: 'https://potato-disease-backend-latest.onrender.com', 
        ...
    }
    ```
3.  **Replace** the placeholder URL with your **actual Render Backend URL** (from Part 1).
    - Example: `BACKEND_URL: 'https://potato-disease-backend-ad2s.onrender.com',`
    - **Important**: Do not include a trailing slash `/` at the end.
4.  **Commit and Push** this change to GitHub.

---

## Part 3: Deploy Frontend to Vercel
1.  **Log in to Vercel** and click **"Add New..."** -> **Project**.
2.  **Import your GitHub repository**.
3.  **Configure Project**:
    - **Framework Preset**: Other (default is fine).
    - **Root Directory**: Click "Edit" and select the `frontend` folder. **(Crucial Step!)**
4.  **Click "Deploy"**.
5.  Vercel will deploy your website in seconds.
6.  **Visit your shiny new website!**

## Troubleshooting
- **Chatbot not working?** Check if `GEMINI_API_KEY` is set correctly in Render.
- **Prediction error?** Check the browser console (F12) to see if it's a CORS issue or if the Backend URL is wrong.
- **"Model not loaded"?** The first request might be slow as the model loads. Try again in a few seconds.
