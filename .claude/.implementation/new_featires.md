Excellent idea. Separating the responsibilities into two distinct commands (`polish` and `docs`) makes the system much cleaner, more modular, and more aligned with the Single Responsibility Principle.

This new design improves the workflow:
*   `./devdb.sh polish`: Focuses purely on **code formatting and standardization**. It's fast and can be run frequently.
*   `./devdb.sh docs`: Focuses on the more intensive (and potentially more expensive) task of **analysis and documentation generation**. This might be run less frequently, perhaps only before creating a pull request.

Let's redesign the system based on this superior architecture.

---

### **New System Design: `polish` and `docs` Commands**

#### **1. The `polish` Command Workflow**

*   **Goal:** Format SQL code and ensure headers are present and correct.
*   **User Action:**
    ```bash
    # Polish all .sql files in the ./schemas directory
    ./devdb.sh polish
    ```
    or
    ```bash
    # Polish a single file
    ./devdb.sh polish schemas/sprocs/my_sproc.sql
    ```
*   **Process:**
    1.  The script finds the target SQL file(s).
    2.  For each file, it performs a **two-step process**:
        a. **SQL Formatting:** It first runs a deterministic, local SQL formatter to standardize indentation, keywords, casing, etc. This reduces the "noise" for the LLM. We can use a popular Python library like `sql-formatter`.
        b. **Header Remediation:** It then sends the *formatted* SQL to the Gemini API with the "header-fix" prompt.
    3.  The file is overwritten in place.
    4.  The output is a summary of files processed.

#### **2. The `docs` Command Workflow**

*   **Goal:** Analyze the final, polished SQL code and generate documentation.
*   **User Action:**
    ```bash
    # Generate documentation for all .sql files and create a single manual
    ./devdb.sh docs
    ```
    or
    ```bash
    # Generate documentation for a single file
    ./devdb.sh docs schemas/sprocs/my_sproc.sql
    ```
*   **Process:**
    1.  The script finds the target SQL file(s).
    2.  For each file, it sends the content to the Gemini API with the "documentation-generation" prompt.
    3.  If running in batch mode, it concatenates the results into `docs/Database_Manual.md`. If in single-file mode, it creates `docs/sprocs/my_sproc.md`.
    4.  The output confirms which documents were created/updated.

---

### **Implementation Plan**

This requires significant changes to our scripts. We'll split `intelligent_polish.py` into two separate, focused scripts.

#### **Step 1: Update Project Setup**

We need to add a new Python dependency for SQL formatting.

**Update `README.md` (Setup section):**
```markdown
**One-Time Setup:**

1.  **Install Python 3:** ...
2.  **Install Python Libraries:**
    ```bash
    pip install google-generativeai sql-formatter
    ```
3.  **Set Your Gemini API Key:** ...
```

#### **Step 2: Create `code_polisher.py`**

This script will handle only formatting and header standardization.

**File: `.devdb/scripts/code_polisher.py`**
```python
import os
import sys
import argparse
from datetime import datetime
import google.generativeai as genai
from sql_formatter.core import format_sql
from concurrent.futures import ThreadPoolExecutor, as_completed

# --- Configuration & Setup ---
SCHEMA_DIR = os.path.join(os.getcwd(), "schemas")
MODEL_NAME = "gemini-1.5-pro-latest"

# Helper functions (print_color, Gemini setup, call_gemini) are the same
# ...

# --- Prompt Definition for Header ---
def get_header_prompt(sql_content, author):
    # ... (same header prompt as before) ...
    return user_prompt, system_instruction

# --- Worker Function for Polishing ---
def polish_sql_file(sql_file_path):
    author_name = os.getenv("GIT_USER_NAME", "Unknown Author")
    
    with open(sql_file_path, 'r') as f:
        original_sql = f.read()

    # Step 1: Apply deterministic SQL formatting first
    try:
        formatted_sql = format_sql(original_sql, uppercase=True)
    except Exception:
        # If formatter fails, use original SQL. LLM is robust enough.
        formatted_sql = original_sql
    
    # Step 2: Send formatted SQL to LLM for header remediation
    header_user_prompt, header_system_prompt = get_header_prompts(formatted_sql, author_name)
    final_sql = call_gemini(header_user_prompt, header_system_prompt)
    
    if "GEMINI_API_ERROR" in final_sql:
        return (sql_file_path, f"Header Error: {final_sql}")

    with open(sql_file_path, 'w') as f:
        f.write(final_sql)

    return (sql_file_path, "Success")

# --- Main Logic for Polishing ---
def main():
    parser = argparse.ArgumentParser(description="Format SQL files and standardize headers.")
    # ... (argparse setup for file/--all remains the same) ...
    # This script will now only call polish_sql_file in its main loop.
    # ...
    # Example for batch mode:
    # with ThreadPoolExecutor(...) as executor:
    #     future_to_file = {executor.submit(polish_sql_file, path): path for path in sql_files}
    #     for future in as_completed(future_to_file):
    #         _, status = future.result()
    #         # ... (print status) ...

if __name__ == "__main__":
    main()
```

#### **Step 3: Create `doc_generator.py`**

This script is dedicated to generating documentation from existing SQL files.

**File: `.devdb/scripts/doc_generator.py`**
```python
import os
import sys
import argparse
from datetime import datetime
import google.generativeai as genai
from concurrent.futures import ThreadPoolExecutor, as_completed

# --- Configuration & Setup ---
# ... (same setup as the polisher script) ...
DOCS_DIR = os.path.join(os.getcwd(), "docs")
FINAL_DOC_FILE = os.path.join(DOCS_DIR, "Database_Manual.md")

# Helper functions (print_color, Gemini setup, call_gemini) are the same
# ...

# --- Prompt Definition for Docs ---
def get_docs_prompt(sql_content):
    # ... (same docs prompt as before) ...
    return user_prompt, system_instruction

# --- Worker Function for Generating Docs ---
def generate_doc_for_file(sql_file_path):
    with open(sql_file_path, 'r') as f:
        sql_content = f.read()

    docs_user_prompt, docs_system_prompt = get_docs_prompts(sql_content)
    markdown_docs = call_gemini(docs_user_prompt, docs_system_prompt)

    if "GEMINI_API_ERROR" in markdown_docs:
        return (sql_file_path, f"Docs Error: {markdown_docs}", "")

    # Add separator for the final consolidated manual
    markdown_docs += "\n\n---\n\n"
    
    return (sql_file_path, "Success", markdown_docs)

# --- Main Logic for Documentation ---
def main():
    parser = argparse.ArgumentParser(description="Generate documentation for SQL files.")
    # ... (argparse setup for file/--all remains the same) ...
    # This script will now call generate_doc_for_file in its main loop and
    # handle the logic for consolidating the docs into a single file if --all is used.
    # ...

if __name__ == "__main__":
    main()
```

#### **Step 4: Update `devdb.sh` to handle both commands**

The main script will now have two distinct command sections, each calling its respective Python script.

**File: `devdb.sh` (new `case` statement)**
```bash
# ... (inside the main case statement) ...

  polish)
    cmd_polish "$2"
    ;;
  docs)
    cmd_docs "$2"
    ;;

# ... (add these new functions) ...

check_api_key() {
  if [ -z "$GEMINI_API_KEY" ]; then
    warn "GEMINI_API_KEY environment variable is not set."
    warn "Please get a key from Google AI Studio and export it:"
    warn "export GEMINI_API_KEY='your-key-here'"
    error "Command aborted."
  fi
}

cmd_polish() {
  check_api_key
  local git_user=$(git config user.name)
  
  info "Invoking the Code Polisher..."
  if [ -z "$1" ]; then
    GEMINI_API_KEY=$GEMINI_API_KEY GIT_USER_NAME="$git_user" python3 ./.devdb/scripts/code_polisher.py --all
  else
    GEMINI_API_KEY=$GEMINI_API_KEY GIT_USER_NAME="$git_user" python3 ./.devdb/scripts/code_polisher.py "$1"
  fi
  success "Polish command complete."
}

cmd_docs() {
  check_api_key
  
  info "Invoking the Documentation Generator..."
  if [ -z "$1" ]; then
    GEMINI_API_KEY=$GEMINI_API_KEY python3 ./.devdb/scripts/doc_generator.py --all
  else
    GEMINI_API_KEY=$GEMINI_API_KEY python3 ./.devdb/scripts/doc_generator.py "$1"
  fi
  success "Docs command complete."
}
```

This new design is significantly more robust, maintainable, and user-friendly. It provides clear separation of concerns, allowing developers to choose the right tool for the job at the right time.