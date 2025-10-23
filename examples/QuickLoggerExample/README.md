# QuickLogger Integration Example

## ⚠️ Prerequisites

This example requires **external dependencies** that must be installed separately:

### 1. QuickLogger Library

QuickLogger is an external logging library by Exilon that must be installed first.

**Installation:**
1. Download from: https://github.com/exilon/QuickLogger
2. Follow QuickLogger installation instructions
3. Ensure QuickLogger's units are in your Delphi library path

### 2. Two Compilation Options

#### Option A: Using BPL Packages (Dynamic Linking)

**Requirements:**
- QuickLogger BPL package compiled
- `LoggingFacade.bpl` compiled
- `LoggingFacade.QuickLogger.bpl` compiled

**Steps:**
1. Compile QuickLogger package
2. Compile `LoggingFacade.dpk` (in project root)
3. Compile `LoggingFacade.QuickLogger.dpk` (in project root)
4. Build this example: `msbuild QuickLoggerExample.dproj` or use Delphi IDE

**Current Configuration:**
This example is currently configured for BPL usage (see `.dproj` line 63-64):
```xml
<UsePackages>true</UsePackages>
<DCC_UsePackage>LoggingFacade.QuickLogger;LoggingFacade;$(DCC_UsePackage)</DCC_UsePackage>
```

#### Option B: Static Linking (Source Files)

If you prefer not to use BPL packages:

**Steps:**
1. Install QuickLogger library
2. Modify `QuickLoggerExample.dproj`:
   - Remove or set `<UsePackages>false</UsePackages>`
   - Remove `<DCC_UsePackage>` line
   - Add unit search paths to logging facade source:
   ```xml
   <DCC_UnitSearchPath>..\..\src;$(DCC_UnitSearchPath)</DCC_UnitSearchPath>
   ```

3. Update `QuickLoggerExample.cfg`:
   ```
   -U..\..\src
   -I..\..\src
   -O..\..\src
   -R..\..\src
   # Add QuickLogger path here:
   -U<path_to_quicklogger>\src
   ```

## What This Example Demonstrates

Once dependencies are installed, this example shows:

1. **QuickLogger Configuration**
   - Console output provider
   - File rotation provider
   - Multiple providers simultaneously

2. **Facade Integration**
   - Using QuickLogger through `TQuickLoggerAdapter`
   - Seamless integration with LoggingFacade

3. **Production Patterns**
   - Structured logging
   - Performance-conscious logging with level checks
   - API service logging example

4. **Output**
   - Console output with colors
   - Log file: `app.log` (with rotation)

## Running the Example

After installing prerequisites and compiling:

```bash
cd examples/QuickLoggerExample
QuickLoggerExample.exe
```

Check `app.log` for file output.

## Troubleshooting

**Error: "Unit 'Quick.Logger' not found"**
- QuickLogger is not installed or not in library path
- Solution: Install QuickLogger from https://github.com/exilon/QuickLogger

**Error: "Package 'LoggingFacade.QuickLogger' not found"**
- BPL packages not compiled
- Solution: Compile BPL packages first OR switch to static linking (Option B above)

**Error: "Unit 'Logger.Types' not found"**
- Source paths not configured
- Solution: Use Option B (static linking) and add unit search paths

## Alternative: Use BasicExample or ConfigExample

If you want to test LoggingFacade without external dependencies, use:
- **BasicExample** - Works out of the box with default console logger
- **ConfigExample** - Demonstrates configuration without external libraries
- **HierarchyApp** - Full hierarchical logging demo with default logger

These examples don't require QuickLogger and compile immediately.
