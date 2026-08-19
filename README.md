Input Filter Interaction in a Synchronous Buck Converter

A worked example of why "stable converter + stable filter ≠ stable system" in switching power supplies, and what to do about it.


---

The story

This repo answers one question with MATLAB, in three acts:

> You design a converter. It's stable, with healthy gain and phase margin.
> You design an LC input filter to meet an EMI spec. It's a well-damped, boring LC network.
> You connect the filter to the converter. The whole system rings, or outright oscillates.
> What happened, and how do you fix it without giving up the attenuation you paid for?

| Act | Question | Scripts |
|---|---|---|
| 1. The interaction | Does adding a "harmless" input filter actually break loop stability? | `01`–`04` |
| 2. The criterion | *Why* does it break, and how do you predict it before you build hardware? | `05` |
| 3. The fix | How do you damp the filter (and scale to multiple stages) without destroying its attenuation? | `06` |

---

Act 1 — The interaction (scripts 01–04)

- **`01_converter_baseline.m`** — The synchronous buck + PID voltage loop, standalone.
  Computes `Gvd`, the loop gain `T`, and gain/phase margin with `margin()`. This is the
  "converter alone is stable" baseline. It also plots the converter's **closed-loop input
  impedance** `Zi` — note it goes **negative** at low frequency. That negative incremental
  resistance (constant-power-load behavior of a regulated converter) is the seed of the whole
  problem, and it's shown here *before* any filter exists, so it's clearly a converter property,
  not a filter artifact.

- **`02_input_filter_design.m`** — The Lf–Cf input filter, designed only against an EMI
  attenuation spec (85 dB at `fs` = 1 MHz), evaluated **in isolation** (terminated in its own
  characteristic impedance / open circuit). By itself it's a clean, well-behaved 2nd-order
  low-pass — "the filter alone is fine."

- **`03_combined_gvd_bode.m`** — Uses the Extra Element Theorem (EET) to fold the filter's
  output impedance `Zo` into the converter's control-to-output transfer function, producing
  `Gvd_filter`. Bode overlay of `Gvdold` (no filter) vs `Gvd_filter` (with filter) — **this is
  the plot that visually shows the filter corrupting the plant seen by the compensator.**
  Also overlays `Zo`, `ZN`, `ZD` on one plot, since their relative magnitudes are exactly what
  Act 2 turns into a design criterion.

- **`04_stability_with_without_filter.m`** — Closes the loop both ways and runs `margin()` and
  `step()` on each. **This is the reveal**: Case 1 (no filter) has healthy GM/PM; Case 2 (with
  filter) shows degraded/negative margin and a ringing or diverging step response — while both
  the converter alone (script 01) and the filter alone (script 02) looked completely fine.

**Punchline of Act 1:** stability is not a property you can check part-by-part and then assume
holds for the assembled system. Source and load impedances interact.

---

## Act 2 — The criterion (script 05)

**`05_middlebrook_criterion.m`**

R.D. Middlebrook's 1976 result, reduced to a design rule: the converter's closed-loop input
impedance `Zi` (computed in script 01) is not just a curiosity — treat the filter as a
disturbance source loading that impedance. Overlay `|Zo(filter)|` against `|Zi(converter)|` on
one Bode magnitude plot.

- **Where `|Zo| << |Zi|`**, the filter is "invisible" to the loop — negligible interaction.
- **Where `|Zo|` approaches or exceeds `|Zi|`** (this happens right around the filter's LC
  resonance, and note `Zi` is *negative* / has a phase discontinuity at low frequency), the
  filter's dynamics leak into `Gvd` and can eat your phase margin — exactly what script 04
  showed happening.

The script also constructs the **minor-loop gain** `Tm = Zo/Zi` and inspects it — this is the
quantity whose Nyquist behavior formally governs whether the EET correction term
`(1+Zo/ZN)/(1+Zo/ZD)` stays "nice." Treat this as a diagnostic overlay, not a strict
`margin()`-style GM/PM call, since `Zi` is not itself a simple minimum-phase loop gain — the
magnitude-separation view (`|Zo| < |Zi|` at all frequencies, by some safety factor, commonly
6–20 dB) is the practical design rule you can act on.

**Punchline of Act 2:** you can predict the Act-1 failure *before* building anything, directly
from impedances you already have. This turns "huh, it oscillates" into a spec you can design to.

---

## Act 3 — The fix (scripts 06)

### `06_single_stage_damping.m`

Adds a classic **parallel RC damping branch** (`Rd` in series with a DC-blocking cap `Cb`,
paralleled across `Cf`) — damps the filter's resonant peak without adding continuous power loss
in `Rd` (the blocking cap keeps DC off it).

Design approach used here (kept practical/computational rather than quoting closed-form
"optimum damping" constants):

1. **Starting point (rule of thumb):** `Cb ≈ 4×Cf`, `Rd ≈ R0 = sqrt(Lf/Cf)` (the filter's own
   characteristic impedance) — a well-known reasonable first guess for parallel damping.
2. **MATLAB sweep:** re-derive `Zo_damped(Rd)`, re-run the EET correction and `margin()` across
   a range of `Rd` (and optionally `Cb`), and plot **phase margin vs. `Rd`**. Pick the `Rd` that
   maximizes margin (or hits your target, e.g. ≥45°) directly from the swept data — no textbook
   lookup required, and it's self-verifying against *your* actual converter/compensator, not a
   generic formula.
3. Final overlay: undamped vs. damped `T`, `margin()` plots, and closed-loop step response —
   showing the ringing from Act 1 goes away.

**Trade-off to show explicitly:** re-plot filter attenuation at `fs` with and without damping —
damping the resonance peak slightly reduces high-frequency rolloff/attenuation. Quantify that
cost; it's the honest engineering trade-off, not a free lunch.

---

## How to run

All scripts are self-contained MATLAB (Control System Toolbox: `tf`, `feedback`, `margin`,
`bode`, `step`, `minreal`). Run in order 01 → 06; each is independent (no `.mat` hand-off), so
you can also cherry-pick.

```
matlab -batch "run('01_converter_baseline.m')"
```

or just open in the MATLAB GUI and run — every script saves its figures automatically to
`/figures` (see the last few lines of each script) so they land in the repo for the README/report.

## Repo layout

```
├── README.md
├── 01_converter_baseline.m
├── 02_input_filter_design.m
├── 03_combined_gvd_bode.m
├── 04_stability_with_without_filter.m
├── 05_middlebrook_criterion.m
├── 06_single_stage_damping.m
└── figures/            <- generated .png/.fig output lands here
```

## Converter parameters (used throughout)

| Param | Value | Param | Value |
|---|---|---|---|
| Vg | 5 V | fs | 1 MHz |
| Vout / Vref | 1.8 V | L | 1 µH |
| Iout | 5 A | C | 200 µF |
| Rs (RL+Ron) | 30 mΩ | Resr | 0.8 mΩ |
| Filter Cf | 47 µF | Filter Lf | 10 µH (RLf = 10 mΩ) |
| Target attenuation | 85 dB @ fs | | |

## References

- R. D. Middlebrook, "Input Filter Considerations in Design and Application of Switching
  Regulators," *IEEE IAS Annual Meeting*, 1976.
  

