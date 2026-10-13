# setup-sandbox

Follow the project's contribution rules, including the commit message format:

@CONTRIBUTING.md

## File Header

Before committing, check that every source file (scripts, code, configs) added or modified in the commit starts with this header:

```
# Source: https://github.com/infraguide-org/setup-sandbox
# Copyright (c) 2026 infraguide.org, MIT License
```

* If a file lacks the header, add it in the same commit.
* Keep the same text and use the file type's comment syntax (e.g. `//` or `<!-- -->` instead of `#`).
* Put the header after a shebang line (`#!...`) if the file has one.
* Do not add it to project-describing files (`CLAUDE.md`, `CONTRIBUTING.md`, `LICENSE`, `README.md` and similar docs), or to files that cannot hold comments (e.g. JSON).

