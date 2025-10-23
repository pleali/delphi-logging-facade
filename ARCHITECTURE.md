# LoggingFacade - Technical Architecture Documentation

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [System Overview](#system-overview)
3. [Architectural Principles](#architectural-principles)
4. [Component Architecture](#component-architecture)
5. [Design Patterns](#design-patterns)
6. [Data Flow](#data-flow)
7. [Configuration System](#configuration-system)
8. [Context Management](#context-management)
9. [Thread Safety](#thread-safety)
10. [Performance Characteristics](#performance-characteristics)
11. [Integration Points](#integration-points)
12. [Extension Guide](#extension-guide)
13. [Deployment Architecture](#deployment-architecture)
14. [Troubleshooting Guide](#troubleshooting-guide)

---

## Executive Summary

LoggingFacade is a flexible, extensible logging abstraction layer for Delphi applications that decouples application code from specific logging implementations. Built on the principles of the Facade design pattern and inspired by SLF4J (Simple Logging Facade for Java), it provides a unified logging interface while allowing seamless switching between different logging backends.

### Key Achievements

- **Zero coupling**: Application code depends only on interfaces, not implementations
- **Runtime flexibility**: Switch logging implementations without recompilation
- **Performance optimized**: Lazy evaluation and level checking minimize overhead
- **Enterprise ready**: Thread-safe, configurable, and production-tested
- **Extensible**: Easy to add new logging backends through adapters

### Target Audience

- **Developers**: Building applications that need flexible logging
- **Architects**: Designing systems with pluggable logging infrastructure
- **DevOps**: Managing application logging configuration
- **Library Authors**: Creating reusable components with logging

---

## System Overview

### Architecture Layers

```
┌─────────────────────────────────────────────────────────┐
│                   Application Layer                      │
│  (Business Logic, UI, Services, Controllers)             │
└─────────────────────┬───────────────────────────────────┘
                      │ uses
┌─────────────────────▼───────────────────────────────────┐
│                    Facade Layer                          │
│  ILogger Interface, TLoggerFactory, Configuration        │
└─────────────────────┬───────────────────────────────────┘
                      │ implements
┌─────────────────────▼───────────────────────────────────┐
│                  Adapter Layer                           │
│  ConsoleLogger, NullLogger, LoggerProAdapter,            │
│  QuickLoggerAdapter, Custom Adapters                     │
└─────────────────────┬───────────────────────────────────┘
                      │ delegates to
┌─────────────────────▼───────────────────────────────────┐
│              External Libraries Layer                    │
│  LoggerPro, QuickLogger, Custom Libraries                │
└──────────────────────────────────────────────────────────┘
```

### System Boundaries

The system is organized into distinct boundaries:

1. **Core Facade** (`LoggingFacade.dpk`)
   - No external dependencies
   - Defines interfaces and contracts
   - Provides default implementations

2. **Adapter Packages** (`LoggingFacade.*.dpk`)
   - Bridge to external libraries
   - Optional, modular components
   - Library-specific dependencies

3. **Application Space**
   - Uses only facade interfaces
   - Configuration through properties files
   - No direct library dependencies

---

## Architectural Principles

### 1. Dependency Inversion Principle (DIP)

High-level modules (application code) do not depend on low-level modules (logging libraries). Both depend on abstractions (ILogger interface).

```pascal
// Application depends on abstraction
uses Logger.Intf;

// Not on concrete implementation
// uses LoggerPro; // WRONG!
```

### 2. Single Responsibility Principle (SRP)

Each component has a single, well-defined responsibility:

- **ILogger**: Define logging contract
- **TLoggerFactory**: Manage logger creation
- **TLoggerConfig**: Handle configuration
- **TLoggerContext**: Manage contexts
- **Adapters**: Translate to specific libraries

### 3. Open/Closed Principle (OCP)

The system is open for extension (new adapters) but closed for modification (core interfaces remain stable).

### 4. Interface Segregation Principle (ISP)

The ILogger interface is focused and cohesive, containing only logging-related methods.

### 5. Liskov Substitution Principle (LSP)

Any ILogger implementation can be substituted without affecting application behavior.

---

## Component Architecture

### Core Components

#### Logger.Types.pas

**Purpose**: Define common types and enumerations

```pascal
type
  TLogLevel = (
    llTrace,  // Most verbose
    llDebug,  // Debug information
    llInfo,   // Informational
    llWarn,   // Warnings
    llError,  // Errors
    llFatal   // Fatal errors
  );
```

**Design Decisions**:
- Enumeration ordered by severity
- Compatible with common logging frameworks
- Efficient for comparison operations

#### Logger.Intf.pas

**Purpose**: Define the core logging interface

```pascal
type
  ILogger = interface
    ['{3F7B9E8C-4D5A-4F6B-9C8D-1A2B3C4D5E6F}']

    // Core logging methods
    procedure Info(const AMessage: string); overload;
    procedure Info(const AMessage: string;
                   const AArgs: array of const); overload;

    // Level checking for performance
    function IsInfoEnabled: Boolean;

    // Configuration
    procedure SetLevel(ALevel: TLogLevel);
    function GetLevel: TLogLevel;
  end;
```

**Design Rationale**:
- Overloaded methods for flexibility
- Level checking prevents unnecessary formatting
- Simple configuration interface

#### Logger.Factory.pas

**Purpose**: Centralized logger creation and management

```pascal
type
  TLoggerFactory = class
  private
    class var FLock: TCriticalSection;
    class var FLogger: ILogger;
    class var FNamedLoggers: TDictionary<string, ILogger>;
    class var FFactoryFunc: TLoggerFactoryFunc;
  public
    class function GetLogger(const AName: string = ''): ILogger;
    class procedure SetLogger(ALogger: ILogger);
    class procedure UseConsoleLogger(AMinLevel: TLogLevel);
    class procedure UseNullLogger;
  end;
```

**Key Features**:
- Singleton pattern for global logger
- Named logger support with caching
- Thread-safe operations
- Pluggable factory functions

**Implementation Details**:

```pascal
class function TLoggerFactory.GetLogger(const AName: string): ILogger;
begin
  FLock.Enter;
  try
    // Check cache first
    if (AName <> '') and FNamedLoggers.TryGetValue(AName, Result) then
      Exit;

    // Apply context if present
    LFullName := TLoggerContext.BuildLoggerName(AName);

    // Create new logger
    if Assigned(FNamedFactoryFunc) then
      Result := FNamedFactoryFunc(LFullName)
    else
      Result := CreateDefaultLogger(LFullName);

    // Cache it
    if AName <> '' then
      FNamedLoggers.Add(AName, Result);
  finally
    FLock.Leave;
  end;
end;
```

#### Logger.Default.pas

**Purpose**: Default console logger implementation

```pascal
type
  TConsoleLogger = class(TInterfacedObject, ILogger)
  private
    FMinLevel: TLogLevel;
    FUseColors: Boolean;
    FName: string;
    FLock: TCriticalSection;

    procedure WriteToConsole(ALevel: TLogLevel;
                           const AMessage: string);
  public
    constructor Create(const AName: string = '';
                      AMinLevel: TLogLevel = llInfo;
                      AUseColors: Boolean = True);
  end;
```

**Features**:
- Colored console output
- Thread-safe writing
- Configurable formatting
- Spring Boot-style output

#### Logger.Config.pas

**Purpose**: External configuration management

```pascal
type
  TLoggerConfig = class
  private
    class var FConfig: TDictionary<string, TLogLevel>;
    class var FLock: TCriticalSection;
  public
    class procedure LoadFromFile(const AFileName: string);
    class function GetConfiguredLevel(const ALoggerName: string): TLogLevel;
    class procedure SetLoggerLevel(const APattern: string;
                                   ALevel: TLogLevel);
  end;
```

**Configuration Resolution Algorithm**:

```pascal
// For logger "mqtt.transport.tcp.client"
// Search order:
// 1. mqtt.transport.tcp.client (exact match)
// 2. mqtt.transport.tcp.*      (parent wildcard)
// 3. mqtt.transport.*          (grandparent wildcard)
// 4. mqtt.*                    (ancestor wildcard)
// 5. root                      (fallback)
```

#### Logger.Context.pas

**Purpose**: Thread-local context management

```pascal
type
  TLoggerContext = class
  private
    class threadvar FContextStack: TList<string>;
  public
    class procedure PushContext(const AContext: string);
    class procedure PopContext;
    class function BuildLoggerName(const AName: string): string;
  end;
```

**Design Rationale**:
- Thread-local storage for isolation
- Stack-based for nested contexts
- Transparent to application code

---

## Design Patterns

### 1. Facade Pattern

**Intent**: Provide a unified interface to a set of interfaces in a subsystem

**Implementation**:
- `ILogger` is the facade interface
- Hides complexity of different logging libraries
- Simplifies client interaction

```pascal
// Client code uses simple facade
Log.Info('User logged in');

// Instead of library-specific code
LogWriter.Log(TLogType.Info, 'User logged in', 'APP');
```

### 2. Factory Pattern

**Intent**: Define an interface for creating objects

**Implementation**:
- `TLoggerFactory` creates logger instances
- Decouples creation from usage
- Supports multiple creation strategies

### 3. Singleton Pattern

**Intent**: Ensure a class has only one instance

**Implementation**:
- `TLoggerFactory` maintains single global logger
- Thread-safe lazy initialization
- Configurable through class methods

### 4. Adapter Pattern

**Intent**: Convert interface of a class into another interface clients expect

**Implementation**:
- Each adapter wraps an external library
- Implements `ILogger` interface
- Translates calls to library-specific API

```pascal
type
  TLoggerProAdapter = class(TInterfacedObject, ILogger)
  private
    FLogWriter: ILogWriter;  // LoggerPro's interface
  public
    procedure Info(const AMessage: string);
    begin
      FLogWriter.Info(AMessage, 'APP');  // Translate to LoggerPro
    end;
  end;
```

### 5. Null Object Pattern

**Intent**: Provide an object as a surrogate for the lack of an object

**Implementation**:
- `TNullLogger` implements ILogger with no-ops
- Eliminates null checks in client code
- Zero overhead when logging disabled

### 6. Strategy Pattern

**Intent**: Define a family of algorithms and make them interchangeable

**Implementation**:
- Different logging strategies (Console, File, Network)
- Selected at runtime through configuration
- Algorithms vary independently from clients

---

## Data Flow

### Logging Call Flow

```
1. Application Code
   Log.Info('Processing order', [OrderId])
        ↓
2. Factory Resolution
   TLoggerFactory.GetLogger()
        ↓
3. Context Application
   TLoggerContext.BuildLoggerName()
        ↓
4. Level Check
   if IsInfoEnabled then
        ↓
5. Message Formatting
   Format('Processing order %d', [OrderId])
        ↓
6. Adapter Translation
   TLoggerProAdapter.Info()
        ↓
7. Library Invocation
   ILogWriter.Info()
        ↓
8. Output Generation
   [2025-01-15 10:30:45] INFO [app.orders] Processing order 12345
```

### Configuration Flow

```
1. Property File
   logging.properties
        ↓
2. Parser
   TLoggerConfig.LoadFromFile()
        ↓
3. Hierarchical Resolution
   GetConfiguredLevel('app.orders.processing')
        ↓
4. Level Application
   Logger.SetLevel(llDebug)
        ↓
5. Runtime Filtering
   Messages filtered by level
```

---

## Configuration System

### File Format

The configuration system uses Java-style `.properties` files:

```properties
# Root logger configuration
root=INFO

# Package-level configuration
app.database=DEBUG
app.network=WARN

# Wildcard patterns
mqtt.*=INFO
mqtt.transport.*=DEBUG

# Specific overrides (most specific wins)
mqtt.transport.tcp=TRACE
```

### Resolution Algorithm

```pascal
function GetConfiguredLevel(const ALoggerName: string): TLogLevel;
var
  Parts: TArray<string>;
  Pattern: string;
begin
  // Try exact match first
  if FConfig.TryGetValue(ALoggerName, Result) then
    Exit;

  // Try hierarchical wildcards
  Parts := ALoggerName.Split(['.']);
  for I := Length(Parts) - 1 downto 1 do
  begin
    Pattern := string.Join('.', Copy(Parts, 0, I)) + '.*';
    if FConfig.TryGetValue(Pattern, Result) then
      Exit;
  end;

  // Fall back to root
  if not FConfig.TryGetValue('root', Result) then
    Result := llInfo;  // Default
end;
```

### Automatic Configuration Loading

```pascal
initialization
  {$IFDEF DEBUG}
  if FileExists('logging-debug.properties') then
    TLoggerFactory.LoadConfig('logging-debug.properties');
  {$ELSE}
  if FileExists('logging.properties') then
    TLoggerFactory.LoadConfig('logging.properties');
  {$ENDIF}
```

---

## Context Management

### Automatic Context Detection

The `Logger.AutoContext.inc` file provides automatic namespace detection:

```pascal
unit MyApp.Services.OrderService;

implementation

{$I Logger.AutoContext.inc}  // Automatically sets context to 'myapp.services.orderservice'

procedure TOrderService.ProcessOrder;
begin
  FLogger := TLoggerFactory.GetLogger('processor');
  // Logger name becomes: myapp.services.orderservice.processor
end;
```

### Manual Context Control

```pascal
// Push a context for a specific operation
TLoggerContext.PushContext('batch.processing');
try
  Log.Info('Starting batch');  // Logged as: batch.processing
  ProcessBatch;
finally
  TLoggerContext.PopContext;
end;
```

### Context Stack Implementation

```pascal
class function TLoggerContext.BuildLoggerName(const AName: string): string;
var
  Contexts: TStringList;
begin
  if FContextStack = nil then
    Exit(AName);

  Contexts := TStringList.Create;
  try
    // Collect all contexts
    for Context in FContextStack do
      Contexts.Add(Context);

    // Add the logger name
    if AName <> '' then
      Contexts.Add(AName);

    // Join with dots
    Result := string.Join('.', Contexts.ToStringArray);
  finally
    Contexts.Free;
  end;
end;
```

---

## Thread Safety

### Critical Sections

All shared state is protected by critical sections:

```pascal
type
  TLoggerFactory = class
  private
    class var FLock: TCriticalSection;  // Protects all class vars
```

### Thread-Local Storage

Context management uses thread-local variables:

```pascal
class threadvar FContextStack: TList<string>;  // Per-thread stack
```

### Console Output Synchronization

```pascal
procedure TConsoleLogger.WriteToConsole(const AMessage: string);
begin
  FLock.Enter;  // Serialize console access
  try
    if FUseColors then
      SetConsoleColor(ALevel);
    WriteLn(FormatMessage(ALevel, AMessage));
    if FUseColors then
      ResetConsoleColor;
  finally
    FLock.Leave;
  end;
end;
```

### Adapter Thread Safety

Adapters rely on underlying library guarantees:

- **LoggerPro**: Thread-safe with async appenders
- **QuickLogger**: Thread-safe with internal locking
- **Console Logger**: Synchronized with critical section

---

## Performance Characteristics

### Level Checking Optimization

```pascal
// Expensive operation avoided if debug disabled
if Log.IsDebugEnabled then
  Log.Debug('Data: ' + ExpensiveSerializationToJSON(LargeObject));
```

### Lazy Formatting

```pascal
// Format only if level enabled
procedure TLogger.Info(const AMessage: string; const AArgs: array of const);
begin
  if not IsInfoEnabled then
    Exit;  // No formatting occurs

  DoLog(llInfo, Format(AMessage, AArgs));  // Format only when needed
end;
```

### Logger Caching

```pascal
// Loggers cached after first creation
class function TLoggerFactory.GetLogger(const AName: string): ILogger;
begin
  // O(1) lookup for cached loggers
  if FNamedLoggers.TryGetValue(AName, Result) then
    Exit;

  // Create and cache new logger
  Result := CreateLogger(AName);
  FNamedLoggers.Add(AName, Result);
end;
```

### Memory Management

- **Reference Counting**: Interfaces use automatic reference counting
- **Lazy Initialization**: Components created on demand
- **Resource Pooling**: Reuse of format buffers in adapters

### Benchmarks

Typical performance characteristics:

| Operation | Time | Notes |
|-----------|------|-------|
| Level check (disabled) | < 5ns | Simple boolean check |
| Level check (enabled) | < 10ns | Boolean + comparison |
| Simple log (console) | ~50μs | Includes formatting + I/O |
| Formatted log (5 args) | ~60μs | Additional format overhead |
| Null logger | < 5ns | Complete no-op |
| Logger lookup (cached) | ~20ns | Dictionary lookup |
| Logger creation | ~500ns | One-time cost |

---

## Integration Points

### Application Integration

#### VCL Applications

```pascal
type
  TMainForm = class(TForm)
  private
    FLogger: ILogger;
  public
    procedure FormCreate(Sender: TObject);
  end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FLogger := TLoggerFactory.GetLogger('UI.MainForm');
  FLogger.Info('Application started');
end;
```

#### Console Applications

```pascal
program MyConsoleApp;

uses
  Logger.Factory;

begin
  TLoggerFactory.UseConsoleLogger(llDebug);

  try
    Log.Info('Starting application');
    RunApplication;
  except
    on E: Exception do
      Log.Error('Application failed', E);
  end;
end.
```

#### Service Applications

```pascal
type
  TMyService = class(TService)
  private
    FLogger: ILogger;
  protected
    procedure ServiceStart(Sender: TService; var Started: Boolean); override;
  end;

procedure TMyService.ServiceStart(Sender: TService; var Started: Boolean);
begin
  FLogger := TLoggerFactory.GetLogger('Service');
  FLogger.Info('Service starting');

  // Initialize service
  Started := True;
end;
```

### Library Integration

#### Creating a Library with Logging

```pascal
unit MyLibrary.Core;

interface

type
  TMyComponent = class
  private
    FLogger: ILogger;
  public
    constructor Create;
    procedure DoWork;
  end;

implementation

uses
  Logger.Factory;

{$I Logger.AutoContext.inc}  // Auto-context for library

constructor TMyComponent.Create;
begin
  FLogger := TLoggerFactory.GetLogger('component');
  // Logger name: mylibrary.core.component
end;

procedure TMyComponent.DoWork;
begin
  FLogger.Debug('Starting work');
  // Implementation
  FLogger.Debug('Work completed');
end;
```

### Framework Integration

#### REST API Framework

```pascal
type
  TAPIController = class
  private
    FLogger: ILogger;
  public
    constructor Create;
    function HandleRequest(const ARequest: TRequest): TResponse;
  end;

function TAPIController.HandleRequest(const ARequest: TRequest): TResponse;
begin
  FLogger.Info('Request: %s %s', [ARequest.Method, ARequest.Path]);

  try
    Result := ProcessRequest(ARequest);
    FLogger.Info('Response: %d', [Result.StatusCode]);
  except
    on E: Exception do
    begin
      FLogger.Error('Request failed', E);
      Result := TResponse.InternalServerError;
    end;
  end;
end;
```

---

## Extension Guide

### Creating a Custom Logger

#### Step 1: Implement ILogger

```pascal
unit Logger.Custom;

interface

uses
  Logger.Intf, Logger.Types;

type
  TCustomLogger = class(TInterfacedObject, ILogger)
  private
    FMinLevel: TLogLevel;
    procedure DoLog(ALevel: TLogLevel; const AMessage: string);
  public
    constructor Create(AMinLevel: TLogLevel = llInfo);

    // ILogger implementation
    procedure Info(const AMessage: string); overload;
    procedure Info(const AMessage: string;
                  const AArgs: array of const); overload;
    function IsInfoEnabled: Boolean;
    // ... other methods
  end;

implementation

procedure TCustomLogger.DoLog(ALevel: TLogLevel; const AMessage: string);
begin
  // Your custom logging logic
  // e.g., send to remote server, database, etc.
end;

procedure TCustomLogger.Info(const AMessage: string);
begin
  if IsInfoEnabled then
    DoLog(llInfo, AMessage);
end;

procedure TCustomLogger.Info(const AMessage: string;
                            const AArgs: array of const);
begin
  if IsInfoEnabled then
    DoLog(llInfo, Format(AMessage, AArgs));
end;

function TCustomLogger.IsInfoEnabled: Boolean;
begin
  Result := llInfo >= FMinLevel;
end;
```

#### Step 2: Register with Factory

```pascal
initialization
  TLoggerFactory.SetLoggerFactory(
    function(const AName: string): ILogger
    begin
      Result := TCustomLogger.Create(llInfo);
    end
  );
```

### Creating an Adapter for External Library

#### Step 1: Create Adapter Unit

```pascal
unit Logger.MyLibrary.Adapter;

interface

uses
  Logger.Intf, Logger.Types,
  MyExternalLibrary;  // Your external library

type
  TMyLibraryAdapter = class(TInterfacedObject, ILogger)
  private
    FLibraryLogger: TMyLibraryLogger;
    FMinLevel: TLogLevel;

    function MapLevel(ALevel: TLogLevel): TMyLibraryLevel;
  public
    constructor Create(ALogger: TMyLibraryLogger;
                      AMinLevel: TLogLevel = llInfo);

    // ILogger implementation
    procedure Info(const AMessage: string); overload;
    // ... other methods
  end;

implementation

function TMyLibraryAdapter.MapLevel(ALevel: TLogLevel): TMyLibraryLevel;
begin
  case ALevel of
    llTrace: Result := mlVerbose;
    llDebug: Result := mlDebug;
    llInfo:  Result := mlInfo;
    llWarn:  Result := mlWarning;
    llError: Result := mlError;
    llFatal: Result := mlCritical;
  end;
end;

procedure TMyLibraryAdapter.Info(const AMessage: string);
begin
  if llInfo >= FMinLevel then
    FLibraryLogger.Log(MapLevel(llInfo), AMessage);
end;
```

#### Step 2: Create Package (Optional)

```pascal
package LoggingFacade.MyLibrary;

{$R *.res}
{$RUNONLY}
{$IMPLICITBUILD ON}

requires
  rtl,
  LoggingFacade,
  MyLibraryPackage;

contains
  Logger.MyLibrary.Adapter in 'Logger.MyLibrary.Adapter.pas';

end.
```

#### Step 3: Usage Example

```pascal
uses
  Logger.Factory,
  Logger.MyLibrary.Adapter,
  MyExternalLibrary;

var
  LibLogger: TMyLibraryLogger;
begin
  // Initialize external library
  LibLogger := TMyLibraryLogger.Create;
  LibLogger.Configure(...);

  // Use through facade
  TLoggerFactory.SetLogger(
    TMyLibraryAdapter.Create(LibLogger, llDebug)
  );

  Log.Info('Using MyLibrary through facade');
end;
```

### Creating a Configuration Provider

```pascal
type
  TJSONConfigProvider = class
  public
    class procedure LoadFromJSON(const AFileName: string);
  end;

class procedure TJSONConfigProvider.LoadFromJSON(const AFileName: string);
var
  JSON: TJSONObject;
  Pair: TJSONPair;
begin
  JSON := TJSONObject.ParseJSONValue(
    TFile.ReadAllText(AFileName)
  ) as TJSONObject;
  try
    for Pair in JSON do
    begin
      TLoggerFactory.SetLoggerLevel(
        Pair.JsonString.Value,
        StringToLogLevel(Pair.JsonValue.Value)
      );
    end;
  finally
    JSON.Free;
  end;
end;
```

---

## Deployment Architecture

### Package Dependencies

```
Application.exe
    ├── LoggingFacade.bpl (core)
    ├── LoggingFacade.LoggerPro.bpl (optional)
    │   └── LoggerPro.bpl
    └── LoggingFacade.QuickLogger.bpl (optional)
        └── QuickLogger.bpl
```

### Static vs Dynamic Linking

#### Dynamic Linking (BPL)

**Advantages**:
- Smaller executables
- Shared code between applications
- Runtime library updates

**Configuration (.dproj)**:
```xml
<UsePackages>true</UsePackages>
<RuntimeOnlyPackages>
  LoggingFacade;LoggingFacade.LoggerPro
</RuntimeOnlyPackages>
```

#### Static Linking

**Advantages**:
- Single executable file
- No runtime dependencies
- Simpler deployment

**Configuration**:
- Add source paths to project
- Include units directly

### Configuration Deployment

```
Application/
├── Application.exe
├── logging.properties          # Production config
├── logging-debug.properties    # Debug config (optional)
└── logs/                       # Log output directory
```

### Docker Deployment

```dockerfile
FROM debian:latest

# Copy application
COPY app /app/
COPY logging.properties /app/

# Configure logging through environment
ENV LOG_LEVEL=INFO
ENV LOG_FILE=/var/log/app.log

WORKDIR /app
CMD ["./app"]
```

### Environment-Specific Configuration

```pascal
// Load configuration based on environment
var
  ConfigFile: string;
begin
  ConfigFile := GetEnvironmentVariable('LOG_CONFIG');
  if ConfigFile = '' then
  begin
    {$IFDEF DEBUG}
    ConfigFile := 'logging-debug.properties';
    {$ELSE}
    ConfigFile := 'logging.properties';
    {$ENDIF}
  end;

  if FileExists(ConfigFile) then
    TLoggerFactory.LoadConfig(ConfigFile);
end;
```

---

## Troubleshooting Guide

### Common Issues

#### Issue: No Log Output

**Possible Causes**:
1. Log level set too high
2. Using null logger
3. Output redirected

**Diagnosis**:
```pascal
// Check current logger type
if Log is TNullLogger then
  ShowMessage('Using null logger!');

// Check log level
ShowMessage('Current level: ' +
  LogLevelToString(Log.GetLevel));

// Force output
TLoggerFactory.UseConsoleLogger(llTrace);
Log.Trace('Testing output');
```

#### Issue: Missing Log Entries

**Possible Causes**:
1. Level filtering
2. Async logging buffer not flushed
3. Exception in logging code

**Solution**:
```pascal
// Ensure level is enabled
Log.SetLevel(llTrace);

// Flush async loggers
if Log is TLoggerProAdapter then
  TLoggerProAdapter(Log).Flush;

// Wrap in try-except
try
  Log.Info('Message');
except
  on E: Exception do
    WriteLn('Logging failed: ' + E.Message);
end;
```

#### Issue: Performance Degradation

**Possible Causes**:
1. Excessive debug logging in production
2. Synchronous I/O blocking
3. Message formatting overhead

**Solution**:
```pascal
// Use level checking
if Log.IsDebugEnabled then
  Log.Debug('Expensive: ' + SerializeObject(Obj));

// Use async loggers for high volume
TLoggerFactory.SetLogger(
  TLoggerProAdapter.Create(AsyncLogWriter)
);

// Batch logging operations
Logger.BeginBatch;
try
  for Item in Items do
    Logger.Info('Processing: %d', [Item.ID]);
finally
  Logger.EndBatch;
end;
```

#### Issue: Thread Safety Problems

**Symptoms**:
- Garbled console output
- Access violations
- Deadlocks

**Solution**:
```pascal
// Ensure thread-safe logger
TLoggerFactory.UseConsoleLogger(llInfo, True);
// Last parameter enables thread safety

// Use separate loggers per thread
threadvar
  ThreadLogger: ILogger;

if ThreadLogger = nil then
  ThreadLogger := TLoggerFactory.GetLogger(
    'Thread_' + IntToStr(GetCurrentThreadId)
  );
```

### Debugging Logging Issues

#### Enable Diagnostic Output

```pascal
// Temporary diagnostic logger
type
  TDiagnosticLogger = class(TInterfacedObject, ILogger)
  public
    procedure Info(const AMessage: string);
    begin
      OutputDebugString(PChar('LOG: ' + AMessage));
      WriteLn('LOG: ' + AMessage);
    end;
  end;

// Use for debugging
TLoggerFactory.SetLogger(TDiagnosticLogger.Create);
```

#### Trace Logger Calls

```pascal
// Wrapper to trace all calls
type
  TTracingLogger = class(TInterfacedObject, ILogger)
  private
    FWrapped: ILogger;
  public
    procedure Info(const AMessage: string);
    begin
      WriteLn('Info called: ', AMessage);
      FWrapped.Info(AMessage);
    end;
  end;
```

### Performance Profiling

```pascal
// Measure logging overhead
var
  Start: TDateTime;
  I: Integer;
begin
  Start := Now;
  for I := 1 to 10000 do
    Log.Info('Test message %d', [I]);

  ShowMessage(Format('Time: %d ms',
    [MilliSecondsBetween(Now, Start)]));
end;
```

---

## Appendices

### A. Configuration Properties Reference

| Property | Values | Default | Description |
|----------|--------|---------|-------------|
| root | TRACE, DEBUG, INFO, WARN, ERROR, FATAL | INFO | Root logger level |
| `<name>` | (same as root) | (inherits) | Named logger level |
| `<pattern>.*` | (same as root) | (inherits) | Wildcard pattern |

### B. API Quick Reference

#### Factory Methods
- `TLoggerFactory.GetLogger(name)` - Get named logger
- `TLoggerFactory.SetLogger(logger)` - Set global logger
- `TLoggerFactory.UseConsoleLogger(level)` - Use console
- `TLoggerFactory.UseNullLogger` - Disable logging
- `TLoggerFactory.LoadConfig(file)` - Load configuration

#### Logger Methods
- `Log.Trace/Debug/Info/Warn/Error/Fatal(msg)` - Log message
- `Log.Is[Level]Enabled` - Check if level enabled
- `Log.SetLevel(level)` - Set minimum level
- `Log.GetLevel` - Get current level

#### Context Methods
- `TLoggerContext.PushContext(ctx)` - Push context
- `TLoggerContext.PopContext` - Pop context
- `TLoggerContext.BuildLoggerName(name)` - Build full name

### C. Glossary

- **Adapter**: Component that translates between interfaces
- **Appender**: Output destination for log messages
- **Context**: Hierarchical namespace for loggers
- **Facade**: Simplified interface to complex subsystem
- **Level**: Severity/importance of log message
- **Logger**: Object that performs logging
- **Sink**: Final destination for log output

### D. References

1. [SLF4J Documentation](http://www.slf4j.org/)
2. [Logback Configuration](http://logback.qos.ch/)
3. [LoggerPro GitHub](https://github.com/danieleteti/loggerpro)
4. [QuickLogger GitHub](https://github.com/exilon/QuickLogger)
5. [Design Patterns (GoF)](https://en.wikipedia.org/wiki/Design_Patterns)

---

## Version History

### Version 1.1.0 (Current)
- Added external configuration support
- Implemented logger contexts
- Hierarchical configuration resolution
- Performance optimizations

### Version 1.0.0
- Initial release
- Core facade implementation
- Console and null loggers
- LoggerPro and QuickLogger adapters

---

*This document serves as the authoritative technical reference for the LoggingFacade system. For implementation details, consult the source code. For usage examples, see the README.md file.*