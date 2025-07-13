#!/usr/bin/env python3
"""
Documentation Generator for DevDB
Generates comprehensive documentation from SQL files using Gemini AI
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

# Configuration
MODEL_NAME = "gemini-2.0-flash-exp"
MAX_WORKERS = 3

# Load configuration from environment
def load_config():
    """Load configuration from environment variables"""
    default_source_dir = os.getenv("DEFAULT_SOURCE_DIR", "schemas")
    docs_output_dir = os.getenv("DOCS_OUTPUT_DIR", "output/docs")
    
    return {
        "source_dir": os.path.join(os.getcwd(), default_source_dir),
        "output_dir": os.path.join(os.getcwd(), docs_output_dir),
        "manual_file": os.path.join(os.getcwd(), docs_output_dir, "Database_Manual.md")
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
            temperature=0.3,
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

def get_docs_prompt(sql_content, filename):
    """Generate prompts for documentation generation"""
    system_instruction = """You are a database documentation specialist who creates comprehensive, professional documentation for SQL schema files.

Your task is to analyze SQL code and generate detailed Markdown documentation that includes:

1. **Overview**: Brief description of the file's purpose
2. **Tables**: For each table, document:
   - Purpose and business logic
   - Column descriptions with data types
   - Primary keys, foreign keys, and constraints
   - Indexes and their purposes
3. **Views**: For each view, document:
   - Purpose and what data it provides
   - Source tables and join logic
   - Key columns and their meanings
4. **Functions**: For each function, document:
   - Purpose and use cases
   - Parameters and return types
   - Examples of usage
5. **Stored Procedures**: For each procedure, document:
   - Purpose and business logic
   - Input/output parameters
   - Error handling approach
   - Usage examples
6. **Dependencies**: What this file depends on and what depends on it

Format requirements:
- Use proper Markdown syntax
- Include code blocks for SQL examples
- Use tables for parameter documentation
- Provide clear, business-friendly explanations
- Include practical usage examples
- Highlight important constraints or business rules"""

    user_prompt = f"""Please generate comprehensive documentation for this SQL schema file: {filename}

Analyze the SQL code and create detailed Markdown documentation following the specified format.

SQL Content:
{sql_content}

Return only the Markdown documentation."""

    return user_prompt, system_instruction

def generate_doc_for_file(sql_file_path, output_dir, client):
    """Generate documentation for a single SQL file"""
    try:
        with open(sql_file_path, 'r', encoding='utf-8') as f:
            sql_content = f.read()

        filename = os.path.basename(sql_file_path)
        user_prompt, system_instruction = get_docs_prompt(sql_content, filename)
        markdown_docs = call_gemini(user_prompt, system_instruction, client)
        
        if "GEMINI_API_ERROR" in markdown_docs:
            return (sql_file_path, f"API Error: {markdown_docs}", "", None)

        # Add file separator for consolidated manual
        header = f"\n\n# {filename}\n\n"
        footer = "\n\n---\n\n"
        formatted_docs = header + markdown_docs + footer

        # Save individual documentation file
        doc_filename = filename.replace('.sql', '.md')
        output_file_path = os.path.join(output_dir, doc_filename)
        
        # Ensure output directory exists
        os.makedirs(output_dir, exist_ok=True)
        
        # Write individual doc file
        with open(output_file_path, 'w', encoding='utf-8') as f:
            f.write(markdown_docs)

        return (sql_file_path, "Success", formatted_docs, output_file_path)
        
    except Exception as e:
        return (sql_file_path, f"Error: {str(e)}", "", None)

def find_sql_files(target_path, default_source_dir):
    """Find SQL files to process"""
    if target_path:
        # Check if it's a directory (docs only works with directories)
        if os.path.isdir(target_path):
            pattern = os.path.join(target_path, "*.sql")
            files = glob.glob(pattern)
            if not files:
                print_warning(f"No SQL files found in directory: {target_path}")
            return sorted(files)  # Sort for consistent output
        else:
            print_error(f"Path not found or not a directory: {target_path}")
            return []
    else:
        # Use default source directory
        pattern = os.path.join(default_source_dir, "*.sql")
        files = glob.glob(pattern)
        if not files:
            print_warning(f"No SQL files found in default directory: {default_source_dir}")
        return sorted(files)  # Sort for consistent output

def create_manual_header():
    """Create header for the consolidated manual"""
    current_date = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    return f"""# DevDB Database Manual

*Generated on {current_date}*

This document provides comprehensive documentation for the DevDB database schema, including tables, views, functions, and stored procedures.

## Table of Contents

- [Overview](#overview)
- [Database Objects](#database-objects)

## Overview

DevDB is an automated development database deployment system that provides a one-command solution to deploy fresh, containerized SQL Server databases for local development.

## Database Objects

"""

# Remove save_individual_doc function - now handled in generate_doc_for_file

def main():
    parser = argparse.ArgumentParser(description="Generate documentation for SQL files")
    parser.add_argument("directory", nargs="?", help="Directory containing SQL files to document (default: use DEFAULT_SOURCE_DIR from .env)")
    
    args = parser.parse_args()
    
    # Load configuration
    config = load_config()
    
    # Setup
    client = setup_gemini()
    
    # Find files to process
    sql_files = find_sql_files(args.directory, config["source_dir"])
    
    if not sql_files:
        print_error("No files to process")
        sys.exit(1)
    
    if args.directory:
        print_info(f"Generating documentation for directory: {args.directory}")
    else:
        print_info(f"Generating documentation for default directory: {config['source_dir']}")
    
    # Process files
    print_info(f"Processing {len(sql_files)} file(s)")
    print_info(f"Output directory: {config['output_dir']}")
    
    success_count = 0
    error_count = 0
    all_documentation = []
    
    # Multiple files - use threading and create consolidated manual
    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        future_to_file = {
            executor.submit(generate_doc_for_file, file_path, config["output_dir"], client): file_path 
            for file_path in sql_files
        }
        
        for future in as_completed(future_to_file):
            file_path, status, docs, output_path = future.result()
            if status == "Success":
                print_success(f"Documented: {os.path.basename(file_path)} -> {os.path.basename(output_path)}")
                all_documentation.append((file_path, docs))
                success_count += 1
            else:
                print_error(f"Failed: {os.path.basename(file_path)} - {status}")
                error_count += 1
    
    # Create consolidated manual
    if all_documentation:
        try:
            with open(config["manual_file"], 'w', encoding='utf-8') as f:
                f.write(create_manual_header())
                
                # Sort by filename for consistent order
                all_documentation.sort(key=lambda x: os.path.basename(x[0]))
                
                for _, docs in all_documentation:
                    f.write(docs)
            
            print_success(f"Consolidated manual saved: {config['manual_file']}")
        except Exception as e:
            print_error(f"Failed to create consolidated manual: {str(e)}")
            error_count += 1
    
    # Summary
    print_info(f"Documentation complete: {success_count} succeeded, {error_count} failed")
    print_info(f"Individual docs saved to: {config['output_dir']}")
    print_info(f"Consolidated manual: {config['manual_file']}")
    
    if error_count > 0:
        sys.exit(1)

if __name__ == "__main__":
    main()