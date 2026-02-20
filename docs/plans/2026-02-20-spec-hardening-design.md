# Spec Hardening Design: Review-Driven Guardrails

**Date**: 2026-02-20  
**Scope**: `specs/001-kaiten-sdk-core/spec.md`, `specs/002-kaiten-cli/spec.md`, `specs/002-kaiten-cli/checklists/requirements.md`

## Problem

Package review surfaced recurring failure modes that were under-specified or not explicitly testable in the current specs: cancellation masking, pagination progression assumptions, help/validation drift, silent option dropping, and credential exposure through CLI token input patterns.

## Approaches Considered

1. **Minimal patching (recommended for now)**  
   Add explicit normative requirements and acceptance scenarios only for observed gaps.  
   - Pros: low risk, fast to merge, immediately enforceable in planning and review.  
   - Cons: incremental; does not fully redesign spec structure.

2. **Broad spec refactor**  
   Reorganize both specs around cross-cutting quality attributes (validation, reliability, security) with traceability matrices.  
   - Pros: cleaner long-term structure.  
   - Cons: high churn, delays delivery, harder review.

3. **Process-only hardening**  
   Keep specs mostly as-is and rely on checklists/tests to catch these issues.  
   - Pros: smallest text changes.  
   - Cons: weak prevention; ambiguity remains in source-of-truth requirements.

## Chosen Design

Use **Approach 1**:
- Extend SDK spec with explicit requirements for:
  - cancellation propagation semantics,
  - auto-pagination offset progression semantics,
  - strict absolute HTTPS base URL validation with host,
  - preserving 400 error class as typed error,
  - endpoint-cap validation coverage for users/card types/sprints.
- Extend CLI spec with explicit requirements for:
  - strict enum coercion behavior (no silent `nil` fallback),
  - help-text ↔ parser allowed-value parity,
  - strict CSV parsing consistency across commands,
  - secure non-argv token input requirement and safer docs posture.
- Extend CLI checklist to enforce those guardrails during spec-quality review.

## Expected Outcomes

- Future implementation plans must include concrete work for these behaviors.
- Reviewers can reject regressions using explicit requirement IDs instead of implicit expectations.
- The same class of issues should be prevented earlier (spec/planning), not after runtime bug reports.
