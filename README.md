# LaTeXKit

**Component-based LaTeX template manager for academic documents.**

LaTeXKit is a productivity tool designed to help you manage academic assignments, research papers, and other LaTeX-based documents using a streamlined workflow. It features a **Main-Only (Trunk-Based) workflow** where all projects live in the `documents/` folder without needing separate git branches.

## Features

- 📁 **Project Management** - Create and switch between multiple projects easily
- 🎨 **Component-based Templates** - Reusable LaTeX components (tables, figures, code blocks, etc.)
- 🔄 **AI-Assisted Workflow** - Integration with GitHub Copilot Chat for document generation
- 📚 **Academic Focus** - Built-in support for citations, bibliography (BibTeX/Biber), and APA formatting
- 🚀 **Zero Branch Switching** - All projects on main branch for easy searchability

## Quick Start

```bash
# Create a new project
./latexkit new "Essay Sejarah Indonesia"

# Switch between projects
./latexkit switch 1  # or ./latexkit switch 001-essay-sejarah-indonesia

# List all projects
./latexkit projects

# Show current project
./latexkit current

# Build PDF
./latexkit build
```

## Main-Only Workflow

Unlike traditional git workflows that create branches for each project, LaTeXKit uses a **trunk-based workflow**:

1. **All projects in `documents/`** - Each project gets a folder like `001-project-name/`
2. **Active project tracking** - `.active_project` file tracks which project you're working on
3. **Easy searchability** - Search across all projects using VS Code search
4. **Chronological history** - Git commits show your timeline across all projects

### Project Structure

```
LaTeXKit/
├── .latexkit/              # Engine (scripts, templates, config)
│   ├── scripts/bash/       # Shell scripts
│   ├── templates/          # LaTeX templates
│   └── config/             # Configuration files
├── documents/              # Your projects (Personal Archive)
│   ├── 001-essay-sejarah/  # Project 1
│   │   ├── start.md        # Project metadata
│   │   ├── latex_source/   # LaTeX files
│   │   ├── build/          # Compiled PDFs
│   │   └── ...
│   └── 002-tugas-kalkulus/ # Project 2
├── registry/               # Reusable components
│   ├── components/         # LaTeX components
│   └── layouts/            # Document layouts
└── .active_project         # Current active project (gitignored)
```

## Commands

### Project Management

| Command | Description |
|---------|-------------|
| `./latexkit new "description"` | Create a new project |
| `./latexkit switch <num\|id>` | Switch to a project |
| `./latexkit projects` | List all projects |
| `./latexkit current` | Show current project |

### Template Commands

| Command | Description |
|---------|-------------|
| `./latexkit start` | Initialize LaTeX template |
| `./latexkit add <component>` | Add a component |
| `./latexkit list` | List available components |
| `./latexkit build` | Compile to PDF |
| `./latexkit clean` | Remove build artifacts |

### Git Integration

| Command | Description |
|---------|-------------|
| `./latexkit commit [stage]` | Smart commit with workflow labels |
| `./latexkit reset` | Reset projects (destructive) |

## GitHub Copilot Integration

LaTeXKit includes prompt files for GitHub Copilot Chat:

- `/latexkit.start` - Initialize a new assignment
- `/latexkit.research` - Generate research strategy
- `/latexkit.outline` - Create document outline
- `/latexkit.draft` - Write full draft
- `/latexkit.convert` - Convert Markdown to LaTeX
- `/latexkit.build` - Compile PDF
- `/latexkit.check` - Final quality check

## Requirements

- **LaTeX Distribution**: TeX Live or MiKTeX
- **Shell**: Bash or Zsh
- **Optional**: 
  - [Zotero](https://www.zotero.org/) with Better BibTeX for citations
  - GitHub Copilot for AI-assisted workflow

## License

MIT License - see [LICENSE](LICENSE)