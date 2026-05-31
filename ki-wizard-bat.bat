@echo off
setlocal EnableDelayedExpansion

REM This program generates fab deliverables from a Kicad project
REM Usage: ./pcb-outputs.sh <projectname>
REM Use quotes if the file has spaces

REM Generate Timestamp
set timestamp=%DATE:/=-%@%TIME::=-%
set timestamp=%timestamp: =%

REM Create output directory _mfg if it does not exist already
IF NOT EXIST "_mfg\" (
  mkdir "_mfg\"
)

REM Parse terminal input to remove spaces, if needed
SET proj_file=%~1
SET proj_name=%proj_file: =_%

REM Set sch and pcb file names
SET "SCH=!proj_file!.kicad_sch"
SET "PCB=!proj_file!.kicad_pcb"

echo !proj_file!
echo !SCH!
echo !PCB!

REM GOTO :end

REM create directory based on project name and timestamp
SET "out=!proj_name!_fab-outputs_!timestamp!"
mkdir "!out!"

REM run ERC and DRC, generate reports
kicad-cli "pcb" "drc" "--output" "!out!\drc.txt" "--schematic-parity" "--severity-error" "--severity-warning" "!PCB!"
kicad-cli "sch" "erc" "--output" "!out!\erc.txt" "--severity-error" "--severity-warning" "!SCH!"

REM export PDF schematic in BW and Color
kicad-cli "sch" "export" "pdf" "--output" "!out!/!proj_name!_schematic_bw.pdf" "--theme" "Black-White" "!SCH!"
kicad-cli "sch" "export" "pdf" "--output" "!out!/!proj_name!_schematic_color.pdf" "--theme" "wDark" "!SCH!"

REM export BOM with correct fields
kicad-cli "sch" "export" "bom" "--output" "!out!/!proj_name!.csv" "--fields" "Reference,${QUANTITY},Value,${FOOTPRINT_NAME},Description,MFG,MPN" "--labels" "Refs, Qty, Value, Footprint, Description, MFG, MPN" "--group-by" "Value" "--exclude-dnp" "!SCH!"

REM generate netlist
kicad-cli "pcb" "export" "ipcd356" "--output" "!out!/!proj_name!_netlist.d356" "!PCB!"

REM export positions, sans DNP footprints
kicad-cli "pcb" "export" "pos" "--output" "!out!/!proj_name!_positions.csv" "--format" "csv" "--units" "mm" "--use-drill-file-origin" "--exclude-dnp" "!PCB!"

REM export gerbers into their own subdirectory
kicad-cli "pcb" "export" "gerbers" "--output" "!out!/!proj_name!_gerbers" "--layers" "F.Cu,In1.Cu,In2.Cu,B.Cu,F.Silkscreen,B.Silkscreen,Edge.Cuts,F.Paste,B.Paste,F.Mask,B.Mask,User.2" "!PCB!"

REM export drill file into the same subdirectory
kicad-cli "pcb" "export" "drill" "--output" "!out!/!proj_name!_gerbers" "!PCB!"

REM zip up the gerber directory
REM zip "-r" "!out!/!proj_name!_gerbers.zip" "!out!/!proj_name!_gerbers"

REM drill drawing: User.2 and the drawing frame
kicad-cli "pcb" "export" "pdf" "--output" "!out!/!proj_name!_drilldwg.pdf" "--layers" "User.2" "--ibt" "--sp" "--black-and-white" "--drill-shape-opt" "1" "--mode-single" "!PCB!"

REM Top and Bottom fab drawings: still a work in progress
kicad-cli "pcb" "export" "pdf" "--output" "!out!/!proj_name!_assy_front.pdf" "--layers" "F.Fab,Edge.Cuts" "--ibt" "--sp" "--black-and-white" "--mode-single" "!PCB!"
kicad-cli "pcb" "export" "pdf" "--output" "!out!/!proj_name!_assy_back.pdf" "--layers" "B.Fab,Edge.Cuts" "--mirror" "--ibt" "--sp" "--black-and-white" "--mode-single" "!PCB!"
REM kicad-cli pcb export pdf --output !out!/!proj_name!_assy_front.pdf --layers F.Fab,Edge.Cuts --exclude-value --ibt --sp --black-and-white --mode-single !PCB!
REM kicad-cli pcb export pdf --output !out!/!proj_name!_assy_back.pdf --layers B.Fab,Edge.Cuts --exclude-value --mirror --ibt --sp --black-and-white --mode-single !PCB!



MOVE "!out!" "_mfg\"

echo "Deliverables saved to \_mfg\!out!."

REM :end 