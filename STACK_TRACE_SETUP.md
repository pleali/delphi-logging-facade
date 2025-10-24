# Stack Trace Module - Installation and Usage

## Overview

The stack trace module is now integrated into LoggingFacade. It allows automatic capture and display of stack traces during exceptions.

## 📁 Created Files

### Core (in LoggingFacade.dpk)
- `src/Logger.StackTrace.pas` - Stack trace interface and manager

### JclDebug Adapter (separate package)
- `src/Logger.StackTrace.JclDebug.pas` - Implementation with JCL Debug
- `LoggingFacade.StackTrace.JclDebug.dpk` - Runtime package
- `LoggingFacade.StackTrace.JclDebug.dproj` - Project file

### Example
- `examples/StackTraceExample/StackTraceExample.dpr` - Complete demonstration application

## 🔨 Compilation

### Prerequisites

1. **JEDI Code Library (JCL)** must be installed
   - Download from: https://github.com/project-jedi/jcl
   - Install and configure in Delphi

2. **Close Delphi IDE** if a LoggingFacade package is loaded

### Step 1: Compile core package

```powershell
# From project root directory
powershell -ExecutionPolicy Bypass -File build-delphi.ps1 LoggingFacade.dproj -Clean
```

Or from Delphi IDE:
1. Open `LoggingFacade.dproj`
2. Project → Build LoggingFacade
3. Verify that `Logger.StackTrace.pas` is included

### Step 2: Compile JclDebug package

```powershell
powershell -ExecutionPolicy Bypass -File build-delphi.ps1 LoggingFacade.StackTrace.JclDebug.dproj -Clean
```

Or from Delphi IDE:
1. Open `LoggingFacade.StackTrace.JclDebug.dproj`
2. Project → Build LoggingFacade.StackTrace.JclDebug

### Step 3: Test the example

```powershell
powershell -ExecutionPolicy Bypass -File build-delphi.ps1 examples\StackTraceExample\StackTraceExample.dpr
```

**Important:** To get detailed stack traces with line numbers:
- Project → Options → Linking → Map file: **Detailed**
- Or use JCL "Insert JCL Debug Data" tool

## 📦 Usage in Your Projects

### Option A: Dynamic Linking (BPL)

1. **Add runtime packages** in your `.dproj`:

```xml
<Requires>
  <Package>LoggingFacade</Package>
  <Package>LoggingFacade.StackTrace.JclDebug</Package>
  <Package>Jcl</Package>
  <Package>rtl</Package>
</Requires>
```

2. **In your code**:

```delphi
program MyApp;

uses
  System.SysUtils,
  Logger.Factory,
  Logger.StackTrace,
  Logger.StackTrace.JclDebug;

begin
  // Configure logger
  TLoggerFactory.UseConsoleLogger(llDebug);

  // Enable stack trace capture
  TStackTraceManager.SetProvider(TJclDebugStackTraceProvider.Create);
  TStackTraceManager.Enable;

  // Exceptions now include stack traces
  try
    // Your code
    raise Exception.Create('Test');
  except
    on E: Exception do
      Log.Error('An error occurred', E);
      // Automatically displays complete stack trace
  end;
end.
```

### Option B: Static Linking (source files)

1. **Add search paths**:
   - Project → Options → Delphi Compiler → Search path
   - Add: `$(LoggingFacadeDir)\src`

2. **In your code** (same as Option A above)

3. **Install JCL** and ensure it's in the library path

## ✨ Features

### Dynamic Enable/Disable

```delphi
// Enable
TStackTraceManager.Enable;

// Disable (zero overhead)
TStackTraceManager.Disable;

// Check state
if TStackTraceManager.IsEnabled then
  ShowMessage('Stack traces are active');
```

### Capture Current Stack Trace

```delphi
// Get stack trace at any point
var StackTrace := TStackTraceManager.GetCurrentStackTrace;
Log.Debug('Call stack: ' + StackTrace);
```

### Output Examples

**Without stack trace**:
```
2025-01-24 15:30:45.123 ERROR : Operation failed - Exception: EAccessViolation: Access violation
```

**With stack trace**:
```
2025-01-24 15:30:45.123 ERROR : Operation failed - Exception: EAccessViolation: Access violation
Stack Trace:
  [00401234] MyUnit.ProcessData (Line 145)
  [00401567] MyUnit.ValidateInput (Line 89)
  [00401890] MyApp.Execute (Line 42)
  [00402123] MyApp.Main (Line 15)
```

## 🎯 Best Practices

### For Development
```delphi
{$IFDEF DEBUG}
  // Enable in DEBUG mode
  TStackTraceManager.SetProvider(TJclDebugStackTraceProvider.Create);
  TStackTraceManager.Enable;
{$ENDIF}
```

### For Production
```delphi
{$IFDEF RELEASE}
  // Disable or enable as needed
  TStackTraceManager.Disable;
{$ENDIF}
```

### Compiler Configuration

**For best stack traces**:
1. **Detailed map file**:
   - Project → Options → Linking
   - Map file: **Detailed**

2. **Or JCL Debug Info** (recommended):
   - Use JCL "Insert JCL Debug Data" tool
   - No separate .map file needed
   - Debug info embedded in exe

## 🔍 Troubleshooting

### "JclDebug unit not found"
→ JCL is not installed or not in library path

### "Stack trace not available"
→ Verify that:
1. `TStackTraceManager.Enable` was called
2. JclDebug provider is configured
3. JCL tracking is active (automatic with Logger.StackTrace.JclDebug)

### Stack traces without line numbers
→ Compile with:
- Detailed map file, OR
- Embedded JCL Debug Data

### Error "Cannot create output file .bpl"
→ BPL is locked:
1. Close Delphi IDE
2. Or uninstall package
3. Recompile

## 📚 Resources

- **JCL GitHub**: https://github.com/project-jedi/jcl
- **JCL Debug Documentation**: https://wiki.delphi-jedi.org/wiki/JCL_Help:JclDebug
- **Complete example**: `examples/StackTraceExample/StackTraceExample.dpr`
- **Complete documentation**: `README.md` section "Stack Trace Capture"

## 🚀 Quick Start

```delphi
// 1. Uses clause
uses
  Logger.Factory,
  Logger.StackTrace,
  Logger.StackTrace.JclDebug;

// 2. Initialization (at app startup)
begin
  TLoggerFactory.UseConsoleLogger(llDebug);
  TStackTraceManager.SetProvider(TJclDebugStackTraceProvider.Create);
  TStackTraceManager.Enable;

  // 3. Normal usage - automatic stack traces
  try
    DoSomething;
  except
    on E: Exception do
      Log.Error('Error', E); // Stack trace included automatically
  end;
end.
```

## ⚡ Performance

- **Disabled**: No overhead (0% impact)
- **Enabled**: Minimal overhead (~1-2ms per exception)
- **Thread-safe**: Yes, safe for multi-threading
- **On-demand capture**: Stack traces formatted only during exceptions

## 📝 Architecture

```
Application
    ↓
ILogger.Error(msg, exception)
    ↓
TConsoleLogger (or other implementation)
    ↓
TStackTraceManager.FormatExceptionMessage
    ↓
IStackTraceProvider (TJclDebugStackTraceProvider)
    ↓
JCL Debug Library
```

**Key Points**:
- ✅ Core module without dependencies (Logger.StackTrace.pas)
- ✅ JclDebug adapter in separate package
- ✅ Strategy pattern to support other providers
- ✅ Enable/disable at runtime
- ✅ Transparent for existing code
