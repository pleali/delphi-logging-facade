# LoggingFacade Examples

This directory contains several example projects demonstrating different features of the LoggingFacade.

## ✅ Ready-to-Run Examples (No External Dependencies)

These examples work immediately without installing external libraries:

### 1. BasicExample
**Path:** `BasicExample/`
**What it demonstrates:**
- Basic console logging
- Changing log levels at runtime
- String formatting
- Exception logging
- Performance optimization with level checks

**To run:**
```bash
cd BasicExample
dcc32 -B BasicExample.dpr
BasicExample.exe
```

Or with the build script:
```bash
.\build-delphi.ps1 examples\BasicExample\BasicExample.dproj -Config Debug
```

---

### 2. ConfigExample
**Path:** `ConfigExample/`
**What it demonstrates:**
- External `.properties` configuration files
- Hierarchical logger configuration (Logback-style)
- Wildcard patterns (`mqtt.*=DEBUG`)
- Runtime configuration changes
- Automatic DEBUG/RELEASE config loading
- Logger context stacking

**To run:**
```bash
cd ConfigExample
dcc32 -B ConfigExample.dpr
ConfigExample.exe
```

Or:
```bash
.\build-delphi.ps1 examples\ConfigExample\ConfigExample.dproj -Config Debug
```

---

### 3. HierarchicalDemo
**Path:** `HierarchicalDemo/HierarchyApp/`
**What it demonstrates:**
- Multi-level hierarchical logging (up to 4 levels deep)
- Application structure: `app.ui.mainform`, `app.business.orderprocessor`, etc.
- Library structure: `dataprocessor.validation`, `dataprocessor.transform.converter`, etc.
- Configuration with wildcards at multiple levels
- Most specific rule wins (Logback resolution)
- Logs from both application code and library code
- DEBUG vs RELEASE configuration

**To run:**
```bash
cd HierarchicalDemo/HierarchyApp
dcc32 -B HierarchyApp.dpr
HierarchyApp.exe
```

Or:
```bash
.\build-delphi.ps1 examples\HierarchicalDemo\HierarchyApp\HierarchyApp.dproj -Config Debug
```

**Configuration files:**
- `logging-debug.properties` - Verbose logging for development
- `logging.properties` - Minimal logging for production

---

## ⚠️ Examples Requiring External Dependencies

### 4. QuickLoggerExample
**Path:** `QuickLoggerExample/`
**Status:** ⚠️ Requires external QuickLogger library

**Prerequisites:**
1. QuickLogger library installed from: https://github.com/exilon/QuickLogger
2. Either:
   - BPL packages compiled (`LoggingFacade.bpl`, `LoggingFacade.QuickLogger.bpl`)
   - OR source files configured for static linking

**See:** `QuickLoggerExample/README.md` for detailed setup instructions

---

### 5. LoggerProExample
**Path:** `LoggerProExample/` (if exists)
**Status:** ⚠️ Requires external LoggerPro library

**Prerequisites:**
1. LoggerPro library installed from: https://github.com/danieleteti/loggerpro
2. Either BPL packages or static linking configured

---

## Quick Start Guide

### Easiest Way to Test

Start with **BasicExample** - it has zero dependencies:

```bash
# From project root
cd examples/BasicExample
dcc32 -B BasicExample.dpr
BasicExample.exe
```

### Next Steps

1. **ConfigExample** - Learn about external configuration
2. **HierarchicalDemo** - See real-world multi-layer logging
3. **QuickLoggerExample** - Production-ready logging (requires setup)

### Compilation Notes

All examples include `.cfg` files for automatic path configuration when using `dcc32` directly.

For IDE compilation, use the `.dproj` files which have pre-configured unit search paths.

For script compilation:
```bash
# From project root
.\build-delphi.ps1 examples\<example-name>\<project-file>.dproj
```

## Configuration Files

Examples that support external configuration (`logging.properties` or `logging-debug.properties`):

- ✅ ConfigExample
- ✅ HierarchicalDemo
- ❌ BasicExample (uses programmatic configuration only)
- ⚠️ QuickLoggerExample (uses QuickLogger's own configuration)

## Troubleshooting

### "Unit 'Logger.Types' not found"
**Solution:** Ensure the `.cfg` file exists in the example directory, or compile using the build script.

### "Package 'LoggingFacade' not found"
**Solution:** The example is configured for BPL packages. Either:
1. Compile the BPL packages first
2. Switch to static linking (edit `.dproj` and remove `UsePackages`)

### Example doesn't compile
1. Check if it has external dependencies (see sections above)
2. Ensure you're compiling from the example's directory
3. Try using the build script: `.\build-delphi.ps1 examples\...\project.dproj`

## Additional Resources

- Main README: `../../README.md`
- API Documentation: See source code XML comments
- Configuration Guide: See `config/` directory examples
