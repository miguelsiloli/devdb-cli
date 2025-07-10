/***************************************************************************************************
Procedure:          dbo.usp_DoSomeStuff
Create Date:        2018-01-25
Author:             Joe Expert
Description:        Verbose description of what the query does goes here. Be specific and don't be
                    afraid to say too much. More is better, than less, every single time. Think about
                    "what, when, where, how and why" when authoring a description.
Call by:            [schema.usp_ProcThatCallsThis]
                    [Application Name]
                    [Job]
                    [PLC/Interface]
Affected table(s):  [schema.TableModifiedByProc1]
                    [schema.TableModifiedByProc2]
Used By:            Functional Area this is use in, for example, Payroll, Accounting, Finance
Parameter(s):       @param1 - description and usage
                    @param2 - description and usage
Usage:              EXEC dbo.usp_DoSomeStuff
                        @param1 = 1,
                        @param2 = 3,
                        @param3 = 2
                    Additional notes or caveats about this object, like where is can and cannot be run, or
                    gotchas to watch for when using it.
****************************************************************************************************
SUMMARY OF CHANGES
Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------- ------------------------------------------------------------
2012-04-27          John Usdaworkhur    Move Z <-> X was done in a single step. Warehouse does not
                                        allow this. Converted to two step process.
                                        Z <-> 7 <-> X
                                            1) move class Z to class 7
                                            2) move class 7 to class X

2018-03-22          Maan Widaplan       General formatting and added header information.
2018-03-22          Maan Widaplan       Added logic to automatically Move G <-> H after 12 months.
***************************************************************************************************/

Excellent point. Preserving the `SUMMARY OF CHANGES` is a critical requirement for a production-ready tool. Losing the change history would be a deal-breaker.

Let's refine the design to intelligently handle existing headers and their change logs. This makes the `polish` command truly idempotent and non-destructive.

---

### **Refined Design: Change History-Aware Polishing**

The workflow will now have a more sophisticated "analysis" step before rendering the template.

**New, Refined Workflow:**

1.  **Developer runs:** `./devdb.sh polish schemas/sprocs/usp_DoSomeStuff.sql`
2.  **`code_polisher.py` script executes:**
    a. **Read File:** The script reads the entire content of `usp_DoSomeStuff.sql`.
    b. **Initial Analysis (Local):** The script will first use Regular Expressions (regex) to perform two crucial local checks, *before* any API calls:
        *   **Detect Existing Header:** Does a `/* ... */` block exist at the top?
        *   **Extract Change History:** If a header exists, extract the entire `SUMMARY OF CHANGES` block. This is a deterministic, fast, and free operation.
    c. **First LLM Call (Metadata Extraction):**
        *   This step proceeds as before, sending the *full original SQL content* to Gemini to get the JSON metadata (`procedure_name`, `description`, `parameters`, etc.).
    d. **Prepare Jinja2 Context:**
        *   The script now assembles a rich context object including:
            *   System variables (`author`, `date`).
            *   LLM-inferred metadata (`description`, `affected_tables`).
            *   **The extracted `change_history` block from the local regex analysis.**
            *   A new `is_update` flag set to `True` if an existing header was found.
    e. **Render Jinja2 Template:**
        *   The Jinja2 template will now have logic to handle this context. It can add a *new* change history line if `is_update` is true.
    f. **Second LLM Call (Final Polish):**
        *   The fully rendered prompt (containing the old change history and a new line item) is sent to Gemini for the final polish.
        *   The LLM's job is to intelligently merge everything into the new, clean header format.
    g. **File Update:** The original SQL file is overwritten with the final, polished result.

---

### **Implementation Plan**

#### **Step 1: Update the Jinja2 Template**

The template needs to be smarter. It will now receive the *full, raw change history block* and a new line to add if it's an update.

**File: `.devdb/templates/header_template.jinja2` (New Version)**
```jinja2
/*
****************************************************************************************************
Procedure:          {{ procedure_name }}
Create Date:        {{ create_date }}
Author:             {{ author }}
Description:        {{ description }}
Call by:            [Application Name]
Affected table(s):  {% for table in affected_tables %}[{{ table }}]{% if not loop.last %}\n                    {% endif %}{% endfor %}
Used By:            [Functional Area]
Parameter(s):       {% if parameters %}{% for param in parameters %}{{ param.name }} - {{ param.description }}{% if not loop.last %}\n                    {% endif %}{% endfor %}{% else %}[N/A]{% endif %}
Usage:              EXEC {{ procedure_name }}
                        ...

                    Additional notes or caveats...
****************************************************************************************************
SUMMARY OF CHANGES
Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------- ------------------------------------------------------------
{% if existing_change_history %}{{ existing_change_history | trim }}{% endif %}
{% if is_update %}{{ new_change_entry }}{% endif %}
***************************************************************************************************/

{# This is a comment: The SQL code itself will be appended after the header by the final prompt #}
```
*   **Key Change:** We now have placeholders for `existing_change_history` (the block we extracted) and a `new_change_entry` that we'll add.

#### **Step 2: Update the `code_polisher.py` Script**

This script gets the biggest upgrade. It will now include regex logic.

**File: `.devdb/scripts/code_polisher.py` (New Version)**
```python
import os
import sys
import json
import re # Import the regular expression module
import argparse
from datetime import datetime
import google.generativeai as genai
from jinja2 import Environment, FileSystemLoader
# ... other imports ...

# ... (Configuration and Gemini setup remain the same) ...

# ... (LLM prompt functions remain the same) ...

def extract_header_and_history(sql_content):
    """
    Uses regex to find an existing header and extract the change history.
    """
    header_regex = re.compile(r"/\*+([\s\S]*?)\*+/", re.MULTILINE)
    history_regex = re.compile(r"SUMMARY OF CHANGES([\s\S]*)", re.IGNORECASE | re.MULTILINE)
    
    header_match = header_regex.match(sql_content)
    if not header_match:
        return None, None # No header found

    header_content = header_match.group(1)
    history_match = history_regex.search(header_content)
    
    if not history_match:
        return header_content, None # Header found, but no change history section

    # Return the full header content and just the lines of the history
    history_lines = history_match.group(1).strip()
    return header_content, history_lines

def strip_header(sql_content):
    """Removes the initial comment block from the SQL script."""
    header_regex = re.compile(r"/\*+[\s\S]*?\*+/", re.MULTILINE)
    return header_regex.sub('', sql_content).lstrip()

# --- Worker Function for Polishing ---
def polish_sql_file(sql_file_path):
    author_name = os.getenv("GIT_USER_NAME", "Unknown Author")
    
    with open(sql_file_path, 'r') as f:
        original_sql = f.read()

    # Step 1: Local analysis with Regex
    existing_header, existing_history = extract_header_and_history(original_sql)
    sql_code_only = strip_header(original_sql)
    
    is_update = existing_header is not None

    # Step 2: LLM call for metadata extraction (as before)
    # ... (code to call LLM for metadata) ...
    try:
        metadata = json.loads(call_gemini(...))
    except (json.JSONDecodeError, TypeError):
        return (sql_file_path, "Failed to parse metadata.")

    # Step 3: Set up Jinja2 and prepare context
    env = Environment(loader=FileSystemLoader(TEMPLATE_DIR), trim_blocks=True, lstrip_blocks=True)
    template = env.get_template('header_template.jinja2')

    # Prepare new change entry if it's an update
    new_change_entry = ""
    if is_update:
        date_str = datetime.utcnow().strftime('%Y-%m-%d')
        author_str = author_name.ljust(19) # Pad for alignment
        comment_str = "Automated polish and formatting."
        new_change_entry = f"{date_str}    {author_str} {comment_str}"

    context = {
        # ... (all previous context variables) ...
        'is_update': is_update,
        'existing_change_history': existing_history,
        'new_change_entry': new_change_entry
    }

    # Step 4: Render the template to create the header structure
    header_template_content = template.render(context)
    
    # Step 5: Final LLM call to get the polished script
    # The final prompt should now include the rendered header and the clean SQL code
    final_prompt = f"""
Please merge the following header template with the SQL code. Refine the descriptions and ensure the final output is a single, valid T-SQL script. Preserve the change history and add the new entry logically.

--- HEADER TEMPLATE ---
{header_template_content}

--- SQL CODE ---
{sql_code_only}
    """
    # ... (send final_prompt to Gemini) ...
    final_sql = call_gemini(final_prompt, "You are an expert SQL DBA...")

    if "GEMINI_API_ERROR" in final_sql:
        return (sql_file_path, f"Final Polish Error: {final_sql}")

    with open(sql_file_path, 'w') as f:
        f.write(final_sql)

    return (sql_file_path, "Success")


# --- Main Logic ---
# The main function remains the same, calling the updated polish_sql_file.
# ...
```

This upgraded system is now significantly more robust and production-ready. It respects the work that has already been done by preserving version history, while still enforcing modern standards and leveraging AI to enrich the content. It's the perfect blend of deterministic local processing (regex for speed and accuracy on known patterns) and intelligent cloud processing (LLM for nuanced understanding and generation).