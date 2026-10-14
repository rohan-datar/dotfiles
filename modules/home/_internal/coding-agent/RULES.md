# OMP Agent Policy

## Core execution style

Use the retained `eval` environment as the default control plane for substantial multi-step work.

The primary optimization goal is to **minimize outer model round trips**. When practical, batch related filesystem, search, subprocess, parsing, and tool operations into one eval cell, keep bulky intermediate state inside the retained runtime, and return only concise results to the conversation.

Prefer **JavaScript/Bun** for general orchestration:
- filesystem and repository traversal;
- subprocess and shell coordination;
- JSON and structured-data processing;
- HTTP/fetch;
- async and concurrent work;
- calling OMP tools programmatically;
- coordinating subagents and work pools.

Use **Python** when the task is genuinely Python-native, numeric/scientific, data-analysis oriented, or a Python library is materially better suited.

Do not shell out to `python -c`, `node -e`, or `bun -e` for ad-hoc computation that can be done directly in retained eval.

Do not create throwaway script files merely to escape the retained runtime. Temporary orchestration belongs in retained JS/Python state. Write normal project files only when the code is part of the project or is genuinely reusable.

## Context discipline

Treat model context as expensive even when the active provider is covered by a subscription.

Do not dump large raw command, search, compiler, test, or file outputs into the conversation when they can be filtered, parsed, summarized, or inspected programmatically in eval first.

Keep large collections, search results, parsed data, and intermediate artifacts in retained runtime state. Surface only the evidence needed for the next reasoning step.

Prefer one model turn that performs several deterministic operations in eval over several model turns that each perform one tool action.

When a tool result is unexpectedly large, inspect and reduce it before continuing.

## Semantic model roles

Treat role names as capabilities, not model identities. Concrete model bindings may change independently of this policy.

- `@primary`: normal interactive coding and implementation.
- `@architect`: user-selected foreground architecture/design work.
- `@worker`: substantial delegated implementation or reasoning.
- `@scout`: bounded repository reconnaissance and information gathering.
- `@reviewer`: independent correctness, design, or security review.
- `@utility`: inexpensive auxiliary work.

Do not reason about these roles in terms of a specific provider or model family.

## Delegation policy

The foreground model is selected by the user. Never switch to `@architect` automatically.

Never explicitly select `@architect` for a child agent unless the user specifically requests an architect subagent.

When `@architect` is the foreground model:
- keep architecture, design, tradeoff analysis, synthesis, and direct discussion with the user in the foreground session;
- delegate bounded repository exploration, code searches, implementation, testing, and mechanical analysis to configured workers;
- do not clone the foreground architecture model merely to parallelize work.

Use `@scout` for narrow discovery and reconnaissance.
Use `@worker` for substantial delegated implementation or reasoning.
Use `@reviewer` only when an independent review materially improves the result.

Keep delegated tasks narrow and ask for concise findings: relevant paths, symbols, commands, evidence, and conclusions.

Do not delegate trivial work.
Avoid spawning multiple agents when one bounded worker is sufficient.
Children should not delegate further work unless the user explicitly asks for deeper fan-out.

## Reasoning and efficiency

Use the lowest amount of orchestration necessary to solve the task well.

Do not repeatedly re-read or re-search information already retained in eval state unless the repository or relevant state has changed.

Prefer deterministic computation, filtering, and inspection inside eval over asking the model to reason repeatedly over raw data.

For long-running tasks, periodically compress working state into a concise internal summary and continue from that summary rather than carrying unnecessary raw detail forward.

When subscription quota or PAYG cost is relevant, favor fewer, higher-value model turns over many small turns.
