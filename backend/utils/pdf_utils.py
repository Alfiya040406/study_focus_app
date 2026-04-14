import fitz


def extract_text_from_pdf(pdf_path: str) -> str:
    text_chunks = []

    with fitz.open(pdf_path) as doc:
        for page_number, page in enumerate(doc, start=1):
            page_text = page.get_text("text")
            if page_text and page_text.strip():
                text_chunks.append(
                    f"\n--- Page {page_number} ---\n{page_text.strip()}"
                )

    return "\n".join(text_chunks).strip()