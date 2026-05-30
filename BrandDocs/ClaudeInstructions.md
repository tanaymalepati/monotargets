# Claude Development Prompt Guide

Use these exact instructions when starting a new session or prompting Claude for development work to save tokens and maintain extreme efficiency.

## Core Directives
1. **No Code Explanations**: Do NOT explain any code, architecture, or logic unless I explicitly ask you to.
2. **Action Updates Only**: Do NOT explain what you are doing in plain text. Instead, only output your progress as a percentage (e.g., `[Progress: 25%] - Modifying View`). 
3. **Concise Output**: Keep your responses as short as humanly possible. Output only the necessary code or tool executions.
4. **End-of-Session Log**: At the end of every task or right before the session ends, you MUST create and output a concise "State Log" summarizing:
   - What was just completed.
   - The current state of the application.
   - The exact file and line numbers of the last modifications.
   - The immediate next steps to be taken in the next session.
   This log will be passed into the next session so you don't need to read through the entire codebase again.
