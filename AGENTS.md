# AgroZen Project Rules — Default Prompt Enhancer & Broiler Agronomy Standards

## 1. Default Prompt Enhancement Pipeline (ALWAYS ACTIVE)
For **every** user request in this project (whether UI/UX, feature development, or domain/AI improvements):
1. **Automatically Apply `enhance-prompt` First**:
   - Read and apply [`.agents/skills/enhance-prompt/SKILL.md`](.agents/skills/enhance-prompt/SKILL.md) and [`DESIGN.md`](DESIGN.md) before implementing changes.
   - Transform rough, conversational, or voice-transcribed requests into a structured **Enhanced Prompt Specification** containing:
     - One-line purpose & vibe summary
     - **DESIGN SYSTEM (REQUIRED)** tokens from [`DESIGN.md`](DESIGN.md)
     - **Component / Feature Structure** (numbered actionable sections)
     - **Broiler Agronomy & Technical Acceptance Criteria** (Ross-308 / Cobb-500 standards, trilingual `uz`/`ru`/`en` support, offline-first safety).
2. **Present the Enhanced Prompt**:
   - Include the structured Enhanced Prompt block at the top of the response so the user can see how their prompt was refined.

## 2. Broiler Grower Domain & Safety Standards
- **Scientific Grounding**: All poultry calculations, schedules, and recommendations must follow verified **Ross-308 / Cobb-500** standards (Days 1–42) via `BroilerGrowerLibrary`, `NormsData`, and `LocalRag`.
- **Trilingual Parity**: Every user-facing string, manual, calculator, and prompt template must support **O'zbekcha (`uz`)**, **Русский (`ru`)**, and **English (`en`)**.
- **Veterinary Safety**: Never prescribe antibiotic dosages or specific medications; always refer clinical disease treatment to the farmer's district veterinarian.
