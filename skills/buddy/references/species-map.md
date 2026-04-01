# Species Variable Map — Binary Reference

## Species → Minified Variable Names

These 18 species have ASCII art templates in the binary. Each uses a 3-character minified variable name.

| Species | Variable | String.fromCharCode |
|---------|----------|-------------------|
| duck | `b0_` | `S2(100,117,99,107)` |
| goose | `I0_` | `S2(103,111,111,115,101)` |
| blob | `x0_` | `S2(98,108,111,98)` |
| cat | `u0_` | `S2(99,97,116)` |
| dragon | `m0_` | `S2(100,114,97,103,111,110)` |
| octopus | `p0_` | `S2(111,99,116,111,112,117,115)` |
| owl | `g0_` | `S2(111,119,108)` |
| penguin | `B0_` | `S2(112,101,110,103,117,105,110)` |
| turtle | `d0_` | `S2(116,117,114,116,108,101)` |
| snail | `c0_` | `S2(115,110,97,105,108)` |
| axolotl | `F0_` | `S2(97,120,111,108,111,116,108)` |
| ghost | `U0_` | `S2(103,104,111,115,116)` |
| robot | `Q0_` | `S2(114,111,98,111,116)` |
| mushroom | `l0_` | `S2(109,117,115,104,114,111,111,109)` |
| cactus | `i0_` | `S2(99,97,99,116,117,115)` |
| rabbit | `n0_` | `S2(114,97,98,98,105,116)` |
| chonk | `r0_` | `S2(99,104,111,110,107)` |
| capybara | `o0_` | `S2(99,97,112,121,98,97,114,97)` |

## Binary Patch Locations (v2.1.89)

| Component | Anchor Pattern | Expected Locations |
|-----------|---------------|-------------------|
| Species array (Trq) | `b0_,I0_,x0_,u0_,` | 4 |
| Rarity weights (LN6) | `common:60,uncommon:25,rare:10,epic:4,legendary:1` | 2 |
| Shiny threshold | `H()<0.01` | 2 |
| ASCII art (sk7) | `[{var}]:[[` per species | 2 |
| Stat generator (eN4) | `Math.floor(H()*40)` | 2 |

## Patching Constraints

1. All patches MUST maintain exact byte length (no shifting)
2. All species variable names are exactly 3 bytes
3. Binary must be re-signed with `codesign --force --sign -` after patching
4. Offsets are version-specific — the script uses pattern matching, not hardcoded offsets
5. The `__BUN/__bun` Mach-O section contains the actual executable JS bundle
6. Source map strings exist separately and must also be patched for consistency

## Rarity Probability Weights

| Rarity | Original Weight | Probability |
|--------|----------------|-------------|
| common | 60 | 60% |
| uncommon | 25 | 25% |
| rare | 10 | 10% |
| epic | 4 | 4% |
| legendary | 1 | 1% |

## Rarity → Reaction Frequency

| Rarity | Reaction Rate |
|--------|--------------|
| common | 5% |
| uncommon | 15% |
| rare | 25% |
| epic | 35% |
| legendary | 50% |
