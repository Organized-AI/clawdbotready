# Workflow Patterns

Patterns for structuring complex, multi-step tasks in Skills.

## Contents

- [Sequential Workflows](#sequential-workflows)
- [Checklist Pattern](#checklist-pattern)
- [Conditional Workflows](#conditional-workflows)
- [Feedback Loops](#feedback-loops)
- [Verifiable Intermediate Outputs](#verifiable-intermediate-outputs)

---

## Sequential Workflows

For complex tasks, break operations into clear, sequential steps. Provide an overview near the beginning of SKILL.md:

```markdown
Filling a PDF form involves these steps:

1. Analyze the form (run analyze_form.py)
2. Create field mapping (edit fields.json)
3. Validate mapping (run validate_fields.py)
4. Fill the form (run fill_form.py)
5. Verify output (run verify_output.py)
```

Clear steps prevent Claude from skipping critical validation.

---

## Checklist Pattern

For particularly complex workflows, provide a checklist that Claude can copy into its response and check off as it progresses.

### Example: Research Synthesis (No Code)

```markdown
## Research synthesis workflow

Copy this checklist and track your progress:

```
Research Progress:
- [ ] Step 1: Read all source documents
- [ ] Step 2: Identify key themes
- [ ] Step 3: Cross-reference claims
- [ ] Step 4: Create structured summary
- [ ] Step 5: Verify citations
```

**Step 1: Read all source documents**
Review each document in the `sources/` directory. Note the main arguments and supporting evidence.

**Step 2: Identify key themes**
Look for patterns across sources. What themes appear repeatedly? Where do sources agree or disagree?

**Step 3: Cross-reference claims**
For each major claim, verify it appears in the source material. Note which source supports each point.

**Step 4: Create structured summary**
Organize findings by theme. Include:
- Main claim
- Supporting evidence from sources
- Conflicting viewpoints (if any)

**Step 5: Verify citations**
Check that every claim references the correct source document. If citations are incomplete, return to Step 3.
```

### Example: PDF Form Filling (With Code)

```markdown
## PDF form filling workflow

Copy this checklist and check off items as you complete them:

```
Task Progress:
- [ ] Step 1: Analyze the form (run analyze_form.py)
- [ ] Step 2: Create field mapping (edit fields.json)
- [ ] Step 3: Validate mapping (run validate_fields.py)
- [ ] Step 4: Fill the form (run fill_form.py)
- [ ] Step 5: Verify output (run verify_output.py)
```

**Step 1: Analyze the form**
Run: `python scripts/analyze_form.py input.pdf`
This extracts form fields and their locations, saving to `fields.json`.

**Step 2: Create field mapping**
Edit `fields.json` to add values for each field.

**Step 3: Validate mapping**
Run: `python scripts/validate_fields.py fields.json`
Fix any validation errors before continuing.

**Step 4: Fill the form**
Run: `python scripts/fill_form.py input.pdf fields.json output.pdf`

**Step 5: Verify output**
Run: `python scripts/verify_output.py output.pdf`
If verification fails, return to Step 2.
```

The checklist helps both Claude and users track progress through multi-step workflows.

---

## Conditional Workflows

Guide Claude through decision points with branching logic:

```markdown
## Document modification workflow

1. Determine the modification type:

   **Creating new content?** → Follow "Creation workflow" below
   **Editing existing content?** → Follow "Editing workflow" below

2. Creation workflow:
   - Use docx-js library
   - Build document from scratch
   - Export to .docx format

3. Editing workflow:
   - Unpack existing document
   - Modify XML directly
   - Validate after each change
   - Repack when complete
```

**Tip:** If workflows become large with many steps, push them into separate files and tell Claude to read the appropriate file based on the task.

---

## Feedback Loops

Implement validation loops to catch errors early and improve output quality.

**Common pattern**: Run validator → fix errors → repeat

### Example: Style Guide Compliance (No Code)

```markdown
## Content review process

1. Draft your content following the guidelines in STYLE_GUIDE.md
2. Review against the checklist:
   - Check terminology consistency
   - Verify examples follow the standard format
   - Confirm all required sections are present
3. If issues found:
   - Note each issue with specific section reference
   - Revise the content
   - Review the checklist again
4. Only proceed when all requirements are met
5. Finalize and save the document
```

### Example: Document Editing Process (With Code)

```markdown
## Document editing process

1. Make your edits to `word/document.xml`
2. **Validate immediately**: `python ooxml/scripts/validate.py unpacked_dir/`
3. If validation fails:
   - Review the error message carefully
   - Fix the issues in the XML
   - Run validation again
4. **Only proceed when validation passes**
5. Rebuild: `python ooxml/scripts/pack.py unpacked_dir/ output.docx`
6. Test the output document
```

The validation loop catches errors early, before they cascade into bigger problems.

---

## Verifiable Intermediate Outputs

When Claude performs complex, open-ended tasks, it can make mistakes. The "plan-validate-execute" pattern catches errors early by having Claude create a plan in a structured format, then validate that plan before executing.

### Why Use This Pattern

Without validation, Claude might:
- Reference non-existent fields
- Create conflicting values
- Miss required fields
- Apply updates incorrectly

### Solution: Intermediate Plan Files

Add a `changes.json` file that gets validated before applying changes:

```
analyze → create plan file → validate plan → execute → verify
```

### Benefits

| Benefit | Description |
|---------|-------------|
| **Catches errors early** | Validation finds problems before changes are applied |
| **Machine-verifiable** | Scripts provide objective verification |
| **Reversible planning** | Claude can iterate on the plan without touching originals |
| **Clear debugging** | Error messages point to specific problems |

### When to Use

- Batch operations
- Destructive changes
- Complex validation rules
- High-stakes operations

### Implementation Tip

Make validation scripts verbose with specific error messages:

```
"Field 'signature_date' not found. Available fields: customer_name, order_total, signature_date_signed"
```

Specific error messages help Claude fix issues without guessing.
