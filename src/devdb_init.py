#!/usr/bin/env python3
"""
DevDB Project Initialization
Creates a complete DevDB project scaffolding similar to 'airflow init'
"""

import os
import shutil
import sys
from pathlib import Path
from datetime import datetime
try:
    import pkg_resources
except ImportError:
    pkg_resources = None
try:
    # Try relative imports first (when installed as package)
    from .devdb_utils import (
        print_success, print_error, print_warning, print_info, print_header,
        check_docker, check_python_dependencies, generate_strong_password,
        copy_and_process_template, get_git_user_info, download_tsqlt
    )
except ImportError:
    # Fallback to direct imports (development mode)
    from devdb_utils import (
        print_success, print_error, print_warning, print_info, print_header,
        check_docker, check_python_dependencies, generate_strong_password,
        copy_and_process_template, get_git_user_info, download_tsqlt
    )

class DevDBInit:
    def __init__(self):
        # Try to use pkg_resources for installed package, fallback to file system
        if pkg_resources:
            try:
                # When installed as package, use pkg_resources
                templates_path = pkg_resources.resource_filename('src', 'templates')
                self.templates_dir = Path(templates_path)
            except Exception:
                # Fallback to filesystem-based discovery
                self._init_filesystem_templates()
        else:
            # Development mode - use filesystem
            self._init_filesystem_templates()
    
    def _init_filesystem_templates(self):
        """Initialize templates directory using filesystem paths"""
        # Get the absolute path to this file's directory
        self.src_dir = Path(__file__).parent.resolve()
        self.templates_dir = self.src_dir / "templates"
        
        # If templates don't exist in src dir, try the parent directory
        if not self.templates_dir.exists():
            parent_templates = self.src_dir.parent / "templates"
            if parent_templates.exists():
                self.templates_dir = parent_templates
        
        
    def create_project(self, project_name="devdb-project", target_path=".", 
                      template="advanced", force=False, test_mode=False):
        """Create a new DevDB project with complete scaffolding"""
        
        print_header(f"Creating DevDB project: {project_name}")
        
        # Validate inputs
        target_dir = Path(target_path).resolve() / project_name
        
        if not self._validate_setup(target_dir, force, test_mode):
            return False
            
        # Prepare template variables
        variables = self._prepare_variables(project_name)
        
        # Create project structure
        if not self._create_project_structure(target_dir, template, variables):
            return False
            
        # Download dependencies
        if not self._setup_dependencies(target_dir):
            return False
            
        # Set permissions
        self._set_permissions(target_dir)
        
        # Success message
        self._print_success_message(target_dir, project_name)
        return True
    
    def _validate_setup(self, target_dir, force, test_mode=False):
        """Validate system requirements and target directory"""
        
        print_info("Validating system requirements...")
        
        # Check Docker (skip in test mode)
        if not test_mode and not check_docker():
            return False
            
        # Check Python dependencies
        if not check_python_dependencies():
            return False
            
        # Check target directory
        if target_dir.exists():
            if not force:
                if any(target_dir.iterdir()):
                    print_error(f"Directory {target_dir} exists and is not empty")
                    print_info("Use --force to overwrite or choose a different location")
                    return False
            else:
                print_warning(f"Overwriting existing directory: {target_dir}")
                shutil.rmtree(target_dir)
        
        return True
    
    def _prepare_variables(self, project_name):
        """Prepare template variables for substitution"""
        author_name = get_git_user_info()
        
        variables = {
            'PROJECT_NAME': project_name,
            'AUTHOR_NAME': author_name,
            'DB_PASSWORD': generate_strong_password(),
            'CREATION_DATE': datetime.now().strftime('%Y-%m-%d'),
            'DB_PORT': '1433',
            'GUI_PORT': '8081',
            'YEAR': datetime.now().year
        }
        
        return variables
    
    def _create_project_structure(self, target_dir, template, variables):
        """Create the complete project directory structure"""
        
        print_info("Creating project structure...")
        
        try:
            # Create base directories
            directories = [
                '.devdb/scripts',
                '.devdb/tSQLt', 
                'schemas',
                'tests',
                'output/prod_scripts',
                'output/docs'
            ]
            
            for dir_path in directories:
                (target_dir / dir_path).mkdir(parents=True, exist_ok=True)
            
            # Copy template files
            template_path = self.templates_dir / template
            if not template_path.exists():
                print_error(f"Template '{template}' not found at {template_path}")
                print_info(f"Available templates: {list(self.templates_dir.glob('*'))}")
                return False
                
            self._copy_template_files(template_path, target_dir, variables)
            
            return True
            
        except Exception as e:
            print_error(f"Failed to create project structure: {e}")
            return False
    
    def _copy_template_files(self, template_path, target_dir, variables):
        """Copy and process all template files"""
        
        # Template files to copy and process
        template_files = [
            ('devdb.sh', 'devdb.sh'),
            ('e2e_test.sh', 'e2e_test.sh'),
            ('test_connection.sh', 'test_connection.sh'),
            ('.gitignore', '.gitignore'),
            ('README.md', 'README.md'),
            ('CLAUDE.md', 'CLAUDE.md'),
            ('.devdb/docker-compose.yml', '.devdb/docker-compose.yml'),
            ('.devdb/.env.example', '.devdb/.env.example'),
            ('.devdb/.env', '.devdb/.env'),
            ('.devdb/scripts/code_polisher.py', '.devdb/scripts/code_polisher.py'),
        ]
        
        # Schema files
        schema_files = [
            ('schemas/01_tables.sql', 'schemas/01_tables.sql'),
            ('schemas/02_sprocs_and_views.sql', 'schemas/02_sprocs_and_views.sql'),
            ('schemas/03_functions.sql', 'schemas/03_functions.sql'),
            ('schemas/04_advanced_views.sql', 'schemas/04_advanced_views.sql'),
            ('schemas/05_stored_procedures.sql', 'schemas/05_stored_procedures.sql'),
            ('schemas/99_install_tsqlt.sql', 'schemas/99_install_tsqlt.sql'),
        ]
        
        # Test files
        test_files = [
            ('tests/test_functions.sql', 'tests/test_functions.sql'),
            ('tests/test_stored_procedures.sql', 'tests/test_stored_procedures.sql'),
            ('tests/test_views.sql', 'tests/test_views.sql'),
            ('tests/test_user_creation.sql', 'tests/test_user_creation.sql'),
            ('tests/test_product_stock_fail.sql', 'tests/test_product_stock_fail.sql'),
        ]
        
        all_files = template_files + schema_files + test_files
        
        for src_file, dest_file in all_files:
            src_path = template_path / src_file
            dest_path = target_dir / dest_file
            
            if src_path.exists():
                copy_and_process_template(src_path, dest_path, variables)
            else:
                print_warning(f"Template file not found: {src_path}")
    
    def _setup_dependencies(self, target_dir):
        """Download and setup project dependencies"""
        
        print_info("Setting up project dependencies...")
        
        try:
            # Download tSQLt framework
            if not download_tsqlt(target_dir):
                print_warning("Failed to download tSQLt - using placeholders")
                
            return True
            
        except Exception as e:
            print_error(f"Failed to setup dependencies: {e}")
            return False
    
    def _set_permissions(self, target_dir):
        """Set appropriate file permissions"""
        
        # Make shell scripts executable
        script_files = [
            'devdb.sh',
            'e2e_test.sh', 
            'test_connection.sh'
        ]
        
        for script in script_files:
            script_path = target_dir / script
            if script_path.exists():
                script_path.chmod(0o755)
    
    def _print_success_message(self, target_dir, project_name):
        """Print success message with next steps"""
        
        print_success(f"DevDB project '{project_name}' created successfully!")
        
        print("\n" + "="*60)
        print_header("Next Steps:")
        print("\n1. Navigate to your project:")
        print(f"   cd {target_dir}")
        
        print("\n2. Configure your environment:")
        print("   • Edit .devdb/.env with your preferred settings")
        print("   • Add your Gemini API key for SQL polishing (optional)")
        
        print("\n3. Start your development environment:")
        print("   ./devdb.sh up")
        
        print("\n4. Test your setup:")
        print("   ./devdb.sh test all")
        
        print("\n5. Access your database:")
        print("   • SQL Server: localhost:1433 (user: sa)")
        print("   • Web GUI: http://localhost:8081")
        
        print("\n6. Available commands:")
        print("   ./devdb.sh help")
        
        print("\n" + "="*60)
        print_info("Your DevDB project is ready for development!")