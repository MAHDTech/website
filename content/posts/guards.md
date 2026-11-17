---
title: "GUARDS Framework"
date: 2026-05-01
draft: false
description: "Why unconstrained chat loops fail at repository scale, and how phase-gated contracts, isolated worktrees, and independent verification turn AI agents into reliable engineering spokes."
taxonomies:
  tags:
    - "ai-agents"
    - "rust"
    - "architecture"
    - "devops"
  categories:
    - "AI Engineering"
extra:
  category: "AI Harness Engineering"
  image: "/images/posts/ai-harness-guards.svg"
  image_alt: "Phase-gated orchestration schematic showing hub-and-spoke verification gates"
  digest: "Unbounded agent loops drift on scope and grade their own homework. Separating specification, implementation, and verification across isolated spokes with machine-checked contracts makes autonomous delivery auditable."
  key_points:
    - "Never allow the implementation agent to verify its own diff or mutate scope."
    - "Bind each execution spoke to an isolated Git worktree and explicit file manifest."
    - "Enforce deterministic gates (linters, typechecks, reproducible Nix builds) between phases."
---

## Why Unconstrained Agent Loops Drift

If you give a capable frontier model shell access and a vague prompt, the first twenty minutes look _magical_.

Give it a 40-file architectural migration with strict backwards-compatibility invariants, and failure modes surface predictably:

1. **Scope creep under error pressure**: When a test fails, an unconstrained loop frequently weakens the assertion or widens its touch surface rather than diagnosing the root cause.

2. **Context window pollution**: Mixing codebase exploration, design trade-offs, implementation edits, and test log scraping inside a single transcript degrades instruction adherence.

3. **Self-attestation bias**: An agent that writes the implementation and immediately writes the verification summary inherits the exact blind spots that produced the bug.

Treating autonomous coding as a **systems engineering problem** rather than a prompt-crafting exercise changes the architecture completely.

Instead of one omnipotent agent, we build a deterministic **AI harness**.

## Hub-and-Spoke Separation of Duties

A resilient agentic harness borrows directly from high-assurance CI/CD and distributed systems;

- privilege separation
- immutable inputs
- explicit state transitions.

Enter **GUARDS**;

- **G**ather
- **U**nderstand
- **A**rchitect
- **R**ealize
- **D**emonstrate
- **S**hip

```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Phase {
    GatherContext,
    UnderstandScope,
    ArchitectDesign,
    RealizeImplementation,
    VerifyIndependently,
    ShipPullRequest,
}

pub struct SpokeContract {
    pub phase: Phase,
    pub allowed_paths: Vec<String>,
    pub worktree_sha: String,
    pub verification_exit_code: i32,
}
```

Each phase delegates to a specialized spoke with bounded permissions:

- **Research Spoke (Read-Only)**: Surveys existing modules, upstream documentation, and prior art without write tools. It emits cited evidence artifacts rather than speculative edits.

- **Architecture Spoke**: Translates requirements and research into a concrete file-level specification and dependency-ordered plan, pausing at a human or policy gate before code is written.

- **Implementation Spoke**: Operates inside an isolated Git worktree restricted to the declared file manifest. It writes code and unit tests, but cannot approve its own phase transition.

- **Verification Spoke**: Checks out the resulting commit independently, executes the full reproducible test suite inside Nix `devenv`, and audits spec compliance line by line.

## Reproducible Toolchains Are the Real Guardrail

An agent harness is only as deterministic as the environment beneath it.

When `cargo test`, `zola check`, or `kubectl --dry-run` depends on mutable global packages on a developer laptop, agent failures become non-reproducible noise.

Pinning every compiler, linter, and formatter inside `devenv.nix` and enforcing them via `prek` hooks gives every agent spoke an identical, hermetic feedback signal:

```yaml
---
# Example spoke contract artifact checked by the hub state machine
phase: "R.2_VERIFY"
status: "PASS"
checks:
  nix_devenv_test: "pass"
  prek_hooks: "pass"
  scope_manifest_clean: true
```

## Takeaways for Platform Teams

AI Harness Engineering is platform engineering applied to probabilistic compute.

Keep context windows focused on one cognitive mode per turn, isolate filesystem mutations in disposable worktrees, and make deterministic compilers and linters the final arbiters of state advancement.
