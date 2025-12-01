# LaTeXKit Naming System

LaTeXKit uses a sequential, branch-based naming convention for documents.

## Naming Format

Documents are named using the pattern: `{NUMBER}-{SLUG}`

### Components

1. **NUMBER**: Sequential document number (001, 002, 003, ...)
   - Automatically assigned by scanning existing `documents/` directory
   - Always 3 digits, zero-padded
   - Increments automatically for each new document

2. **SLUG**: Descriptive text derived from document description
   - Generated from document description or user-provided short name
   - Stop words removed
   - Acronyms preserved
   - Lowercase, hyphen-separated
   - Maximum 48 characters by default

### Examples

```bash
# Sequential numbering
001-climate-change-research
002-ethics-proposal
003-annual-report
```

## Slug Generation

### Automatic Generation

The system generates meaningful slugs from document descriptions:

```bash
# Input: "Write essay on climate change impacts"
# Output: 001-climate-essay

# Input: "Research proposal for AI ethics"
# Output: 002-ai-ethics-proposal

# Input: "Annual sustainability report Q4 2024"
# Output: 003-annual-sustainability-report
```

### User-Provided Short Names

You can specify a custom short name (2-4 words):

```bash
./latexkit start "Long document description here" --short-name "my-project"
# Result: 001-my-project
```

### Slug Algorithm

1. **Normalize**: Convert to ASCII, handle special characters
2. **Tokenize**: Split into words, convert to lowercase
3. **Filter Stop Words**: Remove common/meaningless words
4. **Preserve Acronyms**: Keep ALLCAPS words even if short
5. **Limit Length**: Respect max words (4) and max characters (48)
6. **Sanitize**: Ensure filesystem-safe characters only

## Stop Words

Common words automatically removed from slugs to create meaningful names:

```
i, a, an, the, to, for, of, in, on, at, by, with, from,
is, are, was, were, be, been, being, have, has, had,
do, does, did, will, would, should, could, can, may,
might, must, shall, this, that, these, those, my, your,
our, their, want, need, add, get, set, write, create,
make, draft, document, paper, report
```

## Branch Naming

Each document gets its own git branch with the same name:

```bash
# Document directory: documents/{NUMBER}-{SLUG}/
# Git branch: {NUMBER}-{SLUG}
```

This enables:
- Isolated work per document
- Clean git history per project
- Easy switching between documents

## Best Practices

1. **Be Specific**: Use descriptive document descriptions
   - Good: "Climate change impact on coastal cities"
   - Bad: "Write essay"

2. **Use Short Names for Important Projects**: 
   - Provide `--short-name` for memorable branch names
   - Keep it concise (2-4 words)

3. **Let the System Number**: 
   - Don't manually specify numbers
   - System ensures uniqueness automatically

4. **Descriptive Slugs**: 
   - Default 4 words usually works well
   - System handles acronyms intelligently (e.g., "AI", "PDF")

## Document Type Support

The system works for any document type:

- **Academic**: assignments, essays, papers, theses
- **Business**: reports, proposals, memos, presentations
- **Personal**: letters, resumes, portfolios
- **Technical**: documentation, specifications, manuals
- **Creative**: articles, books, scripts

## Troubleshooting

### Slug too long

The system automatically limits slugs to 48 characters. If still too long, provide a custom `--short-name`.

### Slug too generic

Make document description more specific or use `--short-name` option.

### Non-English documents

The system handles Unicode and transliterates to ASCII automatically. For better slug generation, consider providing a custom `--short-name` in English or romanized form.

## See Also

- [Common Utilities](../scripts/bash/common.sh)
- [Document Creation](../scripts/bash/create-new-document.sh)
- [Workflow Guide](../../README.md)
