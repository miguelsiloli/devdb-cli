#!/bin/bash
#
# DevDB - Automated Development Database Deployment System
#

# --- Configuration ---
# Exit script on any error
set -e

# Path to the docker-compose file relative to the script's location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/.devdb/docker-compose.yml"
ENV_FILE="${SCRIPT_DIR}/.devdb/.env"

# --- Style Definitions ---
COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_NC='\033[0m' # No Color

# --- Helper Functions ---
info() {
  echo -e "${COLOR_BLUE}INFO: $1${COLOR_NC}"
}

success() {
  echo -e "${COLOR_GREEN}SUCCESS: $1${COLOR_NC}"
}

warn() {
  echo -e "${COLOR_YELLOW}WARN: $1${COLOR_NC}"
}

error() {
  echo -e "${COLOR_RED}ERROR: $1${COLOR_NC}" >&2
  exit 1
}

# --- Command Functions ---

# Print the help message
usage() {
  echo "DevDB - Automated Development Database Control"
  echo ""
  echo "Usage: ./devdb.sh [COMMAND]"
  echo ""
  echo "Commands:"
  echo "  up           Start and provision the database services."
  echo "  down         Stop and remove the database services."
  echo "  reset        Reset the entire environment (down then up)."
  echo "  schema       Initialize/re-initialize database schemas."
  echo "  test [file]  Run a specific SQL test file from the ./tests directory."
  echo "  test all     Run all .sql tests in the ./tests directory."
  echo "  query \"<SQL>\" Execute an ad-hoc SQL query string."
  echo "  status       Show the status of the running containers."
  echo "  polish [path] Format SQL files and standardize headers. Path can be file or directory."
  echo "  help         Show this help message."
  echo ""
}

# Start the database environment
cmd_up() {
  info "Starting DevDB environment..."
  if ! command -v docker &> /dev/null; then
    error "Docker is not installed or not in your PATH. Please install Docker and try again."
  fi
  if ! docker info &> /dev/null; then
      error "Docker daemon is not running. Please start Docker and try again."
  fi

  docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d

  info "Waiting for SQL Server to be healthy... (this may take a minute on first run)"
  # shellcheck source=.devdb/.env
  source "$ENV_FILE"
  
  # Loop until health check passes or timeout
  for i in {1..40}; do
    HEALTH_STATUS=$(docker inspect --format='{{.State.Health.Status}}' devdb-sqlserver 2>/dev/null || echo "starting")
    
    # If health check passes, we're good
    if [ "$HEALTH_STATUS" == "healthy" ]; then
      success "Database is up and running!"
      echo -e "--------------------------------------------------"
      echo -e "  ${COLOR_YELLOW}SQL Server Connection Details:${COLOR_NC}"
      echo -e "    Host:     localhost"
      echo -e "    Port:     $(grep DB_PORT "$ENV_FILE" | cut -d '=' -f2)"
      echo -e "    User:     sa"
      echo -e "    Password: (from your .env file)"
      echo ""
      echo -e "  ${COLOR_YELLOW}Web GUI:${COLOR_NC}"
      echo -e "    URL:      http://localhost:$(grep GUI_PORT "$ENV_FILE" | cut -d '=' -f2)"
      echo -e "--------------------------------------------------"
      
      # Initialize schemas
      init_schemas
      exit 0
    fi
    
    # If health check is failing but container is running, try direct connection
    if [ "$HEALTH_STATUS" == "unhealthy" ] && [ "$i" -gt 20 ]; then
      info "Health check failing, testing direct connection..."
      if docker exec devdb-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "${SA_PASSWORD}" -Q "SELECT 1" -C -l 5 >/dev/null 2>&1; then
        success "Database is responding to direct connection!"
        echo -e "--------------------------------------------------"
        echo -e "  ${COLOR_YELLOW}SQL Server Connection Details:${COLOR_NC}"
        echo -e "    Host:     localhost"
        echo -e "    Port:     $(grep DB_PORT "$ENV_FILE" | cut -d '=' -f2)"
        echo -e "    User:     sa"
        echo -e "    Password: (from your .env file)"
        echo ""
        echo -e "  ${COLOR_YELLOW}Web GUI:${COLOR_NC}"
        echo -e "    URL:      http://localhost:$(grep GUI_PORT "$ENV_FILE" | cut -d '=' -f2)"
        echo -e "--------------------------------------------------"
        warn "Health check is failing but database is accessible"
        
        # Initialize schemas
        init_schemas
        exit 0
      fi
    fi
    
    printf "."
    sleep 3
  done

  error "Database container failed to become healthy. Check logs with 'docker logs devdb-sqlserver'."
}

# Stop the database environment
cmd_down() {
  info "Stopping and removing DevDB containers..."
  docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" down --remove-orphans
  success "DevDB environment has been shut down."
}

# Run tests
cmd_test() {
  if [ -z "$1" ]; then
    error "No test specified. Usage: ./devdb.sh test [filename | all]"
  fi

  # Load DB connection details from .env
  # shellcheck source=.devdb/.env
  source "$ENV_FILE"

  if [ "$1" == "all" ]; then
    info "Running all tests in ./tests directory..."
    for test_file in ./tests/**/*.sql ./tests/*.sql; do
      if [ -f "$test_file" ]; then
        run_single_test "$test_file"
      fi
    done
    success "All tests completed."
  else
    local test_file="./tests/$1"
    if [ ! -f "$test_file" ]; then
      error "Test file not found: $test_file"
    fi
    run_single_test "$test_file"
  fi
}

run_single_test() {
  local file_to_test=$1
  info "Executing test: $file_to_test"
  if docker exec devdb-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "${SA_PASSWORD}" -d master -i "/host_tests/$(basename "$file_to_test")" -b -C; then
    success "Test PASSED: $file_to_test"
  else
    error "Test FAILED: $file_to_test. Check output above for details."
  fi
}

# Initialize database schemas
init_schemas() {
  info "Initializing database schemas..."
  # shellcheck source=.devdb/.env
  source "$ENV_FILE"
  
  # Execute schema files in order
  for schema_file in ./schemas/*.sql; do
    if [ -f "$schema_file" ]; then
      info "Executing schema: $schema_file"
      if docker exec devdb-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "${SA_PASSWORD}" -d master -i "/docker-entrypoint-initdb.d/$(basename "$schema_file")" -C; then
        success "Schema applied: $schema_file"
      else
        warn "Schema failed: $schema_file"
      fi
    fi
  done
  success "Schema initialization completed"
}

# Run an ad-hoc query
cmd_query() {
  if [ -z "$1" ]; then
    error "No query string provided. Usage: ./devdb.sh query \"SELECT * FROM ...\""
  fi
  # shellcheck source=.devdb/.env
  source "$ENV_FILE"
  info "Executing query..."
  docker exec devdb-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "${SA_PASSWORD}" -d master -Q "$1" -C
}

# Check if Gemini API key is set
check_api_key() {
  # Source .env file to get GEMINI_API_KEY
  # shellcheck source=.devdb/.env
  source "$ENV_FILE"
  
  if [ -z "$GEMINI_API_KEY" ]; then
    warn "GEMINI_API_KEY environment variable is not set."
    warn "Please add your Gemini API key to .devdb/.env file:"
    warn "GEMINI_API_KEY=your-key-here"
    error "Command aborted."
  fi
}

# Polish SQL files - format and standardize headers
cmd_polish() {
  check_api_key
  # shellcheck source=.devdb/.env
  source "$ENV_FILE"
  
  info "Invoking the Code Polisher..."
  env DEFAULT_SOURCE_DIR="$DEFAULT_SOURCE_DIR" \
      POLISH_OUTPUT_DIR="$POLISH_OUTPUT_DIR" \
      AUTHOR_NAME="$AUTHOR_NAME" \
      GEMINI_API_KEY="$GEMINI_API_KEY" \
      python3 ./.devdb/scripts/code_polisher.py "$1"
  success "Polish command complete."
}

# Generate documentation for SQL files (removed for now)
# cmd_docs() {
#   check_api_key
#   # shellcheck source=.devdb/.env
#   source "$ENV_FILE"
#   
#   info "Invoking the Documentation Generator..."
#   env DEFAULT_SOURCE_DIR="$DEFAULT_SOURCE_DIR" \
#       DOCS_OUTPUT_DIR="$DOCS_OUTPUT_DIR" \
#       GEMINI_API_KEY="$GEMINI_API_KEY" \
#       python3 ./.devdb/scripts/doc_generator.py "$1"
#   success "Docs command complete."
# }


# --- Main Execution Logic ---
if [ ! -f "$ENV_FILE" ]; then
  error ".env file not found at ${ENV_FILE}. Please copy .env.example to .env and configure it."
fi

case "$1" in
  up)
    cmd_up
    ;;
  down)
    cmd_down
    ;;
  reset)
    info "Resetting environment..."
    cmd_down
    cmd_up
    ;;
  schema)
    init_schemas
    ;;
  test)
    cmd_test "$2"
    ;;
  query)
    cmd_query "$2"
    ;;
  status)
    docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" ps
    ;;
  polish)
    cmd_polish "$2"
    ;;
  help|--help|-h|*)
    usage
    ;;
esac