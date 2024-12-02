# GitHub Organization Code Search Tool

A bash script that performs advanced code search across all repositories in a GitHub organization. The script clones repositories locally and searches for specific strings, producing detailed JSON reports of the findings.

## Features

- Search across all repositories in a GitHub organization
- Local repository caching to avoid repeated cloning
- Multiple search terms support
- Detailed JSON output with file locations and context
- Result summaries with match statistics
- Support for incremental searches
- Proper error handling and progress feedback

## Requirements

- Bash (version 4.0 or higher)
- Git
- GitHub CLI (`gh`)
- `jq` (command-line JSON processor)
- `grep`
- `awk`

## Installation

1. Clone this repository:
```bash
git clone https://github.com/yourusername/github-org-search.git
cd github-org-search
```

2. Make the script executable:
```bash
chmod +x search.sh
```

3. Install dependencies:

For Debian/Ubuntu:
```bash
sudo apt-get update
sudo apt-get install git gh jq
```

For macOS:
```bash
brew install gh jq
```

4. Authenticate with GitHub:
```bash
gh auth login
```

## Usage

### Basic Usage

```bash
./search.sh <organization-name> <strings-file> [output-file]
```

Example:
```bash
./search.sh microsoft strings.txt results.json
```

### Parameters

- `organization-name`: The GitHub organization to search
- `strings-file`: A text file containing search terms (one per line)
- `output-file`: (Optional) The JSON file to store results (default: results.json)

### Search Terms File Format

Create a file (e.g., `strings.txt`) with search terms, one per line:
```
searchterm1
searchterm2
searchterm3
```

## Output Format

### Main Results (results.json)
```json
[
  {
    "repo": "org/repository-name",
    "file": "path/to/file",
    "line": 42,
    "position": 10,
    "pattern": "searchedString",
    "content": "The line content containing the match"
  }
]
```

### Summary (results_summary.json)
```json
[
  {
    "repository": "org/repository-name",
    "total_matches": 5,
    "unique_files": 3,
    "matches": [
      {
        "file": "path/to/file",
        "match_count": 2,
        "matches": [
          {
            "line": 42,
            "position": 10,
            "pattern": "searchedString",
            "content": "matching line content"
          }
        ]
      }
    ]
  }
]
```

## File Structure

```
.
├── search.sh           # Main script
├── repos/             # Directory for cloned repositories
├── repos.txt          # Cache of repository list
├── results.json       # Main results file
└── results_summary.json # Summary of results
```

## Script Components

### Main Functions

1. `check_commands()`: Verifies required commands are installed
2. `check_github_auth()`: Ensures GitHub CLI is authenticated
3. `fetch_repos()`: Retrieves repository list from organization
4. `process_matches()`: Processes and formats individual matches
5. `process_repo()`: Handles repository cloning and searching
6. `generate_summary()`: Creates statistical summary of results

### Process Flow

1. Validates requirements and authentication
2. Fetches organization repository list
3. For each repository:
   - Clones if not cached
   - Searches for each term
   - Processes and records matches
4. Generates JSON output files
5. Creates statistical summary

## Caching

The script implements two levels of caching:
1. Repository list caching (`repos.txt`)
2. Local repository caching (in `repos/` directory)

This reduces API calls and improves subsequent search performance.

## Error Handling

The script includes comprehensive error handling for:
- Missing dependencies
- Authentication failures
- Repository access issues
- Invalid search terms
- JSON formatting errors

## Limitations

- Requires GitHub CLI authentication
- Searches in text files only
- Local storage needed for repository clones
- Rate limiting based on GitHub API limits

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.