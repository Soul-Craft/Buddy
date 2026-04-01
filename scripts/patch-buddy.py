#!/usr/bin/env python3
"""
Buddy Customizer — Binary patching engine for Claude Code Buddy.

Patches the Claude Code Mach-O binary to customize the terminal pet's
species, rarity, shiny status, ASCII art (emoji), and stats.
Also updates the companion soul (name, personality) in ~/.claude.json.

Usage:
    python3 patch-buddy.py --species dragon --rarity legendary --shiny \
        --emoji "🐲" --name "Aethos" --personality "A fearsome dragon" \
        --stats '{"debugging":99,"patience":99,"chaos":99,"wisdom":99,"snark":99}'
    python3 patch-buddy.py --restore
    python3 patch-buddy.py --dry-run --species cat --rarity epic --emoji "🐱"
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

# ── Constants ──────────────────────────────────────────────────────────

SPECIES_VAR_MAP = {
    "duck": "b0_",    "goose": "I0_",   "blob": "x0_",    "cat": "u0_",
    "dragon": "m0_",  "octopus": "p0_", "owl": "g0_",     "penguin": "B0_",
    "turtle": "d0_",  "snail": "c0_",   "axolotl": "F0_", "ghost": "U0_",
    "robot": "Q0_",   "mushroom": "l0_", "cactus": "i0_", "rabbit": "n0_",
    "chonk": "r0_",   "capybara": "o0_",
}

VALID_RARITIES = ["common", "uncommon", "rare", "epic", "legendary"]

STAT_NAMES = ["debugging", "patience", "chaos", "wisdom", "snark"]

# Anchor pattern to locate the Trq species array — first 4 species variable refs
TRQ_ANCHOR = b"b0_,I0_,x0_,u0_,"

CLAUDE_JSON = Path.home() / ".claude.json"
BACKUP_DIR = Path.home() / ".claude" / "backups"
META_FILE = BACKUP_DIR / "buddy-patch-meta.json"


# ── Binary discovery ───────────────────────────────────────────────────

def find_binary() -> Path:
    """Resolve the Claude Code binary path from the symlink."""
    symlink = Path.home() / ".local" / "bin" / "claude"
    if not symlink.exists():
        raise FileNotFoundError(f"Claude Code symlink not found at {symlink}")
    resolved = symlink.resolve()
    if not resolved.exists():
        raise FileNotFoundError(f"Claude Code binary not found at {resolved}")
    return resolved


def get_version(binary_path: Path) -> str:
    """Extract version from binary path (e.g., '2.1.89' from '.../versions/2.1.89')."""
    return binary_path.name


# ── Backup / Restore ──────────────────────────────────────────────────

def ensure_backup(binary_path: Path) -> None:
    """Create backups if they don't exist (idempotent)."""
    backup = binary_path.parent / f"{binary_path.name}.original-backup"
    if not backup.exists():
        shutil.copy2(binary_path, backup)
        print(f"  [+] Binary backed up to {backup}")
    else:
        print(f"  [=] Binary backup already exists at {backup}")

    BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    soul_backup = BACKUP_DIR / ".claude.json.pre-customize"
    if not soul_backup.exists() and CLAUDE_JSON.exists():
        shutil.copy2(CLAUDE_JSON, soul_backup)
        print(f"  [+] Soul backed up to {soul_backup}")


def verify_binary(binary_path: Path) -> bool:
    """Run patched binary with --version to verify it's not corrupted."""
    try:
        result = subprocess.run(
            [str(binary_path), "--version"],
            capture_output=True,
            timeout=5,
        )
        return result.returncode == 0
    except (subprocess.TimeoutExpired, OSError):
        return False


def restore_backup(binary_path: Path) -> bool:
    """Restore binary and soul from backups."""
    backup = binary_path.parent / f"{binary_path.name}.original-backup"
    if not backup.exists():
        print("  [!] No binary backup found — nothing to restore")
        return False

    shutil.copy2(backup, binary_path)
    print(f"  [+] Binary restored from {backup}")

    soul_backup = BACKUP_DIR / ".claude.json.pre-customize"
    if soul_backup.exists():
        shutil.copy2(soul_backup, CLAUDE_JSON)
        print(f"  [+] Soul restored from {soul_backup}")

    resign_binary(binary_path)
    print("\n  Buddy restored to original! Restart Claude Code to see your OG buddy.")
    return True


# ── Patching functions ─────────────────────────────────────────────────

def find_all(data: bytearray, pattern: bytes) -> list[int]:
    """Find all occurrences of pattern in data."""
    results = []
    pos = 0
    while True:
        idx = data.find(pattern, pos)
        if idx == -1:
            break
        results.append(idx)
        pos = idx + 1
    return results


def patch_species(data: bytearray, target_species: str) -> int:
    """Replace ALL species variable refs in the Trq array with the target species."""
    target_var = SPECIES_VAR_MAP[target_species].encode()
    assert len(target_var) == 3, f"Species var must be 3 bytes, got {len(target_var)}"

    # Find all Trq array locations via anchor pattern
    anchors = find_all(data, TRQ_ANCHOR)
    if not anchors:
        print("  [!] WARNING: Could not find species array (Trq) — binary may have changed")
        return 0

    patches = 0
    for anchor_idx in anchors:
        # The Trq array starts at the anchor and contains comma-separated 3-char variable refs
        # Scan forward to find the array bounds (ends with ']')
        start = anchor_idx
        # Scan backward to find '['
        while start > 0 and data[start:start+1] != b'[':
            start -= 1
        # Scan forward from anchor to find closing ']'
        end = anchor_idx
        while end < len(data) and data[end:end+1] != b']':
            end += 1
        end += 1  # include the ']'

        array_region = data[start:end]

        # Replace each known species variable ref with the target
        for species_name, var_name in SPECIES_VAR_MAP.items():
            var_bytes = var_name.encode()
            # Only replace within the array region to avoid collisions
            region_pos = 0
            while True:
                idx = array_region.find(var_bytes, region_pos)
                if idx == -1:
                    break
                # Verify it's a variable ref (preceded by comma or bracket, followed by comma or bracket)
                if idx > 0 and array_region[idx-1:idx] in (b',', b'['):
                    array_region[idx:idx+3] = target_var
                    patches += 1
                region_pos = idx + 3

        # Write the modified region back
        data[start:end] = array_region

    print(f"  [+] Species: {patches} variable refs → {target_species} ({SPECIES_VAR_MAP[target_species]})")
    return patches


def patch_rarity(data: bytearray, target_rarity: str) -> int:
    """Zero all rarity weights except the target."""
    # Build the replacement: zero all weights except target
    rarity_weights = {"common": "60", "uncommon": "25", "rare": "10", "epic": "4", "legendary": "1"}
    old_parts = []
    new_parts = []
    for rarity, weight in rarity_weights.items():
        old_parts.append(f"{rarity}:{weight}")
        if rarity == target_rarity:
            # Keep this weight (use "01" for 2-digit weights to maintain length, "1" for 1-digit)
            new_weight = "01" if len(weight) == 2 else "1"
            new_parts.append(f"{rarity}:{new_weight}")
        else:
            # Zero out (maintain digit count)
            new_weight = "00" if len(weight) == 2 else "0"
            new_parts.append(f"{rarity}:{new_weight}")

    old_pattern = ",".join(old_parts).encode()
    new_pattern = ",".join(new_parts).encode()
    assert len(old_pattern) == len(new_pattern), f"Rarity length mismatch: {len(old_pattern)} vs {len(new_pattern)}"

    locations = find_all(data, old_pattern)
    if not locations:
        # Try matching already-patched state
        for r in VALID_RARITIES:
            alt_parts = []
            for rarity, weight in rarity_weights.items():
                if rarity == r:
                    alt_parts.append(f"{rarity}:{'01' if len(weight)==2 else '1'}")
                else:
                    alt_parts.append(f"{rarity}:{'00' if len(weight)==2 else '0'}")
            alt_pattern = ",".join(alt_parts).encode()
            alt_locs = find_all(data, alt_pattern)
            if alt_locs:
                locations = alt_locs
                old_pattern = alt_pattern
                break

    if not locations:
        print("  [!] WARNING: Could not find rarity weights (LN6) — binary may have changed")
        return 0

    for idx in locations:
        data[idx:idx+len(new_pattern)] = new_pattern

    print(f"  [+] Rarity: {len(locations)} weight tables → {target_rarity}")
    return len(locations)


def patch_shiny(data: bytearray, make_shiny: bool) -> int:
    """Set shiny to always-true or restore original probability."""
    if make_shiny:
        old, new = b"H()<0.01", b"H()<1.01"
    else:
        old, new = b"H()<1.01", b"H()<0.01"

    locations = find_all(data, old)
    if not locations:
        # Already in desired state?
        check = b"H()<1.01" if make_shiny else b"H()<0.01"
        if find_all(data, check):
            state = "shiny" if make_shiny else "normal"
            print(f"  [=] Shiny: already in {state} state")
            return 0
        print("  [!] WARNING: Could not find shiny threshold — binary may have changed")
        return 0

    for idx in locations:
        data[idx:idx+len(new)] = new

    state = "always shiny ✨" if make_shiny else "normal (1%)"
    print(f"  [+] Shiny: {len(locations)} thresholds → {state}")
    return len(locations)


def patch_art(data: bytearray, target_species: str, emoji: str) -> int:
    """Replace the target species' ASCII art with a centered emoji."""
    target_var = SPECIES_VAR_MAP[target_species]
    art_marker = f"[{target_var}]:[[".encode()

    # Find the next species marker to determine art section boundaries
    all_vars = list(SPECIES_VAR_MAP.values())
    target_idx_in_list = all_vars.index(target_var) if target_var in all_vars else -1

    locations = find_all(data, art_marker)
    if not locations:
        print(f"  [!] WARNING: Could not find art for {target_species} ({target_var}) — skipping art patch")
        return 0

    emoji_bytes = emoji.encode('utf-8')
    patches = 0

    for art_start in locations:
        # Find the end of this species' art (next species marker or end of object)
        end_candidates = []
        for var_name in SPECIES_VAR_MAP.values():
            if var_name == target_var:
                continue
            end_mark = f"],[{var_name}]:".encode()
            end_idx = data.find(end_mark, art_start + len(art_marker))
            if end_idx != -1 and end_idx < art_start + 2000:  # sanity bound
                end_candidates.append(end_idx)

        if not end_candidates:
            # Try closing with }
            end_idx = data.find(b"]}", art_start + len(art_marker))
            if end_idx != -1:
                end_candidates.append(end_idx)

        if not end_candidates:
            print(f"  [!] WARNING: Could not find art boundary for {target_species} at 0x{art_start:x}")
            continue

        art_end = min(end_candidates)
        old_art = bytes(data[art_start:art_end])
        old_len = len(old_art)

        # Build new art: 3 variants, each with 5 lines, centered emoji
        # Pad each line to fit and ensure total byte count matches
        line = f'" {emoji}  "'
        empty = '"      "'
        variant = f'[{empty},{empty},{empty},{line},{empty}]'
        new_art_str = f"[{target_var}]:[[{variant[1:]},{variant},{variant}]"

        new_art = new_art_str.encode('utf-8')
        diff = old_len - len(new_art)

        if diff > 0:
            # Pad with spaces inside the last empty string
            new_art = new_art[:-2] + b' ' * diff + new_art[-2:]
        elif diff < 0:
            # Need to shrink — use shorter padding
            line_s = f'" {emoji} "'
            empty_s = '"    "'
            variant_s = f'[{empty_s},{empty_s},{empty_s},{line_s},{empty_s}]'
            new_art_str = f"[{target_var}]:[[{variant_s[1:]},{variant_s},{variant_s}]"
            new_art = new_art_str.encode('utf-8')
            diff = old_len - len(new_art)
            if diff > 0:
                new_art = new_art[:-2] + b' ' * diff + new_art[-2:]
            elif diff < 0:
                # Ultra-compact
                line_u = f'"{emoji}"'
                empty_u = '"  "'
                variant_u = f'[{empty_u},{empty_u},{empty_u},{line_u},{empty_u}]'
                new_art_str = f"[{target_var}]:[[{variant_u[1:]},{variant_u},{variant_u}]"
                new_art = new_art_str.encode('utf-8')
                diff = old_len - len(new_art)
                if diff > 0:
                    new_art = new_art[:-2] + b' ' * diff + new_art[-2:]

        if len(new_art) != old_len:
            print(f"  [!] WARNING: Art size mismatch ({len(new_art)} vs {old_len}) — skipping")
            continue

        data[art_start:art_end] = new_art
        patches += 1
        print(f"  [+] Art: replaced {target_species} art with {emoji} at 0x{art_start:x}")

    return patches


def patch_soul(name=None, personality=None) -> bool:
    """Update the companion soul in ~/.claude.json."""
    if not name and not personality:
        return True

    if not CLAUDE_JSON.exists():
        print("  [!] WARNING: ~/.claude.json not found — skipping soul patch")
        return False

    try:
        with open(CLAUDE_JSON, 'r') as f:
            config = json.load(f)
    except json.JSONDecodeError:
        print("  [!] WARNING: ~/.claude.json is not valid JSON — skipping soul patch")
        return False

    companion = config.get("companion", {})
    if name:
        companion["name"] = name
    if personality:
        companion["personality"] = personality
    config["companion"] = companion

    with open(CLAUDE_JSON, 'w') as f:
        json.dump(config, f, indent=2, ensure_ascii=False)
        f.write('\n')

    updates = []
    if name:
        updates.append(f"name={name}")
    if personality:
        updates.append(f"personality={personality[:50]}...")
    print(f"  [+] Soul: {', '.join(updates)}")
    return True


# ── Binary re-signing ──────────────────────────────────────────────────

def resign_binary(binary_path: Path) -> bool:
    """Re-sign the binary with an ad-hoc codesign."""
    result = subprocess.run(
        ["codesign", "--force", "--sign", "-", str(binary_path)],
        capture_output=True, text=True
    )
    if result.returncode == 0:
        print(f"  [+] Binary re-signed with ad-hoc signature")
        return True
    else:
        print(f"  [!] WARNING: codesign failed: {result.stderr.strip()}")
        return False


# ── Metadata ───────────────────────────────────────────────────────────

def save_metadata(binary_path: Path, **kwargs) -> None:
    """Save patch metadata for auto-update recovery."""
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    meta = {
        "version": get_version(binary_path),
        "binary_path": str(binary_path),
        **kwargs,
    }
    with open(META_FILE, 'w') as f:
        json.dump(meta, f, indent=2, ensure_ascii=False)
    print(f"  [+] Metadata saved to {META_FILE}")


def load_metadata():
    """Load saved patch metadata."""
    if META_FILE.exists():
        with open(META_FILE) as f:
            return json.load(f)
    return None


# ── Main ───────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Buddy Customizer — evolve your Claude Code terminal pet")
    parser.add_argument("--species", choices=list(SPECIES_VAR_MAP.keys()), help="Target species")
    parser.add_argument("--rarity", choices=VALID_RARITIES, help="Target rarity tier")
    parser.add_argument("--shiny", action="store_true", help="Make buddy shiny")
    parser.add_argument("--no-shiny", action="store_true", help="Remove shiny")
    parser.add_argument("--emoji", help="Custom emoji for buddy art")
    parser.add_argument("--name", help="Buddy name")
    parser.add_argument("--personality", help="Buddy personality description")
    parser.add_argument("--stats", help="Stats as JSON: {\"debugging\":99,...}")
    parser.add_argument("--restore", action="store_true", help="Restore original buddy")
    parser.add_argument("--dry-run", action="store_true", help="Show what would change without applying")
    parser.add_argument("--binary", help="Override binary path")
    args = parser.parse_args()

    print()
    print("  🍄 Buddy Customizer v1.0.0")
    print("  ═══════════════════════════")
    print()

    # Find binary
    try:
        binary_path = Path(args.binary) if args.binary else find_binary()
    except FileNotFoundError as e:
        print(f"  [!] ERROR: {e}")
        sys.exit(1)

    print(f"  Binary: {binary_path}")
    print(f"  Version: {get_version(binary_path)}")
    print()

    # Restore mode
    if args.restore:
        if args.dry_run:
            print("  [DRY RUN] Would restore from backup")
            return
        if restore_backup(binary_path):
            # Clean up metadata
            if META_FILE.exists():
                META_FILE.unlink()
            sys.exit(0)
        else:
            sys.exit(1)

    # Validate we have something to do
    if not any([args.species, args.rarity, args.shiny, args.no_shiny,
                args.emoji, args.name, args.personality, args.stats]):
        print("  [!] Nothing to customize. Use --species, --rarity, --shiny, --emoji, --name, --personality, or --stats")
        parser.print_help()
        sys.exit(1)

    if args.dry_run:
        print("  [DRY RUN MODE — no changes will be applied]")
        print()

    # Backup
    if not args.dry_run:
        ensure_backup(binary_path)
        print()

    # Read binary
    with open(binary_path, "rb") as f:
        data = bytearray(f.read())
    print(f"  Read {len(data):,} bytes")
    print()

    total_patches = 0

    # Apply patches
    if args.species:
        if args.dry_run:
            print(f"  [DRY RUN] Would patch species → {args.species} ({SPECIES_VAR_MAP[args.species]})")
        else:
            total_patches += patch_species(data, args.species)

    if args.rarity:
        if args.dry_run:
            print(f"  [DRY RUN] Would patch rarity → {args.rarity}")
        else:
            total_patches += patch_rarity(data, args.rarity)

    if args.shiny:
        if args.dry_run:
            print(f"  [DRY RUN] Would patch shiny → always true")
        else:
            total_patches += patch_shiny(data, True)
    elif args.no_shiny:
        if args.dry_run:
            print(f"  [DRY RUN] Would patch shiny → normal (1%)")
        else:
            total_patches += patch_shiny(data, False)

    if args.emoji and args.species:
        if args.dry_run:
            print(f"  [DRY RUN] Would patch art → {args.emoji}")
        else:
            total_patches += patch_art(data, args.species, args.emoji)
    elif args.emoji and not args.species:
        print("  [!] WARNING: --emoji requires --species to know which art to replace")

    # Write binary
    if not args.dry_run and total_patches > 0:
        print()
        with open(binary_path, "wb") as f:
            f.write(data)
        print(f"  [+] Wrote {len(data):,} bytes with {total_patches} patches")
        resign_binary(binary_path)

        # Verify patched binary still works
        print("  [~] Verifying patched binary...")
        if verify_binary(binary_path):
            print("  [+] Binary verification passed")
        else:
            print()
            print("  [!] Patched binary failed verification — restoring backup...")
            restore_backup(binary_path)
            print("  [!] Your original buddy has been restored. No harm done.")
            print("  [!] Run /test-patch to check if anchor patterns need updating.")
            sys.exit(1)

    # Patch soul (separate from binary)
    if args.name or args.personality:
        print()
        if args.dry_run:
            if args.name:
                print(f"  [DRY RUN] Would set name → {args.name}")
            if args.personality:
                print(f"  [DRY RUN] Would set personality → {args.personality}")
        else:
            patch_soul(args.name, args.personality)

    # Save metadata
    if not args.dry_run:
        print()
        stats_dict = json.loads(args.stats) if args.stats else None
        save_metadata(
            binary_path,
            species=args.species,
            rarity=args.rarity,
            shiny=args.shiny,
            emoji=args.emoji,
            name=args.name,
            personality=args.personality,
            stats=stats_dict,
        )

    print()
    if args.dry_run:
        print("  [DRY RUN] No changes were made.")
    else:
        print(f"  ✅ Evolution complete! {total_patches} binary patches applied.")
        print()
        print("  ⚠️  Restart Claude Code to see your evolved buddy:")
        print("     pkill -f claude && claude")
        print()
        print("  To revert: python3 patch-buddy.py --restore")


if __name__ == "__main__":
    main()
