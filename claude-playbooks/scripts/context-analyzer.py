#!/usr/bin/env python3
"""
Claude Context Analyzer
Automatically analyzes project structure and generates comprehensive context files.
"""

import os
import json
import subprocess
import re
from datetime import datetime
from pathlib import Path
import argparse
import shutil

class ProjectAnalyzer:
    def __init__(self, project_path="."):
        self.project_path = Path(project_path).resolve()
        self.claude_dir = self.project_path / ".claude"
        self.context_dir = self.claude_dir / "context"
        
        # Check if .claude directory exists, create if not
        if not self.claude_dir.exists():
            print("📁 Creating .claude directory...")
            self.claude_dir.mkdir(exist_ok=True)
        
        # Create context subdirectory within .claude
        self.context_dir.mkdir(parents=True, exist_ok=True)
        
    def detect_project_type(self):
        """Detect project type based on configuration files."""
        indicators = {
            'python': ['requirements.txt', 'setup.py', 'pyproject.toml', 'Pipfile'],
            'javascript': ['package.json', 'yarn.lock', 'npm-shrinkwrap.json'],
            'typescript': ['tsconfig.json', 'package.json'],
            'rust': ['Cargo.toml'],
            'go': ['go.mod', 'go.sum'],
            'java': ['pom.xml', 'build.gradle', 'build.gradle.kts'],
            'docker': ['Dockerfile', 'docker-compose.yml', 'docker-compose.yaml']
        }
        
        detected = []
        for proj_type, files in indicators.items():
            for file in files:
                if (self.project_path / file).exists():
                    detected.append(proj_type)
                    break
                    
        return detected if detected else ['unknown']
    
    def analyze_git_status(self):
        """Analyze git repository status."""
        try:
            # Check if it's a git repo
            result = subprocess.run(['git', 'rev-parse', '--git-dir'], 
                                  capture_output=True, text=True, cwd=self.project_path)
            if result.returncode != 0:
                return {"is_git_repo": False}
            
            # Get current branch
            branch = subprocess.run(['git', 'branch', '--show-current'], 
                                   capture_output=True, text=True, cwd=self.project_path).stdout.strip()
            
            # Get status
            status = subprocess.run(['git', 'status', '--porcelain'], 
                                   capture_output=True, text=True, cwd=self.project_path).stdout.strip()
            
            # Get recent commits
            commits = subprocess.run(['git', 'log', '--oneline', '-5'], 
                                    capture_output=True, text=True, cwd=self.project_path).stdout.strip()
            
            return {
                "is_git_repo": True,
                "current_branch": branch,
                "has_changes": bool(status),
                "change_count": len(status.split('\n')) if status else 0,
                "recent_commits": commits.split('\n') if commits else []
            }
        except Exception as e:
            return {"is_git_repo": False, "error": str(e)}
    
    def detect_build_tools(self, project_types):
        """Detect build and development tools."""
        tools = {
            'build': [],
            'test': [],
            'lint': [],
            'format': []
        }
        
        # Check package.json scripts
        if 'javascript' in project_types or 'typescript' in project_types:
            package_json = self.project_path / 'package.json'
            if package_json.exists():
                try:
                    with open(package_json) as f:
                        data = json.load(f)
                        scripts = data.get('scripts', {})
                        
                        for script_name, script_cmd in scripts.items():
                            if any(word in script_name.lower() for word in ['build', 'compile']):
                                tools['build'].append(f"npm run {script_name}")
                            elif any(word in script_name.lower() for word in ['test', 'spec']):
                                tools['test'].append(f"npm run {script_name}")
                            elif any(word in script_name.lower() for word in ['lint', 'check']):
                                tools['lint'].append(f"npm run {script_name}")
                            elif any(word in script_name.lower() for word in ['format', 'prettier']):
                                tools['format'].append(f"npm run {script_name}")
                except json.JSONDecodeError:
                    pass
        
        # Check Python tools
        if 'python' in project_types:
            if (self.project_path / 'setup.py').exists():
                tools['build'].append('python setup.py build')
            if (self.project_path / 'pytest.ini').exists() or any(f.name.startswith('test_') for f in self.project_path.glob('**/*.py')):
                tools['test'].append('pytest')
            if (self.project_path / '.flake8').exists():
                tools['lint'].append('flake8')
            if (self.project_path / 'pyproject.toml').exists():
                tools['format'].append('black .')
        
        # Check Rust tools
        if 'rust' in project_types:
            tools['build'].append('cargo build')
            tools['test'].append('cargo test')
            tools['format'].append('cargo fmt')
            tools['lint'].append('cargo clippy')
        
        # Check Go tools
        if 'go' in project_types:
            tools['build'].append('go build')
            tools['test'].append('go test ./...')
            tools['format'].append('go fmt ./...')
            tools['lint'].append('golangci-lint run')
            
        return tools
    
    def scan_project_structure(self):
        """Scan and categorize project files."""
        structure = {
            'config_files': [],
            'source_dirs': [],
            'doc_files': [],
            'test_dirs': [],
            'total_files': 0,
            'languages': {}
        }
        
        # Common config files to look for
        config_patterns = [
            r'.*\.json$', r'.*\.yaml$', r'.*\.yml$', r'.*\.toml$',
            r'.*\.ini$', r'.*\.cfg$', r'Dockerfile$', r'Makefile$',
            r'requirements.*\.txt$', r'package\.json$', r'go\.mod$'
        ]
        
        # Source file extensions
        source_extensions = {
            '.py': 'python', '.js': 'javascript', '.ts': 'typescript',
            '.rs': 'rust', '.go': 'go', '.java': 'java', '.cpp': 'cpp',
            '.c': 'c', '.h': 'c', '.hpp': 'cpp'
        }
        
        for root, dirs, files in os.walk(self.project_path):
            # Skip hidden directories and common ignore patterns
            dirs[:] = [d for d in dirs if not d.startswith('.') and d not in ['node_modules', '__pycache__', 'target']]
            
            root_path = Path(root)
            rel_path = root_path.relative_to(self.project_path)
            
            # Categorize directories
            if any(name in root_path.name.lower() for name in ['test', 'tests', 'spec']):
                structure['test_dirs'].append(str(rel_path))
            elif any(name in root_path.name.lower() for name in ['src', 'lib', 'app']):
                structure['source_dirs'].append(str(rel_path))
            
            for file in files:
                file_path = root_path / file
                rel_file_path = file_path.relative_to(self.project_path)
                structure['total_files'] += 1
                
                # Check for config files
                if any(re.match(pattern, file) for pattern in config_patterns):
                    structure['config_files'].append(str(rel_file_path))
                
                # Check for documentation
                if any(name in file.lower() for name in ['readme', 'doc', 'changelog']):
                    structure['doc_files'].append(str(rel_file_path))
                
                # Count languages
                ext = file_path.suffix.lower()
                if ext in source_extensions:
                    lang = source_extensions[ext]
                    structure['languages'][lang] = structure['languages'].get(lang, 0) + 1
        
        return structure
    
    def generate_analysis(self, update_mode=False):
        """Generate comprehensive project analysis."""
        print("🔍 Analyzing project structure...")

        project_types = self.detect_project_type()
        git_info = self.analyze_git_status()
        build_tools = self.detect_build_tools(project_types)
        structure = self.scan_project_structure()

        overview_file = self.context_dir / 'project-overview.md'

        if update_mode and overview_file.exists():
            print("📝 Updating existing project overview...")
            # Create backup
            backup_file = overview_file.with_suffix('.md.bak')
            shutil.copy(overview_file, backup_file)

            # Read existing content to preserve custom sections
            with open(overview_file, 'r') as f:
                existing_content = f.read()

            # Generate new overview
            new_overview = self._generate_project_overview(project_types, git_info, build_tools, structure)

            # Merge: Update timestamps and dynamic sections, preserve custom notes
            if '## Custom Notes' in existing_content:
                # Extract custom notes section
                custom_section = existing_content.split('## Custom Notes')[1].split('\n##')[0]
                # Append to new overview
                new_overview += '\n## Custom Notes' + custom_section

            with open(overview_file, 'w') as f:
                f.write(new_overview)
        else:
            # Generate new project overview
            overview = self._generate_project_overview(project_types, git_info, build_tools, structure)

            # Write files
            with open(overview_file, 'w') as f:
                f.write(overview)
        
        # Generate initial task list
        self._generate_initial_tasks(project_types, structure)
        
        print(f"✅ Analysis complete! Context saved to {self.context_dir}")
        return {
            'project_types': project_types,
            'git_info': git_info,
            'build_tools': build_tools,
            'structure': structure
        }
    
    def _generate_project_overview(self, project_types, git_info, build_tools, structure):
        """Generate the project overview markdown content."""
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        
        # Determine primary language
        if structure['languages']:
            primary_lang = max(structure['languages'], key=structure['languages'].get)
        else:
            primary_lang = project_types[0] if project_types else 'unknown'
        
        content = f"""# Project Overview

**Generated:** {timestamp}  
**Project Path:** {self.project_path}  
**Analysis Version:** 1.0  

## Project Summary
This appears to be a {', '.join(project_types)} project with {structure['total_files']} files.

## Technology Stack
- **Primary Language:** {primary_lang}
- **Project Types:** {', '.join(project_types)}
- **Languages Detected:** {', '.join(f"{lang} ({count} files)" for lang, count in structure['languages'].items())}

## Project Structure
```
Total Files: {structure['total_files']}
Source Directories: {len(structure['source_dirs'])}
Test Directories: {len(structure['test_dirs'])}
Config Files: {len(structure['config_files'])}
Documentation Files: {len(structure['doc_files'])}
```

### Key Directories
{self._format_list(structure['source_dirs'], 'No source directories identified')}

### Configuration Files
{self._format_list(structure['config_files'][:10], 'No configuration files found')}

### Documentation
{self._format_list(structure['doc_files'], 'No documentation files found')}

## Development Environment
### Build Commands
{self._format_list(build_tools['build'], 'No build commands detected')}

### Test Commands  
{self._format_list(build_tools['test'], 'No test commands detected')}

### Linting Commands
{self._format_list(build_tools['lint'], 'No linting commands detected')}

### Formatting Commands
{self._format_list(build_tools['format'], 'No formatting commands detected')}

## Git Repository Status
- **Is Git Repo:** {'Yes' if git_info.get('is_git_repo') else 'No'}
"""

        if git_info.get('is_git_repo'):
            content += f"""- **Current Branch:** {git_info.get('current_branch', 'unknown')}
- **Has Uncommitted Changes:** {'Yes' if git_info.get('has_changes') else 'No'}
- **Change Count:** {git_info.get('change_count', 0)}

### Recent Commits
{self._format_list(git_info.get('recent_commits', []), 'No recent commits')}
"""

        content += f"""
## Next Steps
1. Review and understand the project's main purpose
2. Identify any immediate development tasks
3. Set up development environment if needed
4. Review existing documentation and code patterns

## Questions for User
1. What is the primary goal or purpose of this project?
2. Are there any specific tasks or features you'd like to work on?
3. Are there any particular coding standards or patterns to follow?
4. Do you need help setting up the development environment?

---
*This analysis was generated automatically on {timestamp}*
"""
        return content
    
    def _format_list(self, items, empty_message="None found"):
        """Format a list of items for markdown display."""
        if not items:
            return f"- {empty_message}"
        return '\n'.join(f"- `{item}`" for item in items)
    
    def _generate_initial_tasks(self, project_types, structure):
        """Generate or update task list based on analysis."""
        task_file = self.context_dir / 'task-tracker.md'
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

        # Check if task file already exists
        if task_file.exists():
            print("📋 Updating existing task tracker...")
            # Read existing content
            with open(task_file, 'r') as f:
                existing_content = f.read()

            # Update timestamp only
            import re
            updated_content = re.sub(
                r'\*\*Last Updated:\*\*.*',
                f'**Last Updated:** {timestamp}',
                existing_content
            )

            # Add analysis suggestions if needed
            if not structure['doc_files'] and 'Consider creating project documentation' not in existing_content:
                # Find pending tasks section and append
                lines = updated_content.split('\n')
                for i, line in enumerate(lines):
                    if '## Pending Tasks' in line:
                        # Insert after this line
                        lines.insert(i + 1, '- [ ] Consider creating project documentation (auto-suggested)')
                        break
                updated_content = '\n'.join(lines)

            if structure['languages'] and not structure['test_dirs'] and 'Consider adding test coverage' not in existing_content:
                lines = updated_content.split('\n')
                for i, line in enumerate(lines):
                    if '## Pending Tasks' in line:
                        lines.insert(i + 1, '- [ ] Consider adding test coverage (auto-suggested)')
                        break
                updated_content = '\n'.join(lines)

            with open(task_file, 'w') as f:
                f.write(updated_content)
            return

        # Create new task tracker if doesn't exist
        tasks = [
            "Complete project analysis and understand codebase",
            "Review existing documentation and README files",
            "Understand project goals and requirements"
        ]

        # Add project-specific tasks
        if not structure['doc_files']:
            tasks.append("Consider creating project documentation")

        if structure['languages'] and not structure['test_dirs']:
            tasks.append("Consider adding test coverage")
        
        content = f"""# Task Tracker

**Last Updated:** {timestamp}

## Pending Tasks
{chr(10).join(f'- [ ] {task}' for task in tasks)}

## Completed Tasks
- [x] Initialize Claude workflow automation
- [x] Complete automated project analysis

## Task History
| Date | Task | Status | Notes |
|------|------|--------|-------|
| {datetime.now().strftime('%Y-%m-%d')} | Initialize workflow | Completed | Auto-setup complete |
| {datetime.now().strftime('%Y-%m-%d')} | Project analysis | Completed | Automated analysis complete |

## Resources & Links
- Project Root: {self.project_path}
- Claude Directory: {self.claude_dir}
- Context Directory: {self.context_dir}
"""
        
        with open(task_file, 'w') as f:
            f.write(content)

def main():
    parser = argparse.ArgumentParser(description='Analyze project structure for Claude Code')
    parser.add_argument('--path', default='.', help='Project path to analyze')
    parser.add_argument('--verbose', action='store_true', help='Verbose output')
    parser.add_argument('--update', action='store_true', help='Update existing analysis instead of overwriting')

    args = parser.parse_args()

    analyzer = ProjectAnalyzer(args.path)
    try:
        result = analyzer.generate_analysis(update_mode=args.update)
        
        if args.verbose:
            print("\nAnalysis Results:")
            print(f"Project Types: {result['project_types']}")
            print(f"Total Files: {result['structure']['total_files']}")
            print(f"Languages: {result['structure']['languages']}")
            
    except Exception as e:
        print(f"❌ Error during analysis: {e}")
        return 1
    
    return 0

if __name__ == '__main__':
    exit(main())