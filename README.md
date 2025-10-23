# LoggingFacade

A flexible, SLF4J-inspired logging facade for Delphi that decouples your application code from specific logging implementations.

## Features

- **Interface-based Design**: Application code depends only on the `ILogger` interface
- **Multiple Implementations**:
  - Default console logger with colored output
  - Null logger for testing/disabling logs
  - Adapters for LoggerPro and QuickLogger
- **Factory Pattern**: Centralized logger creation and configuration
- **External Configuration**: Logback-style `.properties` files with hierarchical resolution
  - Automatic loading based on DEBUG/RELEASE builds
  - Wildcard patterns (`mqtt.*=INFO`)
  - Most specific rule wins
  - Runtime reconfiguration support
- **Named Loggers**: Component-level logging with Spring Boot-style formatting
  - Hierarchical logger names (e.g., `MyApp.Database`)
  - Cached logger instances for performance
  - Automatic name formatting in output
- **Zero Dependencies**: Core framework has no external dependencies
- **Modular Packages**: Separate BPL packages for core and adapters
- **Thread-Safe**: Factory and configuration are thread-safe
- **Cross-Platform**: Compatible with Windows, Linux, macOS
- **Modern Delphi**: Compatible with Delphi 10.x+
- **Easy to Extend**: Add your own logger implementations by implementing `ILogger`

## Architecture

```
┌─────────────────┐
│ Application     │
│ Code            │
└────────┬────────┘
         │
         │ depends on
         ▼
┌─────────────────┐
│ ILogger         │
│ Interface       │
└────────┬────────┘
         │
         │ implemented by
         ▼
┌─────────────────────────────────────────┐
│ TConsoleLogger                          │
│ TNullLogger                             │
│ TLoggerProAdapter                       │
│ TQuickLoggerAdapter                     │
│ ... (your custom implementations)       │
└─────────────────────────────────────────┘
```

## Default Logger vs Production Logging

**Important Note**: The default `TConsoleLogger` provided by this facade is a basic implementation designed for:
- Development and debugging
- Console applications
- Simple logging scenarios
- Learning and testing

While the default logger is **thread-safe**, it is **not optimized for production use** and lacks advanced features such as:
- Asynchronous logging
- Log rotation and archiving
- Multiple output targets (file, database, network)
- Structured logging
- Performance optimization for high-volume logging
- Advanced filtering and formatting

**For production applications**, we strongly recommend using one of the supported external logging libraries:
- **LoggerPro**: High-performance, async logging with multiple appenders
- **QuickLogger**: Feature-rich with providers for files, console, email, databases, etc.

These libraries are specifically designed for production workloads and offer the performance, reliability, and features required by enterprise applications.

The facade pattern allows you to start development with the simple default logger and seamlessly switch to a production-ready library when needed, without changing your application code.

## Installation

The framework provides packages (`.dpk` files) that can be used in two ways:

### Option 1: Dynamic Linking (Runtime Packages)

Use BPL files for shared components across multiple applications or to reduce executable size.

1. **Compile the packages:**
   - Open `LoggingFacade.dpk` in Delphi and compile it (F9) → generates `LoggingFacade.bpl`
   - If using LoggerPro: compile `LoggingFacade.LoggerPro.dpk` → generates `LoggingFacade.LoggerPro.bpl`
   - If using QuickLogger: compile `LoggingFacade.QuickLogger.dpk` → generates `LoggingFacade.QuickLogger.bpl`

2. **Add runtime packages to your application's `.dproj` file:**

For basic usage (console logger only):
```xml
<Requires>
  <Package>LoggingFacade</Package>
  <Package>rtl</Package>
</Requires>
```

For LoggerPro integration:
```xml
<Requires>
  <Package>LoggingFacade</Package>
  <Package>LoggingFacade.LoggerPro</Package>
  <Package>LoggerPro</Package>
  <Package>rtl</Package>
</Requires>
```

For QuickLogger integration:
```xml
<Requires>
  <Package>LoggingFacade</Package>
  <Package>LoggingFacade.QuickLogger</Package>
  <Package>QuickLogger</Package>
  <Package>rtl</Package>
</Requires>
```

### Option 2: Static Linking (Include Source Files)

Include the source files directly in your project for a single executable with no external dependencies.

1. **Add source paths to your project:**
   - Copy or link the source files from `src/` directory to your project
   - Alternatively, add the directory to your project's search paths: Project → Options → Source

2. **Use units directly in your application:**
```delphi
uses
  Logger.Intf,
  Logger.Factory;

begin
  Log.Info('Application started');
end;
```

This approach produces a standalone executable without requiring any BPL files at runtime.

## Quick Start

### 1. Basic Usage (Default Console Logger)

```delphi
uses
  Logger.Intf,
  Logger.Factory;

var
  LLogger: ILogger;
begin
  LLogger := Log;  // Get the global logger

  LLogger.Info('Application started');
  LLogger.Debug('Debug information');
  LLogger.Warn('Warning message');
  LLogger.Error('Error message');
end;
```

**Required Runtime Packages for this example:**
- `LoggingFacade` (core package)

### 2. Configure Log Level

```delphi
uses
  Logger.Factory, Logger.Types;

begin
  // Configure console logger with DEBUG level
  TLoggerFactory.UseConsoleLogger(llDebug, True);

  Log.Debug('This will now appear');
  Log.Trace('This will not appear (below DEBUG level)');
end;
```

### 3. Use Null Logger (Disable Logging)

```delphi
uses
  Logger.Factory;

begin
  // Disable all logging
  TLoggerFactory.UseNullLogger;

  Log.Info('This message will be discarded');
end;
```

### 4. Use LoggerPro

```delphi
uses
  Logger.Intf,
  Logger.Factory,
  Logger.LoggerPro.Adapter,
  Logger.Types,
  LoggerPro,
  LoggerPro.FileAppender;

var
  LLogWriter: ILogWriter;
begin
  // Create LoggerPro logger with file appender
  LLogWriter := BuildLogWriter([TLoggerProFileAppender.Create(10, 5, 'logs')]);

  // Use LoggerPro through our facade (3 params: name, logWriter, minLevel)
  TLoggerFactory.SetLogger(TLoggerProAdapter.Create('', LLogWriter, llDebug));

  Log.Info('This goes to LoggerPro');
end;
```

**Required Runtime Packages for this example:**
- `LoggingFacade` (core package)
- `LoggingFacade.LoggerPro` (LoggerPro adapter package)
- `LoggerPro` (external logging library package)

### 5. Use QuickLogger

```delphi
uses
  Logger.Intf,
  Logger.Factory,
  Logger.QuickLogger.Adapter,
  Logger.Types,
  Quick.Logger,
  Quick.Logger.Provider.Files;

begin
  // Configure QuickLogger
  Quick.Logger.Logger.Providers.Add(TLogFileProvider.Create);

  // Use QuickLogger through our facade (2 params: name, minLevel)
  TLoggerFactory.SetLogger(TQuickLoggerAdapter.Create('', llInfo));

  Log.Info('This goes to QuickLogger');
end;
```

**Required Runtime Packages for this example:**
- `LoggingFacade` (core package)
- `LoggingFacade.QuickLogger` (QuickLogger adapter package)
- `QuickLogger` (external logging library package)

### 6. Named Loggers (Component-Level Logging)

Named loggers allow you to organize logs by component or module, similar to Spring Boot's logging system:

```delphi
uses
  Logger.Intf,
  Logger.Factory;

var
  LLoggerMain: ILogger;
  LLoggerDb: ILogger;
  LLoggerApi: ILogger;
begin
  // Get named loggers for different components
  LLoggerMain := TLoggerFactory.GetLogger('MyApp.Main');
  LLoggerDb := TLoggerFactory.GetLogger('MyApp.Database');
  LLoggerApi := TLoggerFactory.GetLogger('MyApp.ApiClient');

  // Each logger adds its name to the output (Spring Boot style)
  LLoggerMain.Info('Application initialized');
  // Output: 2025-01-15 10:30:45.123 INFO  [                             MyApp.Main] : Application initialized

  LLoggerDb.Debug('Connection established');
  // Output: 2025-01-15 10:30:45.456 DEBUG [                         MyApp.Database] : Connection established

  LLoggerApi.Warn('Rate limit approaching');
  // Output: 2025-01-15 10:30:45.789 WARN  [                        MyApp.ApiClient] : Rate limit approaching

  // Root logger (no name) still works
  Log.Info('Application started');
  // Output: 2025-01-15 10:30:45.000 INFO  : Application started
end;
```

**Benefits of Named Loggers:**
- **Organization**: Group logs by component, module, or layer
- **Identification**: Instantly see which part of your application generated the log
- **Debugging**: Quickly filter logs when troubleshooting specific components
- **Performance**: Loggers are cached - getting the same named logger multiple times is very fast

**Best Practices:**
- Use hierarchical names: `MyApp.Module.Component`
- Store logger in class fields for performance:
  ```delphi
  type
    TApiClient = class
    private
      FLogger: ILogger;
    public
      constructor Create;
    end;

  constructor TApiClient.Create;
  begin
    inherited;
    FLogger := TLoggerFactory.GetLogger('MyApp.ApiClient');
  end;
  ```
- Root logger (no name) is fastest - use for simple applications

## Log Levels

The framework supports the following log levels (from most verbose to most severe):

| Level | Description | Use Case |
|-------|-------------|----------|
| `llTrace` | Very detailed information | Fine-grained debugging |
| `llDebug` | Debug information | Developer diagnostics |
| `llInfo` | Informational messages | General application flow |
| `llWarn` | Warning messages | Potentially harmful situations |
| `llError` | Error messages | Error events that might still allow the app to continue |
| `llFatal` | Fatal messages | Severe errors that will lead the app to abort |

## Advanced Configuration

### Configuration Files (Logback-style)

The framework supports external configuration files using the Java `.properties` format for portable, cross-platform configuration:

**Automatic Loading:**
- DEBUG builds: automatically loads `logging-debug.properties`
- RELEASE builds: automatically loads `logging.properties`

**File Format:**
```properties
# Comments start with #
root=INFO

# Exact logger names
MyApp.Database=DEBUG
MyApp.Network=INFO

# Hierarchical patterns with wildcards
mqtt.*=INFO
mqtt.transport.ics=TRACE

# The most specific rule wins
```

**Hierarchical Resolution (inspired by Logback):**

For a logger named `mqtt.transport.ics`, the framework searches in this order:
1. `mqtt.transport.ics` (exact match)
2. `mqtt.transport.*` (parent wildcard)
3. `mqtt.*` (grandparent wildcard)
4. `root` (fallback)

The most specific matching rule wins.

**Example Configuration:**

```properties
# logging-debug.properties (development)
root=DEBUG
MyApp.*=TRACE
mqtt.*=DEBUG
mqtt.core=INFO

# logging.properties (production)
root=WARN
MyApp.*=INFO
mqtt.*=ERROR
```

**API Methods:**

```delphi
// Manual loading
TLoggerFactory.LoadConfig('path/to/config.properties');

// Reload configuration at runtime
TLoggerFactory.ReloadConfig;

// Set level programmatically
TLoggerFactory.SetLoggerLevel('mqtt.*', llDebug);

// Query configured level
LLevel := TLoggerFactory.GetConfiguredLevel('MyApp.Database');
```


## API Reference

### ILogger Interface

```delphi
type
  ILogger = interface
    // Logging methods
    procedure Trace(const AMessage: string); overload;
    procedure Trace(const AMessage: string; const AArgs: array of const); overload;

    procedure Debug(const AMessage: string); overload;
    procedure Debug(const AMessage: string; const AArgs: array of const); overload;

    procedure Info(const AMessage: string); overload;
    procedure Info(const AMessage: string; const AArgs: array of const); overload;

    procedure Warn(const AMessage: string); overload;
    procedure Warn(const AMessage: string; const AArgs: array of const); overload;

    procedure Error(const AMessage: string); overload;
    procedure Error(const AMessage: string; const AArgs: array of const); overload;
    procedure Error(const AMessage: string; AException: Exception); overload;

    procedure Fatal(const AMessage: string); overload;
    procedure Fatal(const AMessage: string; const AArgs: array of const); overload;
    procedure Fatal(const AMessage: string; AException: Exception); overload;

    // Level checking
    function IsTraceEnabled: Boolean;
    function IsDebugEnabled: Boolean;
    function IsInfoEnabled: Boolean;
    function IsWarnEnabled: Boolean;
    function IsErrorEnabled: Boolean;
    function IsFatalEnabled: Boolean;

    // Configuration
    procedure SetLevel(ALevel: TLogLevel);
    function GetLevel: TLogLevel;

    // Logger identification
    function GetName: string;
  end;
```

### TLoggerFactory Class

```delphi
type
  TLoggerFactory = class
    // Get logger instance (with optional name for component-level logging)
    class function GetLogger(const AName: string = ''): ILogger;

    // Set a custom factory function
    class procedure SetLoggerFactory(AFactoryFunc: TLoggerFactoryFunc);

    // Set a custom named logger factory function
    class procedure SetNamedLoggerFactory(AFactoryFunc: TNamedLoggerFactoryFunc);

    // Set a specific logger instance
    class procedure SetLogger(ALogger: ILogger);

    // Reset to default logger
    class procedure Reset;

    // Quick configuration methods
    class procedure UseConsoleLogger(AMinLevel: TLogLevel = llInfo;
                                     AUseColors: Boolean = True);
    class procedure UseNullLogger;

    // Logger name formatting configuration
    class procedure SetLoggerNameWidth(AWidth: Integer);
    class function GetLoggerNameWidth: Integer;

    // Configuration management
    class procedure LoadConfig(const AFileName: string = '');
    class procedure ReloadConfig;
    class procedure SetLoggerLevel(const ALoggerName: string; ALevel: TLogLevel);
    class function GetConfiguredLevel(const ALoggerName: string;
                                      ADefaultLevel: TLogLevel = llInfo): TLogLevel;
    class procedure ClearConfig;
  end;
```

### Global Function

```delphi
// Convenience function - equivalent to TLoggerFactory.GetLogger
function Log: ILogger;
```

## Best Practices

### 1. Check Log Level for Expensive Operations

```delphi
// Bad - always constructs expensive string
LLogger.Debug('Data: ' + ExpensiveOperation());

// Good - only constructs if debug is enabled
if LLogger.IsDebugEnabled then
  LLogger.Debug('Data: ' + ExpensiveOperation());
```

### 2. Use Format Overloads

**Always use the overloaded methods with arguments instead of pre-formatting strings.** This is critical for performance because the formatting only occurs if the log level is enabled.

```delphi
// GOOD - Formatting only happens if Info level is enabled
LLogger.Info('Processing order #%d for user %s', [OrderId, Username]);

// BAD - Format() is always executed, even if Info level is disabled!
LLogger.Info(Format('Processing order #%d for user %s', [OrderId, Username]));

// ALSO BAD - String concatenation always occurs
LLogger.Info('Processing order #' + IntToStr(OrderId) + ' for user ' + Username);
```

**Why this matters:** When using `Log.Info(Format(...))`, the `Format()` call is executed *before* the method is called, so the string formatting happens even if the Info level is disabled. With `Log.Info('...', [...])`, the internal implementation only formats the string if the log level is enabled, avoiding unnecessary CPU cycles.

### 3. Log Exceptions Properly

```delphi
try
  DoSomething();
except
  on E: Exception do
  begin
    LLogger.Error('Operation failed', E);  // Logs exception details
    raise;
  end;
end;
```

### 4. Configure Logger at Application Startup

```delphi
program MyApp;

uses
  Logger.Factory;

begin
  // Configure logging once at startup
  TLoggerFactory.UseConsoleLogger(llDebug);

  // Rest of application...
end.
```

### 5. Use Dependency Injection in Classes

```delphi
type
  TMyService = class
  private
    FLogger: ILogger;
  public
    constructor Create;
    procedure DoWork;
  end;

constructor TMyService.Create;
begin
  inherited Create;
  FLogger := Log;  // Get logger in constructor
end;

procedure TMyService.DoWork;
begin
  FLogger.Info('Starting work');
  // ...
end;
```

## Project Structure

```
LoggingFacade/
├── src/
│   ├── Logger.Types.pas              - Log level types and helpers
│   ├── Logger.Intf.pas               - ILogger interface
│   ├── Logger.Default.pas            - Default console logger
│   ├── Logger.Null.pas               - Null logger (no output)
│   ├── Logger.Factory.pas            - Logger factory (singleton)
│   ├── Logger.Config.pas             - Configuration manager (.properties parser)
│   ├── Logger.LoggerPro.Adapter.pas  - LoggerPro adapter
│   └── Logger.QuickLogger.Adapter.pas - QuickLogger adapter
├── examples/
│   ├── BasicExample/                 - Basic usage examples
│   ├── ConfigExample/                - Advanced configuration demo
│   ├── config/                       - Example configuration files
│   │   ├── logging-debug.properties  - Development config
│   │   └── logging.properties        - Production config
│   ├── LoggerProExample/             - LoggerPro integration example
│   └── QuickLoggerExample/           - QuickLogger integration example
├── LoggingFacade.dpk                 - Core package
├── LoggingFacade.LoggerPro.dpk       - LoggerPro adapter package
├── LoggingFacade.QuickLogger.dpk     - QuickLogger adapter package
└── README.md                         - This file
```

## Examples

> **Note:** The examples show two approaches: dynamic linking with runtime packages (easiest) or static linking by including source files directly in your project (see Installation section for details).


### Example 1: Simple Console Application

**Runtime Packages Required:** `LoggingFacade`

```delphi
program SimpleApp;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Logger.Factory,
  Logger.Types;

begin
  try
    // Configure logger
    TLoggerFactory.UseConsoleLogger(llDebug, True);

    // Use logger
    Log.Info('Application started');
    Log.Debug('Debug mode enabled');

    // Simulate work
    try
      Log.Info('Processing data...');
      // ... do work ...
      Log.Info('Processing completed');
    except
      on E: Exception do
      begin
        Log.Error('Processing failed', E);
        raise;
      end;
    end;

    Log.Info('Application finished');
  except
    on E: Exception do
    begin
      Writeln('FATAL: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
```

### Example 2: Service Class with Logging

**Runtime Packages Required:** `LoggingFacade`

```delphi
uses
  Logger.Intf,
  Logger.Factory;

type
  TDataService = class
  private
    FLogger: ILogger;
  public
    constructor Create;
    function GetUserById(AUserId: Integer): TUser;
  end;

constructor TDataService.Create;
begin
  inherited Create;
  FLogger := Log;
end;

function TDataService.GetUserById(AUserId: Integer): TUser;
begin
  FLogger.Debug('Fetching user with ID: %d', [AUserId]);

  try
    Result := FDatabase.QueryUser(AUserId);

    if Result = nil then
    begin
      FLogger.Warn('User not found: %d', [AUserId]);
      Exit(nil);
    end;

    FLogger.Info('User retrieved: %s', [Result.Username]);
  except
    on E: Exception do
    begin
      FLogger.Error('Failed to fetch user %d', E);
      raise;
    end;
  end;
end;
```

### Example 3: LoggerPro Integration

**Runtime Packages Required:** `LoggingFacade`, `LoggingFacade.LoggerPro`, `LoggerPro`

```delphi
program LoggerProApp;

uses
  Logger.Intf,
  Logger.Factory,
  Logger.LoggerPro.Adapter,
  Logger.Types,
  LoggerPro,
  LoggerPro.FileAppender,
  LoggerPro.OutputDebugStringAppender;

var
  LLogWriter: ILogWriter;
begin
  // Create LoggerPro with multiple appenders
  LLogWriter := BuildLogWriter([
    TLoggerProFileAppender.Create(10, 5, 'logs'),
    TLoggerProOutputDebugStringAppender.Create
  ]);

  // Configure facade to use LoggerPro
  TLoggerFactory.SetLogger(TLoggerProAdapter.Create('', LLogWriter, llDebug));

  // Use the facade
  Log.Debug('Application started with LoggerPro');
  Log.Info('Processing...');
  Log.Debug('Processing completed');
end.
```

### Example 4: Custom Logger Implementation

**Runtime Packages Required:** `LoggingFacade`

```delphi
type
  TMyCustomLogger = class(TInterfacedObject, ILogger)
  private
    procedure LogMessage(ALevel: TLogLevel; const AMessage: string);
  public
    // Implement all ILogger methods
    procedure Info(const AMessage: string); overload;
    procedure Info(const AMessage: string; const AArgs: array of const); overload;
    // ... etc ...
  end;

procedure TMyCustomLogger.LogMessage(ALevel: TLogLevel; const AMessage: string);
begin
  // Your custom logging logic here
  // e.g., send to a remote server, database, etc.
end;

// Use your custom logger
TLoggerFactory.SetLogger(TMyCustomLogger.Create);
```

## Testing

When writing unit tests, use the null logger to disable logging output:

```delphi
procedure TMyTests.SetUp;
begin
  inherited;
  TLoggerFactory.UseNullLogger;  // Disable logging during tests
end;

procedure TMyTests.TearDown;
begin
  TLoggerFactory.Reset;  // Reset to default
  inherited;
end;
```

## Performance Considerations

1. **Level Checking**: Always check if a log level is enabled before expensive operations
2. **Format Overloads**: **Never use `Format()` or string concatenation before calling log methods.** Always use the overloaded methods with arguments (e.g., `Log.Info('User %s', [Name])` instead of `Log.Info(Format('User %s', [Name]))`). This ensures formatting only occurs when the log level is enabled, avoiding unnecessary CPU cycles.
3. **Null Logger**: Use the null logger in production if logging is not needed
4. **Async Logging**: Consider using LoggerPro or QuickLogger for async logging in high-performance scenarios

## Using Adapter Packages

The framework provides adapter packages that can optionally be used for dynamic linking. You can also integrate adapters by including their source files directly in your project for static linking (see Installation section).

### Package Dependencies

```
Your Application
    ↓ (runtime dependency on)
LoggingFacade.bpl (core runtime package)
    ↓ (optionally runtime dependency on)
LoggingFacade.LoggerPro.bpl (adapter runtime package)
    ↓ (runtime dependency on)
LoggerPro.bpl (external library runtime package)
```

### Step-by-Step: Using the LoggerPro Adapter

#### Option A: Dynamic Linking (Runtime Packages)

**1. Compile the Packages**

Ensure you have:
- LoggerPro library installed (from https://github.com/danieleteti/loggerpro)
- Compile `LoggingFacade.dpk` → produces `LoggingFacade.bpl`
- Compile `LoggingFacade.LoggerPro.dpk` → produces `LoggingFacade.LoggerPro.bpl`

**2. Add Runtime Packages to Your Project**

In your project's `.dproj` file:

```xml
<Requires>
  <Package>LoggingFacade</Package>
  <Package>LoggingFacade.LoggerPro</Package>
  <Package>LoggerPro</Package>
  <Package>rtl</Package>
</Requires>
```

Or use the IDE: Project → Options → Packages → Runtime packages

#### Option B: Static Linking (Include Source Files)

Add the LoggingFacade and LoggerPro adapter source files to your project search paths:
- Add `LoggingFacade/src` to your project paths
- Add the adapter unit `Logger.LoggerPro.Adapter.pas` to your project

**3. Use in Your Code**

```delphi
program MyApp;

uses
  Logger.Intf,
  Logger.Factory,
  Logger.LoggerPro.Adapter,
  Logger.Types,
  LoggerPro,
  LoggerPro.FileAppender;

var
  GLogWriter: ILogWriter;

procedure InitializeLogging;
begin
  // Create LoggerPro instance
  GLogWriter := BuildLogWriter([
    TLoggerProFileAppender.Create(10, 5, 'logs')
  ]);

  // Configure facade to use LoggerPro
  TLoggerFactory.SetLogger(TLoggerProAdapter.Create('', GLogWriter, llDebug));
end;

begin
  InitializeLogging;

  // Use the facade normally
  Log.Info('Application started');
  // ...
end.
```

### Step-by-Step: Using the QuickLogger Adapter

#### Option A: Dynamic Linking (Runtime Packages)

**1. Compile the Packages**

Ensure you have:
- QuickLogger library installed (from https://github.com/exilon/QuickLogger)
- Compile `LoggingFacade.dpk` → produces `LoggingFacade.bpl`
- Compile `LoggingFacade.QuickLogger.dpk` → produces `LoggingFacade.QuickLogger.bpl`

**2. Add Runtime Packages to Your Project**

In your project's `.dproj` file:

```xml
<Requires>
  <Package>LoggingFacade</Package>
  <Package>LoggingFacade.QuickLogger</Package>
  <Package>QuickLogger</Package>
  <Package>rtl</Package>
</Requires>
```

Or use the IDE: Project → Options → Packages → Runtime packages

#### Option B: Static Linking (Include Source Files)

Add the LoggingFacade and QuickLogger adapter source files to your project search paths:
- Add `LoggingFacade/src` to your project paths
- Add the adapter unit `Logger.QuickLogger.Adapter.pas` to your project

**3. Use in Your Code**

```delphi
program MyApp;

uses
  Logger.Intf,
  Logger.Factory,
  Logger.QuickLogger.Adapter,
  Logger.Types,
  Quick.Logger,
  Quick.Logger.Provider.Files;

procedure InitializeLogging;
begin
  // Configure QuickLogger providers
  Quick.Logger.Logger.Providers.Add(TLogFileProvider.Create);

  // Configure facade to use QuickLogger
  TLoggerFactory.SetLogger(TQuickLoggerAdapter.Create('', llDebug));
end;

begin
  InitializeLogging;

  // Use the facade normally
  Log.Info('Application started');
  // ...
end.
```

### Switching Between Adapters at Runtime

You can switch logging implementations at runtime without changing application code:

```delphi
// Start with console logger
TLoggerFactory.UseConsoleLogger(llDebug);
Log.Info('Using console logger');

// Switch to LoggerPro
TLoggerFactory.SetLogger(TLoggerProAdapter.Create('', GLogWriter, llDebug));
Log.Info('Now using LoggerPro');

// Switch to QuickLogger
TLoggerFactory.SetLogger(TQuickLoggerAdapter.Create('', llDebug));
Log.Info('Now using QuickLogger');

// Disable logging completely
TLoggerFactory.UseNullLogger;
```

### Adapter Package Benefits

1. **No Forced Dependencies**: Your application doesn't need LoggerPro or QuickLogger unless you explicitly use them
2. **Smaller Binaries**: Only include what you use
3. **Easy Migration**: Switch between logging libraries by changing one line of code
4. **Testing**: Use null logger in tests, real logger in production

## Creating a Custom Adapter

To integrate a new logging framework with LoggingFacade, follow these steps:

> **Note on Packages:** You can optionally create a runtime package (`.dpk` file) for your adapter to enable dynamic linking. Alternatively, applications can use your adapter by including the source files directly in their projects (static linking).

### Step 1: Create the Adapter Unit

Create a new unit following the naming convention: `Logger.YourFramework.Adapter.pas`

```delphi
unit Logger.YourLibrary.Adapter;

interface

uses
  System.SysUtils,
  Logger.Intf,
  Logger.Types,
  YourLoggingLibrary;  // Your external logging library

type
  /// <summary>
  /// Adapter for YourLibrary logging framework
  /// </summary>
  TYourLibraryAdapter = class(TInterfacedObject, Logger.Intf.ILogger)
  private
    FMinLevel: Logger.Types.TLogLevel;
    FYourLogger: TYourLibraryLogger;  // Your library's logger instance

    function IsLevelEnabled(ALevel: Logger.Types.TLogLevel): Boolean;
  public
    constructor Create(AYourLogger: TYourLibraryLogger;
                       AMinLevel: Logger.Types.TLogLevel = Logger.Types.llInfo);
    destructor Destroy; override;

    // ILogger implementation
    procedure Trace(const AMessage: string); overload;
    procedure Trace(const AMessage: string; const AArgs: array of const); overload;

    procedure Debug(const AMessage: string); overload;
    procedure Debug(const AMessage: string; const AArgs: array of const); overload;

    procedure Info(const AMessage: string); overload;
    procedure Info(const AMessage: string; const AArgs: array of const); overload;

    procedure Warn(const AMessage: string); overload;
    procedure Warn(const AMessage: string; const AArgs: array of const); overload;

    procedure Error(const AMessage: string); overload;
    procedure Error(const AMessage: string; const AArgs: array of const); overload;
    procedure Error(const AMessage: string; AException: Exception); overload;

    procedure Fatal(const AMessage: string); overload;
    procedure Fatal(const AMessage: string; const AArgs: array of const); overload;
    procedure Fatal(const AMessage: string; AException: Exception); overload;

    function IsTraceEnabled: Boolean;
    function IsDebugEnabled: Boolean;
    function IsInfoEnabled: Boolean;
    function IsWarnEnabled: Boolean;
    function IsErrorEnabled: Boolean;
    function IsFatalEnabled: Boolean;

    procedure SetLevel(ALevel: Logger.Types.TLogLevel);
    function GetLevel: Logger.Types.TLogLevel;
  end;

implementation

constructor TYourLibraryAdapter.Create(AYourLogger: TYourLibraryLogger;
                                       AMinLevel: Logger.Types.TLogLevel);
begin
  inherited Create;
  FYourLogger := AYourLogger;
  FMinLevel := AMinLevel;
end;

destructor TYourLibraryAdapter.Destroy;
begin
  // Clean up if needed
  inherited;
end;

function TYourLibraryAdapter.IsLevelEnabled(ALevel: Logger.Types.TLogLevel): Boolean;
begin
  Result := ALevel >= FMinLevel;
end;

procedure TYourLibraryAdapter.Info(const AMessage: string);
begin
  if IsLevelEnabled(Logger.Types.llInfo) then
    FYourLogger.LogInfo(AMessage);  // Call your library's method
end;

procedure TYourLibraryAdapter.Info(const AMessage: string; const AArgs: array of const);
begin
  if IsLevelEnabled(Logger.Types.llInfo) then
    FYourLogger.LogInfo(Format(AMessage, AArgs));
end;

// Implement other methods similarly...

function TYourLibraryAdapter.IsInfoEnabled: Boolean;
begin
  Result := IsLevelEnabled(Logger.Types.llInfo);
end;

procedure TYourLibraryAdapter.SetLevel(ALevel: Logger.Types.TLogLevel);
begin
  FMinLevel := ALevel;
end;

function TYourLibraryAdapter.GetLevel: Logger.Types.TLogLevel;
begin
  Result := FMinLevel;
end;

end.
```

### Step 2: Handle Type Conflicts

If your logging library defines its own `TLogLevel` or `ILogger`, use qualified names to avoid conflicts:

```delphi
// Always qualify types from the facade
FMinLevel: Logger.Types.TLogLevel;  // Our facade's TLogLevel

// Qualify your library's types
FLibraryLevel: YourLibrary.TLogLevel;  // Library's TLogLevel

// Qualify interface implementations
TYourAdapter = class(TInterfacedObject, Logger.Intf.ILogger)
```

### Step 3: Map Log Levels

Create a mapping between facade log levels and your library's levels:

```delphi
function TYourLibraryAdapter.MapLogLevel(ALevel: Logger.Types.TLogLevel): TYourLibraryLevel;
begin
  case ALevel of
    Logger.Types.llTrace: Result := YourLibrary.lvTrace;
    Logger.Types.llDebug: Result := YourLibrary.lvDebug;
    Logger.Types.llInfo:  Result := YourLibrary.lvInfo;
    Logger.Types.llWarn:  Result := YourLibrary.lvWarning;
    Logger.Types.llError: Result := YourLibrary.lvError;
    Logger.Types.llFatal: Result := YourLibrary.lvFatal;
  else
    Result := YourLibrary.lvInfo;
  end;
end;
```

### Step 4: Create the BPL Package (Optional for Dynamic Linking)

If you want to support dynamic linking, create a runtime package `LoggingFacade.YourLibrary.dpk` for your adapter. This is optional - applications can also use your adapter by including the source files directly.

Create `LoggingFacade.YourLibrary.dpk`:

```pascal
package LoggingFacade.YourLibrary;

{$R *.res}
{$ALIGN 8}
{$ASSERTIONS ON}
{$BOOLEVAL OFF}
{$DEBUGINFO OFF}
{$EXTENDEDSYNTAX ON}
{$IMPORTEDDATA ON}
{$IOCHECKS ON}
{$LOCALSYMBOLS ON}
{$LONGSTRINGS ON}
{$OPENSTRINGS ON}
{$OPTIMIZATION OFF}
{$OVERFLOWCHECKS ON}
{$RANGECHECKS ON}
{$REFERENCEINFO ON}
{$SAFEDIVIDE OFF}
{$STACKFRAMES ON}
{$TYPEDADDRESS OFF}
{$VARSTRINGCHECKS ON}
{$WRITEABLECONST OFF}
{$MINENUMSIZE 1}
{$IMAGEBASE $400000}
{$DESCRIPTION 'LoggingFacade - YourLibrary adapter'}
{$RUNONLY}
{$IMPLICITBUILD ON}

requires
  rtl,
  LoggingFacade,        // Core LoggingFacade package
  YourLibraryPackage;   // Your library's package name

contains
  Logger.YourLibrary.Adapter in 'src\Logger.YourLibrary.Adapter.pas';

end.
```

**For applications using your package dynamically**, add to their `.dproj` file:
```xml
<Requires>
  <Package>LoggingFacade</Package>
  <Package>LoggingFacade.YourLibrary</Package>
  <Package>YourLibraryPackage</Package>
  <Package>rtl</Package>
</Requires>
```

**For static linking**, applications simply include the source file in their project instead.

### Step 5: Create an Example

Create `examples/YourLibraryExample/YourLibraryExample.dpr`:

```delphi
program YourLibraryExample;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Logger.Factory,
  Logger.YourLibrary.Adapter,
  Logger.Types,
  YourLoggingLibrary;

var
  GYourLogger: TYourLibraryLogger;

procedure ConfigureLogging;
begin
  // Initialize your library
  GYourLogger := TYourLibraryLogger.Create;
  GYourLogger.OutputFile := 'app.log';

  // Configure facade to use your adapter
  TLoggerFactory.SetLogger(TYourLibraryAdapter.Create(GYourLogger, llDebug));
end;

begin
  try
    ConfigureLogging;

    Log.Info('Application started with YourLibrary');
    Log.Debug('Debug message');
    Log.Warn('Warning message');

    Writeln('Check app.log for output');
    Readln;
  except
    on E: Exception do
    begin
      Writeln('Error: ', E.Message);
      Readln;
    end;
  end;
end.
```

### Step 6: Add Documentation

Update your adapter's unit documentation with:

1. **Usage instructions**
2. **Dependencies and version requirements**
3. **Known limitations or special considerations**
4. **Example code**

```delphi
/// <summary>
/// Adapter that bridges ILogger interface to YourLibrary.
///
/// Usage:
///   var Logger: TYourLibraryLogger;
///   Logger := TYourLibraryLogger.Create;
///   TLoggerFactory.SetLogger(TYourLibraryAdapter.Create(Logger));
///
/// Requirements:
///   - YourLibrary v2.0 or later
///   - Windows/macOS/Linux compatible
///
/// Notes:
///   - YourLibrary doesn't support Trace level, maps to Debug
///   - Thread-safe if YourLibrary instance is thread-safe
/// </summary>
```

### Step 7: Testing Checklist

Before publishing your adapter:

- [ ] All ILogger methods implemented
- [ ] Type conflicts resolved with qualified names
- [ ] Log level mapping tested
- [ ] Exception handling tested
- [ ] Thread safety considered
- [ ] Memory leaks checked
- [ ] Example application works
- [ ] Documentation complete
- [ ] BPL package compiles
- [ ] No warnings in strict mode

### Adapter Best Practices

1. **Stateless if possible**: Don't maintain state unless necessary
2. **Thread-safe**: Document thread-safety guarantees
3. **Performance**: Check log levels before formatting messages
4. **Resource management**: Properly manage any resources (file handles, connections)
5. **Error handling**: Never let adapter exceptions crash the application
6. **Documentation**: Provide clear usage examples

## Contributing

To add support for a new logging framework:

1. Create a new adapter unit (e.g., `Logger.MyFramework.Adapter.pas`)
2. Implement the `ILogger` interface
3. Map the log levels appropriately
4. Create a new BPL package (e.g., `LoggingFacade.MyFramework.dpk`)
5. Add an example in the `examples/` directory

## License

This is free and unencumbered software released into the public domain.

## Acknowledgments

- Inspired by [SLF4J](http://www.slf4j.org/) (Simple Logging Facade for Java)
- Compatible with [LoggerPro](https://github.com/danieleteti/loggerpro)
- Compatible with [QuickLogger](https://github.com/exilon/QuickLogger)

## Version History

- **1.1.0** - Configuration & Named Logger Support
  - **External Configuration**: Logback-style `.properties` files
    - Automatic loading based on DEBUG/RELEASE builds
    - Hierarchical resolution with wildcard patterns
    - Runtime configuration changes
  - **Named Loggers**: Component-level logging
    - Support for hierarchical logger names
    - Spring Boot-style formatting
    - Cached logger instances for performance
  - **New Components**:
    - `Logger.Config.pas` - Configuration manager
  - **Extended API**:
    - `LoadConfig()`, `ReloadConfig()`, `SetLoggerLevel()`
    - `GetConfiguredLevel()`, `ClearConfig()`
    - `GetName()` in ILogger interface
    - `SetLoggerNameWidth()`, `GetLoggerNameWidth()`
    - `SetNamedLoggerFactory()` for adapter support
  - **Examples**:
    - ConfigExample demonstrating configuration features
    - Updated BasicExample with config demos
    - Example `.properties` files for dev/prod

- **1.0.0** - Initial release
  - Core interface and factory
  - Default console logger
  - Null logger
  - LoggerPro adapter
  - QuickLogger adapter
  - Modular BPL packages
  - Complete examples

## Support

For issues, questions, or contributions, please open an issue on the project repository.
