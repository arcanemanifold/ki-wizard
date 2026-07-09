# ki-wizard

Generates fabrication deliverables from a KiCad project via `kicad-cli`: DRC/ERC reports, schematic PDFs, BOMs (CM/ENG/JLC), netlist, pick-and-place/CPL, gerbers, fab drawings, 3D renders, and an interactive HTML gerber layer viewer.

## Usage

```
ki-wizard <projectname>
```

`<projectname>` is the base filename of the `.kicad_sch` / `.kicad_pcb` files, without extension.

## Requirements

- Python 3, standard library only — no third-party packages
- `kicad-cli` on `PATH`
- Tested with KiCad V9
- BOM fields must follow EAE library conventions

## Documentation

Full documentation — output structure, BOM header/text variables, gerbview details, version history — lives in the `claude-wiki` repo (`arcanemanifold/claude-wiki`), not here: `tools/ki-wizard.md`.
