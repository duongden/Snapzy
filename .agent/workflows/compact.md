---
description: Summarizes the current session context into a portable format for seamless restoration in a new chat
---

## Trigger

When the user types `/compact`, execute the following logic immediately.

## Objective

Generate a "Context Restoration Block" that summarizes the current session. This block must contain all necessary information for a fresh AI instance to resume the conversation seamlessly without losing context, technical details, or user preferences.

## Output Format (Markdown)

The output must be in English and enclosed in a code block for easy copying. Structure it exactly as follows:

---

**[CONTEXT RESTORATION BLOCK]**

**1. 🎯 Session Goal & Status**

- **Original Goal:** [Briefly state what we started doing]
- **Current State:** [Where are we right now?]
- **Pending Tasks:** [What is left to do?]

**2. 🧠 Key Context & Decisions**

- **Tech Stack/Tools:** [List specific tools, languages, or frameworks used]
- **Constraints:** [List any specific rules or preferences established]
- **Critical Data:** [Key variables, code snippets, or definitions created]

**3. ⏭️ Next Step Action Plan**

- [Immediate next step for the new session]

**4. 🔗 Reference Link**

- **Source:** [Insert conversation link if available, otherwise "N/A"]
- **Instruction:** Please read the content at the link above (if provided) to fully sync with the history.

**5. 📥 Restoration Prompt**

- _(Instruction to User: Copy and paste the text below into the new chat)_
- "I am continuing a previous session. Here is the summary of where we left off. Please acknowledge and be ready for the next step: [Insert Short Summary Here]"

---
