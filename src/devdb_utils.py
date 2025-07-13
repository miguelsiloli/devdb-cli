#!/usr/bin/env python3
"""
DevDB Utility Functions
Common utilities for the DevDB CLI tool
"""

import os
import sys
import shutil
import subprocess
from pathlib import Path

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

def print_header(text):
    print_color(f"\n🚀 {text}", "36")

def check_docker():
    """Check if Docker is installed and running"""
    try:
        # Check if docker command exists
        subprocess.run(['docker', '--version'], 
                      capture_output=True, check=True)
        
        # Check if docker daemon is running
        result = subprocess.run(['docker', 'info'], 
                              capture_output=True, check=False)
        if result.returncode != 0:
            print_error("Docker daemon is not running. Please start Docker and try again.")
            return False
            
        return True
    except FileNotFoundError:
        print_error("Docker is not installed or not in your PATH.")
        print_info("Please install Docker and try again: https://docs.docker.com/get-docker/")
        return False
    except subprocess.CalledProcessError:
        print_error("Docker command failed. Please check your Docker installation.")
        return False

def check_python_dependencies():
    """Check if required Python packages are available"""
    required_packages = ['sqlparse']
    missing_packages = []
    
    for package in required_packages:
        try:
            __import__(package)
        except ImportError:
            missing_packages.append(package)
    
    if missing_packages:
        print_warning(f"Missing Python packages: {', '.join(missing_packages)}")
        print_info("Install with: pip install " + " ".join(missing_packages))
        return False
    
    return True

def download_tsqlt(target_dir):
    """Download tSQLt framework to target directory"""
    tsqlt_dir = target_dir / ".devdb" / "tSQLt"
    tsqlt_dir.mkdir(parents=True, exist_ok=True)
    
    # For now, create placeholder files - in real implementation would download from tsqlt.org
    placeholder_files = [
        "tSQLt.class.sql",
        "PrepareServer.sql", 
        "Example.sql",
        "License.txt",
        "ReleaseNotes.txt"
    ]
    
    for filename in placeholder_files:
        file_path = tsqlt_dir / filename
        if filename == "tSQLt.class.sql":
            # Create a minimal tSQLt installation script
            file_path.write_text("""-- tSQLt Testing Framework Installation
-- This is a placeholder - in production, download from https://tsqlt.org/
-- The actual tSQLt.class.sql file would be downloaded during project initialization

PRINT 'tSQLt framework placeholder - replace with actual tSQLt.class.sql';
""")
        else:
            file_path.write_text(f"-- {filename} placeholder\n-- Download actual tSQLt files from https://tsqlt.org/\n")
    
    return True

def generate_strong_password():
    """Generate a strong SQL Server password"""
    import random
    import string
    
    # SQL Server password requirements: 8+ chars, upper, lower, digit, special
    chars = string.ascii_letters + string.digits + "!@#$%^&*"
    password = ""
    
    # Ensure at least one of each required type
    password += random.choice(string.ascii_uppercase)  # Upper
    password += random.choice(string.ascii_lowercase)  # Lower  
    password += random.choice(string.digits)          # Digit
    password += random.choice("!@#$%^&*")            # Special
    
    # Fill rest with random chars
    for _ in range(8):
        password += random.choice(chars)
    
    # Shuffle to avoid predictable pattern
    password_list = list(password)
    random.shuffle(password_list)
    
    return ''.join(password_list)

def replace_template_variables(content, variables):
    """Replace template variables in content string"""
    for key, value in variables.items():
        placeholder = f"{{{{{key}}}}}"
        content = content.replace(placeholder, str(value))
    return content

def copy_and_process_template(src_path, dest_path, variables):
    """Copy template file and replace variables"""
    # Read template content
    with open(src_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Replace variables
    processed_content = replace_template_variables(content, variables)
    
    # Write to destination
    dest_path.parent.mkdir(parents=True, exist_ok=True)
    with open(dest_path, 'w', encoding='utf-8') as f:
        f.write(processed_content)

def get_git_user_info():
    """Get git user name and email if available"""
    try:
        name_result = subprocess.run(['git', 'config', 'user.name'], 
                                   capture_output=True, text=True, check=True)
        email_result = subprocess.run(['git', 'config', 'user.email'], 
                                    capture_output=True, text=True, check=True)
        
        name = name_result.stdout.strip()
        email = email_result.stdout.strip()
        
        if name and email:
            return f"{name} <{email}>"
        elif name:
            return name
        else:
            return "Unknown Author"
            
    except (subprocess.CalledProcessError, FileNotFoundError):
        return "Unknown Author"