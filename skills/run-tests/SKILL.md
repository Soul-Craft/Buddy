---
name: run-tests
description: This skill should be used when the user asks to "run tests", "run-tests", "test the patcher", "run swift tests", "check tests", "run unit tests", or "verify tests pass".
disable-model-invocation: true
---

# Run Tests — Swift Test Suite

Run the BuddyPatcher Swift unit tests and report results.

## Steps

### 1. Run tests

```bash
cd "${CLAUDE_PLUGIN_ROOT}/scripts/BuddyPatcher" && swift test 2>&1
```

### 2. Parse and report results

Read the output and extract:
- Total tests run
- Tests passed
- Tests failed
- Time elapsed

### 3. Display formatted report

```
Test Suite Report — 178 tests across 12 files
══════════════════════════════════════════════

  AnalyzeTests              ✅ / ❌
  ArgumentParsingTests      ✅ / ❌
  BackupRestoreTests         ✅ / ❌
  BinaryDiscoveryTests       ✅ / ❌
  ByteUtilsTests             ✅ / ❌
  MetadataTests              ✅ / ❌
  OrchestrationTests         ✅ / ❌
  PatchEngineTests           ✅ / ❌
  PatchLengthInvariantTests  ✅ / ❌
  RegressionTests            ✅ / ❌
  SoulPatcherTests           ✅ / ❌
  ValidationTests            ✅ / ❌
  VariableMapDetectionTests  ✅ / ❌

  Total: N tests, M passed, K failed (X.XXs)
  Result: ALL PASS ✅  /  FAILURES ❌
```

### 4. If failures

Show the specific test names and assertion messages that failed. Suggest checking the corresponding source files:

- `Analyze.swift` — binary introspection (--analyze mode)
- `ArgumentParsing.swift` — CLI argument handling
- `BackupRestore.swift` — backup/restore and SHA-256 verification
- `BinaryDiscovery.swift` — binary path resolution
- `ByteUtils.swift` — byte pattern matching
- `Metadata.swift` — patch metadata persistence
- `Orchestration.swift` — patch pipeline coordination
- `PatchEngine.swift` — binary patching functions
- `RegressionTests.swift` — one test per previously-fixed bug
- `SoulPatcher.swift` — companion config updates
- `Validation.swift` — input validation (emoji, name, personality, binary path)
- `VariableMapDetection.swift` — species variable maps

### 5. If build fails

If `swift test` fails during compilation (before running tests), report the build errors separately and suggest checking:
- `Package.swift` for target configuration
- Whether all source files are in the correct directories
