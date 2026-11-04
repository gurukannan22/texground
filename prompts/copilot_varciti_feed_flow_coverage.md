# Copilot Prompts: VARCITI-FEED (oasystovarcitifeed) Flow + tp-regression Coverage

Use these in order in Copilot Chat (VS Code: prefix with `@workspace`; IntelliJ: open the repo and attach the key files).
Context:
- `oasystovarcitifeed (VARCITI-FEED)` – the batch job / feed name
- `tp-javabatch-service` – the Spring Batch service repo
- `tp-regression` – the Cucumber automation repo

---

## Prompt 1 — Map the full end-to-end flow (run in `tp-javabatch-service`)

```
@workspace I need a complete end-to-end map of the oasystovarcitifeed (VARCITI-FEED) batch flow in this repository. Trace it from trigger to final output and do not skip any branch.

Find and report:

1. ENTRY POINT
   - How the job is triggered (main class, Spring Boot runner, scheduler, Autosys command/script, CLI args, profiles).
   - Job bean name and the configuration class(es) that define it.

2. JOB STRUCTURE
   - Every Step in order, including conditional flows, deciders, `.on("FAILED")` / `.on("COMPLETED")` transitions, partitions, parallel splits.
   - For each step: Reader, Processor(s), Writer, chunk size, skip/retry policy, listeners.

3. INPUT
   - Source type (file / DB query / MQ / Kafka / Solace / API), location property keys, file naming pattern, delimiter/format, header/trailer handling.
   - Any validation applied on input (mandatory fields, formats, record counts, checksums).

4. TRANSFORMATION LOGIC
   - All business rules in processors/services: mappings, filters, enrichments, lookups, date/number formatting, currency/amount handling.
   - Every condition that drops, rejects or routes a record differently.

5. OUTPUT
   - Every DB table written (insert/update/merge/delete), with the SQL or repository method used.
   - Any output file / message / downstream call produced.
   - Reject/error/exception tables or files.

6. ERROR HANDLING & RESTART
   - What happens on bad records, DB errors, empty input, duplicate input.
   - Restartability: job parameters, JobRepository usage, idempotency checks.
   - Exit codes returned to the scheduler for each outcome.

7. CONFIGURATION
   - All properties/env variables the job depends on (per profile).
   - Anything JDK-version sensitive: date/time formatting, Locale usage, reflection, serialization, deprecated APIs.

OUTPUT FORMAT:
- A numbered flow (trigger → steps → outputs) with file path + class + method for each point.
- A table: | # | Flow point | Class/Method | Input | Output | Branch/condition |
- A final list titled "TESTABLE BEHAVIOURS" — one line per distinct behaviour/branch that a functional test should cover.
If something is unclear or not found, say so explicitly instead of guessing.
```

---

## Prompt 2 — Check regression coverage (run in `tp-regression`)

Paste the "TESTABLE BEHAVIOURS" list from Prompt 1 at the end of this prompt.

```
@workspace This repository contains Cucumber automation. I need a coverage gap analysis for the oasystovarcitifeed (VARCITI-FEED) batch flow.

Steps:
1. Find every .feature file, scenario, Scenario Outline and Examples row related to oasystovarcitifeed (VARCITI-FEED) (search by tag, feature name, job name, table names, and file names used in the flow).
2. For each scenario, list: feature file path, scenario name, tags, what it sets up (input data), what it triggers, and exactly what it asserts (DB tables/columns, files, job status, exit code).
3. Check the step definitions behind those scenarios and flag any steps that are stubbed, commented out, always pass, or assert nothing meaningful.
4. Compare against the TESTABLE BEHAVIOURS list below and produce:

   | Behaviour | Covered? (Yes / Partial / No) | Scenario(s) | Gap description |

5. List the missing scenarios in priority order (critical path first), and note which existing step definitions can be reused for each.
6. Note how these scenarios are run: runner class, tag expressions, Maven/Gradle command, required profiles/env, and the CI pipeline file that executes them.

Do not write new code yet — analysis only.

TESTABLE BEHAVIOURS:
<paste list from Prompt 1>
```

---

## Prompt 3 — Generate missing scenarios (run in `tp-regression`)

```
@workspace Using the gap table from the previous answer, write the missing Cucumber scenarios for oasystovarcitifeed (VARCITI-FEED).

Rules:
- Follow the existing feature file style, folder structure, tag conventions and Background usage in this repo.
- Reuse existing step definitions wherever possible; only create new steps when nothing suitable exists.
- Tag every new scenario with the existing feed tag plus @jdk21.
- For new steps, generate step-definition methods in the matching existing glue class, using the repo's existing DB/file helper utilities.
- Each scenario must assert concrete outcomes: row counts, key column values, reject records, job status and exit code.
- Use Scenario Outline + Examples for variations of the same behaviour (e.g. invalid field types).

Cover at minimum (where applicable to the flow):
- Happy path end-to-end with source vs DB count reconciliation
- Field-level mapping validation
- Empty input
- Header/trailer or count mismatch
- Invalid / malformed records → reject handling
- Duplicate input / rerun idempotency
- Failure mid-job then restart
- Date/number formatting output check (JDK 21 regression risk)

Finally, give the exact command to run only these scenarios locally, e.g.
mvn clean verify -Dcucumber.filter.tags="<varciti-feed-tag> and @jdk21"
```

---

## Prompt 4 — JDK 21 run readiness (optional, either repo)

```
@workspace Check this project for JDK 21 readiness for running the oasystovarcitifeed (VARCITI-FEED) tests:
- Maven/Gradle compiler source/target/release settings, toolchains, surefire/failsafe plugin versions.
- Dependencies known to break on JDK 17/21 (Lombok, Mockito, ByteBuddy, Jackson, old Spring/Spring Batch, cucumber-jvm versions).
- Any use of removed/encapsulated JDK internals (sun.*, --add-opens needs).
- CI pipeline JDK version and image.
List each issue with file path and the recommended fix.
```
