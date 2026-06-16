#!/usr/bin/env python3
"""
ki-wizard.py — generates fab deliverables from a KiCad project.

Usage:
    python ki-wizard.py [options] <projectname>

The project name should be the base name of the .kicad_sch / .kicad_pcb
files, without extension. Quote it if it contains spaces.

2026-01-13: added JLC outputs
2026-06-09: argparse; provenance file; --include-source
"""

import argparse
import csv
import hashlib
import shutil
import subprocess
import sys
import zipfile
from datetime import datetime
from pathlib import Path

VERSION = "2.1"


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def run(cmd: list[str]) -> None:
    """Run a command, printing it first, and exit on non-zero return code."""
    print(">>", " ".join(cmd))
    result = subprocess.run(cmd)
    if result.returncode != 0:
        sys.exit(f"Command failed with exit code {result.returncode}: {' '.join(cmd)}")


def zip_directory(source_dir: Path, zip_path: Path) -> None:
    """Zip source_dir into zip_path, preserving internal relative paths."""
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
        for file in source_dir.rglob("*"):
            if file.is_file():
                zf.write(file, file.relative_to(source_dir.parent))


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def convert_cpl_jlc(input_path: Path) -> None:
    """
    Convert a _positions_JLCREADY.csv to JLC CPL format.
    Drops Val and Package columns; renames remaining columns to JLC names.
    Saves alongside the input with _positions_JLCREADY replaced by _CPL_JLC.
    """
    output_path = Path(str(input_path).replace("_positions_JLCREADY.csv", "_CPL_JLC.csv"))

    column_map = {
        "Ref":  "Designator",
        "PosX": "Mid X",
        "PosY": "Mid Y",
        "Rot":  "Rotation",
        "Side": "Layer",
    }
    keep = list(column_map.keys())

    with input_path.open(newline="") as infile, \
         output_path.open("w", newline="") as outfile:

        reader = csv.DictReader(infile)
        writer = csv.DictWriter(outfile, fieldnames=list(column_map.values()))
        writer.writeheader()

        for row in reader:
            writer.writerow({column_map[col]: row[col] for col in keep})

    print(f"Saved: {output_path}")


def write_provenance(out: Path, sch: Path, pcb: Path, timestamp: str) -> None:
    """Write provenance.txt recording source file identities for this build."""
    lines = [
        f"ki-wizard version: {VERSION}",
        f"timestamp: {timestamp}",
        "",
        "source files:",
        f"  {sch}",
        f"    sha256: {sha256(sch)}",
        f"  {pcb}",
        f"    sha256: {sha256(pcb)}",
    ]
    prov = out / "provenance.txt"
    prov.write_text("\n".join(lines) + "\n")
    print(f"Saved: {prov}")


def bundle_source(out: Path, proj_file: str, proj_name: str) -> None:
    """Zip minimal source files (.kicad_pcb, .kicad_sch, .kicad_pro, .pretty/) into the output folder."""
    source_zip = out / f"{proj_name}_source.zip"
    proj_dir = Path(proj_file).parent if Path(proj_file).parent != Path(".") else Path(".")

    candidates = [
        Path(f"{proj_file}.kicad_pcb"),
        Path(f"{proj_file}.kicad_sch"),
        Path(f"{proj_file}.kicad_pro"),
    ]
    # Include any additional .kicad_sch sheets in the same directory
    candidates += [p for p in proj_dir.glob("*.kicad_sch") if p not in candidates]
    # Include custom footprint libraries (.pretty directories)
    pretty_dirs = list(proj_dir.glob("*.pretty"))

    with zipfile.ZipFile(source_zip, "w", zipfile.ZIP_DEFLATED) as zf:
        for path in candidates:
            if path.exists():
                zf.write(path, path.name)
        for pretty in pretty_dirs:
            for file in pretty.rglob("*"):
                if file.is_file():
                    zf.write(file, file.relative_to(proj_dir))

    print(f"Saved: {source_zip}")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate KiCad fabrication deliverables."
    )
    parser.add_argument("projectname",
                        help="Base filename of the .kicad_sch/.kicad_pcb files (no extension)")
    parser.add_argument("--include-source", action="store_true",
                        help="Zip minimal source files into the output folder")
    args = parser.parse_args()

    proj_file = args.projectname
    proj_name = proj_file.replace(" ", "_")

    sch = Path(f"{proj_file}.kicad_sch")
    pcb = Path(f"{proj_file}.kicad_pcb")

    timestamp = datetime.now().strftime("%Y-%m-%d-%H%M%S")

    # Create _mfg output directory if it doesn't exist
    Path("_mfg").mkdir(exist_ok=True)

    # Create per-run output directory
    out = Path(f"{proj_name}_fab-outputs_{timestamp}")
    out.mkdir()

    # -- ERC / DRC -----------------------------------------------------------
    run(["kicad-cli", "pcb", "drc",
         "--output",            str(out / "drc.txt"),
         "--schematic-parity",
         "--severity-error", "--severity-warning",
         str(pcb)])

    run(["kicad-cli", "sch", "erc",
         "--output",        str(out / "erc.txt"),
         "--severity-error", "--severity-warning",
         str(sch)])

    # -- Schematic PDFs ------------------------------------------------------
    run(["kicad-cli", "sch", "export", "pdf",
         "--output", str(out / f"{proj_name}_schematic_bw.pdf"),
         "--theme",  "Black-White",
         str(sch)])

    run(["kicad-cli", "sch", "export", "pdf",
         "--output", str(out / f"{proj_name}_schematic_color.pdf"),
         "--theme",  "wDark",
         str(sch)])

    # -- BOMs ----------------------------------------------------------------
    # CM BOM
    run(["kicad-cli", "sch", "export", "bom",
         "--output", str(out / f"{proj_name}_BOM_CM.csv"),
         "--fields", "${QUANTITY},Reference,Value,Description,${FOOTPRINT_NAME},MFG,MPN,LCSC,Sub,Note",
         "--labels", "Qty, Refs, Value, Description, Footprint, MFG, MPN, LCSC#, Substitute, Note",
         "--group-by", "Value",
         "--ref-range-delimiter", "",
         "--exclude-dnp",
         str(sch)])

    # ENG / Costed BOM
    run(["kicad-cli", "sch", "export", "bom",
         "--output", str(out / f"{proj_name}_BOM_ENG.csv"),
         "--fields", "${QUANTITY},Reference,Value,Description,${FOOTPRINT_NAME},MFG,MPN,LCSC,Sub,Note,Price",
         "--labels", "Qty, Refs, Value, Description, Footprint, MFG, MPN, LCSC#, Substitute, Note, Price",
         "--group-by", "Value",
         "--ref-range-delimiter", "",
         "--exclude-dnp",
         str(sch)])

    # JLC BOM
    run(["kicad-cli", "sch", "export", "bom",
         "--output", str(out / f"{proj_name}_BOM_JLC.csv"),
         "--fields", "Reference,${FOOTPRINT_NAME},${QUANTITY},Value,LCSC",
         "--labels", "Designator, Footprint, Quantity, Value, LCSC Part #",
         "--group-by", "Value",
         "--ref-range-delimiter", "",
         "--exclude-dnp",
         str(sch)])

    # -- Netlist -------------------------------------------------------------
    run(["kicad-cli", "pcb", "export", "ipcd356",
         "--output", str(out / f"{proj_name}_netlist.d356"),
         str(pcb)])

    # -- Pick-and-place / CPL ------------------------------------------------
    positions_csv = out / f"{proj_name}_positions.csv"
    positions_jlc = out / f"{proj_name}_positions_JLCREADY.csv"

    run(["kicad-cli", "pcb", "export", "pos",
         "--output",              str(positions_csv),
         "--format", "csv",
         "--units",  "mm",
         "--use-drill-file-origin",
         "--exclude-dnp",
         str(pcb)])

    shutil.copy(positions_csv, positions_jlc)
    convert_cpl_jlc(positions_jlc)

    # -- Gerbers -------------------------------------------------------------
    gerber_dir = out / f"{proj_name}_gerbers"

    run(["kicad-cli", "pcb", "export", "gerbers",
         "--output", str(gerber_dir),
         "--layers", "F.Cu,In1.Cu,In2.Cu,B.Cu,F.Silkscreen,B.Silkscreen,"
                     "Edge.Cuts,F.Paste,B.Paste,F.Mask,B.Mask,User.2",
         str(pcb)])

    run(["kicad-cli", "pcb", "export", "drill",
         "--output", str(gerber_dir),
         str(pcb)])

    zip_directory(gerber_dir, out / f"{proj_name}_gerbers.zip")

    # -- Fab drawings --------------------------------------------------------
    run(["kicad-cli", "pcb", "export", "pdf",
         "--output", str(out / f"{proj_name}_drilldwg.pdf"),
         "--layers", "User.2,Edge.Cuts",
         "--ibt", "--sp", "--black-and-white",
         "--drill-shape-opt", "1",
         "--mode-single",
         str(pcb)])

    run(["kicad-cli", "pcb", "export", "pdf",
         "--output", str(out / f"{proj_name}_assy_front.pdf"),
         "--layers", "F.Fab,Edge.Cuts",
         "--ibt", "--sp", "--black-and-white", "--mode-single",
         str(pcb)])

    run(["kicad-cli", "pcb", "export", "pdf",
         "--output", str(out / f"{proj_name}_assy_back.pdf"),
         "--layers", "B.Fab,Edge.Cuts",
         "--mirror", "--ibt", "--sp", "--black-and-white", "--mode-single",
         str(pcb)])

    # -- Renders -------------------------------------------------------------
    run(["kicad-cli", "pcb", "render",
         "--output", str(out / f"{proj_name}_render_top.png"),
         "--side", "top", "--background", "opaque",
         str(pcb)])

    run(["kicad-cli", "pcb", "render",
         "--output", str(out / f"{proj_name}_render_bottom.png"),
         "--side", "bottom", "--background", "opaque",
         str(pcb)])

    # -- Provenance ----------------------------------------------------------
    write_provenance(out, sch, pcb, timestamp)

    # -- Optional source bundle ----------------------------------------------
    if args.include_source:
        bundle_source(out, proj_file, proj_name)

    # -- Move output bundle into _mfg ----------------------------------------
    shutil.move(str(out), "_mfg/")

    print(f"\nDeliverables saved to _mfg/{out}.")


if __name__ == "__main__":
    main()
