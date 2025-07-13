#!/usr/bin/env python3
"""
DevDB CLI - SQL Server Development Database Management Tool
"""

import sys
import argparse
from pathlib import Path

try:
    # Try relative imports first (when installed as package)
    from .devdb_init import DevDBInit
    from .devdb_utils import print_error, print_success, print_info
    from . import __version__
except ImportError:
    # Fallback to direct imports (development mode)
    from devdb_init import DevDBInit
    from devdb_utils import print_error, print_success, print_info
    __version__ = "1.0.0"

def main():
    parser = argparse.ArgumentParser(
        description="DevDB - SQL Server Development Database Management Tool",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # Init command
    init_parser = subparsers.add_parser('init', help='Initialize a new DevDB project')
    init_parser.add_argument('project_name', nargs='?', default='devdb-project', 
                           help='Name of the project to create (default: devdb-project)')
    init_parser.add_argument('--path', '-p', default='.', 
                           help='Directory to create the project in (default: current directory)')
    init_parser.add_argument('--template', '-t', choices=['basic', 'advanced'], default='advanced',
                           help='Project template to use (default: advanced)')
    init_parser.add_argument('--force', '-f', action='store_true',
                           help='Force creation even if directory exists')
    
    # Version command
    version_parser = subparsers.add_parser('version', help='Show DevDB version')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return 1
    
    try:
        if args.command == 'init':
            initializer = DevDBInit()
            success = initializer.create_project(
                project_name=args.project_name,
                target_path=args.path,
                template=args.template,
                force=args.force,
                test_mode=False
            )
            return 0 if success else 1
            
        elif args.command == 'version':
            print_info(f"DevDB version {__version__}")
            return 0
            
    except KeyboardInterrupt:
        print_error("Operation cancelled by user")
        return 1
    except Exception as e:
        print_error(f"Unexpected error: {str(e)}")
        return 1

if __name__ == "__main__":
    sys.exit(main())