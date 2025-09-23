# TODO: Upcoming Improvements for customzsh

This file tracks actionable tasks to implement later. No code changes are made here; this is a planning artifact only.

- Apply theme from config to `.zshrc`
  - Summary: Use `ZSH_THEME` from `config.sh` to update the `ZSH_THEME="..."` line in the user’s `.zshrc` after copying. Keep idempotent (only change when needed).
  - Acceptance: Running with `ZSH_THEME="robbyrussell"` results in `.zshrc` containing `ZSH_THEME="robbyrussell"`; safe across re-runs; respects existing user customizations where possible.

- Strengthen dependency checks
  - Summary: Update `check_dependencies()` to require `git`, `curl`, `sudo`, `jq` (these are used by scripts). Warn-only for `chsh`, `wget` as optional helpers.
  - Acceptance: Script exits with a clear error if any required tool is missing; tests include a case for missing `jq` when `EZA_VERSION="latest"`.

- Add rollback on failure
  - Summary: Track created resources (e.g., `.oh-my-zsh`, `.zshrc` backup state) and add an `EXIT` trap to restore `.zshrc` from backup and remove any partial Oh My Zsh installation when the script exits non‑zero.
  - Acceptance: Simulated failure after `.zshrc` copy restores the original `.zshrc` and removes partial `.oh-my-zsh`; script exits non‑zero; repeated runs are safe.

- Standardize `install_eza.sh` failure behavior
  - Summary: Ensure all manager paths (`dnf`, `pacman`, `zypper`, `brew`) fail fast on errors; attempt `cargo` fallback if available; require `jq` when resolving `EZA_VERSION="latest"` via GitHub API.
  - Acceptance: Returns non‑zero when unable to install via package manager and no cargo fallback present; succeeds via cargo when available; error message clearly instructs next steps.

- Tests for new behavior
  - Summary: Add Bats tests to verify:
    - Theme application to `.zshrc` from `config.sh`.
    - `check_dependencies` includes `jq` as required.
    - Rollback restores `.zshrc` and removes partial `.oh-my-zsh` on forced error.
    - `install_eza.sh` exits non‑zero on manager failure and uses cargo fallback when present.
  - Acceptance: New tests pass locally/CI; existing suites remain green.

- Housekeeping
  - Summary: After implementation, update `AGENTS.md` dependency list and any relevant contributor docs to reflect new requirements/behavior.
  - Acceptance: Docs accurately describe theme application, dependencies, rollback behavior, and installer fallback strategy.
