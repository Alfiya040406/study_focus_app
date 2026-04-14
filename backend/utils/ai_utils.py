import os
import time
from dotenv import load_dotenv
from google import genai

load_dotenv()

client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))
MODEL_NAME = os.getenv("GEMINI_MODEL", "gemini-2.5-flash-lite")


def _generate_with_retry(prompt: str, retries: int = 3, delay: int = 2) -> str:
    last_error = None

    for attempt in range(retries):
        try:
            response = client.models.generate_content(
                model=MODEL_NAME,
                contents=prompt,
            )
            return response.text or ""
        except Exception as e:
            last_error = e
            if attempt < retries - 1:
                time.sleep(delay)

    raise Exception(str(last_error))


def ask_general_ai(question: str) -> str:
    return _generate_with_retry(question)


def explain_note_text(note_text: str, user_question: str = "") -> str:
    prompt = f"""
You are a helpful study assistant.

Explain the following notes in simple, student-friendly language.

Notes:
{note_text}

Extra question:
{user_question if user_question else "None"}
"""
    return _generate_with_retry(prompt)


def answer_from_note_text(note_text: str, question: str) -> str:
    prompt = f"""
Answer the user's question only using the notes below.
If the answer is not available in the notes, say: "Not available in notes."

Question:
{question}

Notes:
{note_text}
"""
    return _generate_with_retry(prompt)