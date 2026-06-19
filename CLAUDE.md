# ki-wizard

CLI tool for generating KiCad fabrication deliverables. Tested with KiCad V9. BOM fields must be compatible with EAE libraries.

## Usage

```bash
ki-wizard <projectname> [--include-source]
```

`<projectname>` is the base filename of the `.kicad_sch` and `.kicad_pcb` files, without extension.

## Key facts

- `ki-wizard` is the main script (Python 3, standard library only + `hashlib`)
- `ki-wizard.zsh` is the original shell script, kept for archival purposes only
- `ki-wizard-bat.bat` is the Windows equivalent (not yet ported to Python)
- BOM field compatibility with EAE KiCad libraries is a hard requirement — incorrect fields will produce bad output silently
- `kicad-cli` must be on PATH

## Output bundle

Written to `_mfg/<projectname>_fab-outputs_<timestamp>/`:

- `drc.txt`, `erc.txt` — design rule check reports
- `*_schematic_bw.pdf`, `*_schematic_color.pdf`
- `*_BOM_CM.csv`, `*_BOM_ENG.csv`, `*_BOM_JLC.csv`
- `*_netlist.d356`
- `*_positions.csv`, `*_CPL_JLC.csv`
- `*_gerbers/`, `*_gerbers.zip`
- `*_drilldwg.pdf`, `*_assy_front.pdf`, `*_assy_back.pdf`
- `*_render_top.png`, `*_render_bottom.png`
- `provenance.txt` — ki-wizard version, timestamp, sha256 of source files

## Options

- `--include-source` — zip `.kicad_pcb`, `.kicad_sch`, `.kicad_pro`, and `.pretty/` libraries into the output folder
