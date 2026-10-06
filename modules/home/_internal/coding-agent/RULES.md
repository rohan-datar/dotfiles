# RLM-style execution and delegation policy

## Runtime choice

For substantial multi-step work, use the retained `eval` runtimes as the
control plane rather than emitting a long sequence of isolated tool calls.

Prefer JavaScript/Bun for general orchestration:
- filesystem and repository operations;
- shell/process coordination;
- JSON and structured-data manipulation;
- HTTP/fetch;
- asynchronous/concurrent work;
- calling OMP tools programmatically;
- coordinating subagents, handles, waits, and work pools.

Prefer Python when the task is genuinely Python-native, numeric/scientific,
data-analysis oriented, or a Python library is materially better suited.

Keep useful state in the retained runtime between cells. Filter and aggregate
large outputs there before returning concise results to the conversation.

Do not shell out to `python -c`, `node -e`, or `bun -e` for ad-hoc computation
that can be done directly in retained eval.

Do not create throwaway script files merely to escape the retained runtime.
Temporary orchestration belongs in retained JS/Python state. Real project code
and reusable repository utilities belong in normal project files.

The JavaScript runtime is first-class, not a fallback. Use Bun/Node APIs,
top-level await, fetch, filesystem APIs, and managed packages when appropriate.

## Semantic model roles

Treat role names as capabilities, not concrete model identities:

- `@primary`: normal interactive coding and implementation.
- `@architect`: user-selected foreground architecture/design conversation.
- `@worker`: substantial delegated implementation or reasoning.
- `@scout`: cheap bounded repository reconnaissance.
- `@reviewer`: independent correctness/security/design review.
- `@utility`: tiny auxiliary tasks.

Never depend on a specific model family or version in reasoning about these
roles. Concrete model bindings are external configuration and may change.

## Foreground model vs workers

The foreground model is selected by the user. Do not switch to `@architect`
automatically.

Never explicitly select `@architect` or an OpenCode Zen model for a
subagent unless the user explicitly asks for such a subagent.

When the foreground model is `@architect`:
- keep architecture, design, tradeoff analysis, synthesis, and direct
  conversation with the user in the foreground session;
- delegate bounded repository reconnaissance, code searches, implementation,
  tests, mechanical analysis, and similar support work to configured workers;
- do not clone the foreground architecture model into children.

Use `scout`/`sonic` for narrow reconnaissance.
Use `task` for substantial delegated implementation/reasoning.
Use reviewer agents only for an independent review that materially helps.

Keep child assignments narrow and request concise evidence: relevant paths,
symbols, commands, results, and conclusions.

Do not spawn subagents for trivial work.
Avoid spawning multiple agents when one bounded worker is sufficient.
Do not ask a child to delegate further work.

## Cost and context discipline

Prefer programmatic aggregation in eval over repeated model round-trips when
several operations can be performed and reduced to a concise result in one
retained cell.

Do not dump large raw command/file outputs into the conversation when they can
be searched, parsed, filtered, or summarized in eval first.

Spend expensive foreground-model tokens on judgment and synthesis, not
repository archaeology that a worker/scout can perform.

