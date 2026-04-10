# Security Policy

## Security Model

Buddy Evolver modifies a signed Mach-O binary in-place. The project maintains
defense-in-depth across three layers: Swift input validation, atomic writes with
SHA-256 integrity verification, and plugin-level argument interception. See the
[Security Model](CLAUDE.md#security) section of CLAUDE.md for the full
architecture.

## Supported Versions

| Version | Supported |
| ------- | --------- |
| 1.0.0   | ✅ Yes     |

## Reporting a Vulnerability

**Please do not open a public GitHub issue for security vulnerabilities.**

Use [GitHub Security Advisories](https://github.com/Soul-Craft/buddy-evolver/security/advisories/new)
to report privately. We aim to acknowledge reports within 72 hours.

Include:
- Description of the vulnerability
- Steps to reproduce
- Affected versions
- Potential impact

## Security-Sensitive Files

These files have outsized security impact — reports here are especially welcome:

| File | Role |
|------|------|
| `scripts/BuddyPatcher/Sources/BuddyPatcherLib/Validation.swift` | All user-input validation |
| `scripts/BuddyPatcher/Sources/BuddyPatcherLib/BackupRestore.swift` | Backup integrity, SHA-256 verification |
| `scripts/BuddyPatcher/Sources/BuddyPatcherLib/PatchEngine.swift` | Binary modification |
| `hooks/validate-patcher-args.sh` | Shell injection prevention |
| `scripts/test-security.sh` | Security test suite |

## Security Design Principles

Contributors should maintain these invariants:

- All user inputs are validated in `Validation.swift` **before** any write operation
- All `Data.write()` calls use `.atomic` (backed by `rename(2)`) — no partial writes on crash
- Backup integrity is verified by SHA-256 hash before any restore
- Codesign failure after patching triggers automatic restore and `exit(1)`
- Zero third-party Swift dependencies — only Foundation and CryptoKit

## No Bug Bounty

There is no formal bug bounty program. Responsibly disclosed vulnerabilities will
be credited in release notes.
