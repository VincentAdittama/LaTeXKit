# Draft Command Checklist

**Document**: `DOCUMENT_ID`  
**Created**: `CREATED_DATE`  
**Command**: `/latexkit.draft`  
**Purpose**: Validate complete Markdown draft quality and readiness

---

## Prerequisites (from previous commands)
- [ ] Plan command completed (plan.md exists)
- [ ] Research command completed (if academic)
- [ ] Outline command completed (outline file exists)
- [ ] Project structure validated
- [ ] All required sources available

## Draft Generation
- [ ] Draft file created in `generated_work/drafts/`
- [ ] File versioned correctly (YYYYMMDD_v01_draft.md)
- [ ] Metadata header complete (title, author, date, word count)
- [ ] All outline sections expanded to full paragraphs
- [ ] Structure follows outline hierarchy

## Ambiguity Handling
- [ ] User was asked about auto-fill vs. clarification preference (if ambiguities found)
- [ ] User choice recorded: Auto-fill / Leave markers / Interactive clarification
- [ ] If auto-fill: `<!-- AUTO-FILLED -->` comments added where assumptions made
- [ ] If clarification mode: `[NEEDS CLARIFICATION: ...]` markers inserted appropriately
- [ ] If interactive: Critical questions asked and answered before proceeding

## Content Quality
- [ ] Introduction: Hook → Context → Thesis → Roadmap present
- [ ] Body sections: Topic sentences clear for each paragraph
- [ ] Analysis developed with supporting evidence
- [ ] Transitions explicit between paragraphs and sections
- [ ] Conclusion: Synthesizes (not just summarizes) key points
- [ ] Broader implications addressed in conclusion

## Citation Integration
- [ ] Citations use correct `\cite{key}` notation
- [ ] Citation keys match exactly with .bib file
- [ ] Citations integrated naturally with signal phrases
- [ ] Citation placement varies appropriately
- [ ] Citation density appropriate (undergrad: 1-2/para, grad: 2-4/para)
- [ ] No verbatim copying from sources (paraphrase + cite)

## Style Guide Compliance
- [ ] Writing style guide loaded and followed
- [ ] Academic tone maintained throughout
- [ ] Discipline-specific conventions applied
- [ ] Required terminology used, banned words avoided
- [ ] Person/voice consistent (1st, 3rd person as required)
- [ ] Formatting rules applied (headings, lists, emphasis)

## Quality Standards
- [ ] Clarity: Every sentence has clear purpose
- [ ] Coherence: Ideas flow logically within/between paragraphs
- [ ] Concision: No unnecessary words or repetition
- [ ] Correctness: Grammar, spelling, academic conventions checked
- [ ] Word count within required range (±10%)

## Self-Review Completed
- [ ] All outline points addressed
- [ ] Citations for all major claims present
- [ ] No plagiarism flags (all sources properly attributed)
- [ ] Consistent voice throughout document
- [ ] Clear argument progression maintained
- [ ] `<!-- REVIEW: -->` comments added for areas needing human attention
- [ ] All `[SOURCE NEEDED]` items from outline addressed or flagged

## Constitution Validation
- [ ] Original analysis present (not just synthesis)
- [ ] Proper attribution throughout
- [ ] Academic integrity maintained
- [ ] No over-reliance on single source
- [ ] Paraphrasing proper (not just word substitution)

## Deliverables
- [ ] Draft file saved with version number
- [ ] Review checklist file created in `checklists/`
- [ ] Word count vs. target comparison provided
- [ ] Citation statistics documented
- [ ] Review points flagged with `<!-- REVIEW -->`
- [ ] If auto-fill mode used: List of assumptions documented
- [ ] If clarification mode used: List of `[NEEDS CLARIFICATION]` markers provided

## Next Steps
- [ ] User informed: Human review required before conversion
- [ ] User knows next command: `/latexkit.convert` (after review)
- [ ] If clarification markers added: User informed to run `/latexkit.clarify`
- [ ] Review checklist provided for human validation

---

## Notes

<!-- Add draft-specific notes, review concerns, or clarifications -->

---

**Status**: `Pass` / `Fail` / `In Progress`  
**Last Validated**: `LAST_CHECK_DATE`
