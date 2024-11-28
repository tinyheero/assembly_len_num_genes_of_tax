#!/usr/bin/env bash

#
# Bash long-argument script template
# Please see the USAGE, AUTHOR and VERSION variables below for more information.
#

# We need to get the pathname first before doing anything else or it will change
PATHNAME="$_";

# Exit on uncaught error, disallow unset variables and raise an error if any
# command in a pipe fails
set -euo pipefail;

# Note whether the script is sourced and get the script's path
if [[ "$PATHNAME" != "$0" ]]; then
    SCRIPT_PATH="${BASH_SOURCE[0]}";
    SCRIPT_SOURCED="yes";
else
    SCRIPT_PATH="$0";
    SCRIPT_SOURCED="no";
fi

SCRIPT_NAME=$(basename "${SCRIPT_PATH}");
SCRIPT_DIRECTORY=$(dirname "${SCRIPT_PATH}");

# Join strings using a specified separator
#
# NB: only the first character of the separator will be used
#
# Usage:
#     string_join SEPARATOR STRING STRING ...
function string_join() {
    local IFS="${1:-}";
    shift;
    echo "$*";
    return 0;
}

# Default parameter values
declare -A parameters;

# Script metadata
VERSION="0.1.0";
AUTHOR="Fong Chun Chan <fongchunchan@gmail.com>";
USAGE="
Usage:

    ${SCRIPT_NAME} [OPTIONS]

Description:

    This script uses NCBI datasets to get the assembly length and number of 
    protein coding genes for a list of taxons.

Options:

    --taxons human \"mus musculus\" \"Drosophila melanogaster\"
        A list of taxons to get the assembly length and number of protein 
        coding genes for. Taxons with a space in their name should be enclosed
        with double quotes.

    -v --version
        Print script name and version.

    -u -h --usage --help
        Print this usage/help information.

";

# The main function of the script
main() {
    # Parse the command line arguments. If it has a non-zero exit status, the
    # main function should return immediately. If $noerror is not "yes", main()
    # should return the same exit status, otherwise it is a clean exit 0;
    noerror="";
    parseargs "$@";
    parseargs_status=$?;
    if [[ "${parseargs_status}" -gt 0 ]]; then
        [[ "${noerror}" == "yes" ]] && return 0;
        return "${parseargs_status}";
    fi

    if ! command -v datasets &> /dev/null;  then
        echo "datasets command could not be found"
        exit
    fi

    if ! command -v jq &> /dev/null;  then
        echo "jq command could not be found"
        exit
    fi


    echo -e "taxon\tassembly_length\tnum_protein_coding_genes"

    for taxon in "${taxons[@]}"; do
      # Grab the length of the reference assembly for a taxon
      assembly_length=$(
        datasets summary genome taxon "${taxon}" --reference \
          | jq '.reports[0].assembly_stats.total_sequence_length'
      )
      # Strip the quotes from the assembly length
      assembly_length="${assembly_length%\"}"
      assembly_length="${assembly_length#\"}"

      # Grab the number of protein coding genes for a taxon
      num_protein_coding_genes=$(
          datasets summary gene taxon "${taxon}" \
              | jq '[.reports[] | select(.gene.type == "PROTEIN_CODING")]' \
              | jq 'length'
      )

      echo -e "${taxon}\t${assembly_length}\t${num_protein_coding_genes}"
    done

    return 0;
}

# Print usage information
usage() {
    local error="${1:-}";
    version;

    if [[ ! -z "${error}" ]]; then
        >&2 echo "";
        >&2 echo "    Error: ${error}";
    fi

    >&2 echo "${USAGE}";
}

# Print the script version
version() {
    >&2 echo "${SCRIPT_NAME} version ${VERSION}";
    >&2 echo "${AUTHOR}";
}

# Parse the command line arguments
parseargs() {
    local args=("$@");
    local nargs="${#args[@]}";
    local idx=0;
    while (( idx < nargs )); do
        local this_arg="${args[$idx]}";
        local next_arg="${args[((idx + 1))]:-}";
        
        case "${this_arg}" in
            --taxons-file)
                (( idx ++ ));
                parameters[taxon_file]="${next_arg}";
                ;;

            --taxons)
                (( idx ++ ));
                taxons+=("${next_arg}")
            
                # Iterate over the arguments after --patient-id until the next
                # `--` argument. This would indicate that we have hit the end
                # of the patient identifers. 
                #
                # Note we cannot add patient_ids to the parameters array
                while : ; do
                    # In the case --patient-id was the last argument, we need
                    # to stop once the argument index is equal to the
                    # number of arguments
                    #
                    # Since the argument index is 0-based, we add 1 to it to 
                    # allow for matching to the number of args.
                    if (( ($idx + 1) == ${#args[@]} )); then
                        break
                    fi
            
                    # If the next argument is just another patient identifer,
                    # then we add it to the patient_ids array. Else, we break
                    # out of the while loop
                    next_arg="${args[(( $idx + 1 ))]}";
                    if [[ ${next_arg} != --* ]]; then
                        taxons+=("${next_arg}")
                        (( idx ++ ));
                    else
                        break
                    fi
                done
                ;;

            -v | --version)
                version;
                noerror="yes";
                return 1;
                ;;
                
            -u | -h | --usage | --help)
                usage;
                noerror="yes";
                return 1;
                ;;
                
            --)
                (( idx ++ ));
                break;
                ;;
                
            -*)
                usage "Unrecognised option: ${this_arg}";
                return 1;
                ;;
                
            *)
                break;
                ;;
            
        esac
        
        (( idx ++ ));
    done

    if (( idx < nargs )); then
        unhandled_args=("${args[@]:$idx}")
        usage "Unhandled arguments: ${unhandled_args[@]}";
        return 1;
    fi

    if [[ -f "${parameters[output_file]:-}" ]]; then
        >&2 echo "Output file already exists";
        return 1;
    fi
    
    return 0;
}

# Execute the script, capturing the return value in a way that will work even if
# the script is sourced
exitstatus=0;
main "$@" || exitstatus=$?;

if [[ "${SCRIPT_SOURCED}" == "no" ]]; then
    exit "${exitstatus}";
else
    set +e;
    return "${exitstatus}";
fi
