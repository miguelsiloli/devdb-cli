#!/usr/bin/env python3
"""
SQL Code Polisher for DevDB
Formats SQL files and standardizes headers using Gemini AI
"""

import os
import sys
import argparse
import glob
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor, as_completed

try:
    from google import genai
    from google.genai import types
except ImportError:
    print("Error: google-generativeai library not installed. Run: pip install google-generativeai")
    sys.exit(1)

try:
    import sqlparse
except ImportError:
    print("Error: sqlparse library not installed. Run: pip install sqlparse")
    sys.exit(1)

# Configuration
MODEL_NAME = "gemini-2.0-flash-exp"
MAX_WORKERS = 3

# Load configuration from environment
def load_config():
    """Load configuration from environment variables"""
    default_source_dir = os.getenv("DEFAULT_SOURCE_DIR", "schemas")
    polish_output_dir = os.getenv("POLISH_OUTPUT_DIR", "output/prod_scripts")
    author_name = os.getenv("AUTHOR_NAME", "Unknown Author")
    
    return {
        "source_dir": os.path.join(os.getcwd(), default_source_dir),
        "output_dir": os.path.join(os.getcwd(), polish_output_dir),
        "author_name": author_name
    }

# Color output helpers
def print_color(text, color_code):
    """Print colored text to terminal"""
    print(f"\033[{color_code}m{text}\033[0m")

def print_success(text):
    print_color(f"✅ {text}", "32")

def print_error(text):
    print_color(f"❌ {text}", "31")

def print_warning(text):
    print_color(f"⚠️  {text}", "33")

def print_info(text):
    print_color(f"ℹ️  {text}", "34")

# Gemini AI setup
def setup_gemini():
    """Initialize Gemini AI client with API key"""
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        print_error("GEMINI_API_KEY environment variable not set")
        print_info("Get your API key from: https://aistudio.google.com/app/apikey")
        sys.exit(1)
    
    return genai.Client(api_key=api_key)

def call_gemini(user_prompt, system_instruction, client):
    """Call Gemini API with error handling"""
    try:
        contents = [
            types.Content(
                role="user",
                parts=[
                    types.Part.from_text(text=user_prompt),
                ],
            ),
        ]
        
        generate_content_config = types.GenerateContentConfig(
            temperature=0.1,
            max_output_tokens=8192,
            response_mime_type="text/plain",
            system_instruction=[
                types.Part.from_text(text=system_instruction),
            ],
        )

        # Collect the full response
        response_text = ""
        for chunk in client.models.generate_content_stream(
            model=MODEL_NAME,
            contents=contents,
            config=generate_content_config,
        ):
            response_text += chunk.text

        return response_text
    except Exception as e:
        return f"GEMINI_API_ERROR: {str(e)}"

def format_sql_content(sql_content):
    """Format SQL using sqlparse library"""
    try:
        # Use sqlparse to format the SQL
        formatted = sqlparse.format(
            sql_content,
            reindent=True,
            keyword_case='upper',
            identifier_case='lower',
            strip_comments=False,
            use_space_around_operators=True,
            indent_width=4,
            wrap_after=80,
            comma_first=False
        )
        return formatted
    except Exception as e:
        print_warning(f"SQL formatting failed: {str(e)}, using original content")
        return sql_content

def get_header_prompt(sql_content, author_name):
    """Generate prompts for header standardization"""
    system_instruction = """You are a SQL code formatter specializing in header standardization for database schema files.

Your task is to:
1. Add or update a standardized header comment at the top of the SQL file
2. Preserve all existing SQL code exactly as-is (no logic changes)
3. Ensure proper formatting and indentation
4. Use SQL Server T-SQL syntax
5. CRITICALLY IMPORTANT: If there is an existing header with a "SUMMARY OF CHANGES" section, preserve it entirely and add a new entry

Header format should be:
/***************************************************************************************************
Procedure:          [procedure/object name from the SQL]
Create Date:        [original create date or current date if new]
Author:             [author name]
Description:        [Detailed description of what this does - be verbose and specific]
Call by:            [Leave empty for now]
Affected table(s):  [Tables that are modified by this code]
Used By:            [Leave empty for now]
Parameter(s):       [List parameters with descriptions if applicable]
Usage:              [Example of how to execute this code]
                    [Additional notes or caveats about usage]
****************************************************************************************************
SUMMARY OF CHANGES
Date(yyyy-mm-dd)    Author              Comments
------------------- ------------------- ------------------------------------------------------------
[preserve any existing change entries here]
[current date]      [author name]       Automated polish and formatting.
***************************************************************************************************/

Requirements:
- Use /* */ block comments, not -- line comments
- If a header already exists, update it with current information
- If there's a SUMMARY OF CHANGES section, preserve ALL existing entries and add a new one
- Keep the description accurate and verbose based on the SQL content
- For "Call by" and "Used By" fields, leave empty for now
- Preserve all existing SQL code structure and logic
- Maintain proper GO statements and batches
- Use consistent indentation (4 spaces)
- Uppercase SQL keywords consistently"""

    current_date = datetime.now().strftime("%Y-%m-%d")
    
    user_prompt = f"""Please add or update the standardized header for this SQL file and format it properly.

Author: {author_name}
Current Date: {current_date}

SQL Content:
{sql_content}

CRITICAL INSTRUCTIONS:
1. Use the professional SQL header format with /* */ block comments and asterisk borders
2. If there is an existing header with change history, preserve ALL of it
3. Add a new change entry: "{current_date}          {author_name}    Automated polish and formatting."
4. For "Call by:" and "Used By:" fields, leave them empty for now
5. Make the description verbose and detailed - explain what, when, where, how and why
6. Extract the actual procedure/object name from the SQL code
7. List affected tables if any are modified
8. Return ONLY the complete, formatted SQL file with the updated header
9. Do NOT wrap the output in markdown code blocks or add any markdown formatting
10. Output pure SQL code only"""

    return user_prompt, system_instruction

def polish_sql_file(sql_file_path, output_dir, client, author_name):
    """Polish a single SQL file - format and standardize header"""
    try:
        with open(sql_file_path, 'r', encoding='utf-8') as f:
            original_sql = f.read()

        # Step 1: Format SQL using sqlparse
        formatted_sql = format_sql_content(original_sql)
        
        # Step 2: Send to Gemini for header standardization
        user_prompt, system_instruction = get_header_prompt(formatted_sql, author_name)
        polished_sql = call_gemini(user_prompt, system_instruction, client)
        
        if "GEMINI_API_ERROR" in polished_sql:
            return (sql_file_path, f"API Error: {polished_sql}")

        # Step 3: Clean up any markdown artifacts that might have slipped through
        polished_sql = polished_sql.strip()
        if polished_sql.startswith('```sql'):
            polished_sql = polished_sql[6:]  # Remove ```sql
        if polished_sql.startswith('```'):
            polished_sql = polished_sql[3:]   # Remove ```
        if polished_sql.endswith('```'):
            polished_sql = polished_sql[:-3]  # Remove trailing ```
        polished_sql = polished_sql.strip()

        # Step 4: Create output file path
        filename = os.path.basename(sql_file_path)
        output_file_path = os.path.join(output_dir, filename)
        
        # Ensure output directory exists
        os.makedirs(output_dir, exist_ok=True)
        
        # Step 5: Write to output file
        with open(output_file_path, 'w', encoding='utf-8') as f:
            f.write(polished_sql)

        return (sql_file_path, "Success", output_file_path)
        
    except Exception as e:
        return (sql_file_path, f"Error: {str(e)}", None)

def find_sql_files(target_path, default_source_dir):
    """Find SQL files to process"""
    if target_path:
        # Check if it's a file
        if os.path.isfile(target_path) and target_path.endswith('.sql'):
            return [target_path]
        # Check if it's a directory
        elif os.path.isdir(target_path):
            pattern = os.path.join(target_path, "*.sql")
            files = glob.glob(pattern)
            if not files:
                print_warning(f"No SQL files found in directory: {target_path}")
            return files
        else:
            print_error(f"Path not found or not a .sql file/directory: {target_path}")
            return []
    else:
        # Use default source directory
        pattern = os.path.join(default_source_dir, "*.sql")
        files = glob.glob(pattern)
        if not files:
            print_warning(f"No SQL files found in default directory: {default_source_dir}")
        return files

def main():
    parser = argparse.ArgumentParser(description="Format SQL files and standardize headers")
    parser.add_argument("path", nargs="?", help="SQL file or directory to polish (default: use DEFAULT_SOURCE_DIR from .env)")
    
    args = parser.parse_args()
    
    # Load configuration
    config = load_config()
    
    # Setup
    client = setup_gemini()
    
    # Find files to process
    sql_files = find_sql_files(args.path, config["source_dir"])
    
    if not sql_files:
        print_error("No files to process")
        sys.exit(1)
    
    if args.path:
        if os.path.isfile(args.path):
            print_info(f"Polishing single file: {args.path}")
        else:
            print_info(f"Polishing all SQL files in directory: {args.path}")
    else:
        print_info(f"Polishing all SQL files in default directory: {config['source_dir']}")
    
    # Process files
    print_info(f"Processing {len(sql_files)} file(s) with author: {config['author_name']}")
    print_info(f"Output directory: {config['output_dir']}")
    
    success_count = 0
    error_count = 0
    
    if len(sql_files) == 1:
        # Single file - no threading needed
        file_path, status, output_path = polish_sql_file(sql_files[0], config["output_dir"], client, config["author_name"])
        if status == "Success":
            print_success(f"Polished: {os.path.basename(file_path)} -> {os.path.basename(output_path)}")
            success_count += 1
        else:
            print_error(f"Failed: {os.path.basename(file_path)} - {status}")
            error_count += 1
    else:
        # Multiple files - use threading
        with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
            future_to_file = {
                executor.submit(polish_sql_file, file_path, config["output_dir"], client, config["author_name"]): file_path 
                for file_path in sql_files
            }
            
            for future in as_completed(future_to_file):
                file_path, status, output_path = future.result()
                if status == "Success":
                    print_success(f"Polished: {os.path.basename(file_path)} -> {os.path.basename(output_path)}")
                    success_count += 1
                else:
                    print_error(f"Failed: {os.path.basename(file_path)} - {status}")
                    error_count += 1
    
    # Summary
    print_info(f"Polish complete: {success_count} succeeded, {error_count} failed")
    print_info(f"Output files saved to: {config['output_dir']}")
    
    if error_count > 0:
        sys.exit(1)

if __name__ == "__main__":
    main()