# Hierarchical Logging Demonstration

This example demonstrates the full power of the LoggingFacade's hierarchical configuration system, inspired by Logback.

## Overview

The demo consists of:
- **DataProcessorLib.bpl**: A library with 3-level hierarchy (validation, transform, export layers)
- **HierarchyApp.exe**: An application with 3-4 level hierarchy (UI, business, database layers)
- **Configuration files**: Showing hierarchical configuration with wildcards

## Architecture

### Application Hierarchy (app.*)

```
app
├── ui
│   └── mainform
├── business
│   └── orderprocessor
└── database
    ├── connection
    └── repository
        ├── orders
        └── customers
```

### Library Hierarchy (dataprocessor.*)

```
dataprocessor
├── validation
├── transform
│   ├── converter
│   └── mapper
└── export
    ├── csv
    └── json
```

## Configuration Examples

### Development (logging-debug.properties)

```properties
# Root fallback
root=INFO

# Application layers
app.ui.*=INFO
app.ui.mainform=DEBUG              # More specific rule
app.business.*=DEBUG
app.business.orderprocessor=TRACE  # Most specific wins!
app.database.*=DEBUG
app.database.connection=TRACE
app.database.repository.*=INFO
app.database.repository.orders=DEBUG

# Library layers
dataprocessor.*=DEBUG
dataprocessor.validation=TRACE
dataprocessor.transform.*=INFO
dataprocessor.transform.converter=DEBUG
dataprocessor.export.*=DEBUG
dataprocessor.export.csv=TRACE
```

### Production (logging.properties)

```properties
# Minimal overhead in production
root=WARN

# Application
app.ui.*=ERROR
app.business.*=INFO
app.business.orderprocessor=DEBUG  # Critical component
app.database.*=ERROR
app.database.connection=INFO       # Monitor connections

# Library
dataprocessor.*=WARN
dataprocessor.validation=INFO      # Data quality
dataprocessor.transform.*=ERROR
dataprocessor.export.*=WARN
```

## How It Works

### 1. Automatic Context Prefixing

Each unit uses `{$I Logger.AutoContext.inc}` to automatically register its namespace:

```delphi
unit App.Database.Repository.Orders;

implementation

{$I Logger.AutoContext.inc}  // <-- Automatically sets context to 'app.database.repository.orders'

constructor TOrdersRepository.Create;
begin
  // GetLogger('') automatically becomes 'app.database.repository.orders'
  FLogger := TLoggerFactory.GetLogger('');

  // GetLogger('queries') becomes 'app.database.repository.orders.queries'
  FQueryLogger := TLoggerFactory.GetLogger('queries');
end;
```

### 2. Hierarchical Resolution

For logger `app.database.repository.orders`, the framework searches:

1. `app.database.repository.orders` (exact match) ← **WINS if exists**
2. `app.database.repository.*` (parent wildcard)
3. `app.database.*` (grandparent wildcard)
4. `app.*` (great-grandparent wildcard)
5. `root` (fallback)

The **most specific matching rule wins**.

### 3. Configuration from BPL and Application

The demo shows logging from:
- **Application units** (compiled into .exe)
- **Library units** (from DataProcessorLib.bpl)

Both use the same configuration file and hierarchy resolution!

## Building the Demo

### Option 1: Static Linking (Recommended)

Compile HierarchyApp.dpr directly - it includes all sources:

```bash
powershell -ExecutionPolicy Bypass -File build-delphi.ps1 examples/HierarchicalDemo/HierarchyApp/HierarchyApp.dpr
```

### Option 2: With BPL (Advanced)

1. Compile the BPL first:
```bash
# Not yet implemented - use static linking
```

2. Compile the application:
```bash
# Will link against the BPL
```

## Running the Demo

1. **Copy configuration file** to the executable directory:
   ```bash
   copy examples\HierarchicalDemo\HierarchyApp\logging-debug.properties examples\HierarchicalDemo\HierarchyApp\
   ```

2. **Run the application**:
   ```bash
   examples\HierarchicalDemo\HierarchyApp\HierarchyApp.exe
   ```

3. **Observe the logs** showing:
   - Different log levels per component
   - Hierarchical prefixes (app.ui.mainform, dataprocessor.export.csv, etc.)
   - Wildcard pattern matching in action

## Testing Different Configurations

### Test 1: Verbose Everything
```properties
root=TRACE
```

### Test 2: Silence Everything Except Errors
```properties
root=ERROR
app.business.orderprocessor=INFO  # Keep critical logs
```

### Test 3: Focus on Database Layer
```properties
root=WARN
app.database.*=TRACE
```

### Test 4: Wildcard Specificity
```properties
app.*=ERROR                          # All app components = ERROR
app.database.*=INFO                  # Database layer = INFO (overrides app.*)
app.database.repository.orders=TRACE # Orders repo = TRACE (overrides app.database.*)
```

## Key Demonstration Points

1. **Automatic namespace detection** - No manual string prefixes needed
2. **Wildcard patterns** - Configure entire subsystems at once
3. **Hierarchical resolution** - Most specific rule wins
4. **Multi-level hierarchy** - Up to 4 levels deep
5. **Library + Application** - Logs from both BPL and EXE
6. **Dev/Prod configs** - Different configurations without code changes
7. **Runtime changes** - Levels can be changed programmatically

## Files

```
HierarchicalDemo/
├── DataProcessorLib/                    # BPL source
│   ├── src/
│   │   ├── DataProcessor.Validation.pas
│   │   ├── DataProcessor.Transform.Converter.pas
│   │   ├── DataProcessor.Transform.Mapper.pas
│   │   ├── DataProcessor.Export.Csv.pas
│   │   └── DataProcessor.Export.Json.pas
│   └── DataProcessorLib.dpk
│
├── HierarchyApp/                        # Application
│   ├── src/
│   │   ├── App.UI.MainForm.pas
│   │   ├── App.Business.OrderProcessor.pas
│   │   ├── App.Database.Connection.pas
│   │   ├── App.Database.Repository.Orders.pas
│   │   └── App.Database.Repository.Customers.pas
│   ├── HierarchyApp.dpr
│   ├── logging-debug.properties         # Dev config
│   └── logging.properties               # Prod config
│
└── README.md                            # This file
```

## Learn More

See the main [README.md](../../README.md) for complete LoggingFacade documentation.
