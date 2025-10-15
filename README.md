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
