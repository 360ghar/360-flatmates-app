---
name: qa
description: >
  Run QA tests for 360 FlatMates. Analyzes git diff to determine affected areas,
  runs configured test flows with multiple personas, and generates diff-targeted tests.
  Uses agent-browser for mobile app testing via iOS Simulator + serve-sim.
  Use when testing PRs, releases, or smoke testing environments.
---

# QA Orchestrator

**SCOPE: This skill performs manual/functional QA only -- verifying that the application actually works by interacting with it as a real user would (browser, TUI, API calls). Do NOT run or report on CI checks, linting, ESLint, typecheck, unit tests, or any static analysis. Those are handled by separate workflows.**

## Step 1: Load Configuration

Read `.factory/skills/qa/config.yaml` for environment URLs, credentials, personas, and app definitions.

## Step 2: Determine Target Environment

Use the default_target from config unless the user specifies a different environment.
Respect any environment restrictions (e.g., no user creation in prod).

**This project does NOT use preview deployments.** All testing is against the local dev environment:
- Backend: `http://127.0.0.1:3600/api/v1`
- App: iOS Simulator streamed via `npx serve-sim` at `http://localhost:3200`

## Step 3: Analyze Git Diff

Run `git diff` to determine what changed. Map changed files to apps using the path_patterns in config.yaml.

Files that don't match ANY app's path_patterns (e.g., `.factory/skills/**`, `docs/**`, `.github/**`, config files) are NOT associated with any app. Do NOT run app test flows for them.

For the `flatmates` app, relevant path patterns are:
- `lib/**` — all Dart source code
- `assets/**` — illustrations, icons
- `pubspec.yaml` — dependencies
- `.env*` — environment config
- `l10n.yaml`, `analysis_options.yaml` — build/lint config

For each affected app:
- Run ONLY that app's flows from its module file
- Generate ADDITIONAL targeted tests based on the specific changes in the diff

For apps NOT affected by the diff:
- Do NOT load or run their module. Do NOT run their flows. Do NOT run their pre-flight checks.

If NO app is affected by the diff (e.g., docs-only, CI-only, or config-only changes), report as INCONCLUSIVE: "No app code changed -- QA not applicable for this diff." Do NOT run any app flows.

## Step 4: Pre-flight Checks (app-specific only)

Run pre-flight checks ONLY for the apps that are affected by the diff. For 360 FlatMates:

1. **iOS Simulator**: Verify a simulator is booted (`xcrun simctl list devices | grep Booted`)
2. **serve-sim**: Verify it's running at `http://localhost:3200` (or start it: `npx serve-sim`)
3. **Flutter app**: Verify the app is running on the simulator (or launch: `flutter run`)
4. **Backend**: Verify the FastAPI backend is running at `http://127.0.0.1:3600/api/v1` (or start it from `../backend`)
5. **Environment**: Verify `.env` file exists with `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `API_BASE_URL`

If a pre-flight check fails, report it as BLOCKED with the specific error and remediation steps -- but still proceed with other checks.

Do NOT run pre-flight checks for apps that are NOT affected.

## Step 5: Execute Diff-Relevant Flows Only

Read the flatmates sub-skill from `.factory/skills/qa-flatmates/SKILL.md`.

The sub-skill contains a MENU of available test flows. You must:

1. Read the diff carefully and identify which flows are relevant to the change
2. Run those flows PLUS any adjacent flows that verify the change integrates correctly
3. Do NOT run completely unrelated flows (e.g., if the diff only changes chat, do NOT test settings)
4. If no existing flow covers the change, write a NEW ad-hoc test that directly verifies the changed behavior
5. Do NOT run unit tests, lint, typecheck, or any automated test suite. This is manual/functional QA -- interact with the app as a real user would.

## Step 6: Evidence Capture

After each significant test step, capture evidence. Use **text snapshots as primary evidence**.

For the Flutter app (via agent-browser through serve-sim):
- Use `agent-browser snapshot` to capture the page's accessibility tree as text evidence
- Save screenshot files to `./qa-results/$RUN_ID/` for the artifact upload
- Do NOT embed `![image](url)` markdown in the report -- screenshot images cannot be displayed inline in GitHub PR comments. Instead, mention the filename and note that it's available in the downloadable artifacts.

Evidence quality rules:
- Focus on the RELEVANT content. Trim snapshots to the meaningful part.
- Label each snapshot clearly: what it shows and why it matters for the test.
- NEVER embed broken image links.
- Use ImageMagick for animated GIF diffs of before/after screenshots when applicable.

## Step 7: Test Quality Gate

TEST QUALITY REQUIREMENTS:

1. CHANGE-SPECIFIC FIRST. Prioritize tests that directly verify the behavioral change in the diff. At least half your tests should be testing the new/changed feature itself.
2. INTEGRATION TESTS ARE VALID. Tests that verify the change integrates correctly with existing features are good.
3. NO UNRELATED FLOWS. Do NOT test features completely unrelated to the diff.
4. NO AUTOMATED TEST SUITES. Do NOT run flutter test, flutter analyze, or any CI-style checks.
5. NEGATIVE TESTS. Include at least 1 test verifying error handling or boundary conditions related to the change.
6. INTERACTIVE TESTING. Test by actually interacting with the app as a real user would.
7. INCONCLUSIVE IF UNSURE. If you cannot articulate what the PR changes, mark as INCONCLUSIVE rather than PASS.

## Step 8: Handle Failures

**Never silently skip a flow.** If a flow cannot complete, report it as BLOCKED with what was tried and how the user can fix it. Then continue to the next flow -- never abort the entire run for a single failure.

## Step 9: Generate Report

Generate the report at `./qa-results/report.md` using `.factory/skills/qa/REPORT-TEMPLATE.md`.

The report MUST follow the template. Key rules:
- Start with `## QA Report` heading followed by the test results table
- Result column MUST use emojis: :white_check_mark: PASS, :x: FAIL, :no_entry: BLOCKED, :warning: FLAKY, :grey_question: INCONCLUSIVE
- Keep it CONCISE. The table + a short "Action Required" section (if any) + collapsed screenshots = the entire report.
- Do NOT report setup/prerequisite steps as test rows. Only report rows that verify actual user-facing behavior.
- Put ALL evidence in a single collapsed `<details>` block
- For web evidence: embed accessibility tree snapshots as text. Reference screenshot filenames for visual proof.

## Step 10: Suggest Skill Updates (Failure Learning)

After generating the report, check if any BLOCKED or FAIL results revealed a **testing environment insight** that would help future QA runs succeed.

Good suggestions (environment/workflow knowledge):
- "serve-sim takes 10+ seconds to stream after app restart -- increase wait to 15s"
- "Supabase OTP expires quickly -- request fresh OTP for each login attempt"
- "The iOS Simulator must be booted before flutter run"

Bad suggestions (skill bugs, not environment insights -- do NOT suggest these):
- "Selector data-testid=foo doesn't exist" -- that's a skill bug
- "The button text changed from X to Y" -- that's expected from the PR diff

Format as a table:

## Suggested Skill Updates (N issues found)

| #   | Severity        | File     | Issue               | Fix Prompt                                                                           |
| --- | --------------- | -------- | ------------------- | ------------------------------------------------------------------------------------ |
| 1   | <emoji> <level> | `<file>` | <short description> | <details><summary>Copy</summary><br>`<full droid prompt to fix the issue>`</details> |

Severity levels: 🔴 Breaking, 🟡 Degraded, 🔵 Info

The `failure_learning` field in config.yaml is `suggest_in_report` -- include suggestions in the PR comment report only. Do NOT write `skill-updates.json`.
