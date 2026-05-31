#!/bin/zsh

# This program generates fab deliverables from a Kicad project
# Usage: ./pcb-outputs.sh <projectname>
# Use quotes if the file has spaces

# 2026-01-13: added JLC outputs

set -e

# Convert _positions_JLCREADY.csv to JLC CPL format
# Removes Val/Package columns, renames remaining columns to JLC-expected names
convert_cpl_jlc() {
    local input_file="$1"
    local output_file="${input_file/_positions_JLCREADY.csv/_CPL_JLC.csv}"

    awk -F',' 'BEGIN { OFS="," }
    NR == 1 {
        for (i = 1; i <= NF; i++) {
            col = $i
            gsub(/^[ \t"]+|[ \t"]+$/, "", col)
            idx[col] = i
        }
        print "Designator", "Mid X", "Mid Y", "Rotation", "Layer"
        next
    }
    {
        for (i = 1; i <= NF; i++) gsub(/^"|"$/, "", $i)
        print $idx["Ref"], $idx["PosX"], $idx["PosY"], $idx["Rot"], $idx["Side"]
    }' "$input_file" > "$output_file"

    echo "Saved: $output_file"
}

#echo "Filename: $1"

#Generate Timestamp
timestamp=$(date +%Y-%m-%d-%H%M%S)

# Create output directory _mfg if it does not exist already
if [ ! -d "_mfg/" ]; then
    mkdir "_mfg/"
fi

# Parse terminal input to remove spaces, if needed
proj_file=$1
proj_name="${1// /_}"

# Set sch and pcb files
SCH="${proj_file}".kicad_sch
PCB="${proj_file}".kicad_pcb

# create directory based on project name and timestamp
out="${proj_name}_fab-outputs_${timestamp}"
mkdir $out

# run ERC and DRC, generate reports
kicad-cli pcb drc --output $out/drc.txt --schematic-parity --severity-error --severity-warning $PCB
kicad-cli sch erc --output $out/erc.txt --severity-error --severity-warning $SCH

# export PDF schematic in BW and Color
kicad-cli sch export pdf --output $out/${proj_name}_schematic_bw.pdf --theme "Black-White" $SCH
kicad-cli sch export pdf --output $out/${proj_name}_schematic_color.pdf --theme "wDark" $SCH

# export CM BOM
kicad-cli sch export bom --output $out/${proj_name}_BOM_CM.csv \
	--fields '${QUANTITY},Reference,Value,Description,${FOOTPRINT_NAME},MFG,MPN,LCSC,Sub,Note' \
	--labels 'Qty, Refs, Value, Description, Footprint, MFG, MPN, LCSC#, Substitute, Note' \
	--group-by "Value" --ref-range-delimiter "" --exclude-dnp $SCH

# export ENG/Costed BOM
kicad-cli sch export bom --output $out/${proj_name}_BOM_ENG.csv \
	--fields '${QUANTITY},Reference,Value,Description,${FOOTPRINT_NAME},MFG,MPN,LCSC,Sub,Note,Price' \
	--labels 'Qty, Refs, Value, Description, Footprint, MFG, MPN, LCSC#, Substitute, Note, Price' \
	--group-by "Value" --ref-range-delimiter "" --exclude-dnp $SCH

# export JLC-formatted BOM
# note the blank "" for --ref-range-delimiter to individually list refs
kicad-cli sch export bom --output $out/${proj_name}_BOM_JLC.csv \
	--fields 'Reference,${FOOTPRINT_NAME},${QUANTITY},Value,LCSC' \
	--labels 'Designator, Footprint, Quantity, Value, LCSC Part #' \
	--group-by "Value" --ref-range-delimiter "" --exclude-dnp $SCH

# generate netlist
kicad-cli pcb export ipcd356 --output $out/${proj_name}_netlist.d356 $PCB

# export positions, sans DNP footprints
kicad-cli pcb export pos --output $out/${proj_name}_positions.csv \
	--format csv --units mm --use-drill-file-origin --exclude-dnp \
	$PCB

# create a dummy file to hand edit for JLC
cp $out/${proj_name}_positions.csv $out/${proj_name}_positions_JLCREADY.csv

# generate JLC CPL file (renamed columns, Val/Package removed)
convert_cpl_jlc $out/${proj_name}_positions_JLCREADY.csv

# export gerbers into their own subdirectory
kicad-cli pcb export gerbers --output $out/${proj_name}_gerbers \
	--layers F.Cu,In1.Cu,In2.Cu,B.Cu,F.Silkscreen,B.Silkscreen,Edge.Cuts,F.Paste,B.Paste,F.Mask,B.Mask,User.2 \
	$PCB

# export drill file into the same subdirectory
kicad-cli pcb export drill --output $out/${proj_name}_gerbers $PCB

# zip up the gerber directory
zip -r $out/${proj_name}_gerbers.zip $out/${proj_name}_gerbers

# drill drawing: User.2 and the drawing frame
kicad-cli pcb export pdf --output $out/${proj_name}_drilldwg.pdf --layers User.2,Edge.Cuts \
	--ibt --sp --black-and-white --drill-shape-opt 1 --mode-single $PCB

# Top and Bottom fab drawings: still a work in progress
kicad-cli pcb export pdf --output $out/${proj_name}_assy_front.pdf --layers F.Fab,Edge.Cuts --ibt --sp --black-and-white --mode-single $PCB
kicad-cli pcb export pdf --output $out/${proj_name}_assy_back.pdf --layers B.Fab,Edge.Cuts --mirror --ibt --sp --black-and-white --mode-single $PCB
#kicad-cli pcb export pdf --output $out/${proj_name}_assy_front.pdf --layers F.Fab,Edge.Cuts --exclude-value --ibt --sp --black-and-white --mode-single $PCB
#kicad-cli pcb export pdf --output $out/${proj_name}_assy_back.pdf --layers B.Fab,Edge.Cuts --exclude-value --mirror --ibt --sp --black-and-white --mode-single $PCB

# renders
kicad-cli pcb render --output $out/${proj_name}_render_top.png --side top --background opaque $PCB
kicad-cli pcb render --output $out/${proj_name}_render_bottom.png --side bottom --background opaque $PCB

mv $out/ _mfg/

print "Deliverables saved to /_mfg/$out."