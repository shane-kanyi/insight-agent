# app/main.py
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()

class TextInput(BaseModel):
    text: str

class AnalysisResult(BaseModel):
    original_text: str
    word_count: int
    character_count: int

@app.post("/analyze", response_model=AnalysisResult)
def analyze_text(payload: TextInput):
    """
    Analyzes a piece of text to count words and characters.
    """
    text = payload.text
    word_count = len(text.split())
    character_count = len(text)

    return {
        "original_text": text,
        "word_count": word_count,
        "character_count": character_count
    }

@app.get("/")
def read_root():
    return {"message": "Insight-Agent API is running."}