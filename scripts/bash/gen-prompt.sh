#!/usr/bin/env bash
# gen-prompt.sh: Meracik prompt lengkap dengan konteks file
# Usage: ./latexkit prompt <stage>

set -e
source "$(dirname "$0")/common.sh"
eval $(get_document_paths)

if [[ -z "$DOCUMENT_DIR" ]]; then
    echo "Error: No active project found."
    echo "Please run './latexkit switch <project_id>' or cd into a project directory."
    exit 1
fi

STAGE="$1"
OUTPUT_FILE="${DOCUMENT_DIR}/generated_work/current_prompt.txt"
mkdir -p "$(dirname "$OUTPUT_FILE")"

# 1. Tentukan Template Prompt berdasarkan Stage
PROMPT_TEMPLATE=""
case "$STAGE" in
    "context"|"brief")
        PROMPT_TEMPLATE=".latexkit/prompts/context-brief.md"
        ;;
    "research")
        PROMPT_TEMPLATE=".latexkit/prompts/research.md"
        ;;
    # ... stage lain ...
    *)
        echo "Stage tidak dikenal. Gunakan: context, research"
        exit 1
        ;;
esac

# 2. Header Prompt (Instruksi Sistem)
echo "# SISTEM INSTRUCTION" > "$OUTPUT_FILE"
echo "You are LatexKit Assistant. Your goal is to process the user context and update the project files." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 3. Masukkan Konten Template Prompt Utama
if [ -f "$PROMPT_TEMPLATE" ]; then
    cat "$PROMPT_TEMPLATE" >> "$OUTPUT_FILE"
else
    echo "Error: Template prompt $PROMPT_TEMPLATE tidak ditemukan."
    exit 1
fi
echo "" >> "$OUTPUT_FILE"

# 4. INGESTION: Baca Konteks File (Kunci dari requestmu!)
echo "# PROJECT CONTEXT FILES" >> "$OUTPUT_FILE"

# 4a. Baca start.md (State saat ini)
if [ -f "${DOCUMENT_DIR}/start.md" ]; then
    echo "## Current State (start.md):" >> "$OUTPUT_FILE"
    cat "${DOCUMENT_DIR}/start.md" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
fi

# 4b. Baca semua file di assignment_info/ (Instruksi Dosen/Materi)
echo "## Raw Context Materials (assignment_info/):" >> "$OUTPUT_FILE"
if [ -d "${DOCUMENT_DIR}/assignment_info" ]; then
    # Jika ada file markdown yang sudah diconvert
    for f in "${DOCUMENT_DIR}/assignment_info"/*.md; do
        [ -e "$f" ] || continue
        echo "### File: $(basename "$f")" >> "$OUTPUT_FILE"
        echo '```markdown' >> "$OUTPUT_FILE"
        cat "$f" >> "$OUTPUT_FILE"
        echo '```' >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    done
    
    # Optional: Tambahkan peringatan jika ada PDF belum diconvert
    count_pdf=$(find "${DOCUMENT_DIR}/assignment_info" -name "*.pdf" | wc -l)
    if [ "$count_pdf" -gt 0 ]; then
        echo "> Note: There are $count_pdf PDF files in assignment_info. I have attached the converted Markdown versions above if available." >> "$OUTPUT_FILE"
    fi
fi

# 5. Output Final
echo "Prompt telah dibuat di: $OUTPUT_FILE"
# Copy ke clipboard (Mac/Linux support)
if command -v pbcopy &> /dev/null; then
    cat "$OUTPUT_FILE" | pbcopy
    echo "✅ Prompt telah disalin ke Clipboard! Tinggal Paste ke AI."
elif command -v xclip &> /dev/null; then
    cat "$OUTPUT_FILE" | xclip -selection clipboard
    echo "✅ Prompt telah disalin ke Clipboard! Tinggal Paste ke AI."
else
    echo "⚠️  Silakan buka file tersebut dan copy manual."
fi
