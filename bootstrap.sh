#!/bin/bash

# Bootstrap script for linking opencode workflow configuration to a target project
# This script creates symlinks for rules, skills, AGENTS.md, and opencode.json

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Available technologies (prefix used in rule filenames)
declare -A TECHNOLOGIES=(
    ["react"]="React"
    ["ts"]="TypeScript"
)

# Rules that are always included (no technology prefix)
GENERIC_RULES=("project-stack")

print_header() {
    echo -e "\n${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}         ${BLUE}OpenCode Workflow Bootstrap Script${NC}               ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}\n"
}

print_step() {
    echo -e "${BLUE}▶${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Function to display technology selection menu
select_technologies() {
    local selected=()
    local keys=(${!TECHNOLOGIES[@]})
    local num_techs=${#keys[@]}
    
    echo -e "${YELLOW}Select the technologies used in your project:${NC}"
    echo -e "${CYAN}(Enter numbers separated by spaces, e.g., '1 2')${NC}\n"
    
    for i in "${!keys[@]}"; do
        local key="${keys[$i]}"
        echo "  $((i + 1)). ${TECHNOLOGIES[$key]}"
    done
    echo ""
    
    read -p "Your selection: " -a choices
    
    for choice in "${choices[@]}"; do
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$num_techs" ]; then
            selected+=("${keys[$((choice - 1))]}")
        else
            print_warning "Invalid selection: $choice (ignored)"
        fi
    done
    
    if [ ${#selected[@]} -eq 0 ]; then
        print_error "No valid technologies selected. Using generic rules only."
    fi
    
    echo "${selected[@]}"
}

# Function to get target project path
get_target_path() {
    echo -e "\n${YELLOW}Enter the path to your target project:${NC}"
    read -p "> " target_path
    
    # Expand ~ to home directory
    target_path="${target_path/#\~/$HOME}"
    
    # Convert to absolute path if relative
    if [[ ! "$target_path" = /* ]]; then
        target_path="$(pwd)/$target_path"
    fi
    
    # Normalize path
    target_path="$(cd "$target_path" 2>/dev/null && pwd)" || {
        print_error "Directory does not exist: $target_path"
        exit 1
    }
    
    echo "$target_path"
}

# Function to check if a rule matches selected technologies
rule_matches_tech() {
    local rule_name="$1"
    shift
    local selected_techs=("$@")
    
    # Check if it's a generic rule
    for generic in "${GENERIC_RULES[@]}"; do
        if [[ "$rule_name" == "$generic.md" ]]; then
            return 0
        fi
    done
    
    # Check if it matches any selected technology
    for tech in "${selected_techs[@]}"; do
        if [[ "$rule_name" == ${tech}-* ]]; then
            return 0
        fi
    done
    
    return 1
}

# Function to create symlink with backup
create_symlink() {
    local source="$1"
    local target="$2"
    
    if [ -e "$target" ] || [ -L "$target" ]; then
        if [ -L "$target" ]; then
            rm "$target"
        else
            print_warning "File exists and is not a symlink: $target"
            read -p "  Backup and replace? (y/n): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                mv "$target" "${target}.backup"
                print_success "Backed up to ${target}.backup"
            else
                print_warning "Skipped: $target"
                return
            fi
        fi
    fi
    
    # Create parent directory if needed
    mkdir -p "$(dirname "$target")"
    
    ln -s "$source" "$target"
    print_success "Linked: $(basename "$target")"
}

# Main execution
main() {
    print_header
    
    # Step 1: Select technologies
    print_step "Step 1: Technology Selection"
    selected_techs=($(select_technologies))
    
    if [ ${#selected_techs[@]} -gt 0 ]; then
        echo -e "\n${GREEN}Selected technologies:${NC} ${selected_techs[*]}"
    fi
    
    # Step 2: Get target path
    print_step "\nStep 2: Target Project Path"
    target_path=$(get_target_path)
    echo -e "${GREEN}Target project:${NC} $target_path"
    
    # Confirm before proceeding
    echo -e "\n${YELLOW}This will create symlinks in:${NC}"
    echo "  - $target_path/.opencode/rules/"
    echo "  - $target_path/.opencode/skills/"
    echo "  - $target_path/AGENTS.md"
    echo "  - $target_path/opencode.json"
    echo ""
    read -p "Proceed? (y/n): " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_warning "Aborted by user."
        exit 0
    fi
    
    # Step 3: Create .opencode directory structure
    print_step "\nStep 3: Creating directory structure"
    mkdir -p "$target_path/.opencode/rules"
    mkdir -p "$target_path/.opencode/skills"
    print_success "Created .opencode directory structure"
    
    # Step 4: Link rules
    print_step "\nStep 4: Linking rules"
    rules_linked=0
    for rule_file in "$SCRIPT_DIR/.opencode/rules/"*.md; do
        rule_name="$(basename "$rule_file")"
        
        if rule_matches_tech "$rule_name" "${selected_techs[@]}"; then
            create_symlink "$rule_file" "$target_path/.opencode/rules/$rule_name"
            ((rules_linked++))
        fi
    done
    echo -e "  ${CYAN}→ $rules_linked rule(s) linked${NC}"
    
    # Step 5: Link skills
    print_step "\nStep 5: Linking skills"
    skills_linked=0
    for skill_dir in "$SCRIPT_DIR/.opencode/skills/"*/; do
        skill_name="$(basename "$skill_dir")"
        create_symlink "$skill_dir" "$target_path/.opencode/skills/$skill_name"
        ((skills_linked++))
    done
    echo -e "  ${CYAN}→ $skills_linked skill(s) linked${NC}"
    
    # Step 6: Link AGENTS.md
    print_step "\nStep 6: Linking AGENTS.md"
    create_symlink "$SCRIPT_DIR/AGENTS.md" "$target_path/AGENTS.md"
    
    # Step 7: Link opencode.json
    print_step "\nStep 7: Linking opencode.json"
    create_symlink "$SCRIPT_DIR/opencode.json" "$target_path/opencode.json"
    
    # Summary
    echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}                    ${GREEN}Bootstrap Complete!${NC}                     ${GREEN}║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo -e "\n${CYAN}Summary:${NC}"
    echo "  • Rules linked: $rules_linked"
    echo "  • Skills linked: $skills_linked"
    echo "  • AGENTS.md: linked"
    echo "  • opencode.json: linked"
    echo -e "\n${YELLOW}Note:${NC} Symlinks point to this repository. Changes here will be reflected in linked projects."
}

main "$@"
