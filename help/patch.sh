#!/usr/bin/bash

apply_patches() {
	local patch_dir="${1:-patches}"
	local dry_run="${2:-false}"
	local verbose="${3:-false}"
	local force="${4:-false}"
	local git_repo="${5:-}"
	local failed_patches_file="${6:-}"
	local delete_failed="${7:-false}"
	local caller_dir="${PWD}"
	local original_dir="${PWD}"

	# Array to track failed patches
	local failed_patches=()

	# Handle git repository directory
	local is_git_repo="false"
	if [[ -n $git_repo ]]; then
		# If git_repo is not an absolute path, make it relative to caller's directory
		if [[ ! $git_repo =~ ^/ ]]; then
			git_repo="${caller_dir}/${git_repo}"
		fi

		if [[ ! -d $git_repo ]]; then
			printf '\n%s\n' "Target directory '$git_repo' not found"
			return 1
		fi

		if [[ -d $git_repo/.git ]]; then
			is_git_repo="true"
			printf '\n%s\n' "Changing to git repository: $git_repo"
		else
			is_git_repo="false"
			printf '\n%s\n' "Changing to directory (not a git repo): $git_repo"
		fi

		cd "$git_repo" || {
			printf '\n%s\n' "Failed to change to target directory"
			return 1
		}
	else
		git_repo="${PWD}"
		if [[ -d .git ]]; then
			is_git_repo="true"
		else
			is_git_repo="false"
		fi
	fi # If patch_dir is not an absolute path, make it relative to caller's directory
	if [[ ! $patch_dir =~ ^/ ]]; then
		patch_dir="${caller_dir}/${patch_dir}"
	fi

	if [[ ! -d $patch_dir ]]; then
		printf '\n%s\n' "Patch directory '$patch_dir' not found"
		cd "$original_dir" || printf '\n%s\n' "Warning: Failed to return to original directory"
		return 1
	fi

	if [[ $is_git_repo == "true" ]]; then
		printf '\n%s\n' "Applying patches from '$patch_dir' to git repository '$git_repo'..."
	else
		printf '\n%s\n' "Applying patches from '$patch_dir' to directory '$git_repo' (using patch command)..."
	fi

	for patch_file in "$patch_dir"/*.{patch,diff}; do
		[[ -f $patch_file ]] || continue

		printf '\n%s\n' "Processing: $(basename "$patch_file")"

		if [[ $dry_run == "true" ]]; then
			if [[ $is_git_repo == "true" ]]; then
				if [[ $verbose == "true" ]]; then
					if git apply --check --verbose "$patch_file" 2> /dev/null; then
						printf '\n%s\n' "  ✓ OK"
					else
						printf '\n%s\n' "  ✗ Failed"
						failed_patches+=("$(basename "$patch_file")")
						error_message=$(git apply --check "$patch_file" 2>&1)
						printf '\n%s\n\n' "    Reason:"
						printf '%s\n' "$error_message" | sed 's/^/      /'
					fi
				else
					if git apply --check "$patch_file" 2> /dev/null; then
						printf '\n%s\n' "  ✓ OK"
					else
						printf '\n%s\n' "  ✗ Failed"
						failed_patches+=("$(basename "$patch_file")")
						error_message=$(git apply --check "$patch_file" 2>&1 | head -1)
						printf '\n%s\n\n' "    Reason:"
						printf '%s\n' "$error_message" | sed 's/^/      /'
					fi
				fi
			else
				# Use patch command for non-git directories
				if [[ $verbose == "true" ]]; then
					if patch --dry-run -p1 -i "$patch_file" > /dev/null 2>&1; then
						printf '\n%s\n' "  ✓ OK"
					else
						printf '\n%s\n' "  ✗ Failed"
						failed_patches+=("$(basename "$patch_file")")
						error_message=$(patch --dry-run -p1 -i "$patch_file" 2>&1)
						printf '\n%s\n\n' "    Reason:"
						printf '%s\n' "$error_message" | sed 's/^/      /'
					fi
				else
					if patch --dry-run -p1 -i "$patch_file" > /dev/null 2>&1; then
						printf '\n%s\n' "  ✓ OK"
					else
						printf '\n%s\n' "  ✗ Failed"
						failed_patches+=("$(basename "$patch_file")")
						error_message=$(patch --dry-run -p1 -i "$patch_file" 2>&1 | head -1)
						printf '\n%s\n\n' "    Reason:"
						printf '%s\n' "$error_message" | sed 's/^/      /'
					fi
				fi
			fi
		else
			local applied="false"
			local error_message=""

			if [[ $is_git_repo == "true" ]]; then
				# Git repository - use git apply
				if git apply "$patch_file" 2> /dev/null; then
					printf '\n%s\n' "  ✓ Applied"
					applied="true"
				elif git apply --3way "$patch_file" 2> /dev/null; then
					printf '\n%s\n' "  ✓ Applied with 3-way merge"
					applied="true"
				elif [[ $force == "true" ]] && git apply --ignore-whitespace "$patch_file" 2> /dev/null; then
					printf '\n%s\n' "  ✓ Applied (ignored whitespace)"
					applied="true"
				elif [[ $force == "true" ]] && git apply --reject "$patch_file" 2> /dev/null; then
					printf '\n%s\n' "  ⚠ Applied with reject files (check .rej files for conflicts)"
					applied="true"
				else
					# Capture the error message
					error_message=$(git apply "$patch_file" 2>&1)
				fi
			else
				# Non-git directory - use patch command
				if patch -p1 -i "$patch_file" > /dev/null 2>&1; then
					printf '\n%s\n' "  ✓ Applied"
					applied="true"
				elif [[ $force == "true" ]] && patch --ignore-whitespace -p1 -i "$patch_file" > /dev/null 2>&1; then
					printf '\n%s\n' "  ✓ Applied (ignored whitespace)"
					applied="true"
				elif [[ $force == "true" ]] && patch --reject-file=- -p1 -i "$patch_file" > /dev/null 2>&1; then
					printf '\n%s\n' "  ⚠ Applied with reject files (check .rej files for conflicts)"
					applied="true"
				else
					# Capture the error message
					error_message=$(patch -p1 -i "$patch_file" 2>&1)
				fi
			fi

			if [[ $applied == "false" ]]; then
				printf '\n%s\n' "  ✗ Failed to apply"
				printf '\n%s\n\n' "    Reason:"
				printf '%s\n' "$error_message" | sed 's/^/      /'
				if [[ $verbose == "true" ]]; then
					printf '\n%s\n\n' "    Detailed error:"
					if [[ $is_git_repo == "true" ]]; then
						git apply --check --verbose "$patch_file" 2>&1 | sed 's/^/      /'
					else
						patch --dry-run -p1 -i "$patch_file" 2>&1 | sed 's/^/      /'
					fi
					printf '\n%s\n' "    To fix this patch, try one of these approaches:"
					if [[ $is_git_repo == "true" ]]; then
						printf '\n%s\n' "    1. Manual 3-way merge:   git apply --3way --verbose '$patch_file'"
						printf '\n%s\n' "    2. Ignore whitespace:    git apply --ignore-whitespace '$patch_file'"
						printf '\n%s\n' "    3. Check what failed:    git apply --check --verbose '$patch_file'"
						printf '\n%s\n' "    4. Apply with reject:    git apply --reject '$patch_file'"
					else
						printf '\n%s\n' "    1. Ignore whitespace:    patch --ignore-whitespace -p1 -i '$patch_file'"
						printf '\n%s\n' "    2. Check what failed:    patch --dry-run -p1 -i '$patch_file'"
						printf '\n%s\n' "    3. Apply with reject:    patch --reject-file=- -p1 -i '$patch_file'"
						printf '\n%s\n' "    4. Try different strip:  patch -p0 -i '$patch_file'"
					fi
					printf '\n%s\n' "    5. View patch content:   cat '$patch_file'"
					printf '\n%s\n\n' "    6. Apply manually:       patch -p1 < '$patch_file'"
				fi
			fi
		fi
	done

	# Save failed patches to file if requested and in dry run mode
	if [[ $dry_run == "true" && -n $failed_patches_file && ${#failed_patches[@]} -gt 0 ]]; then
		# If failed_patches_file is not an absolute path, make it relative to caller's directory
		local output_file="$failed_patches_file"
		if [[ ! $output_file =~ ^/ ]]; then
			output_file="${caller_dir}/${failed_patches_file}"
		fi

		printf '\n%s\n' "Saving ${#failed_patches[@]} failed patch file names to: $output_file"
		printf '%s\n' "${failed_patches[@]}" > "$output_file"
		if [[ $? -eq 0 ]]; then
			printf '\n%s\n' "Failed patches saved successfully"
		else
			printf '\n%s\n' "Warning: Failed to save failed patches to file"
		fi
	fi

	# Delete failed patches if requested and in dry run mode
	if [[ $dry_run == "true" && $delete_failed == "true" && ${#failed_patches[@]} -gt 0 ]]; then
		printf '\n%s\n' "Deleting ${#failed_patches[@]} failed patch files from: $patch_dir"
		local deleted_count=0
		local failed_count=0

		for patch_name in "${failed_patches[@]}"; do
			local patch_path="$patch_dir/$patch_name"
			if [[ -f $patch_path ]]; then
				if rm "$patch_path" 2> /dev/null; then
					printf '\n%s\n' "  ✓ Deleted: $patch_name"
					((deleted_count++))
				else
					printf '\n%s\n' "  ✗ Failed to delete: $patch_name"
					((failed_count++))
				fi
			else
				printf '\n%s\n' "  ⚠ Not found: $patch_name"
				((failed_count++))
			fi
		done

		if [[ $deleted_count -gt 0 ]]; then
			printf '\n%s\n' "Successfully deleted $deleted_count failed patch file(s)"
		fi
		if [[ $failed_count -gt 0 ]]; then
			printf '\n%s\n' "Warning: Failed to delete $failed_count patch file(s)"
		fi
	fi # Return to original directory
	cd "$original_dir" || printf '\n%s\n' "Warning: Failed to return to original directory"
}

# Main execution when script is called directly
if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
	dry_run="false"
	verbose="false"
	force="false"
	patch_dir=""
	git_repo=""
	failed_patches_file=""
	delete_failed_patches="false"

	# Parse command line arguments
	while [[ $# -gt 0 ]]; do
		case $1 in
			-d | --dry-run)
				dry_run="true"
				shift
				;;
			-v | --verbose)
				verbose="true"
				shift
				;;
			-f | --force)
				force="true"
				shift
				;;
			-r | --repo)
				if [[ -n $2 && ! $2 =~ ^- ]]; then
					git_repo="$2"
					shift 2
				else
					printf '\n%s\n' "Error: --repo requires a directory argument" >&2
					exit 1
				fi
				;;
			-s | --save-failed)
				if [[ -n $2 && ! $2 =~ ^- ]]; then
					failed_patches_file="$2"
					shift 2
				else
					printf '\n%s\n' "Error: --save-failed requires a file path argument" >&2
					exit 1
				fi
				;;
			-x | --delete-failed)
				delete_failed_patches="true"
				shift
				;;
			-h | --help)
				printf '\n%s\n' "Usage: $0 [OPTIONS] [patch_directory]"
				printf '\n%s\n' "Options:"
				printf '\n%s\n' "  -d, --dry-run       Only check patches without applying them"
				printf '\n%s\n' "  -v, --verbose       Show detailed output for debugging"
				printf '\n%s\n' "  -f, --force         Try harder to apply patches (ignore whitespace, use reject files)"
				printf '\n%s\n' "  -r, --repo DIR      Target directory to apply patches to (git repo or regular directory)"
				printf '\n%s\n' "  -s, --save-failed FILE   Save failed patch file names to specified file (dry run only)"
				printf '\n%s\n' "  -x, --delete-failed      Delete failed patch files from patch directory (dry run only)"
				printf '\n%s\n' "  -h, --help          Show this help message"
				printf '\n%s\n' "Arguments:"
				printf '\n%s\n' "  patch_directory     Directory containing .patch or .diff files (default: 'patches')"
				printf '\n%s\n' "                      Can be absolute or relative to current working directory"
				printf '\n%s\n' "The script automatically detects if the target is a git repository:"
				printf '\n%s\n' "  - Git repositories: Uses 'git apply' with 3-way merge support"
				printf '\n%s\n' "  - Regular directories: Uses 'patch' command"
				printf '\n%s\n' "Examples:"
				printf '\n%s\n' "  $0                           # Apply patches from './patches' to current directory"
				printf '\n%s\n' "  $0 my-patches                # Apply patches from './my-patches' to current directory"
				printf '\n%s\n' "  $0 -r /path/to/repo          # Apply patches from './patches' to specified directory"
				printf '\n%s\n' "  $0 -r my-repo my-patches     # Apply patches from './my-patches' to './my-repo'"
				printf '\n%s\n' "  $0 --repo ../other-project   # Apply patches from './patches' to '../other-project'"
				printf '\n%s\n' "  $0 /abs/patches -r /abs/dir  # Use absolute paths for both"
				printf '\n%s\n' "  $0 -d                        # Dry run - only check patches"
				printf '\n%s\n' "  $0 -v -f                     # Verbose output with force mode"
				printf '\n%s\n' "  $0 -d -s failed.txt          # Dry run and save failed patches to 'failed.txt'"
				printf '\n%s\n' "  $0 -d -s /tmp/fails.list     # Dry run and save failed patches with absolute path"
				printf '\n%s\n' "  $0 -d -x                     # Dry run and delete failed patches from patch directory"
				printf '\n%s\n' "  $0 -d -x -v                  # Dry run, delete failed patches, and show verbose output"
				printf '\n%s\n' "Fixing Failed Patches:"
				printf '\n%s\n' "  When patches fail, the script suggests recovery methods based on target type:"
				printf '\n%s\n' "  Git repositories:"
				printf '\n%s\n' "    1. 3-way merge: Attempts to merge conflicts automatically"
				printf '\n%s\n' "    2. Ignore whitespace: Handles whitespace-only differences"
				printf '\n%s\n' "    3. Reject files: Creates .rej files for manual resolution"
				printf '\n%s\n' "  Regular directories:"
				printf '\n%s\n' "    1. Ignore whitespace: Handles whitespace-only differences"
				printf '\n%s\n' "    2. Different strip levels: Try -p0 instead of -p1"
				printf '\n%s\n' "    3. Reject files: Creates .rej files for manual resolution"
				printf '\n'
				exit 0
				;;
			-*)
				printf '\n%s\n' "Unknown option: $1" >&2
				printf '\n%s\n' "Use -h or --help for usage information" >&2
				exit 1
				;;
			*)
				if [[ -z $patch_dir ]]; then
					patch_dir="$1"
				else
					printf '\n%s\n' "Error: Multiple patch directories specified" >&2
					exit 1
				fi
				shift
				;;
		esac
	done

	# Set default patch directory if not specified
	if [[ -z $patch_dir ]]; then
		patch_dir="patches"
	fi

	apply_patches "$patch_dir" "$dry_run" "$verbose" "$force" "$git_repo" "$failed_patches_file" "$delete_failed_patches"
fi

printf '\n'
