#!/usr/bin/env python3
"""
LatexKit: Enhanced PDF to Markdown Converter
Uses pdfplumber for text extraction, Tesseract OCR for scanned PDFs,
and pandoc for markdown conversion.

Dependencies: pdfplumber, pytesseract, Pillow, pandoc (system)
Usage: python pdf_to_md.py <input.pdf> <output.md>
"""

import sys
import subprocess
import pdfplumber
import pytesseract
from PIL import Image
import io


def has_text(pdf_path):
    """Check if PDF has extractable text."""
    try:
        with pdfplumber.open(pdf_path) as pdf:
            for page in pdf.pages:
                text = page.extract_text()
                if text and text.strip():
                    return True
        return False
    except Exception as e:
        print(f"Error checking PDF text: {e}", file=sys.stderr)
        return False


def extract_text_with_pdfplumber(pdf_path):
    """Extract text and tables using pdfplumber with layout preservation."""
    text = ""
    try:
        with pdfplumber.open(pdf_path) as pdf:
            for page_num, page in enumerate(pdf.pages, 1):
                # Extract text with layout preservation
                # Use layout=True to maintain spatial relationships
                page_text = page.extract_text(layout=True, x_tolerance=3, y_tolerance=3)
                if page_text:
                    # Process the text to preserve paragraph structure
                    # Split by double newlines (likely paragraph breaks)
                    paragraphs = page_text.split('\n\n')
                    processed_paragraphs = []
                    
                    for para in paragraphs:
                        # Clean up excessive whitespace within lines but preserve structure
                        lines = para.split('\n')
                        cleaned_lines = []
                        for line in lines:
                            # Preserve lines that have significant content
                            cleaned = line.strip()
                            if cleaned:
                                cleaned_lines.append(cleaned)
                        
                        if cleaned_lines:
                            # Join lines within a paragraph with single newline
                            processed_paragraphs.append('\n'.join(cleaned_lines))
                    
                    # Join paragraphs with double newline
                    if processed_paragraphs:
                        text += '\n\n'.join(processed_paragraphs) + "\n\n"
                
                # Extract tables separately
                tables = page.extract_tables()
                if tables:
                    for table in tables:
                        if table:
                            # Filter out None values and convert to strings
                            table_text = "\n".join([
                                " | ".join([str(cell) if cell else "" for cell in row])
                                for row in table
                            ])
                            text += f"\n{table_text}\n\n"
        
        return text
    except Exception as e:
        print(f"Error extracting text with pdfplumber: {e}", file=sys.stderr)
        return ""


def extract_text_with_tesseract(pdf_path):
    """Extract text using Tesseract OCR with layout preservation for scanned/image-based PDFs."""
    text = ""
    try:
        with pdfplumber.open(pdf_path) as pdf:
            for page_num, page in enumerate(pdf.pages, 1):
                try:
                    # Convert page to high-resolution image
                    img = page.to_image(resolution=300).original
                    
                    # Use pytesseract with layout preservation
                    # PSM 3 = Fully automatic page segmentation (default)
                    # PSM 6 = Assume a single uniform block of text
                    # We'll try to get layout info first
                    try:
                        # Get detailed layout information (bounding boxes, confidence, etc.)
                        data = pytesseract.image_to_data(img, lang='eng', output_type=pytesseract.Output.DICT)
                        
                        # Process data to preserve layout structure
                        page_text_lines = []
                        current_line = []
                        last_top = None
                        last_height = None
                        
                        for i in range(len(data['text'])):
                            text_item = data['text'][i].strip()
                            if not text_item:
                                continue
                            
                            top = data['top'][i]
                            height = data['height'][i]
                            left = data['left'][i]
                            
                            # Detect new line based on vertical position change
                            if last_top is not None:
                                # If vertical position changed significantly (more than half line height)
                                vertical_diff = abs(top - last_top)
                                threshold = (last_height or height) * 0.5
                                
                                if vertical_diff > threshold:
                                    # New line detected
                                    if current_line:
                                        page_text_lines.append(' '.join(current_line))
                                        current_line = []
                                    
                                    # Check if this is a paragraph break (large gap)
                                    if vertical_diff > threshold * 2:
                                        page_text_lines.append('')  # Empty line for paragraph break
                            
                            current_line.append(text_item)
                            last_top = top
                            last_height = height
                        
                        # Add the last line
                        if current_line:
                            page_text_lines.append(' '.join(current_line))
                        
                        # Join lines preserving structure
                        page_text = '\n'.join(page_text_lines)
                        
                    except Exception as layout_error:
                        # Fallback to simple OCR if layout detection fails
                        print(f"Warning: Layout detection failed on page {page_num}, using simple OCR: {layout_error}", file=sys.stderr)
                        page_text = pytesseract.image_to_string(img, lang='eng')
                    
                    if page_text and page_text.strip():
                        text += f"--- Page {page_num} ---\n\n{page_text}\n\n"
                        
                except Exception as page_error:
                    print(f"Warning: Failed to OCR page {page_num}: {page_error}", file=sys.stderr)
                    continue
        
        return text
    except Exception as e:
        print(f"Error extracting text with Tesseract: {e}", file=sys.stderr)
        return ""


def pdf_to_md(pdf_path, md_path):
    """Convert PDF to Markdown using best available method."""
    try:
        # Determine conversion method
        if has_text(pdf_path):
            print(f"Extracting text from searchable PDF: {pdf_path}", file=sys.stderr)
            text = extract_text_with_pdfplumber(pdf_path)
        else:
            print(f"No extractable text found. Using OCR for: {pdf_path}", file=sys.stderr)
            text = extract_text_with_tesseract(pdf_path)
        
        if not text or not text.strip():
            print(f"Warning: No text extracted from {pdf_path}", file=sys.stderr)
            # Create empty markdown file to avoid re-processing
            with open(md_path, 'w') as f:
                f.write(f"# {pdf_path}\n\n*No text could be extracted from this PDF.*\n")
            return True
        
        # Convert to Markdown with pandoc
        result = subprocess.run(
            ['pandoc', '-f', 'markdown', '-t', 'markdown'],
            input=text,
            text=True,
            capture_output=True,
            timeout=60
        )
        
        if result.returncode == 0:
            with open(md_path, 'w', encoding='utf-8') as f:
                f.write(result.stdout)
            return True
        else:
            print(f"Pandoc error for {pdf_path}: {result.stderr}", file=sys.stderr)
            return False
            
    except subprocess.TimeoutExpired:
        print(f"Error: Pandoc conversion timed out for {pdf_path}", file=sys.stderr)
        return False
    except Exception as e:
        print(f"Error processing {pdf_path}: {e}", file=sys.stderr)
        return False


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python pdf_to_md.py <input.pdf> <output.md>", file=sys.stderr)
        sys.exit(1)
    
    input_pdf = sys.argv[1]
    output_md = sys.argv[2]
    
    success = pdf_to_md(input_pdf, output_md)
    sys.exit(0 if success else 1)
