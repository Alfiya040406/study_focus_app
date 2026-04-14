import os
import base64
from PIL import Image
import pytesseract
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Set Tesseract path from .env (for Windows)
tesseract_path = os.getenv("TESSERACT_CMD")

if tesseract_path:
    pytesseract.pytesseract.tesseract_cmd = tesseract_path


def extract_text_from_image(image_path: str) -> str:
    """
    Extract text from an image using Tesseract OCR.
    """
    try:
        image = Image.open(image_path)

        # Optional: convert to RGB to avoid issues
        image = image.convert("RGB")

        text = pytesseract.image_to_string(image)

        return text.strip()

    except Exception as e:
        print(f"[ERROR] OCR failed: {e}")
        return ""


def image_to_base64(image_path: str) -> str:
    """
    Convert image to base64 string (for AI vision fallback).
    """
    try:
        with open(image_path, "rb") as img_file:
            return base64.b64encode(img_file.read()).decode("utf-8")

    except Exception as e:
        print(f"[ERROR] Base64 conversion failed: {e}")
        return ""


def get_mime_type_from_filename(filename: str) -> str:
    """
    Detect MIME type based on file extension.
    """
    ext = os.path.splitext(filename.lower())[1]

    if ext == ".png":
        return "image/png"
    elif ext in [".jpg", ".jpeg"]:
        return "image/jpeg"
    elif ext == ".webp":
        return "image/webp"

    return "image/jpeg"