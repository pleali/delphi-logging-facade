# LoggingFacade for Delphi

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A flexible, SLF4J-inspired logging facade for Delphi that decouples application code from specific logging implementations through a clean interface-based architecture.

## Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [Quick Start Guide](#quick-start-guide)
  - [Minimal Example](#minimal-example)
  - [With Configuration](#with-configuration)
  - [Exception Logging with Stack Traces](#exception-logging-with-stack-traces)
- [ILogger Interface](#ilogger-interface)
  - [Logging Methods](#logging-methods)
  - [Complete Interface Definition](#complete-interface-definition)
  - [Usage Examples](#usage-examples)
- [Hierarchical Configuration System](#hierarchical-configuration-system)
  - [Understanding LoggerFactory](#understanding-loggerfactory)
  - [Hierarchical Logger Names](#hierarchical-logger-names)
  - [Configuration Files](#configuration-files)
  - [Wildcard Patterns](#wildcard-patterns)
  - [Runtime Configuration](#runtime-configuration)
- [Installation](#installation)
  - [Dynamic Linking (BPL)](#dynamic-linking-bpl)
  - [Static Linking (Source Files)](#static-linking-source-files)
- [Advanced Usage](#advanced-usage)
  - [Using LoggerPro Adapter](#using-loggerpro-adapter)
  - [Using QuickLogger Adapter](#using-quicklogger-adapter)
  - [Custom Logger Implementation](#custom-logger-implementation)
  - [Stack Trace Configuration](#stack-trace-configuration)
- [Examples](#examples)
- [Best Practices](#best-practices)
- [Architecture](#architecture)
  - [Design Principles](#design-principles)
  - [Component Architecture](#component-architecture)
  - [Thread Safety](#thread-safety)
- [Log Levels](#log-levels)
- [Configuration Reference](#configuration-reference)
- [API Reference](#api-reference)
- [Troubleshooting](#troubleshooting)
- [Migration Guide](#migration-guide)

## Overview

LoggingFacade provides a unified logging interface for Delphi applications, allowing you to write code against a common API while switching between different logging implementations as needed. Inspired by SLF4J (Simple Logging Facade for Java) and Logback, it brings enterprise-grade logging patterns to the Delphi ecosystem.

**Perfect for:**
- Large applications with multiple teams or modules
- Library development without forcing specific logging implementations
- Microservices with different logging strategies per service
- Testing environments requiring easy mocking or disabling of logs

## Key Features

- **🎭 Interface-Based Design**: Application code depends only on `ILogger` interface
- **🌳 Hierarchical Logger Names**: SLF4J/Logback-style hierarchical logger management with `TLoggerFactory`
- **⚙️ External Configuration**: Properties files with hierarchical resolution and wildcards
- **🔄 Hot Reload**: Runtime configuration changes without restart
- **📚 Multiple Implementations**: Console, Null, LoggerPro, QuickLogger adapters
- **🔍 Stack Trace Support**: Optional exception stack traces with JCL Debug
- **🔒 Thread-Safe**: Concurrent-safe factory and configuration
- **⚡ Performance Optimized**: Logger caching, lazy initialization

## Quick Start Guide

### Minimal Example

Get started in 30 seconds:

```delphi
program QuickStart;

uses
  Logger.Factory, Logger.Intf;

var
  Logger: ILogger;
begin
  // Get a logger (uses default console logger)
  Logger := TLoggerFactory.GetLogger('MyApp');

  // Log messages
  Logger.Info('Application started');
  Logger.Debug('Processing data...');
  Logger.Error('Something went wrong!');
end.
```

### With Configuration

Create `logging.properties`:
```properties
root=WARN
MyApp=DEBUG
MyApp.Database=TRACE
```

```delphi
program ConfiguredLogging;

uses
  Logger.Factory, Logger.Intf, Logger.Types;

type
  TDatabaseManager = class
  private
    FLogger: ILogger;
  public
    constructor Create;
    procedure Connect;
  end;

constructor TDatabaseManager.Create;
begin
  FLogger := TLoggerFactory.GetLogger('MyApp.Database');
end;

procedure TDatabaseManager.Connect;
begin
  FLogger.Debug('Connecting to database...');
  // Connection logic
  FLogger.Info('Connected successfully');
end;

var
  DbManager: TDatabaseManager;
begin
  // Configuration loads automatically from logging.properties

  DbManager := TDatabaseManager.Create;
  try
    DbManager.Connect;
  finally
    DbManager.Free;
  end;
end.
```

### Exception Logging with Stack Traces

```delphi
program ExceptionLogging;

uses
  System.SysUtils,
  Logger.Factory, Logger.Intf,
  Logger.StackTrace.Loader;  // Enable stack traces

procedure RiskyOperation;
var
  Logger: ILogger;
begin
  Logger := TLoggerFactory.GetLogger('MyApp.Critical');

  try
    // Something that might fail
    raise Exception.Create('Database connection lost');
  except
    on E: Exception do
    begin
      Logger.Error('Operation failed', E);  // Logs with stack trace
      raise;
    end;
  end;
end;

begin
  try
    RiskyOperation;
  except
    on E: Exception do
      WriteLn('Application error: ' + E.Message);
  end;
end.
```

## ILogger Interface

The `ILogger` interface is the core contract that all loggers implement. Your application code should depend only on this interface, never on concrete implementations.

### Logging Methods

Each log level has multiple overloads for different use cases:

```delphi
// Basic message
Logger.Info('Application started');

// Message with format arguments
Logger.Info('Processing order #%d', [OrderId]);

// Message with exception (ERROR and FATAL only)
Logger.Error('Database connection failed', DatabaseException);

// Message with format arguments and exception (all levels)
Logger.Error('Failed to process order #%d', [OrderId], OrderException);
```

### Complete Interface Definition

```delphi
ILogger = interface
  ['{B9A7E5D1-4F2C-4E8D-A3B6-7C8D9E0F1A2B}']

  // TRACE level
  procedure Trace(const AMessage: string); overload;
  procedure Trace(const AMessage: string; const AArgs: array of const); overload;
  procedure Trace(const AMessage: string; const AArgs: array of const; AException: Exception); overload;

  // DEBUG level
  procedure Debug(const AMessage: string); overload;
  procedure Debug(const AMessage: string; const AArgs: array of const); overload;
  procedure Debug(const AMessage: string; const AArgs: array of const; AException: Exception); overload;

  // INFO level
  procedure Info(const AMessage: string); overload;
  procedure Info(const AMessage: string; const AArgs: array of const); overload;
  procedure Info(const AMessage: string; const AArgs: array of const; AException: Exception); overload;

  // WARN level
  procedure Warn(const AMessage: string); overload;
  procedure Warn(const AMessage: string; const AArgs: array of const); overload;
  procedure Warn(const AMessage: string; const AArgs: array of const; AException: Exception); overload;

  // ERROR level - includes additional overload without format args
  procedure Error(const AMessage: string); overload;
  procedure Error(const AMessage: string; const AArgs: array of const); overload;
  procedure Error(const AMessage: string; AException: Exception); overload;
  procedure Error(const AMessage: string; const AArgs: array of const; AException: Exception); overload;

  // FATAL level - includes additional overload without format args
  procedure Fatal(const AMessage: string); overload;
  procedure Fatal(const AMessage: string; const AArgs: array of const); overload;
  procedure Fatal(const AMessage: string; AException: Exception); overload;
  procedure Fatal(const AMessage: string; const AArgs: array of const; AException: Exception); overload;

  // Level checking - use before expensive operations
  function IsTraceEnabled: Boolean;
  function IsDebugEnabled: Boolean;
  function IsInfoEnabled: Boolean;
  function IsWarnEnabled: Boolean;
  function IsErrorEnabled: Boolean;
  function IsFatalEnabled: Boolean;

  // Configuration
  procedure SetLevel(ALevel: TLogLevel);
  function GetLevel: TLogLevel;
  function GetName: string;
end;
```

### Usage Examples

**Basic logging:**
```delphi
Logger.Info('User logged in');
Logger.Debug('Configuration loaded from file');
Logger.Warn('Cache miss for key: users:123');
```

**Formatted messages:**
```delphi
Logger.Info('Processing %d items in %d ms', [ItemCount, ElapsedTime]);
Logger.Debug('User %s accessed resource %s', [Username, ResourceName]);
```

**Exception logging:**
```delphi
try
  // Risky operation
  Database.Connect;
except
  on E: Exception do
  begin
    // Log with simple message
    Logger.Error('Database connection failed', E);

    // Or with formatted message
    Logger.Error('Failed to connect to %s:%d', [Host, Port], E);
    raise;
  end;
end;
```

**Performance optimization with level checks:**
```delphi
// Avoid expensive operations when level is disabled
if Logger.IsDebugEnabled then
begin
  var DebugInfo := BuildExpensiveDebugString();
  Logger.Debug('Debug info: %s', [DebugInfo]);
end;

// Simple messages don't need level checks
Logger.Info('Operation completed');  // Very low overhead
```

## Hierarchical Configuration System

**This is the most powerful feature of LoggingFacade** - it allows you to control logging output across your entire application using hierarchical logger names and configuration files.

### Understanding LoggerFactory

`TLoggerFactory` is the central component that:
- **Creates loggers** using hierarchical names (e.g., `MyApp.Database.Connection`)
- **Caches logger instances** for performance
- **Manages configuration** from `.properties` files
- **Resolves log levels** hierarchically based on logger names

Think of it as the "control center" for all your logging.

### Hierarchical Logger Names

Loggers are organized in a hierarchy using dot notation, similar to Java packages or .NET namespaces:

```delphi
var
  AppLogger := TLoggerFactory.GetLogger('MyApp');
  DbLogger := TLoggerFactory.GetLogger('MyApp.Database');
  ConnLogger := TLoggerFactory.GetLogger('MyApp.Database.Connection');
  ApiLogger := TLoggerFactory.GetLogger('MyApp.API.REST');
```

**Each logger inherits configuration from its parent:**
- `MyApp.Database.Connection` inherits from `MyApp.Database`
- `MyApp.Database` inherits from `MyApp`
- `MyApp` inherits from `root`

This means you can configure entire subsystems at once, then override specific components as needed.

### Configuration Files

Configuration files use a simple properties format:

```properties
# Root logger - fallback for everything
root=INFO

# Configure entire application at DEBUG
MyApp=DEBUG

# But database layer needs only INFO
MyApp.Database=INFO

# Except connection pool which needs TRACE for debugging
MyApp.Database.ConnectionPool=TRACE
```

**Automatic Loading:**
- **DEBUG builds**: Looks for `logging-debug.properties`
- **RELEASE builds**: Looks for `logging.properties`

**Search locations:**
1. Current directory
2. Executable directory
3. Parent of executable directory

### Wildcard Patterns

Use wildcards to configure multiple loggers at once:

```properties
# Configure all API endpoints
MyApp.API.*=WARN

# But REST endpoints need DEBUG
MyApp.API.REST=DEBUG

# Configure all repositories
*.repository=INFO
```

**Resolution rules:**
1. **Exact match wins** - `MyApp.Database.Connection` matches exactly
2. **Most specific wildcard** - `MyApp.Database.*` beats `MyApp.*`
3. **Inheritance** - Falls back to parent or root if no match

### Runtime Configuration

Change log levels at runtime without restarting your application:

```delphi
// Change single logger
TLoggerFactory.SetLoggerLevel('app.database', llTrace);

// Change with wildcard - affects all matching loggers
TLoggerFactory.SetLoggerLevel('app.api.*', llError);

// Reload configuration file
TLoggerFactory.ReloadConfig;
```

### Practical Example

```delphi
program HierarchicalDemo;

uses
  Logger.Factory, Logger.Intf, Logger.Types;

procedure InitializeLogging;
begin
  // Configure via code (or use .properties file)
  TLoggerFactory.SetLoggerLevel('app', llInfo);
  TLoggerFactory.SetLoggerLevel('app.database.*', llDebug);
  TLoggerFactory.SetLoggerLevel('app.database.connection', llTrace);
  TLoggerFactory.SetLoggerLevel('app.api.*', llError);
end;

procedure DatabaseOperation;
var
  Logger: ILogger;
begin
  Logger := TLoggerFactory.GetLogger('app.database.connection');

  Logger.Trace('Opening connection...');              // Shows (TRACE level)
  Logger.Debug('Executing query: SELECT * FROM...');  // Shows
  Logger.Info('Query executed successfully');         // Shows
end;

procedure ApiEndpoint;
var
  Logger: ILogger;
begin
  Logger := TLoggerFactory.GetLogger('app.api.users');

  Logger.Info('API called');                    // Hidden (ERROR level)
  Logger.Error('Authentication failed');        // Shows
end;

begin
  InitializeLogging;
  DatabaseOperation;
  ApiEndpoint;
end.
```

## Installation

LoggingFacade can be installed using either dynamic linking (BPL packages) or static linking (source files).

### Dynamic Linking (BPL)

Best for shared components across multiple applications.

#### 1. Compile the Packages

Open each `.dpk` file in Delphi and compile (Shift+F9):

- `packages\LoggingFacade.dpk` → Core framework
- `packages\LoggingFacade.LoggerPro.dpk` → LoggerPro adapter (optional)
- `packages\LoggingFacade.QuickLogger.dpk` → QuickLogger adapter (optional)
- `packages\LoggingFacade.StackTrace.JclDebug.dpk` → Stack traces (optional)

#### 2. Deploy BPL Files

Copy the generated `.bpl` files to:
- System PATH directory, or
- Application directory

#### 3. Configure Your Project

In Project Options → Packages → Runtime Packages:
- Check "Link with runtime packages"
- Add package names (without .bpl extension):
  ```
  LoggingFacade;LoggingFacade.LoggerPro
  ```

### Static Linking (Source Files)

Best for single applications or when you want to avoid BPL deployment.

#### 1. Add Source Path

In Project Options → Delphi Compiler → Search Path, add:
```
..\LoggingFacade\src
```

#### 2. Add Units to Your Code

```delphi
uses
  Logger.Intf,
  Logger.Factory,
  Logger.Types,
  Logger.Default;  // Or other implementations
```

#### Comparison: BPL vs Source

| Aspect | BPL (Dynamic) | Source (Static) |
|--------|---------------|-----------------|
| **Executable Size** | Smaller | Larger |
| **Deployment** | Requires BPL files | Single EXE |
| **Shared Code** | Yes, across apps | No |
| **Updates** | Update BPL only | Recompile all apps |
| **Debugging** | More complex | Straightforward |
| **Best For** | Multiple apps, plugins | Single apps |

## Advanced Usage

### Using LoggerPro Adapter

LoggerPro provides high-performance asynchronous logging with multiple appenders.

```delphi
program LoggerProExample;

uses
  Logger.Factory,
  Logger.Intf,
  Logger.LoggerPro.Factory,  // Helper for LoggerPro setup
  LoggerPro,                  // LoggerPro library
  LoggerPro.FileAppender;     // File output

begin
  // Configure LoggerPro with file appender
  var LogWriter := BuildLogWriter([
    TLoggerProFileAppender.Create(10, 5000, 'logs', [], TEncoding.UTF8)
  ]);

  // Create adapter factory
  TLoggerFactory.SetNamedLoggerFactory(
    function(const AName: string): ILogger
    begin
      Result := TLoggerProAdapter.Create(AName, LogWriter);
    end
  );

  // Use as normal
  var Logger := TLoggerFactory.GetLogger('MyApp');
  Logger.Info('Using LoggerPro backend!');
end.
```

### Using QuickLogger Adapter

QuickLogger offers extensive providers for various outputs.

```delphi
program QuickLoggerExample;

uses
  Logger.Factory,
  Logger.Intf,
  Logger.QuickLogger.Adapter,
  Quick.Logger,
  Quick.Logger.Provider.Files,
  Quick.Logger.Provider.Console;

begin
  // Configure QuickLogger
  Logger.Providers.Add(GlobalLogFileProvider);
  Logger.Providers.Add(GlobalLogConsoleProvider);

  GlobalLogFileProvider.FileName := 'app.log';
  GlobalLogFileProvider.Enabled := True;

  GlobalLogConsoleProvider.Enabled := True;
  GlobalLogConsoleProvider.ShowColors := True;

  // Set up adapter factory
  TLoggerFactory.SetNamedLoggerFactory(
    function(const AName: string): ILogger
    begin
      Result := TQuickLoggerAdapter.Create(AName);
    end
  );

  // Use facade interface
  var AppLogger := TLoggerFactory.GetLogger('MyApp');
  AppLogger.Info('QuickLogger backend active');
end.
```

### Using Composite Logger

The composite logger allows you to broadcast log messages to multiple destinations simultaneously without coupling your code to specific implementations.

```delphi
program CompositeLoggerExample;

uses
  Logger.Factory,
  Logger.Intf,
  Logger.Composite,
  Logger.Default,
  Logger.QuickLogger.Adapter,
  Quick.Logger,
  Quick.Logger.Provider.Files;

var
  CompositeLogger: ILogger;
  ConsoleLogger: ILogger;
  FileLogger: ILogger;
begin
  // Create composite logger
  CompositeLogger := TCompositeLogger.Create('MyApp');

  // Create individual loggers
  ConsoleLogger := TConsoleLogger.Create('MyApp', llDebug, True);

  // Configure QuickLogger for file output
  GlobalLogFileProvider.FileName := 'app.log';
  GlobalLogFileProvider.Enabled := True;
  FileLogger := TQuickLoggerAdapter.Create('MyApp');

  // Add loggers to composite
  TCompositeLogger(CompositeLogger).AddLogger(ConsoleLogger);
  TCompositeLogger(CompositeLogger).AddLogger(FileLogger);

  // This message will be sent to both console and file
  CompositeLogger.Info('Application started');
  CompositeLogger.Debug('Processing data...');

  // Remove a logger at runtime
  TCompositeLogger(CompositeLogger).RemoveLogger(FileLogger);

  // This will only go to console
  CompositeLogger.Info('File logging disabled');

  // Get logger count
  WriteLn('Active loggers: ', TCompositeLogger(CompositeLogger).GetLoggerCount);
end.
```

**Key Features:**
- Broadcast messages to multiple loggers simultaneously
- Add/remove loggers dynamically at runtime
- Thread-safe for concurrent access
- Single-point filtering: The composite handles all level filtering efficiently
- Perfect for logging to multiple destinations (console + file, file + remote service, etc.)

**Level Management:**
The composite logger uses a "single-point filtering" strategy:
- When you add a logger to the composite, it's automatically set to TRACE level
- The composite logger becomes the only filter point
- This prevents double-filtering and ensures consistent behavior
- Changing the composite's level affects what all sub-loggers receive

```delphi
var
  Composite: ILogger;
  Console: ILogger;
begin
  Composite := TCompositeLogger.Create('MyApp', llInfo);
  Console := TConsoleLogger.Create('', llWarn); // Created with WARN level

  TCompositeLogger(Composite).AddLogger(Console);
  // Console is now automatically set to TRACE
  // Only the composite filters at INFO level

  Composite.Debug('Hidden');  // Filtered by composite
  Composite.Info('Visible');  // Passes composite filter, sent to console
end;
```

**Common Use Cases:**
```delphi
// Example 1: Console + File logging
var Composite := TCompositeLogger.Create('MyApp', llInfo);
TCompositeLogger(Composite).AddLogger(TConsoleLogger.Create);
TCompositeLogger(Composite).AddLogger(TFileLogger.Create('app.log'));
// Both loggers will receive INFO and above messages

// Example 2: Change logging level at runtime
var Composite := TCompositeLogger.Create('MyApp', llInfo);
TCompositeLogger(Composite).AddLogger(TConsoleLogger.Create);
TCompositeLogger(Composite).AddLogger(TFileLogger.Create('app.log'));

// Later, enable debug logging for troubleshooting
Composite.SetLevel(llDebug);
// Now both console and file receive DEBUG messages

// Example 3: Development vs Production logging
var Composite: ILogger;
{$IFDEF DEBUG}
  Composite := TCompositeLogger.Create('MyApp', llTrace);
  TCompositeLogger(Composite).AddLogger(TConsoleLogger.Create);
  TCompositeLogger(Composite).AddLogger(TFileLogger.Create('debug.log'));
{$ELSE}
  Composite := TCompositeLogger.Create('MyApp', llInfo);
  TCompositeLogger(Composite).AddLogger(TFileLogger.Create('production.log'));
  TCompositeLogger(Composite).AddLogger(TRemoteLogger.Create('log-server'));
{$ENDIF}
```

### Custom Logger Implementation

Create your own logger by implementing the `ILogger` interface:

```delphi
unit MyCustomLogger;

interface

uses
  Logger.Intf, Logger.Types, System.SysUtils;

type
  TDatabaseLogger = class(TInterfacedObject, ILogger)
  private
    FName: string;
    FMinLevel: TLogLevel;
    procedure WriteToDatabase(ALevel: TLogLevel; const AMessage: string);
  public
    constructor Create(const AName: string);

    // ILogger implementation
    procedure Trace(const AMessage: string); overload;
    procedure Trace(const AMessage: string; const AArgs: array of const); overload;
    // ... implement all ILogger methods ...

    function IsTraceEnabled: Boolean;
    // ... implement all level check methods ...

    procedure SetLevel(ALevel: TLogLevel);
    function GetLevel: TLogLevel;
    function GetName: string;
  end;

implementation

constructor TDatabaseLogger.Create(const AName: string);
begin
  FName := AName;
  FMinLevel := llInfo;
end;

procedure TDatabaseLogger.WriteToDatabase(ALevel: TLogLevel; const AMessage: string);
begin
  // Insert log entry into database
  // ExecuteSQL('INSERT INTO logs (level, logger, message) VALUES (?, ?, ?)',
  //   [ALevel.ToString, FName, AMessage]);
end;

procedure TDatabaseLogger.Info(const AMessage: string);
begin
  if FMinLevel <= llInfo then
    WriteToDatabase(llInfo, AMessage);
end;

// ... implement other methods ...

end.
```

Register your custom logger:

```delphi
TLoggerFactory.SetNamedLoggerFactory(
  function(const AName: string): ILogger
  begin
    Result := TDatabaseLogger.Create(AName);
  end
);
```

### Stack Trace Configuration

#### Dynamic Loading (Production)

```delphi
uses
  Logger.StackTrace.Loader;  // Auto-loads at initialization

begin
  // Stack traces automatically available if BPL found
  var Logger := TLoggerFactory.GetLogger('MyApp');
  try
    raise Exception.Create('Test error');
  except
    on E: Exception do
      Logger.Error('Operation failed', E);  // Includes stack trace
  end;
end.
```

#### Static Linking (Development)

```delphi
uses
  Logger.StackTrace.JclDebug;  // Direct JCL dependency

begin
  // Stack traces available immediately
  TStackTraceManager.Enable;

  var Logger := TLoggerFactory.GetLogger('MyApp');
  // Use as above
end.
```

#### Manual Control

```delphi
// Check availability
if TStackTraceManager.IsAvailable then
  WriteLn('Stack traces enabled')
else
  WriteLn('Stack traces not available');

// Enable/disable at runtime
TStackTraceManager.Disable;  // Temporarily disable
TStackTraceManager.Enable;   // Re-enable

// Get current stack
var Stack := TStackTraceManager.GetCurrentStackTrace;
Logger.Debug('Current call stack: ' + Stack);
```

## Examples

The project includes several example applications demonstrating different features:

### BasicExample
Simple introduction to logging with different levels and basic configuration.

```bash
examples\BasicExample\BasicExample.dpr
```

### ConfigExample
Demonstrates external configuration files, hierarchical resolution, and runtime changes.

```bash
examples\ConfigExample\ConfigExample.dpr
```

### HierarchicalDemo
Complex multi-layer application showing hierarchical loggers across different modules.

```bash
examples\HierarchicalDemo\HierarchyApp\HierarchyApp.dpr
```

### StackTraceExample
Shows exception logging with stack traces using JCL Debug.

```bash
examples\StackTraceExample\StackTraceExample.dpr
```

### LoggerProExample
Integration with LoggerPro library for high-performance logging.

```bash
examples\LoggerProExample\LoggerProExample.dpr
```

### QuickLoggerExample
Integration with QuickLogger for feature-rich logging.

```bash
examples\QuickLoggerExample\QuickLoggerExample.dpr
```

## Best Practices

### Logger Naming Conventions

1. **Mirror your code structure**
   ```delphi
   'MyApp.UI.Forms.MainForm'
   'MyApp.Business.Services.OrderService'
   'MyApp.Data.Repositories.CustomerRepository'
   ```

2. **Use constants for logger names**
   ```delphi
   const
     LOG_DATABASE = 'MyApp.Database';
     LOG_API = 'MyApp.API';
   ```

3. **One logger per class**
   ```delphi
   type
     TMyService = class
     private
       class var FLogger: ILogger;
     public
       class constructor Create;
     end;

   class constructor TMyService.Create;
   begin
     FLogger := TLoggerFactory.GetLogger('MyApp.Services.MyService');
   end;
   ```

### Performance Considerations

1. **Cache logger instances**
   ```delphi
   // Bad - creates logger every time
   procedure DoWork;
   begin
     TLoggerFactory.GetLogger('MyApp').Info('Working...');
   end;

   // Good - reuses cached instance
   var
     Logger: ILogger;

   procedure DoWork;
   begin
     if not Assigned(Logger) then
       Logger := TLoggerFactory.GetLogger('MyApp');
     Logger.Info('Working...');
   end;
   ```

2. **Check level before expensive operations**
   ```delphi
   if Logger.IsDebugEnabled then
   begin
     var Data := CollectDebugData();  // Expensive
     Logger.Debug('Data: ' + Data);
   end;
   ```

3. **Use format strings efficiently**
   ```delphi
   // Good - defers formatting
   Logger.Info('Order %d processed in %d ms', [OrderId, ElapsedMs]);

   // Less efficient - always formats
   Logger.Info(Format('Order %d processed in %d ms', [OrderId, ElapsedMs]));
   ```

### Configuration Management

1. **Separate configs for environments**
   ```
   logging-debug.properties     # Development
   logging.properties           # Production
   logging-test.properties      # Testing
   ```

2. **Start general, get specific**
   ```properties
   # Start with broad rules
   root=WARN
   app.*=INFO

   # Then add specific overrides
   app.database.connection=DEBUG
   app.critical.security=TRACE
   ```

3. **Document your configuration**
   ```properties
   # ===== Production Configuration =====
   # Root: WARN to minimize noise
   # Database: INFO for operations tracking
   # API: ERROR only for production stability

   root=WARN
   app.database=INFO
   app.api=ERROR
   ```

### Deployment Strategies

#### Development
- Use source files for easy debugging
- Enable TRACE/DEBUG levels
- Include stack trace support
- Use console logger for immediate feedback

#### Testing
- Use null logger for unit tests
- Mock ILogger interface for behavior testing
- Separate test configuration file

#### Production
- Use BPL packages for shared deployment
- Configure appropriate log levels (usually INFO/WARN)
- Use production-grade backend (LoggerPro/QuickLogger)
- Implement log rotation and archiving
- Consider performance impact of logging

## Architecture

LoggingFacade implements the **Facade Pattern** to provide a simplified, unified interface to various logging subsystems:

```mermaid
graph TD
    A[Application Code] --> B[ILogger Interface]
    B --> C{TLoggerFactory}
    C --> D[TConsoleLogger]
    C --> E[TNullLogger]
    C --> F[TLoggerProAdapter]
    C --> G[TQuickLoggerAdapter]
    F --> H[LoggerPro Library]
    G --> I[QuickLogger Library]

    style B fill:#f9f,stroke:#333,stroke-width:2px
    style C fill:#bbf,stroke:#333,stroke-width:2px
```

### Design Principles

1. **Facade Pattern**: Single interface (`ILogger`) hiding implementation complexity
2. **Factory Pattern**: Centralized logger creation via `TLoggerFactory`
3. **Singleton Pattern**: Single factory instance with cached loggers
4. **Adapter Pattern**: Bridges to external logging libraries
5. **Registry Pattern**: Dynamic provider registration for stack traces

### Component Architecture

#### Core Package (LoggingFacade.bpl)
- `Logger.Intf.pas` - Core `ILogger` interface
- `Logger.Factory.pas` - Factory with hierarchical logger management
- `Logger.Config.pas` - Configuration file parser with wildcards
- `Logger.Types.pas` - Common types and log levels
- `Logger.Default.pas` - Console logger implementation
- `Logger.Null.pas` - Null logger (no output)
- `Logger.Composite.pas` - Composite logger (aggregator pattern)
- `Logger.StackTrace.pas` - Stack trace registry

#### Adapter Packages
- `LoggingFacade.LoggerPro.bpl` - LoggerPro integration
- `LoggingFacade.QuickLogger.bpl` - QuickLogger integration
- `LoggingFacade.StackTrace.JclDebug.bpl` - JCL Debug provider

### Thread Safety

All core components are designed to be thread-safe:

1. **TLoggerFactory**: Uses critical section for all operations
2. **TConsoleLogger**: Synchronizes console output
3. **TLoggerConfig**: Thread-safe configuration access
4. **TLoggerContext**: Thread-local storage for contexts
5. **Adapters**: Rely on underlying library's thread safety

## Log Levels

LoggingFacade supports six log levels, ordered from most verbose to most severe:

| Level | Usage | Example |
|-------|-------|---------|
| **TRACE** | Very detailed information, typically only enabled during development | Method entry/exit, variable values |
| **DEBUG** | Detailed information useful for debugging | SQL queries, configuration values |
| **INFO** | General informational messages | Application startup, feature usage |
| **WARN** | Potentially harmful situations | Deprecated API usage, poor performance |
| **ERROR** | Error events that might still allow the application to continue | Failed operations, invalid input |
| **FATAL** | Very severe error events that will presumably lead the application to abort | Out of memory, critical resource unavailable |

### Level Filtering

Each logger has a minimum level - messages below this level are discarded:

```delphi
var Logger := TLoggerFactory.GetLogger('MyApp');
Logger.SetLevel(llInfo);

Logger.Trace('Hidden');  // Not logged
Logger.Debug('Hidden');  // Not logged
Logger.Info('Visible');  // Logged
Logger.Warn('Visible');  // Logged
```

### Performance Optimization with Level Checks

Always check if a level is enabled before expensive operations:

```delphi
// Bad - always builds the expensive string
Logger.Debug('Data: ' + ExpensiveDataDump());

// Good - only builds string if DEBUG is enabled
if Logger.IsDebugEnabled then
  Logger.Debug('Data: ' + ExpensiveDataDump());
```

## Configuration Reference

### Properties File Syntax

```properties
# Comment line
! Alternative comment

# Root logger
root=LEVEL

# Named logger
logger.name=LEVEL

# Wildcard pattern
logger.prefix.*=LEVEL

# Levels: TRACE, DEBUG, INFO, WARN, ERROR, FATAL
```

### Configuration Options

| Property | Description | Example |
|----------|-------------|---------|
| `root` | Default level for all loggers | `root=INFO` |
| `*` | Same as root | `*=WARN` |
| `name` | Exact logger name | `myapp.database=DEBUG` |
| `prefix.*` | All loggers starting with prefix | `myapp.*=INFO` |
| `*.suffix` | All loggers ending with suffix | `*.repository=DEBUG` |

### Configuration Precedence

1. Exact match (highest priority)
2. Longest matching wildcard
3. Shorter wildcards
4. Root logger (lowest priority)

### Runtime Configuration API

```delphi
// Load configuration file
TLoggerFactory.LoadConfig('custom.properties');

// Reload current configuration
TLoggerFactory.ReloadConfig;

// Set level for specific logger
TLoggerFactory.SetLoggerLevel('app.database', llDebug);

// Set level with wildcard
TLoggerFactory.SetLoggerLevel('app.*', llInfo);

// Query configured level
var Level := TLoggerFactory.GetConfiguredLevel('app.database');

// Clear all configuration
TLoggerFactory.ClearConfig;
```

## API Reference

### TLoggerFactory

Central factory for creating and managing logger instances.

```delphi
class function GetLogger(const AName: string = ''): ILogger;
// Get a logger instance. Empty name returns root logger.

class procedure SetLoggerFactory(AFactoryFunc: TLoggerFactoryFunc);
// Set custom factory function for creating loggers.

class procedure SetLogger(ALogger: ILogger);
// Set a specific logger instance to use globally.

class procedure UseConsoleLogger(AMinLevel: TLogLevel = llInfo;
                                 AUseColors: Boolean = True);
// Configure factory to use console logger.

class procedure UseNullLogger;
// Configure factory to use null logger (no output).

class procedure LoadConfig(const AFileName: string = '');
// Load configuration from properties file.

class procedure ReloadConfig;
// Reload current configuration file.

class procedure SetLoggerLevel(const ALoggerName: string;
                              ALevel: TLogLevel);
// Set logger level at runtime.

class function GetConfiguredLevel(const ALoggerName: string;
                                 ADefaultLevel: TLogLevel = llInfo): TLogLevel;
// Get configured level for a logger name.
```

### ILogger Interface

Core logging interface that all loggers implement.

See the complete [ILogger Interface](#ilogger-interface) section for full documentation with usage examples.

### TStackTraceManager

Manages stack trace providers for exception logging.

```delphi
class procedure RegisterProviderClass(AClass: TStackTraceProviderClass);
// Register a provider class for lazy instantiation.

class procedure SetProvider(AProvider: IStackTraceProvider);
// Set provider instance directly.

class procedure Enable;
// Enable stack trace capture.

class procedure Disable;
// Disable stack trace capture.

class function IsAvailable: Boolean;
// Check if stack traces are available.

class function GetStackTrace(AException: Exception): string;
// Get stack trace for an exception.

class function GetCurrentStackTrace: string;
// Get current call stack.
```

## Troubleshooting

### Common Issues

#### Logger Shows Nothing
- **Check configuration file** exists and is loaded
- **Verify log level** - default is INFO, DEBUG/TRACE won't show
- **Ensure correct logger name** in configuration matches code

#### Configuration Not Loading
- **File location** - must be in current/exe directory
- **File name** - `logging-debug.properties` for DEBUG, `logging.properties` for RELEASE
- **Syntax errors** - check for typos in properties file

#### BPL Not Found
- **Check BPL path** - must be in system PATH or app directory
- **Version mismatch** - rebuild BPLs with same Delphi version
- **Dependencies** - ensure LoggerPro/QuickLogger installed if using adapters

#### Stack Traces Not Working
- **JCL not installed** - requires JEDI Code Library
- **Debug info disabled** - enable in project options
- **Release mode** - stack traces disabled by default in RELEASE

### Debug Tips

1. **Enable TRACE level** to see everything:
   ```delphi
   TLoggerFactory.UseConsoleLogger(llTrace);
   ```

2. **Check logger name resolution**:
   ```delphi
   var Level := TLoggerFactory.GetConfiguredLevel('MyApp.Database');
   WriteLn('Level for MyApp.Database: ', Level.ToString);
   ```

3. **Verify configuration loading**:
   ```delphi
   try
     TLoggerFactory.LoadConfig('myconfig.properties');
     WriteLn('Config loaded successfully');
   except
     on E: Exception do
       WriteLn('Config error: ', E.Message);
   end;
   ```

4. **Test with simple console logger first**:
   ```delphi
   TLoggerFactory.UseConsoleLogger(llTrace, True);
   var Logger := TLoggerFactory.GetLogger('Test');
   Logger.Trace('If you see this, logging works!');
   ```

## Migration Guide

### From Direct LoggerPro Usage

Before (direct LoggerPro):
```delphi
uses
  LoggerPro;

begin
  Log.Info('Starting application');
  Log.Debug('Debug info');
end;
```

After (with facade):
```delphi
uses
  Logger.Factory, Logger.Intf,
  Logger.LoggerPro.Factory;  // One-time setup

begin
  // Setup (once at app start)
  ConfigureLoggerPro;  // Your LoggerPro configuration

  // Usage (throughout app)
  var Logger := TLoggerFactory.GetLogger('MyApp');
  Logger.Info('Starting application');
  Logger.Debug('Debug info');
end;
```

### From Direct QuickLogger Usage

Before (direct QuickLogger):
```delphi
uses
  Quick.Logger;

begin
  Logger.Info('Processing started');
  Logger.Error('An error occurred');
end;
```

After (with facade):
```delphi
uses
  Logger.Factory, Logger.Intf,
  Logger.QuickLogger.Adapter;

begin
  // Setup (once)
  TLoggerFactory.SetNamedLoggerFactory(
    function(const AName: string): ILogger
    begin
      Result := TQuickLoggerAdapter.Create(AName);
    end
  );

  // Usage
  var Logger := TLoggerFactory.GetLogger('MyApp');
  Logger.Info('Processing started');
  Logger.Error('An error occurred');
end;
```

### Benefits After Migration

1. **Flexibility** - Switch logging implementations without changing code
2. **Testability** - Easy to mock ILogger interface
3. **Configuration** - External configuration files
4. **Consistency** - Same API across all loggers
5. **Performance** - Logger caching and lazy initialization

---

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

For issues, questions, or suggestions, please open an issue on the GitHub repository.