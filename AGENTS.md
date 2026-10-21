# tegra-demo-distro AGENTS.md


## Code comments
Comments must stay short. Hard limits:
- Inline comment: **max 2 lines**, one is better, none is best.
- Docstring: **max 5 lines**. If you can't fit it, you're documenting *what*
  the code does instead of a *why* that isn't obvious from reading it.
- Only explain **why** (a non-obvious constraint, a past failure, a forward-
  compat hazard). Never narrate **what** the next line does.
- Before committing a comment, ask: would the code read itself without it?
  If yes, delete the comment.
- Don't restate the function signature, parameter types, or a spec field
  list — those live in the code or in docstrings elsewhere.