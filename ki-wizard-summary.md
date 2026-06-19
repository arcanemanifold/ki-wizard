# ki-wizard.py — Summary

## Overview

`ki-wizard.py` is a Python script that automates the generation of fabrication
deliverables from a KiCad project. It wraps `kicad-cli` to produce a complete,
timestamped output bundle suitable for board assembly and manufacture.

**Usage:**

```
python ki-wizard.py <projectname>
```

Where `<projectname>` is the base filename of the `.kicad_sch` and `.kicad_pcb`
files, without extension. Paths with spaces do not require quoting in Python.

---

## Output Structure

All outputs are written to a timestamped directory and then moved into `_mfg/`:

```
_mfg/
└── <projectname>_fab-outputs_<YYYY-MM-DD-HHMMSS>/
    ├── drc.txt
    ├── erc.txt
    ├── <proj>_schematic_bw.pdf
    ├── <proj>_schematic_color.pdf
    ├── <proj>_BOM_CM.csv
    ├── <proj>_BOM_ENG.csv
    ├── <proj>_BOM_JLC.csv
    ├── <proj>_netlist.d356
    ├── <proj>_positions.csv
    ├── <proj>_positions_JLCREADY.csv
    ├── <proj>_CPL_JLC.csv
    ├── <proj>_gerbers/
    ├── <proj>_gerbers.zip
    ├── <proj>_drilldwg.pdf
    ├── <proj>_assy_front.pdf
    ├── <proj>_assy_back.pdf
    ├── <proj>_render_top.png
    └── <proj>_render_bottom.png
```

---

## Steps Performed

### 1. Design Rule Checks

Runs PCB DRC (with schematic parity check) and schematic ERC, writing error and
warning reports to `drc.txt` and `erc.txt`.

### 2. Schematic PDFs

Exports the schematic twice: once in black-and-white (`Black-White` theme) and
once in colour (`wDark` theme).

### 3. Bills of Materials

Three BOM variants are produced:

| File           | Purpose               | Fields                                                               |
| -------------- | --------------------- | -------------------------------------------------------------------- |
| `_BOM_CM.csv`  | Contract manufacturer | Qty, Refs, Value, Description, Footprint, MFG, MPN, LCSC#, Sub, Note |
| `_BOM_ENG.csv` | Engineering / costed  | Same as CM, plus Price                                               |
| `_BOM_JLC.csv` | JLCPCB assembly       | Designator, Footprint, Quantity, Value, LCSC Part #                  |

All BOMs are grouped by value, list references individually, and exclude DNP
components.

### 4. Netlist

Exports an IPC-D-356 netlist for electrical test.

### 5. Pick-and-Place / CPL Files

Exports component positions from the PCB in CSV format (mm, drill-file origin,
no DNP). Two additional files are then derived from this:

- `_positions_JLCREADY.csv` — a direct copy retained for manual review or editing.
- `_CPL_JLC.csv` — the JLC-formatted CPL file (see [CPL Conversion](#cpl-conversion) below).

### 6. Gerbers and Drill File

Exports gerbers for the following layers into a subdirectory, then packages them
into a zip:

`F.Cu, In1.Cu, In2.Cu, B.Cu, F.Silkscreen, B.Silkscreen, Edge.Cuts, F.Paste,
B.Paste, F.Mask, B.Mask, User.2`

A drill file is exported into the same subdirectory before zipping.

### 7. Fabrication Drawings

Three PDF drawings are produced:

- **Drill drawing** — `User.2` + `Edge.Cuts` layers, with drill shape visualisation.
- **Front assembly** — `F.Fab` + `Edge.Cuts`.
- **Back assembly** — `B.Fab` + `Edge.Cuts`, mirrored.

### 8. 3D Renders

Top and bottom renders of the PCB are exported as PNG with an opaque background.

---

## CPL Conversion

The `convert_cpl_jlc()` function transforms the raw KiCad positions export into
the column format expected by JLCPCB's assembly service.

| KiCad column | JLC CPL column |
| ------------ | -------------- |
| `Ref`        | `Designator`   |
| `PosX`       | `Mid X`        |
| `PosY`       | `Mid Y`        |
| `Rot`        | `Rotation`     |
| `Side`       | `Layer`        |

The `Val` and `Package` columns are dropped. The conversion uses Python's
`csv.DictReader` / `DictWriter`, which correctly handles quoted fields
containing commas.

---

## Conversion from zsh

### Approach

The script is a direct, line-for-line functional port — no new features were
added. The goal was cross-platform compatibility, since `kicad-cli` itself runs
on Windows, macOS, and Linux but zsh is not available by default on Windows.

### Key changes

| Concern                        | zsh                             | Python                                                                        |
| ------------------------------ | ------------------------------- | ----------------------------------------------------------------------------- |
| Running commands               | Bare shell invocations          | `subprocess.run()` via a `run()` helper                                       |
| Exit on error                  | `set -e`                        | `run()` checks `returncode` and calls `sys.exit()` with a descriptive message |
| File copy                      | `cp`                            | `shutil.copy()`                                                               |
| Directory move                 | `mv`                            | `shutil.move()`                                                               |
| Zip creation                   | `zip -r`                        | `zipfile.ZipFile` with a recursive directory walk                             |
| Path handling                  | String concatenation with `/`   | `pathlib.Path`, safe on all platforms                                         |
| CPL conversion                 | `awk` one-pass column filter    | `csv.DictReader` / `DictWriter`                                               |
| Timestamp                      | `date +%Y-%m-%d-%H%M%S`         | `datetime.now().strftime(...)`                                                |
| Space handling in project name | `${1// /_}` parameter expansion | `str.replace(" ", "_")`                                                       |

### Error handling

The original script used `set -e` to abort on any non-zero exit code, with no
indication of which command failed. The Python `run()` helper prints each
command before executing it and emits a specific error message identifying the
failed command if it exits non-zero, making failures easier to diagnose.

### Commented-out variants

The two commented-out `--exclude-value` assembly drawing variants from the
original script are preserved as comments in the Python version.

### Dependencies

The script uses only the Python standard library (`csv`, `shutil`, `subprocess`,
`sys`, `zipfile`, `datetime`, `pathlib`). No third-party packages are required.
`kicad-cli` must be available on `PATH`, as in the original.
