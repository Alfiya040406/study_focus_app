import os
import uuid
from datetime import datetime

from flask import Flask, jsonify, request
from flask_cors import CORS
from werkzeug.utils import secure_filename

from auth import (
    hash_password,
    is_valid_email,
    is_valid_password,
    verify_password,
)
from config import Config
from database import get_connection, init_db
from utils.image_utils import extract_text_from_image
from utils.pdf_utils import extract_text_from_pdf
from utils.ai_utils import (
    ask_general_ai,
    explain_note_text,
    answer_from_note_text,
)

app = Flask(__name__)
app.config.from_object(Config)
CORS(app)

os.makedirs(app.config["UPLOAD_FOLDER"], exist_ok=True)
init_db()

ALLOWED_EXTENSIONS = {"pdf", "png", "jpg", "jpeg", "webp"}


def allowed_file(filename: str) -> bool:
    return (
        "." in filename
        and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTENSIONS
    )


def save_uploaded_file(file) -> tuple[str, str]:
    filename = secure_filename(file.filename)
    unique_filename = f"{uuid.uuid4().hex}_{filename}"
    file_path = os.path.join(app.config["UPLOAD_FOLDER"], unique_filename)
    file.save(file_path)
    return unique_filename, file_path


def extract_text_from_file(file_path: str, file_name: str) -> str:
    ext = file_name.rsplit(".", 1)[1].lower()

    if ext == "pdf":
        return extract_text_from_pdf(file_path)

    if ext in {"png", "jpg", "jpeg", "webp"}:
        return extract_text_from_image(file_path)

    return ""


@app.route("/", methods=["GET"])
def home():
    return jsonify({"message": "Study Tracker backend is running"}), 200


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"}), 200


@app.route("/signup", methods=["POST"])
def signup():
    try:
        data = request.get_json()

        username = data.get("username", "").strip()
        email = data.get("email", "").strip().lower()
        password = data.get("password", "").strip()

        if not username or not email or not password:
            return jsonify({"error": "Username, email and password are required"}), 400

        if len(username) < 2:
            return jsonify({"error": "Username must be at least 2 characters"}), 400

        if not is_valid_email(email):
            return jsonify({"error": "Invalid email format"}), 400

        if not is_valid_password(password):
            return jsonify({
                "error": "Password must contain at least one uppercase letter, one number, one special character, and be at least 6 characters long"
            }), 400

        conn = get_connection()
        cursor = conn.cursor()

        cursor.execute("SELECT id FROM users WHERE email = ?", (email,))
        existing_user = cursor.fetchone()

        if existing_user:
            conn.close()
            return jsonify({"error": "Email already registered"}), 409

        password_hash = hash_password(password)

        cursor.execute(
            """
            INSERT INTO users (username, email, password_hash, created_at)
            VALUES (?, ?, ?, ?)
            """,
            (
                username,
                email,
                password_hash,
                datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            ),
        )

        conn.commit()
        conn.close()

        return jsonify({
            "success": True,
            "message": "Signup successful"
        }), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/login", methods=["POST"])
def login():
    try:
        data = request.get_json()

        email = data.get("email", "").strip().lower()
        password = data.get("password", "").strip()

        if not email or not password:
            return jsonify({"error": "Email and password are required"}), 400

        conn = get_connection()
        cursor = conn.cursor()

        cursor.execute(
            "SELECT id, username, email, password_hash FROM users WHERE email = ?",
            (email,),
        )
        user = cursor.fetchone()
        conn.close()

        if not user:
            return jsonify({"error": "Invalid email or password"}), 401

        if not verify_password(password, user["password_hash"]):
            return jsonify({"error": "Invalid email or password"}), 401

        return jsonify({
            "success": True,
            "message": "Login successful",
            "username": user["username"],
            "email": user["email"],
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/upload-note", methods=["POST"])
def upload_note():
    try:
        email = request.form.get("email", "").strip().lower()
        subject = request.form.get("subject", "").strip()
        module = request.form.get("module", "").strip()
        file = request.files.get("file")

        if not email or not subject or not module or not file:
            return jsonify({"error": "Email, subject, module and file are required"}), 400

        if file.filename == "":
            return jsonify({"error": "No file selected"}), 400

        if not allowed_file(file.filename):
            return jsonify({"error": "Only PDF and image files are allowed"}), 400

        unique_name, file_path = save_uploaded_file(file)
        extracted_text = extract_text_from_file(file_path, unique_name).strip()
        file_type = unique_name.rsplit(".", 1)[1].lower()

        conn = get_connection()
        cursor = conn.cursor()

        cursor.execute(
            """
            INSERT INTO notes
            (email, subject, module, file_name, file_path, file_type, extracted_text, uploaded_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                email,
                subject,
                module,
                unique_name,
                file_path,
                file_type,
                extracted_text,
                datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            ),
        )

        note_id = cursor.lastrowid

        conn.commit()
        conn.close()

        return jsonify({
            "success": True,
            "message": "Note uploaded successfully",
            "note_id": note_id,
            "file_name": unique_name,
            "subject": subject,
            "module": module,
        }), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/notes", methods=["GET"])
def get_notes():
    try:
        email = request.args.get("email", "").strip().lower()

        if not email:
            return jsonify({"error": "Email is required"}), 400

        conn = get_connection()
        cursor = conn.cursor()

        cursor.execute(
            """
            SELECT id, email, subject, module, file_name, file_path, file_type, extracted_text, uploaded_at
            FROM notes
            WHERE email = ?
            ORDER BY subject ASC, module ASC, id DESC
            """,
            (email,),
        )

        rows = cursor.fetchall()
        notes = [dict(row) for row in rows]

        conn.close()

        return jsonify({"success": True, "notes": notes}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/delete-note/<int:note_id>", methods=["DELETE"])
def delete_note(note_id):
    try:
        email = request.args.get("email", "").strip().lower()

        if not email:
            return jsonify({"error": "Email is required"}), 400

        conn = get_connection()
        cursor = conn.cursor()

        cursor.execute(
            "SELECT file_path FROM notes WHERE id = ? AND email = ?",
            (note_id, email),
        )
        note = cursor.fetchone()

        if not note:
            conn.close()
            return jsonify({"error": "Note not found"}), 404

        file_path = note["file_path"]

        if file_path and os.path.exists(file_path):
            os.remove(file_path)

        cursor.execute(
            "DELETE FROM notes WHERE id = ? AND email = ?",
            (note_id, email),
        )

        conn.commit()
        conn.close()

        return jsonify({"success": True, "message": "Note deleted"}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/ask-ai", methods=["POST"])
def ask_ai():
    try:
        data = request.get_json()
        email = data.get("email", "").strip().lower()
        question = data.get("question", "").strip()

        if not email or not question:
            return jsonify({"error": "Email and question are required"}), 400

        answer = ask_general_ai(question)

        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute(
            """
            INSERT INTO ai_history (email, question, answer, note_id, created_at)
            VALUES (?, ?, ?, ?, ?)
            """,
            (
                email,
                question,
                answer,
                None,
                datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            ),
        )
        conn.commit()
        conn.close()

        return jsonify({
            "success": True,
            "answer": answer,
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/explain-note-by-id", methods=["POST"])
def explain_note_by_id():
    try:
        data = request.get_json()

        note_id = data.get("note_id")
        email = data.get("email", "").strip().lower()

        if not note_id or not email:
            return jsonify({"error": "note_id and email are required"}), 400

        conn = get_connection()
        cursor = conn.cursor()

        cursor.execute(
            """
            SELECT extracted_text
            FROM notes
            WHERE id = ? AND email = ?
            """,
            (note_id, email),
        )
        note = cursor.fetchone()

        if not note:
            conn.close()
            return jsonify({"error": "Note not found"}), 404

        note_text = (note["extracted_text"] or "").strip()

        if not note_text:
            conn.close()
            return jsonify({"error": "No readable text found in this note"}), 400

        answer = explain_note_text(
            note_text,
            "Explain this note clearly in simple language.",
        )

        cursor.execute(
            """
            INSERT INTO ai_history (email, question, answer, note_id, created_at)
            VALUES (?, ?, ?, ?, ?)
            """,
            (
                email,
                "Explain selected note",
                answer,
                note_id,
                datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            ),
        )

        conn.commit()
        conn.close()

        return jsonify({
            "success": True,
            "answer": answer,
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/ask-note-by-id", methods=["POST"])
def ask_note_by_id():
    try:
        data = request.get_json()

        note_id = data.get("note_id")
        email = data.get("email", "").strip().lower()
        question = data.get("question", "").strip()

        if not note_id or not email or not question:
            return jsonify({"error": "note_id, email and question are required"}), 400

        conn = get_connection()
        cursor = conn.cursor()

        cursor.execute(
            """
            SELECT extracted_text
            FROM notes
            WHERE id = ? AND email = ?
            """,
            (note_id, email),
        )
        note = cursor.fetchone()

        if not note:
            conn.close()
            return jsonify({"error": "Note not found"}), 404

        note_text = (note["extracted_text"] or "").strip()

        if not note_text:
            conn.close()
            return jsonify({"error": "No readable text found in this note"}), 400

        answer = answer_from_note_text(note_text, question)

        cursor.execute(
            """
            INSERT INTO ai_history (email, question, answer, note_id, created_at)
            VALUES (?, ?, ?, ?, ?)
            """,
            (
                email,
                question,
                answer,
                note_id,
                datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            ),
        )

        conn.commit()
        conn.close()

        return jsonify({
            "success": True,
            "answer": answer,
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/ai-history", methods=["GET"])
def get_ai_history():
    try:
        email = request.args.get("email", "").strip().lower()

        if not email:
            return jsonify({"error": "Email is required"}), 400

        conn = get_connection()
        cursor = conn.cursor()

        cursor.execute(
            """
            SELECT id, question, answer, note_id, created_at
            FROM ai_history
            WHERE email = ?
            ORDER BY id DESC
            LIMIT 20
            """,
            (email,),
        )

        rows = cursor.fetchall()
        history = [dict(row) for row in rows]

        conn.close()

        return jsonify({
            "success": True,
            "history": history,
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/ai-history", methods=["DELETE"])
def clear_ai_history():
    try:
        email = request.args.get("email", "").strip().lower()

        if not email:
            return jsonify({"error": "Email is required"}), 400

        conn = get_connection()
        cursor = conn.cursor()

        cursor.execute(
            "DELETE FROM ai_history WHERE email = ?",
            (email,),
        )

        conn.commit()
        conn.close()

        return jsonify({
            "success": True,
            "message": "AI history cleared",
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/study-session", methods=["POST"])
def save_study_session():
    try:
        data = request.get_json()

        email = data.get("email", "").strip().lower()
        method_title = data.get("method_title", "").strip()
        phase = data.get("phase", "").strip()
        minutes = int(data.get("minutes", 0))

        if not email or minutes <= 0:
            return jsonify({"error": "Email and valid minutes are required"}), 400

        session_date = datetime.now().strftime("%Y-%m-%d")

        conn = get_connection()
        cursor = conn.cursor()

        cursor.execute(
            """
            INSERT INTO study_sessions (email, method_title, phase, session_date, minutes, created_at)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (
                email,
                method_title,
                phase,
                session_date,
                minutes,
                datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            ),
        )

        conn.commit()
        conn.close()

        return jsonify({
            "success": True,
            "message": "Study session saved",
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/study-summary", methods=["GET"])
def get_study_summary():
    try:
        email = request.args.get("email", "").strip().lower()

        if not email:
            return jsonify({"error": "Email is required"}), 400

        today = datetime.now().strftime("%Y-%m-%d")

        conn = get_connection()
        cursor = conn.cursor()

        cursor.execute(
            """
            SELECT COALESCE(SUM(minutes), 0) AS total_today
            FROM study_sessions
            WHERE email = ? AND session_date = ?
            """,
            (email, today),
        )
        today_row = cursor.fetchone()
        today_minutes = today_row["total_today"] if today_row else 0

        cursor.execute(
            """
            SELECT COALESCE(SUM(minutes), 0) AS total_minutes
            FROM study_sessions
            WHERE email = ?
            """,
            (email,),
        )
        total_row = cursor.fetchone()
        total_minutes = total_row["total_minutes"] if total_row else 0

        cursor.execute(
            """
            SELECT session_date, COALESCE(SUM(minutes), 0) AS minutes
            FROM study_sessions
            WHERE email = ?
            GROUP BY session_date
            ORDER BY session_date DESC
            """,
            (email,),
        )
        rows = cursor.fetchall()

        history = [
            {
                "date": row["session_date"],
                "minutes": row["minutes"],
            }
            for row in rows
        ]

        conn.close()

        return jsonify({
            "success": True,
            "today_minutes": today_minutes,
            "total_minutes": total_minutes,
            "history": history,
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5000)