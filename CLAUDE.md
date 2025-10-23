# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

### Purpose

**LoggingFacade** is a flexible, SLF4J-inspired logging facade for Delphi that decouples application code from specific logging implementations.

The project provides:
- **Interface-based Design**: Application code depends only on the `ILogger` interface
- **Multiple Implementations**: Console logger, Null logger, and adapters for LoggerPro and QuickLogger
- **Factory Pattern**: Centralized logger creation and configuration
- **External Configuration**: Logback-style `.properties` files with hierarchical resolution
- **Logger Contexts**: Automatic namespace prefixing based on unit names
- **Zero Dependencies**: Core framework has no external dependencies
- **Modular Packages**: Separate BPL packages for core and adapters

See [README.md](README.md) for complete feature documentation.

### Architecture Philosophy

**CRITICAL:** This project prioritizes **clean architecture** and **design patterns** above all else.

When working on this codebase:
- **Architecture ALWAYS takes priority** over existing code
- Maintain the **Facade pattern** - the core `ILogger` interface must remain decoupled from implementations
- Preserve **separation of concerns** - factory, implementations, and adapters must remain independent
- Follow **SOLID principles** - especially Single Responsibility and Dependency Inversion
- Respect **package boundaries** - core package has zero dependencies, adapters are modular

If existing code violates architectural principles, the code should be refactored to conform to the architecture, not the other way around.

## Table of Contents

1. [Development Workflow](#development-workflow)
2. [Build System](#build-system)
3. [Coding Standards](#coding-standards)

---

## Development Workflow

### Git Commit Guidelines

**CRITICAL RULES:**
- **Do NOT automatically commit** - always ask for user approval first
- **Never push to remote** without explicit user request
- **Do NOT add Claude signatures** to commits

#### Commit Message Format

Use clean, professional commit messages following conventional commit format:

**Good commit message:**
```
feat: Add RPC method validation for timeout parameters

- Validate timeout values are positive integers
- Add unit tests for validation logic
- Update documentation with timeout constraints
```

**Bad commit message (DO NOT use):**
```
feat: Add RPC method validation

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

Keep commits professional and focused on the technical content.

---

## Build System

### Command-Line Compilation

Use the **PowerShell build-delphi.ps1 build script** from the [delphi-build-tools](https://github.com/pleali/delphi-build-tools) repository.

**IMPORTANT:** Always launch with PowerShell (not bash or cmd)

#### Quick Start

```powershell
# Basic build (Debug, Win32)
powershell -File build-delphi.ps1 examples\delphi\agent-annotated\AnnotatedAgent.dproj

# Release build
powershell -File build-delphi.ps1 examples\delphi\agent-annotated\AnnotatedAgent.dproj -Config Release

# Clean build with verbose output
powershell -File build-delphi.ps1 examples\delphi\agent-annotated\AnnotatedAgent.dproj -Clean -Verbose

# Win64 platform
powershell -File build-delphi.ps1 examples\delphi\agent-annotated\AnnotatedAgent.dproj -Platform Win64

# Custom log file
powershell -File build-delphi.ps1 examples\delphi\agent-annotated\AnnotatedAgent.dproj -LogFile custom.log

# With ExecutionPolicy bypass
powershell -ExecutionPolicy Bypass -File build-delphi.ps1 examples\delphi\agent-annotated\AnnotatedAgent.dproj
```

#### Key Features

- ✅ Automatic RAD Studio detection (any version)
- ✅ Clean build support (`-Clean`)
- ✅ Verbose mode (`-Verbose`)
- ✅ Automatic logging to `build-logs/` directory
- ✅ Configuration profiles: Debug, Release, custom
- ✅ Platform support: Win32, Win64, OSX64, etc.
- ✅ Colored output and build time tracking
- ✅ Error detection and reporting

#### Resources

- Script source: https://github.com/pleali/delphi-build-tools/blob/master/scripts/build-delphi.ps1
- Documentation: See repository README for complete documentation

---

## Coding Standards

### Project Files (.dpr)

**IMPORTANT: Keep .dpr files minimal**

Delphi project files should contain minimal code. Most application logic belongs in separate units (.pas files).

#### Rule of Thumb

- **< 100 lines:** Simple examples can have code directly in .dpr
- **≥ 100 lines:** Move logic to dedicated units

#### Examples

**❌ BAD: Too much code in .dpr**

```pascal
// AVOID - Complex logic in .dpr file (150+ lines)
program MyApplication;

uses
  System.SysUtils;

type
  TMyApp = class
    // 100+ lines of class definition
  end;

procedure DoComplexLogic;
begin
  // 50+ lines of logic
end;

var
  App: TMyApp;

begin
  App := TMyApp.Create;
  try
    DoComplexLogic;
    App.Run;
  finally
    App.Free;
  end;
end.
```

**✅ GOOD: Minimal .dpr file**

```pascal
// CORRECT - Minimal .dpr file
program MyApplication;

uses
  MyAppMain in 'src\MyAppMain.pas';

begin
  RunApplication;  // Implemented in MyAppMain.pas
end.
```

```pascal
// MyAppMain.pas - Contains the actual logic
unit MyAppMain;

interface

procedure RunApplication;

implementation

type
  TMyApp = class
    // All class definition here
  end;

procedure RunApplication;
var
  App: TMyApp;
begin
  App := TMyApp.Create;
  try
    // All complex logic here
    App.Run;
  finally
    App.Free;
  end;
end;

end.
```

#### Benefits

- Easier to test (can unit test the logic unit)
- Better code organization and maintainability
- Cleaner separation of concerns
- Reusable code across multiple projects
- Simpler .dpr files are easier to manage in version control

---

### Unit References

**IMPORTANT: Avoid path-based unit references in Pascal files (.pas)**

#### In .pas Files

DO NOT use the `in` clause with paths:

```pascal
// ❌ AVOID - Path-based references in .pas files
uses
  SomeUnit in '..\..\path\to\SomeUnit.pas',
  OtherUnit in '..\other\OtherUnit.pas';
```

**Correct approach:**

```pascal
// ✅ CORRECT - Simple unit names
uses
  SomeUnit,
  OtherUnit;
```

**Rationale:**
- Path-based references create tight coupling and brittle dependencies
- Makes code harder to refactor and reorganize
- Breaks when directory structures change
- Complicates code reuse across different projects

#### In Project Files (.dpr, .dpk)

Path-based `in` clauses should ONLY be used in project files:

```pascal
// ✅ ACCEPTABLE in .dpr/.dpk files only
program MyApplication;

uses
  MainUnit in 'src\MainUnit.pas',
  HelperUnit in 'src\utils\HelperUnit.pas';

begin
  // Program entry point
end.
```


