# LoggingFacade

A flexible, SLF4J-inspired logging facade for Delphi that decouples your application code from specific logging implementations.

## Features

- **Interface-based Design**: Application code depends only on the `ILogger` interface
- **Multiple Implementations**:
  - Default console logger with colored output
  - Null logger for testing/disabling logs
  - Adapters for LoggerPro and QuickLogger
- **Factory Pattern**: Centralized logger creation and configuration
- **Zero Dependencies**: Core framework has no external dependencies
- **Modular Packages**: Separate BPL packages for core and adapters
- **Thread-Safe**: Factory implementation is thread-safe
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

The framework consists of three BPL packages:

1. **LoggingFacade.dpk** (Core - required)
   - Contains core interfaces, types, and default implementations
   - No external dependencies

2. **LoggingFacade.LoggerPro.dpk** (Optional)
   - Adapter for LoggerPro
   - Requires LoggerPro to be installed

3. **LoggingFacade.QuickLogger.dpk** (Optional)
   - Adapter for QuickLogger
   - Requires QuickLogger to be installed

**Installation steps:**
1. Install `LoggingFacade.dpk` (always required)
2. Install `LoggingFacade.LoggerPro.dpk` if using LoggerPro
3. Install `LoggingFacade.QuickLogger.dpk` if using QuickLogger

## Quick Start

### 1. Basic Usage (Default Console Logger)

```delphi
uses
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

  // Use LoggerPro through our facade
  TLoggerFactory.SetLogger(TLoggerProAdapter.Create(LLogWriter, llDebug));

  Log.Info('This goes to LoggerPro');
end;
```

### 5. Use QuickLogger

```delphi
uses
  Logger.Factory,
  Logger.QuickLogger.Adapter,
  Logger.Types,
  Quick.Logger,
  Quick.Logger.Provider.Files;

begin
  // Configure QuickLogger
  Quick.Logger.Logger.Providers.Add(TLogFileProvider.Create);

  // Use QuickLogger through our facade
  TLoggerFactory.SetLogger(TQuickLoggerAdapter.Create(llInfo));

  Log.Info('This goes to QuickLogger');
end;
```

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
  end;
```

### TLoggerFactory Class

```delphi
type
  TLoggerFactory = class
    // Get the global logger instance
    class function GetLogger: ILogger;

    // Set a custom factory function
    class procedure SetLoggerFactory(AFactoryFunc: TLoggerFactoryFunc);

    // Set a specific logger instance
    class procedure SetLogger(ALogger: ILogger);

    // Reset to default logger
    class procedure Reset;

    // Quick configuration methods
    class procedure UseConsoleLogger(AMinLevel: TLogLevel = llInfo;
                                     AUseColors: Boolean = True);
    class procedure UseNullLogger;
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

```delphi
// Preferred - cleaner and more efficient
LLogger.Info('Processing order #%d for user %s', [OrderId, Username]);

// Avoid - less efficient
LLogger.Info('Processing order #' + IntToStr(OrderId) + ' for user ' + Username);
```

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
│   ├── Logger.LoggerPro.Adapter.pas  - LoggerPro adapter
│   └── Logger.QuickLogger.Adapter.pas - QuickLogger adapter
├── examples/
│   ├── BasicExample/                 - Basic usage examples
│   ├── LoggerProExample/             - LoggerPro integration example
│   └── QuickLoggerExample/           - QuickLogger integration example
├── LoggingFacade.dpk                 - Core package
├── LoggingFacade.LoggerPro.dpk       - LoggerPro adapter package
├── LoggingFacade.QuickLogger.dpk     - QuickLogger adapter package
└── README.md                         - This file
```

## Examples

### Example 1: Simple Console Application

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

```delphi
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

```delphi
program LoggerProApp;

uses
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
  TLoggerFactory.SetLogger(TLoggerProAdapter.Create(LLogWriter, llDebug));

  // Use the facade
  Log.Debug('Application started with LoggerPro');
  Log.Info('Processing...');
  Log.Debug('Processing completed');
end.
```

### Example 4: Custom Logger Implementation

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
2. **Format Strings**: Use the format overloads instead of string concatenation
3. **Null Logger**: Use the null logger in production if logging is not needed
4. **Async Logging**: Consider using LoggerPro or QuickLogger for async logging in high-performance scenarios

## Using Adapter Packages

The framework uses a modular architecture where adapters are provided as separate BPL packages. This allows you to include only the logging libraries you actually use in your project.

### Package Dependencies

```
Your Application
    ↓ (requires)
LoggingFacade.dpk (core)
    ↓ (optionally requires)
LoggingFacade.LoggerPro.dpk
    ↓ (requires)
LoggerPro (external library)
```

### Step-by-Step: Using the LoggerPro Adapter

**1. Install Required Packages**

First, ensure you have:
- LoggerPro library installed (from https://github.com/danieleteti/loggerpro)
- `LoggingFacade.dpk` compiled and installed
- `LoggingFacade.LoggerPro.dpk` compiled and installed

**2. Add Package Reference to Your Project**

In your project's `.dproj` file or via IDE:
- Add `LoggingFacade` to required packages
- Add `LoggingFacade.LoggerPro` to required packages (only if using LoggerPro)

**3. Use in Your Code**

```delphi
program MyApp;

uses
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
  TLoggerFactory.SetLogger(TLoggerProAdapter.Create(GLogWriter, llDebug));
end;

begin
  InitializeLogging;

  // Use the facade normally
  Log.Info('Application started');
  // ...
end.
```

### Step-by-Step: Using the QuickLogger Adapter

**1. Install Required Packages**

First, ensure you have:
- QuickLogger library installed (from https://github.com/exilon/QuickLogger)
- `LoggingFacade.dpk` compiled and installed
- `LoggingFacade.QuickLogger.dpk` compiled and installed

**2. Add Package Reference to Your Project**

- Add `LoggingFacade` to required packages
- Add `LoggingFacade.QuickLogger` to required packages (only if using QuickLogger)

**3. Use in Your Code**

```delphi
program MyApp;

uses
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
  TLoggerFactory.SetLogger(TQuickLoggerAdapter.Create(llDebug));
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
TLoggerFactory.SetLogger(TLoggerProAdapter.Create(GLogWriter, llDebug));
Log.Info('Now using LoggerPro');

// Switch to QuickLogger
TLoggerFactory.SetLogger(TQuickLoggerAdapter.Create(llDebug));
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

### Step 4: Create the BPL Package

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
  LoggingFacade,
  YourLibraryPackage;  // Your library's package name

contains
  Logger.YourLibrary.Adapter in 'src\Logger.YourLibrary.Adapter.pas';

end.
```

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
