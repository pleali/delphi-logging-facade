# Stack Trace Module - Installation and Usage

## Overview

The stack trace module provides **automatic capture and display of stack traces during exceptions**. The module uses **dynamic BPL loading** (Windows only) to detect and load stack trace providers at runtime without compile-time dependencies.

## 🎯 Key Features

- ✅ **Zero Configuration** - BPL automatically loaded at startup
- ✅ **Zero Dependencies** - Core has no compile-time dependency on JCL
- ✅ **Flexible Deployment** - Deploy with or without stack trace BPL
- ✅ **Security** - In Release mode, BPL must be in exe directory
- ✅ **Graceful Degradation** - App works normally without BPL
- ✅ **Windows Only** - Uses Windows LoadPackage API

## 📁 Files

### Core (in LoggingFacade.dpk)
- `src/Logger.StackTrace.pas` - Stack trace interface and dynamic loader

### JclDebug Provider (separate package)
- `src/Logger.StackTrace.JclDebug.pas` - JCL Debug implementation
- `LoggingFacade.StackTrace.JclDebug.dpk` - Runtime package
- `LoggingFacade.StackTrace.JclDebug.dproj` - Project file

### Examples
- `examples/DynamicLoadingTest.dpr` - Demonstrates automatic BPL loading
- `examples/StackTraceTest/` - Complete test suite

## 🔨 Installation

### Prerequisites

**JEDI Code Library (JCL)** must be installed:
- Download from: https://github.com/project-jedi/jcl
- Install and configure in Delphi

### Step 1: Compile Core Package

```powershell
# From project root directory
powershell -ExecutionPolicy Bypass -File build-delphi.ps1 LoggingFacade.dproj -Clean
```

This produces `LoggingFacade.bpl` with dynamic loading support.

### Step 2: Compile JCL Debug Provider

```powershell
powershell -ExecutionPolicy Bypass -File build-delphi.ps1 LoggingFacade.StackTrace.JclDebug.dproj -Clean
```

This produces `LoggingFacade.StackTrace.JclDebug.bpl`.

The BPL is compiled to: `C:\Users\Public\Documents\Embarcadero\Studio\23.0\Bpl\`

### Step 3: Deploy BPL (for Release builds)

**Important:** For Release builds, copy the BPL to your executable directory:

```powershell
# Copy to your exe directory
Copy-Item "C:\Users\Public\Documents\Embarcadero\Studio\23.0\Bpl\LoggingFacade.StackTrace.JclDebug.bpl" "YourApp\bin\"
```

**For Debug builds**, the BPL can stay in the Delphi BPL directory (Windows will find it).

## 📦 Usage in Your Projects

### Recommended: Automatic Loading (Zero Configuration)

Simply use the logger - stack traces are automatically enabled if the BPL is available:

```delphi
program MyApp;

uses
  System.SysUtils,
  Logger.Factory,
  Logger.StackTrace;  // That's all you need!

begin
  // Configure logger
  TLoggerFactory.UseConsoleLogger(llDebug);

  // Stack traces automatically loaded from BPL if available
  // No manual configuration needed!

  // Use logger normally
  try
    DoSomething;
  except
    on E: Exception do
      Log.Error('Operation failed', E);
      // Stack trace included automatically if BPL was loaded
  end;
end.
```

### Alternative: Manual Loading (Advanced)

If you're using static linking instead of BPL:

```delphi
program MyApp;

uses
  System.SysUtils,
  Logger.Factory,
  Logger.StackTrace,
  Logger.StackTrace.JclDebug;  // Static linking

begin
  // Configure logger
  TLoggerFactory.UseConsoleLogger(llDebug);

  // Manually configure provider
  TStackTraceManager.SetProvider(TJclDebugStackTraceProvider.Create);
  TStackTraceManager.Enable;

  // Use logger normally
end.
```

## 🔍 Dynamic Loading Behavior

The system automatically tries to load `LoggingFacade.StackTrace.JclDebug.bpl` at startup.

### Release Mode (Production)

When compiled without `{$IFDEF DEBUG}` or no debugger attached:

| Situation | Behavior |
|-----------|----------|
| BPL not found | ✅ Silent - app runs normally without stack traces |
| BPL in exe directory | ✅ Loaded successfully - stack traces enabled |
| BPL in other directory | ⚠️ **Warning logged** + BPL unloaded + Disabled |

**Security:** In Release mode, the BPL **must** be in the same directory as the exe. This prevents loading potentially malicious BPLs from other locations.

### Debug Mode (Development)

When `{$IFDEF DEBUG}` is defined or debugger is attached:

| Situation | Behavior |
|-----------|----------|
| BPL in Windows search path | ✅ Loaded - stack traces enabled |
| BPL not found | ✅ Silent - normal for development |

**Flexibility:** In Debug mode, Windows searches standard BPL directories, making development easier.

### Check Loading Status

```delphi
// Check if stack traces are enabled
if TStackTraceManager.IsEnabled then
  WriteLn('Stack traces enabled!')
else
begin
  WriteLn('Stack traces disabled');

  // Check why (Windows only)
  {$IFDEF MSWINDOWS}
  if TStackTraceManager.GetLastError <> '' then
    WriteLn('Error: ', TStackTraceManager.GetLastError);
  {$ENDIF}
end;
```

## ✨ Features

### Automatic Exception Stack Traces

When stack traces are enabled, exceptions logged via `ILogger.Error()` or `ILogger.Fatal()` automatically include full stack traces:

```delphi
try
  ProcessData;
except
  on E: Exception do
    Log.Error('Processing failed', E);
    // Automatically includes stack trace!
end;
```

**Output:**
```
2025-01-24 15:30:45.123 ERROR : Processing failed - Exception: EAccessViolation: Access violation
Stack Trace:
  [007CAF30] MyUnit.ProcessData (Line 145)
  [007CAF7F] MyUnit.ValidateInput (Line 89)
  [007CAF8B] MyApp.Execute (Line 42)
  [007CAFDA] MyApp.Main (Line 15)
```

### Capture Current Stack Trace

Get a stack trace at any point (not just during exceptions):

```delphi
var StackTrace := TStackTraceManager.GetCurrentStackTrace;
Log.Debug('Current call stack: ' + StackTrace);
```

### Runtime Enable/Disable

```delphi
// Disable for production sections
TStackTraceManager.Disable;

// Re-enable when needed
TStackTraceManager.Enable;

// Check state
if TStackTraceManager.IsEnabled then
  ShowMessage('Stack traces active');
```

## 🔧 Compiler Settings for Best Results

To get detailed stack traces with function names and line numbers:

### Option A: Detailed Map Files

1. Project → Options → Linking
2. Set "Map file" to **Detailed**

### Option B: JCL Debug Information (Recommended)

1. Use JCL's "Insert JCL Debug Data" tool
2. Debug info is embedded directly in the executable
3. No separate .map file needed

Without these settings, stack traces show memory addresses only.

## 🎯 Deployment Scenarios

### Scenario 1: Production with Stack Traces

```
MyApp\
  ├── MyApp.exe
  ├── LoggingFacade.bpl
  └── LoggingFacade.StackTrace.JclDebug.bpl  ← Copy here
```

Stack traces will be enabled automatically.

### Scenario 2: Production without Stack Traces

```
MyApp\
  └── MyApp.exe
```

App runs normally, no stack traces. No BPL dependencies.

### Scenario 3: Development

```
C:\Users\Public\Documents\Embarcadero\Studio\23.0\Bpl\
  ├── LoggingFacade.bpl
  └── LoggingFacade.StackTrace.JclDebug.bpl
```

Windows finds BPLs automatically in Debug mode.

## 🔍 Troubleshooting

### "Stack traces not working"

1. **Check if enabled:**
   ```delphi
   WriteLn('Enabled: ', TStackTraceManager.IsEnabled);
   ```

2. **Check for errors:**
   ```delphi
   {$IFDEF MSWINDOWS}
   WriteLn('Error: ', TStackTraceManager.GetLastError);
   {$ENDIF}
   ```

3. **Common issues:**
   - BPL not in exe directory (Release mode)
   - Map file not detailed
   - JCL not installed

### "Stack traces show addresses only (no line numbers)"

**Solution:** Compile with detailed map files or use JCL "Insert JCL Debug Data" tool.

### "Warning: BPL loaded from wrong directory"

**Cause:** In Release mode, BPL was found outside exe directory.

**Solution:** Copy BPL to exe directory or deploy without stack trace BPL.

### "Cannot create output file .bpl"

**Cause:** BPL is locked by Delphi IDE.

**Solution:**
1. Close Delphi IDE
2. Or uninstall package from IDE
3. Recompile from command line

## ⚡ Performance

- **Disabled**: 0% overhead (zero cost)
- **Enabled**: ~1-2ms per exception (minimal)
- **Thread-safe**: Yes, uses critical sections
- **On-demand**: Stack traces captured only when exceptions occur

## 📚 Resources

- **Main README**: [README.md](README.md) - Complete documentation
- **JCL GitHub**: https://github.com/project-jedi/jcl
- **JCL Debug Docs**: https://wiki.delphi-jedi.org/wiki/JCL_Help:JclDebug
- **Example**: [examples/DynamicLoadingTest.dpr](examples/DynamicLoadingTest.dpr)

## 🚀 Quick Start

**1. Compile packages:**
```powershell
powershell -ExecutionPolicy Bypass -File build-delphi.ps1 LoggingFacade.dproj -Clean
powershell -ExecutionPolicy Bypass -File build-delphi.ps1 LoggingFacade.StackTrace.JclDebug.dproj -Clean
```

**2. For Release: Copy BPL to exe directory**

**3. In your code:**
```delphi
uses
  Logger.Factory,
  Logger.StackTrace;  // Automatic loading!

begin
  TLoggerFactory.UseConsoleLogger(llDebug);

  // That's it! Stack traces work automatically if BPL is available

  try
    DoWork;
  except
    on E: Exception do
      Log.Error('Error', E); // Stack trace included automatically
  end;
end.
```

## 📝 Architecture

```
Application Startup
    ↓
Logger.StackTrace initialization section
    ↓
TStackTraceManager.TryLoadBplProviders (Windows only)
    ↓
Tries to load LoggingFacade.StackTrace.JclDebug.bpl
    ↓
If successful → Calls CreateStackTraceProvider (exported)
    ↓
If IsAvailable → Enables stack traces
    ↓
Application runs normally
    ↓
On exception → Stack trace captured automatically
```

**Key Design:**
- ✅ Zero compile-time dependencies on JCL
- ✅ Dynamic BPL loading (Windows LoadPackage)
- ✅ Exported factory function in BPL
- ✅ Automatic enable/disable based on availability
- ✅ Security checks in Release mode
