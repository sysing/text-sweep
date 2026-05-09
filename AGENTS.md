# TextSweep — Agent Instructions

## What This Is
TextSweep converts EPUB files for bionic reading (bolding the first few letters of
each word to create fixation points). macOS app with a pure-Swift core library.

## Quick Commands
```
make build          # Build core library (SPM)
make test           # Run all tests (parallel)
make test F=Token   # Run tests matching "Token"
make clean          # Wipe build artifacts
make build-app      # Build macOS app via xcodebuild
```

## Architecture
```
Sources/TextSweepCore/     → Pure logic, no UI dependencies
  Protocols/               → All service interfaces live here
  EPUB/                    → Extract and rebuild EPUB ZIP archives
  Bionic/                  → Text tokenization and HTML transformation
  Utilities/               → Extensions and helpers

Tests/TextSweepCoreTests/  → Mirrors Sources/ structure
  TestHelpers/             → EPUB fixture builders, test utilities
  Bionic/                  → Tokenizer and transformer tests
  EPUB/                    → Extractor and rebuilder tests

App/                       → Thin macOS SwiftUI app shell
  TextSweep/Views/         → UI components
  TextSweep/ViewModels/    → Glue between core and UI
```

## Conventions
- **One public type per file.** File name = type name.
- **Protocols over concretes.** Every service is behind a protocol.
  Protocol files go in `Protocols/`. Naming: `EPUBExtracting`, `BionicTransforming`.
- **Constructor injection only.** Dependencies passed via `init()`.
  No singletons. No `@EnvironmentObject` in core library.
- **Throw or return Result.** Never force-unwrap. No `fatalError()`.
- **Files under 200 lines.** Split if larger.
- **No auto-generated code.** No storyboards, no xibs, no Core Data models.

## Dependencies (Package.swift)
- ZIPFoundation  → EPUB ZIP container handling
- SwiftSoup       → HTML parsing for XHTML content

## Adding a Feature (TDD Flow)
1. Define protocol in `Sources/TextSweepCore/Protocols/`
2. Write failing test in `Tests/TextSweepCoreTests/`
3. Implement concrete type in `Sources/TextSweepCore/[domain]/`
4. `make test` → all green
5. Wire up in `App/` if UI is needed
6. Push → CI validates automatically

## EPUB Processing Pipeline
```
EPUB file → EPUBExtractor (unzip, parse OPF, list XHTMLs)
         → BionicTransformer (walk HTML text nodes, apply bold)
         → EPUBRebuilder (re-zip into valid EPUB)
         → output.epub
```

## Bionic Reading Algorithm
- Split text by whitespace into word segments
- For each word: bold the first `ceil(len * fixationRatio)` chars
- Skip words shorter than `minimumWordLength`
- Optionally skip common stop words
- Preserve surrounding punctuation and inline HTML tags

## Testing
- Fixtures generated programmatically — no binary blobs in repo
- Golden file tests for HTML output (exact match expected)
- Idempotency tests for EPUB roundtrip (extract → rebuild → extract)
- All tests self-contained, no network access

## CI
Runs on every push/PR to main. Single macOS job:
1. `swift build` — compile
2. `swift test --parallel` — all tests
3. `git diff --exit-code` — no uncommitted changes
