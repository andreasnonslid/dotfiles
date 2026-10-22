---
name: my-review
description: Use when the user says /my-review, asks for a merge-request review, or asks to review the current branch diff against master.
---

# My Review

## Overview

Review the branch diff against master. Report only proven failures. The review is the chat message, even when it is long. Do not write it to a file. Do not post it.

## When to Use

- The user says `/my-review`
- The user asks for a merge-request review of the current branch
- The user asks to review the branch diff

Do not use this skill when the user asked for Bugbot, a security review, or for the review to be posted. When the user asks to expand one brief line from an earlier review, follow Expand below instead of starting a new review.

## Verdict

The first line is exactly one of:

- `Request changes` — one or more ship-wrong findings
- `Approve with notes` — no ship-wrong findings, and at least one structure note or brief line
- `Approve` — nothing in scope

## What is in scope

### Ship-wrong (full finding)

Logic, safety, data loss, security, or a broken contract.

Each finding has:

- `file:line`
- the condition
- the wrong outcome
- the unit-test assertion, when a unit test would catch it
- the fix (see Fixes)

Ship-wrong findings are the only blockers.

### Structure (full finding)

Duplicated truth, dead code, broken layering, or a lying API. A name that states the wrong behavior is a lying API.

Each finding has:

- `file:line`
- which of those four it is
- the concrete mechanism
- the fix (see Fixes)

### Brief line

One line, `file:line`, when either:

- the next reader loses real time, or
- the next edit is likely to ship wrong because something is hidden

State the problem in one line, then give the fix right after it (see Fixes). Stop there.

## Fixes

Every finding and brief line ends with a fix. Keep the fix to the problem found. Do not refactor nearby code.

- **One-liner** — the fix changes one line, or a few lines next to each other. Give the exact code: the replacement line, or a short `diff` block with the `-` and `+` lines. It must be ready to paste.
- **Bigger change** — the fix touches several places, adds a function, or changes an API:
    - Brief line: one plain sentence that says what to change and where.
    - Ship-wrong or structure finding: a short paragraph, or up to about five steps. Name the functions or files to change, say what each one should do, and name any caller or contract that has to change with it. Add code only for the key line or signature. Do not write the whole patch.

When there is more than one reasonable fix, give the one you recommend first. Mention one alternative only when the tradeoff matters.

### Fix quality

Each fix must pass a strict review if it were submitted as a change. Hold it to the same standard as the finding:

- Remove the problem; do not wrap it. A fix for duplicated truth deletes one copy and points its callers at the other. Turning one copy into a forwarding wrapper is still duplication.
- Prefer changing call sites over adding indirection. Do not add a helper, wrapper, or alias when a direct call to existing code works.
- Find the usages before writing the fix. Search for every caller of what the fix removes or changes, and name them in the fix. Deleting an unused function is part of the fix.
- Respect the existing dependency direction between modules. Do not suggest a fix that adds a dependency cycle.
- Fix the cause, not the symptom. A comment that documents a defect is a fix only when the behavior is intended.

If you cannot write a fix that meets this standard, say what the fix has to achieve and what makes it hard. Do not offer a weak one.

## Out of scope

Do not write:

- Style, formatting, or naming taste
- Praise, or a tour of the diff
- A suspicion with no proven failure
- A drive-by refactor
- A test request that is not attached to a ship-wrong finding
- A finding with no file, no line, or no failure mode

## Read path

1. Diff against `master` using the merge-base. Read the history since the branch diverged.
2. Read every changed line.
3. For each changed function and variable, record what changed and how widely it is used. Keep this record private.
4. Choose depth from that pair:
    - **All usages** — the change can alter behavior, control flow, shared state, a contract, or a safety path, and either usage is wide or a missed caller can lose data, break safety, or break security.
    - **Selected paths** — the change can alter behavior, and the callers that can observe it are few and identifiable. Read those paths only.
    - **No further chase** — the changed lines cannot change behavior or structure. The changed lines are still read.
5. Open callers, callees, and prior versions only as far as the depth choice requires.
6. Drop any suspect you cannot point at with a file, a line, and a failure mode. Do not show the triage.
7. For each finding you keep, read the code the fix will touch and its callers before writing the fix (see Fix quality).

## Output

No cap. Omit empty groups. Order:

1. Verdict line
2. Ship-wrong findings
3. Structure findings
4. Brief lines

`Approve` is the verdict line alone.

The whole review goes in the chat message. Length is not a reason to write a file and present that file.

## Expand

When the user asks to expand a brief line, write the full version of that line only, with the full-finding fix. Do not re-review the branch.

## Bad comments

Do not produce these:

- `Consider renaming tmp to filteredReadings for clarity.` Naming taste. The name does not state the wrong behavior.
- `This might race if another task writes the register.` No proven interleaving and no failure path.
- `Please add unit tests for this function.` No ship-wrong finding and no assertion.
- `Fix: handle the error properly.` Too vague to act on. Give the exact line, or say what to change and where.
- A full patch rewriting the whole function for a brief line. A bigger fix on a brief line gets one sentence.
- `Fix: make isFile return filereader::exist(path).` For duplicated truth, this keeps both APIs and makes one a wrapper. Point the callers at `filereader::exist` and delete `isFile`.
