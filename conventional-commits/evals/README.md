# Trigger evals

Twenty queries used to check that the skill's `description` fires when it
should and stays quiet when it should not. Ten are written to trigger, ten are
near-misses chosen to be genuinely hard — they share vocabulary with the skill
(`commit`, `rebase`, `PR`, `CHANGELOG`) while needing something else entirely.
An obviously unrelated query would pass no matter how the description is
worded, and so would measure nothing.

The sharpest pair is deliberate: writing a **PR title** that follows the
convention should trigger, writing a **PR description body** should not. If a
description cannot separate those two, it is too broad.

Re-run after editing the `description`, from the skill-creator directory:

```sh
uv run --python 3.12 python -m scripts.run_loop \
  --eval-set <this-dir>/trigger-evals.json \
  --skill-path <repo>/conventional-commits \
  --model claude-opus-5 --max-iterations 5 --verbose
```

`uv run --python 3.12` matters on macOS: the scripts use `str | None`, which
needs Python 3.10+, and the system interpreter is 3.9.
