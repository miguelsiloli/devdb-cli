#!/usr/bin/env python3

from setuptools import setup, find_packages
import os

# Read the contents of README file
this_directory = os.path.abspath(os.path.dirname(__file__))
with open(os.path.join(this_directory, 'README.md'), encoding='utf-8') as f:
    long_description = f.read()

setup(
    name='devdb-cli',
    version='1.0.0',
    description='SQL Server Development Database Scaffolding Tool',
    long_description=long_description,
    long_description_content_type='text/markdown',
    author='DevDB Team',
    author_email='devdb@example.com',
    url='https://github.com/your-org/devdb-cli',
    packages=find_packages(),
    package_data={
        'src': [
            'templates/**/*',
            'templates/**/**/*',
            'templates/**/**/**/*',
        ],
    },
    include_package_data=True,
    install_requires=[
        'sqlparse>=0.4.0',
    ],
    extras_require={
        'ai': ['google-generativeai>=0.3.0'],
    },
    entry_points={
        'console_scripts': [
            'devdb=src.cli:main',
        ],
    },
    classifiers=[
        'Development Status :: 4 - Beta',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: MIT License',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3.9',
        'Programming Language :: Python :: 3.10',
        'Programming Language :: Python :: 3.11',
        'Programming Language :: Python :: 3.12',
        'Operating System :: OS Independent',
        'Topic :: Software Development :: Tools',
        'Topic :: Database',
    ],
    python_requires='>=3.7',
    keywords='sql-server database development scaffolding docker',
    project_urls={
        'Bug Reports': 'https://github.com/your-org/devdb-cli/issues',
        'Source': 'https://github.com/your-org/devdb-cli',
        'Documentation': 'https://github.com/your-org/devdb-cli#readme',
    },
)