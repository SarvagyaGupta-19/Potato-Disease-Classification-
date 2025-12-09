from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional
import google.generativeai as genai
import os
from dotenv import load_dotenv

load_dotenv()

router = APIRouter(prefix="/chat", tags=["chatbot"])

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_API_KEY:
    print("WARNING: GEMINI_API_KEY not found in environment variables")
else:
    genai.configure(api_key=GEMINI_API_KEY)
    print("Gemini API configured successfully")

conversation_context = {}

class ChatRequest(BaseModel):
    message: str
    session_id: str = "default"
    disease_context: Optional[dict] = None
    language: str = "en"

class ClearChatRequest(BaseModel):
    session_id: str = "default"


@router.post("")
async def chat(payload: ChatRequest):
    if not GEMINI_API_KEY:
        raise HTTPException(
            status_code=500,
            detail="Gemini API key not configured. Add GEMINI_API_KEY to .env file"
        )
    
    system_prompt = """You are a potato disease expert. Answer questions directly and concisely.

Rules:
- Answer ONLY what was asked
- Use paragraph format, NOT bullet points or numbered lists
- Write in natural flowing text
- Be complete but concise
- No markdown formatting (no *, **, #, etc.)
- No greetings or filler phrases"""
    
    if payload.disease_context:
        disease = payload.disease_context.get("class", "Unknown")
        confidence = payload.disease_context.get("confidence", 0)
        system_prompt += f"\n\nCurrent Diagnosis: {disease} with {confidence:.1%} confidence."
        system_prompt += "\nProvide advice specific to this diagnosis when relevant."
    
    if payload.language == "hi":
        system_prompt += "\n\nIMPORTANT: Respond ONLY in Hindi (Devanagari script). Do not use English."
    
    session_id = payload.session_id
    if session_id not in conversation_context:
        conversation_context[session_id] = []
    
    try:
        model = genai.GenerativeModel(
            model_name='gemini-2.5-flash',
            generation_config={
                "temperature": 0.5,
                "top_p": 0.8,
                "top_k": 20,
                "max_output_tokens": 800,
            }
        )
        
        history_text = ""
        for msg in conversation_context[session_id][-2:]:
            history_text += f"{msg['role']}: {msg['content']}\n\n"
        
        if history_text:
            full_message = f"{system_prompt}\n\nPrevious messages:\n{history_text}Current question: {payload.message}\n\nAnswer in natural paragraph format:"
        else:
            full_message = f"{system_prompt}\n\nQuestion: {payload.message}\n\nAnswer in natural paragraph format:"
        
        response = model.generate_content(full_message)
        assistant_message = response.text.strip()
        
        conversation_context[session_id].append({"role": "User", "content": payload.message})
        conversation_context[session_id].append({"role": "Assistant", "content": assistant_message})
        
        if len(conversation_context[session_id]) > 10:
            conversation_context[session_id] = conversation_context[session_id][-10:]
        
        return {
            "response": assistant_message,
            "session_id": session_id,
            "success": True
        }
    
    except Exception as e:
        error_msg = str(e)
        
        if "API_KEY_INVALID" in error_msg or "invalid API key" in error_msg.lower():
            return {
                "response": "Invalid API key. Please check your Gemini API key configuration.",
                "error": "Invalid API key",
                "success": False
            }
        elif "quota" in error_msg.lower() or "rate limit" in error_msg.lower():
            return {
                "response": "API quota exceeded. Please try again later or upgrade your Gemini API plan.",
                "error": "Rate limit exceeded",
                "success": False
            }
        else:
            return {
                "response": "I encountered an error processing your request. Please try again.",
                "error": error_msg,
                "success": False
            }


@router.post("/clear")
async def clear_chat(payload: ClearChatRequest):
    if payload.session_id in conversation_context:
        conversation_context[payload.session_id] = []
    return {"message": "Conversation cleared", "session_id": payload.session_id}
