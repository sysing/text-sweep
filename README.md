# TextSweep

Convert EPUB files for bionic reading — bolding the first few letters of each word
to create fixation points that help you read faster.

macOS app. Pure Swift core library.

## Quick Start

```bash
make build    # Compile core library
make test     # Run all tests
```

## How It Works

```
EPUB → extract (unzip) → parse HTML → bold-word-prefixes → rebuild (re-zip) → output.epub
```

## Architecture

`Sources/TextSweepCore/` — Pure logic, no UI. Protocols for all services.
`App/` — Thin macOS SwiftUI app shell.

See `AGENTS.md` for full developer documentation.
