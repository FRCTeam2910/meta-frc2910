# meta-frc2910 AGENTS.md


## Writing: comments and commits
Short and only the *why*. If `git show` (or the code) already says it, drop it.
- Hard limits: every line **≤80 chars** (including leading whitespace);
  inline comment **≤2 lines** (none best), docstring **≤5 lines**;
  commit subject **≤70 chars**, commit body **≤10 lines** (often zero,
  ≤80 chars per line — one short sentence, not a paragraph wrapped to fit).
- Subject is `<imperative>` describing the change (`add X`), not the file
  (`edit responses.py`). For Yocto, `<recipe>: <imperative>` per OE style.
- Body is **default-zero**: omit anything `git show` already says, anything
  a fluent reader of the stack knows, and any hunk paraphrase. Keep only a
  *why* the diff can't carry — a non-obvious constraint, workaround
  rationale, superseded-commit drop, or review-fix anchor. If the subject
  plus the diff are self-explanatory, the body is empty.
- Comments: only a non-obvious constraint, past failure, or forward-compat
  hazard. Never narrate the next line, never restate the signature/params/spec
  list — those live in the code or docstrings elsewhere. Same for `:param:`/
  `:returns:` blocks in commits.


## Yocto recipes and layers
This repo is a Yocto distro; the rules above apply plus these.
- Custom layers live under `layers/` (`meta-tegrademo`, `meta-tegra-support`,
  `meta-demo-ci`). Submodules under `repos/` are upstream — don't commit to
  them; fix upstream and bump the submodule ref here instead.
- Prefer a `.bbappend` with the `%.bbappend` wildcard version over copying or
  forking an upstream `.bb` recipe; start every append with
  `FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"`.
- Don't bump `PR` for recipe edits — the autobuilder's PR-service handles
  that. Only set `PR` when inheriting from a non-PR-service recipe.
- For git recipes use `SRCREV = "${AUTOREV}"` (or pin a SHA when
  reproducibility matters); never hardcode a branch HEAD literal.
