# StackTraceTest - Test Project for Stack Traces

This project contains an automated test suite to validate the stack trace capture module of LoggingFacade.

## 📋 Description

StackTraceTest is a console application that executes 10 different tests to validate all stack trace module functionalities.

**Note:** This test suite uses the **JCL Debug stack trace provider** (`Logger.StackTrace.JclDebug`) to capture real stack traces with actual function names and line numbers. This requires JCL to be installed.

### Tests Included:

1. **Initialization** - Verify initial manager state
2. **Enable/Disable** - Test activation/deactivation functions
3. **Exception Stack Trace** - Capture stack trace during exception
4. **Current Stack Trace** - Capture current stack trace
5. **Logger Integration** - Integration with logging system
6. **Format Exception Message** - Exception message formatting
7. **Disabled Manager** - Behavior when disabled
8. **Multiple Exception Types** - Support for different exception types
9. **Thread Safety** - Basic thread safety tests
10. **Provider Availability** - Provider availability verification

## 🔧 Prerequisites

### Required Packages

This test requires the following packages:
- `LoggingFacade.dproj` (core package)
- `LoggingFacade.StackTrace.JclDebug.dproj` (JCL Debug adapter package)
- **JEDI Code Library (JCL)** must be installed
  - Download from: https://github.com/project-jedi/jcl
  - Install and configure in Delphi

## 🔨 Compilation

### Step 1: Compile LoggingFacade Core Package

```powershell
# From LoggingFacade root directory
cd ..\..

# Compile core package
powershell -ExecutionPolicy Bypass -File build-delphi.ps1 LoggingFacade.dproj -Clean
```

### Step 2: Compile JCL Debug Adapter Package

```powershell
# Compile JCL Debug adapter package
powershell -ExecutionPolicy Bypass -File build-delphi.ps1 LoggingFacade.StackTrace.JclDebug.dproj -Clean
```

### Step 3: Compile StackTraceTest

```powershell
# Option A: Command line
powershell -ExecutionPolicy Bypass -File build-delphi.ps1 "examples/StackTraceTest/StackTraceTest.dproj" -Clean

# Option B: From Delphi IDE
# 1. Open StackTraceTest.dproj in Delphi
# 2. Project → Options → Linking → Map file: Detailed
# 3. Project → Build StackTraceTest
```

### Important Configuration

To get stack traces with line numbers:

**Project → Options → Linking → Map file: Detailed**

Or use JCL's "Insert JCL Debug Data" tool on the compiled executable.

## 🚀 Execution

### From command line

```cmd
cd examples\StackTraceTest\Win32\Debug
StackTraceTest.exe
```

### From IDE

1. Open `StackTraceTest.dproj`
2. Press F9 (Run)
3. Observe console output

## 📊 Expected Output

```
========================================
LoggingFacade - Stack Trace Test Suite
========================================

Running tests...

Test 1: StackTraceManager Initialization
Test 2: Enable/Disable functionality
Test 3: Exception stack trace capture
Stack trace captured:
  [007CAF30] StackTraceTest.StackTraceTest.Level3_ThrowException (Line 126)
  [007CAF7F] StackTraceTest.StackTraceTest.Level2_CallLevel3 (Line 131)
  [007CAF8B] StackTraceTest.StackTraceTest.Level1_CallLevel2 (Line 136)
  [007CAFDA] StackTraceTest.StackTraceTest.Test_ExceptionStackTrace (Line 146)
  [007D4549] StackTraceTest.StackTraceTest.StackTraceTest (Line 414)

Test 4: Current stack trace capture
Current stack trace:
  [007972A0] Logger.StackTrace.Logger.StackTrace.TStackTraceManager.GetCurrentStackTrace (Line 219)
  [007CB37E] StackTraceTest.StackTraceTest.Test_CurrentStackTrace (Line 184)
  [007D454E] StackTraceTest.StackTraceTest.StackTraceTest (Line 415)

Test 5: Logger integration with stack traces
2025-10-24 16:24:28.955 ERROR : Test error with exception - Exception: Exception: Test exception from Level 3
Stack Trace:
  [007CAF30] StackTraceTest.StackTraceTest.Level3_ThrowException (Line 126)
  [007CAF7F] StackTraceTest.StackTraceTest.Level2_CallLevel3 (Line 131)
  [007CAF8B] StackTraceTest.StackTraceTest.Level1_CallLevel2 (Line 136)
  [007CB669] StackTraceTest.StackTraceTest.Test_LoggerIntegration (Line 216)
  [007D4553] StackTraceTest.StackTraceTest.StackTraceTest (Line 416)
Test 6: Format exception message
Test 7: Stack trace when manager is disabled
Test 8: Multiple exception types
Test 9: Thread safety (basic)
Test 10: Provider availability check

========================================
Test Results Summary
========================================

[PASS] StackTraceManager starts disabled
[PASS] Enable stack traces
[PASS] Disable stack traces
[PASS] Exception stack trace capture
[PASS] Current stack trace capture
[PASS] Logger integration
[PASS] Format exception message
[PASS] Stack trace when disabled
[PASS] Multiple exception types
[PASS] Thread safety (basic)
[PASS] Provider availability

Total: 11 tests
Passed: 11
Failed: 0

All tests passed!

Press ENTER to exit...
```

**Note:** The memory addresses `[007CAF30]` and line numbers may vary depending on your compilation settings and Delphi version. The important part is that you see real function names (like `Level3_ThrowException`) and actual line numbers.

## ❌ Troubleshooting

### Error: "Undeclared identifier: 'TJclStackBaseInfo'"

**Cause:** JCL is not installed or not in library path

**Solution:**
1. Install JCL (see Prerequisites section)
2. Verify library paths in Delphi
3. Restart Delphi after JCL installation

### Error: "Cannot find Logger.StackTrace.pas"

**Cause:** Incorrect search paths

**Solution:**
- Project → Options → Delphi Compiler → Search path
- Add: `..\..\src`

### Error: "Cannot create output file .bpl"

**Cause:** BPL locked by IDE

**Solution:**
1. Close Delphi completely
2. Recompile from command line
3. Or uninstall packages in IDE

### Tests fail: Empty stack traces or no line numbers

**Cause:** No debug info

**Solution:**
- Project → Options → Linking → Map file: **Detailed**
- Or use JCL "Insert JCL Debug Data" tool
- Recompile project

### Error: "JCL exception tracking not active"

**Cause:** Logger.StackTrace.JclDebug module not loaded

**Solution:**
- Verify `uses Logger.StackTrace.JclDebug;` is present
- JCL tracking is activated automatically in initialization section

## 📚 Project Structure

```
StackTraceTest/
├── StackTraceTest.dpr       - Main test application
├── StackTraceTest.dproj     - Delphi project file
├── StackTraceTest.res       - Resources
└── README.md                - This file
```

## 🧪 Adding Your Own Tests

To add a new test:

```delphi
procedure Test_MyNewFeature;
begin
  Writeln('Test XX: My new feature');
  try
    // Your test code here

    // If test succeeds
    AddTestResult('My new feature', True);

    // If test fails
    // AddTestResult('My new feature', False, 'Reason for failure');
  except
    on E: Exception do
      AddTestResult('My new feature', False, E.Message);
  end;
end;

// In the begin..end main block, add:
Test_MyNewFeature;
```

## 📝 Notes

- Tests are executed in order
- Each test is independent
- Results are displayed at the end
- Exit code is 0 if all tests pass

## 🔗 Resources

- **Complete documentation**: `..\..\README.md` section "Stack Trace Capture"
- **Setup guide**: `..\..\STACK_TRACE_SETUP.md`
- **JCL GitHub**: https://github.com/project-jedi/jcl
- **JCL Wiki**: https://wiki.delphi-jedi.org/

## ⚡ Quick Start (if JCL already installed)

```powershell
# From LoggingFacade root directory
# Compile core package
powershell -ExecutionPolicy Bypass -File build-delphi.ps1 LoggingFacade.dproj -Clean

# Compile JCL Debug adapter
powershell -ExecutionPolicy Bypass -File build-delphi.ps1 LoggingFacade.StackTrace.JclDebug.dproj -Clean

# Compile and run test
powershell -ExecutionPolicy Bypass -File build-delphi.ps1 "examples/StackTraceTest/StackTraceTest.dproj" -Clean
examples\StackTraceTest\Win32\Debug\StackTraceTest.exe
```
