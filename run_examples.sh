#!/bin/bash

# This script finds all directories matching example_* and runs 'kubectl kustomize' 
# on ALL overlays found within them. It aggregates the output into a single
# 'output.yaml' file at the root of the example directory (e.g., example_n/output.yaml).

BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${BOLD}Kustomize Examples Runner & Persister${NC}"
echo "=========================================="

# Find all example_* directories, sorted
EXAMPLES=$(find . -maxdepth 1 -type d -name "example_*" | sort)

if [ -z "$EXAMPLES" ]; then
    echo "No examples found."
    exit 1
fi

for ex_dir in $EXAMPLES; do
    ex_name=$(basename "$ex_dir")
    final_output_file="$ex_dir/output.yaml"
    
    echo -e "\n${BOLD}>>> ${ex_name}${NC}"
    
    # Clear or create the final output file
    echo "# Aggregated Kustomize Output for $ex_name" > "$final_output_file"
    
    # Find all subdirectories under overlays/
    overlays=$(find "$ex_dir/overlays" -maxdepth 1 -mindepth 1 -type d | sort)
    
    for overlay in $overlays; do
        overlay_name=$(basename "$overlay")
        
        echo -e "\n  ${GREEN}Processing overlay: ${BOLD}$overlay_name${NC}"
        
        # Add a header to the YAML file
        echo -e "\n---\n# OVERLAY: $overlay_name" >> "$final_output_file"
        
        # Render and append to file
        kubectl kustomize "$overlay" >> "$final_output_file"
        
        echo -e "  ${CYAN}Rendered $overlay_name into $final_output_file${NC}"
    done
    
    echo -e "\n  ${YELLOW}Final Aggregated File: $final_output_file${NC}"
    echo "  --------------------------"
    # Show a snippet of the final file
    head -n 20 "$final_output_file" | sed 's/^/  /'
    echo "  ..."
    echo "  --------------------------"
done

# Cleanup old output files from previous incorrect implementation
find . -name "output.yaml" -path "*/overlays/*/output.yaml" -delete

echo -e "\n${BOLD}Finished. Outputs are now at /example_n/output.yaml${NC}"
