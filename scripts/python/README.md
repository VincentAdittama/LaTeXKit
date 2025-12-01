# LatexKit Python Scripts

This directory contains Python utilities for enhanced document processing in LatexKit.

## pdf_to_md.py

Enhanced PDF to Markdown converter with intelligent text extraction.

### Features

- **Smart Detection**: Automatically detects if PDF has extractable text
- **Dual Extraction Methods**:
  - **Pdfplumber**: For searchable PDFs with text content
    - Layout preservation with spatial analysis
    - Maintains paragraph breaks and line structure
    - Configurable tolerance for text grouping
  - **Tesseract OCR**: For scanned/image-based PDFs
    - Bounding box analysis for layout detection
    - Preserves vertical spacing and paragraph breaks
    - Detects line breaks based on position changes
- **Table Extraction**: Preserves tables from PDFs (pdfplumber only)
- **Robust Error Handling**: Continues processing even if individual pages fail
- **Layout-Aware Processing**: 
  - Respects font size changes (headers vs body text)
  - Maintains irregular spacing between paragraphs
  - Preserves line breaks in original document
  - Detects and maintains section boundaries

### Dependencies

The script uses `uvx` to manage dependencies automatically. Required packages:
- `pdfplumber`: PDF text and table extraction
- `pytesseract`: Python wrapper for Tesseract OCR
- `Pillow`: Image processing for OCR

System requirements:
- `pandoc`: For markdown conversion (install via Homebrew)
- `tesseract`: OCR engine (install via Homebrew)
- `uv/uvx`: Python package runner (install via curl)

### Installation

```bash
# macOS/Linux
brew install pandoc tesseract uv
```

### Usage

The script is automatically invoked by the bash conversion scripts. For manual use:

```bash
# Via uvx (recommended - handles dependencies automatically)
uvx --with pdfplumber --with pytesseract --with Pillow python pdf_to_md.py input.pdf output.md

# Direct Python (requires pre-installed dependencies)
python pdf_to_md.py input.pdf output.md
```

### How It Works

1. **Detection Phase**: Checks if PDF contains extractable text
   - If text found → Use pdfplumber (fast, accurate for digital PDFs)
   - If no text → Use Tesseract OCR (slower, works on scanned documents)

2. **Extraction Phase**:
   - **Text PDFs (pdfplumber)**:
     - Extract text with `layout=True` to maintain spatial relationships
     - Use x_tolerance and y_tolerance to group related text
     - Detect paragraph breaks based on vertical spacing
     - Clean excessive whitespace while preserving structure
   - **Scanned PDFs (Tesseract OCR)**:
     - Convert page to 300 DPI image
     - Use `image_to_data()` to get bounding boxes for each word
     - Analyze vertical positions to detect line breaks
     - Detect paragraph breaks from large vertical gaps
     - Preserve original layout structure
   - Extract tables (pdfplumber only)
   - Convert to markdown-friendly format

3. **Conversion Phase**:
   - Pipe extracted text through pandoc
   - Generate final markdown file with preserved structure

### Advantages Over pdftotext

- **Better Table Handling**: Preserves table structure
- **OCR Support**: Can process scanned PDFs
- **Smarter Text Extraction**: Better handling of complex layouts
- **Table Extraction**: Converts PDF tables to markdown format
- **Layout Preservation**: Maintains paragraph breaks, line spacing, and visual structure
  - Respects original document formatting
  - Detects headers vs body text based on spacing
  - Preserves section boundaries
  - Doesn't merge paragraphs into continuous text blocks

### Layout Preservation Examples

**Before (pdftotext - continuous text)**:
```
This is paragraph one with some text here. This is paragraph two that should be separate but gets merged with paragraph one. This is a heading that looks like body text.
```

**After (enhanced converter - preserved structure)**:
```
This is paragraph one with some text here.

This is paragraph two that should be separate
and maintains proper line breaks.

This is a heading that looks like body text
```

### Configuration Parameters

The converter uses these parameters for optimal layout detection:

- **pdfplumber**:
  - `layout=True`: Enable spatial layout analysis
  - `x_tolerance=3`: Horizontal grouping tolerance (pixels)
  - `y_tolerance=3`: Vertical grouping tolerance (pixels)

- **Tesseract OCR**:
  - `resolution=300`: Image DPI for OCR
  - `vertical_threshold=0.5 * line_height`: Line break detection
  - `paragraph_threshold=2 * vertical_threshold`: Paragraph break detection

### Performance

- **Text PDFs**: ~2-5 seconds per file (similar to pdftotext)
- **Scanned PDFs**: ~10-30 seconds per file (depends on page count and resolution)
- **Large PDFs**: Processes incrementally, no memory issues

### Troubleshooting

**"tesseract: command not found"**
```bash
brew install tesseract
```

**"No module named 'pdfplumber'"** (when not using uvx)
```bash
pip install pdfplumber pytesseract Pillow
```

**OCR not working or poor quality**
- Check image resolution (300 DPI recommended)
- Install additional language packs: `brew install tesseract-lang`
- Verify tesseract installation: `tesseract --version`

**Script timeout**
- Large PDFs may take time with OCR
- Timeout is set to 60 seconds per file
- Consider splitting very large PDFs

### Future Enhancements

Potential improvements for future versions:
- Multi-language OCR support
- Parallel processing for multi-page PDFs
- Image extraction and embedding in markdown
- Custom OCR preprocessing (deskew, denoise)
- Progress bars for long conversions
