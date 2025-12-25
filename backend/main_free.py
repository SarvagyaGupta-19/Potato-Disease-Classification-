from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
try:
    from tensorflow import keras  # type: ignore
except ImportError:
    import tensorflow.keras as keras  # type: ignore
import numpy as np
from PIL import Image
from io import BytesIO
import os
import logging
from chatbot import router as chatbot_router

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Potato Disease Detection API",
    version="2.0.0",
    description="AI-powered potato disease detection"
)

app.include_router(chatbot_router)

# CORS Configuration - Update after deploying frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Change to your frontend URL in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load TensorFlow model at startup (no TF Serving needed for free tier)
MODEL_PATH = os.getenv("MODEL_PATH", "models/best_model.keras")
logger.info(f"Loading model from {MODEL_PATH}...")

try:
    model = keras.models.load_model(MODEL_PATH)
    logger.info("✅ Model loaded successfully!")
except Exception as e:
    logger.error(f"❌ Failed to load model: {str(e)}")
    model = None

CLASS_NAMES = ["Early_blight", "Late_blight", "Healthy"]


@app.on_event("startup")
async def startup_event():
    """Log startup information"""
    logger.info("="*50)
    logger.info("🚀 Potato Disease Detection API Starting...")
    logger.info(f"📊 Model Status: {'✅ Loaded' if model else '❌ Not Loaded'}")
    logger.info(f"🌐 Environment: {os.getenv('ENVIRONMENT', 'development')}")
    logger.info(f"🔑 Gemini API Key: {'✅ Set' if os.getenv('GEMINI_API_KEY') else '❌ Not Set'}")
    logger.info(f"🎯 Classes: {CLASS_NAMES}")
    logger.info("="*50)


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "name": "Potato Disease Detection API",
        "version": "2.0.0",
        "status": "online",
        "model_loaded": model is not None
    }


@app.get("/ping")
async def ping():
    """Simple health check endpoint - responds immediately"""
    return {"status": "ok"}


@app.get("/health")
async def health_check():
    """Detailed health check"""
    return {
        "api": "healthy",
        "model": "loaded" if model else "not_loaded",
        "classes": CLASS_NAMES,
        "environment": os.getenv("ENVIRONMENT", "development")
    }


def read_file_as_image(data) -> np.ndarray:
    """Convert uploaded file to normalized numpy array"""
    try:
        image = Image.open(BytesIO(data)).convert("RGB")
        image = image.resize((256, 256))
        img_array = np.array(image, dtype=np.float32)
        img_array = img_array / 255.0
        return img_array
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid image file: {str(e)}")


@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    """
    Predict potato disease from uploaded image
    
    Returns:
        - class: Predicted disease class
        - class_index: Index of predicted class
        - confidence: Prediction confidence (0-1)
    """
    if model is None:
        raise HTTPException(
            status_code=503,
            detail="Model not loaded. Please contact administrator."
        )
    
    # Validate file type
    if file.content_type and not file.content_type.startswith("image/"):
        raise HTTPException(
            status_code=400,
            detail="File must be an image (JPEG, PNG, etc.)"
        )
    
    try:
        # Read and preprocess image
        image_data = await file.read()
        
        # Check file size (max 10MB)
        if len(image_data) > 10 * 1024 * 1024:
            raise HTTPException(status_code=413, detail="Image too large. Max 10MB")
        
        image = read_file_as_image(image_data)
        img_batch = np.expand_dims(image, 0)
        
        # Make prediction directly with embedded model
        prediction = model.predict(img_batch, verbose=0)[0]
        
        predicted_index = int(np.argmax(prediction))
        predicted_class = CLASS_NAMES[predicted_index]
        confidence = float(np.max(prediction))
        
        logger.info(f"Prediction: {predicted_class} ({confidence:.2%})")
        
        return {
            "class": predicted_class,
            "class_index": predicted_index,
            "confidence": confidence
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Prediction error: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Prediction failed: {str(e)}"
        )


# Translation endpoint (keeping from original)
from deep_translator import GoogleTranslator
from pydantic import BaseModel
from typing import List
import html
import asyncio


class TranslationRequest(BaseModel):
    texts: List[str]
    target: str


def unescape_translations(translations, originals):
    return [
        html.unescape(item) if isinstance(item, str) else original 
        for item, original in zip(translations, originals)
    ]


@app.post("/translate")
async def translate_text(payload: TranslationRequest):
    """Translate text to target language"""
    if not payload.texts:
        return {"translations": []}
    
    target_lang = payload.target.lower() if payload.target else "en"

    if target_lang == "en":
        return {"translations": payload.texts}
    
    texts = [text or "" for text in payload.texts]

    try:
        translator = GoogleTranslator(source="auto", target=target_lang)
        translations = []
        
        batch_size = 25
        for i in range(0, len(texts), batch_size):
            batch = texts[i:i + batch_size]
            try:
                batch_translations = translator.translate_batch(batch)
                translations.extend(batch_translations)
                if i + batch_size < len(texts):
                    await asyncio.sleep(0.1)
            except Exception as batch_error:
                logger.warning(f"Batch translation failed: {batch_error}")
                for text in batch:
                    try:
                        translation = translator.translate(text) if text else text
                        translations.append(translation)
                        await asyncio.sleep(0.05)
                    except:
                        translations.append(text)
        
        translations = unescape_translations(translations, payload.texts)
        return {"translations": translations}
        
    except Exception as e:
        logger.error(f"Translation error: {str(e)}")
        return {
            "translations": payload.texts,
            "error": "Translation service temporarily unavailable",
            "success": False
        }


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
