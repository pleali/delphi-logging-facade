program CompositeExample;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Logger.Types,
  Logger.Intf,
  Logger.Console,
  Logger.Null,
  Logger.Composite;

/// <summary>
/// Demonstrates basic composite logger usage with console loggers
/// </summary>
procedure DemoBasicComposite;
var
  LComposite: ILogger;
  LConsole1: ILogger;
  LConsole2: ILogger;
begin
  Writeln('=== Demo 1: Basic Composite Logger ===');
  Writeln;

  // Create composite logger
  LComposite := TCompositeLogger.Create('MyApp');

  // Create two console loggers with different settings
  LConsole1 := TConsoleLogger.Create('Console1', llDebug, True);
  LConsole2 := TConsoleLogger.Create('Console2', llInfo, False);

  // Add loggers to composite
  TCompositeLogger(LComposite).AddLogger(LConsole1);
  TCompositeLogger(LComposite).AddLogger(LConsole2);

  Writeln('** Logging to both console loggers **');
  Writeln;

  // This message goes to both loggers
  LComposite.Info('This message appears twice (from both loggers)');
  LComposite.Debug('Debug message (only Console1 shows it)');

  Writeln;
  Writeln('Logger count: ', TCompositeLogger(LComposite).GetLoggerCount);
  Writeln;
end;

/// <summary>
/// Demonstrates adding and removing loggers dynamically
/// </summary>
procedure DemoDynamicLoggers;
var
  LComposite: ILogger;
  LConsole: ILogger;
  LNull: ILogger;
begin
  Writeln('=== Demo 2: Dynamic Add/Remove Loggers ===');
  Writeln;

  // Create composite logger
  LComposite := TCompositeLogger.Create('DynamicApp');

  // Start with console logger
  LConsole := TConsoleLogger.Create('Console', llInfo, True);
  TCompositeLogger(LComposite).AddLogger(LConsole);

  Writeln('** Console logger active **');
  LComposite.Info('Message 1: Console is active');
  Writeln;

  // Add null logger (does nothing but demonstrates multiple loggers)
  LNull := TNullLogger.Create;
  TCompositeLogger(LComposite).AddLogger(LNull);

  Writeln('** Console + Null logger **');
  LComposite.Info('Message 2: Both loggers active');
  Writeln('Logger count: ', TCompositeLogger(LComposite).GetLoggerCount);
  Writeln;

  // Remove console logger
  TCompositeLogger(LComposite).RemoveLogger(LConsole);

  Writeln('** Console logger removed, only Null remains **');
  LComposite.Info('Message 3: Only null logger (no output expected)');
  Writeln('(The above message was sent but suppressed by null logger)');
  Writeln('Logger count: ', TCompositeLogger(LComposite).GetLoggerCount);
  Writeln;

  // Clear all loggers
  TCompositeLogger(LComposite).ClearLoggers;
  Writeln('** All loggers cleared **');
  LComposite.Info('Message 4: No loggers (no output)');
  Writeln('Logger count: ', TCompositeLogger(LComposite).GetLoggerCount);
  Writeln;
end;

/// <summary>
/// Demonstrates single-point filtering with composite logger
/// </summary>
procedure DemoSinglePointFiltering;
var
  LComposite: ILogger;
  LConsole1: ILogger;
  LConsole2: ILogger;
begin
  Writeln('=== Demo 3: Single-Point Filtering Strategy ===');
  Writeln;

  // Create loggers with different initial levels
  LConsole1 := TConsoleLogger.Create('Console1', llError, True);
  LConsole2 := TConsoleLogger.Create('Console2', llWarn, True);

  Writeln('** Before adding to composite: **');
  Writeln('  Console1 level: ERROR');
  Writeln('  Console2 level: WARN');
  Writeln;

  // Create composite logger with INFO level
  LComposite := TCompositeLogger.Create('FilteredApp', llInfo);

  // Add loggers - they will be automatically set to TRACE
  TCompositeLogger(LComposite).AddLogger(LConsole1);
  TCompositeLogger(LComposite).AddLogger(LConsole2);

  Writeln('** After adding to composite: **');
  Writeln('  Both loggers automatically set to TRACE');
  Writeln('  Composite filters at INFO level');
  Writeln('  This ensures single-point filtering (more efficient)');
  Writeln;

  Writeln('Sending DEBUG message:');
  LComposite.Debug('This DEBUG message is filtered by composite');
  Writeln('(No output - filtered before reaching sub-loggers)');
  Writeln;

  Writeln('Sending INFO message:');
  LComposite.Info('This INFO message passes the filter');
  Writeln('(Both loggers show it - appears twice)');
  Writeln;

  Writeln('Sending ERROR message:');
  LComposite.Error('This ERROR message also passes');
  Writeln('(Both loggers show it - appears twice)');
  Writeln;
end;

/// <summary>
/// Demonstrates dynamic level changes
/// </summary>
procedure DemoDynamicLevelChange;
var
  LComposite: ILogger;
  LConsole1: ILogger;
  LConsole2: ILogger;
begin
  Writeln('=== Demo 4: Dynamic Level Changes ===');
  Writeln;

  // Create composite logger with INFO level
  LComposite := TCompositeLogger.Create('DynamicApp', llInfo);

  // Create and add console loggers
  LConsole1 := TConsoleLogger.Create('Console1', llInfo, True);
  LConsole2 := TConsoleLogger.Create('Console2', llInfo, False);

  TCompositeLogger(LComposite).AddLogger(LConsole1);
  TCompositeLogger(LComposite).AddLogger(LConsole2);

  Writeln('** Composite initially set to INFO level **');
  Writeln;

  Writeln('Attempting DEBUG message:');
  LComposite.Debug('This DEBUG is filtered');
  Writeln('(No output - INFO level blocks DEBUG)');
  Writeln;

  Writeln('INFO message:');
  LComposite.Info('This INFO message appears');
  Writeln('(Both loggers show it)');
  Writeln;

  // Change composite level to DEBUG
  Writeln('** Changing composite level to DEBUG **');
  LComposite.SetLevel(llDebug);
  Writeln;

  Writeln('Now DEBUG message:');
  LComposite.Debug('Now DEBUG messages appear!');
  Writeln('(Both loggers show it - composite now allows DEBUG)');
  Writeln;

  // Change composite level to ERROR
  Writeln('** Changing composite level to ERROR **');
  LComposite.SetLevel(llError);
  Writeln;

  Writeln('Attempting INFO message:');
  LComposite.Info('This INFO is now filtered');
  Writeln('(No output - ERROR level blocks INFO)');
  Writeln;

  Writeln('ERROR message:');
  LComposite.Error('Only ERROR and above appear now');
  Writeln('(Both loggers show it)');
  Writeln;
end;

/// <summary>
/// Demonstrates a realistic use case: logging to multiple destinations
/// </summary>
procedure DemoRealWorldScenario;
var
  LComposite: ILogger;
  LConsoleLogger: ILogger;
  LErrorLogger: ILogger;
  LDebugLogger: ILogger;
  I: Integer;
begin
  Writeln('=== Demo 5: Real-World Scenario ===');
  Writeln('Simulating an application that logs to:');
  Writeln('  - Console: All messages (INFO+)');
  Writeln('  - Error log: Only errors (ERROR+)');
  Writeln('  - Debug log: Debug and above (DEBUG+)');
  Writeln;

  // Create composite logger
  LComposite := TCompositeLogger.Create('ProductionApp', llDebug);

  // Console logger - shows general information
  LConsoleLogger := TConsoleLogger.Create('Console', llInfo, True);

  // Error logger - only errors (simulated with different name prefix)
  LErrorLogger := TConsoleLogger.Create('ErrorLog', llError, True);

  // Debug logger - for troubleshooting (simulated with different name prefix)
  LDebugLogger := TConsoleLogger.Create('DebugLog', llDebug, False);

  // Register all loggers
  TCompositeLogger(LComposite).AddLogger(LConsoleLogger);
  TCompositeLogger(LComposite).AddLogger(LErrorLogger);
  TCompositeLogger(LComposite).AddLogger(LDebugLogger);

  Writeln('** Simulating application workflow **');
  Writeln;

  LComposite.Info('Application starting...');
  LComposite.Debug('Configuration loaded from app.config');

  for I := 1 to 3 do
  begin
    LComposite.Debug('Processing item #%d', [I]);

    if I = 2 then
    begin
      LComposite.Warn('Item #%d requires special handling', [I]);
    end;

    if I = 3 then
    begin
      try
        raise Exception.Create('Simulated error in processing');
      except
        on E: Exception do
          LComposite.Error('Failed to process item #%d: %s', [I, E.Message]);
      end;
    end;
  end;

  LComposite.Info('Processing completed (with errors)');
  Writeln;

  Writeln('** Summary **');
  Writeln('In a real application:');
  Writeln('  - Console would show: INFO, WARN, ERROR messages');
  Writeln('  - error.log file would contain only: ERROR messages');
  Writeln('  - debug.log file would contain: DEBUG, INFO, WARN, ERROR messages');
  Writeln;
end;

/// <summary>
/// Demonstrates exception logging with composite logger
/// </summary>
procedure DemoExceptionLogging;
var
  LComposite: ILogger;
  LConsole1: ILogger;
  LConsole2: ILogger;
  E: Exception;
begin
  Writeln('=== Demo 6: Exception Logging ===');
  Writeln;

  // Create composite logger
  LComposite := TCompositeLogger.Create('ExceptionDemo');

  // Create console loggers
  LConsole1 := TConsoleLogger.Create('Logger1', llInfo, True);
  LConsole2 := TConsoleLogger.Create('Logger2', llWarn, True);

  TCompositeLogger(LComposite).AddLogger(LConsole1);
  TCompositeLogger(LComposite).AddLogger(LConsole2);

  Writeln('** Testing exception logging **');
  Writeln;

  try
    raise Exception.Create('Sample exception for logging');
  except
    on Ex: Exception do
    begin
      E := Ex;
      LComposite.Error('An error occurred', E);
    end;
  end;

  Writeln;

  try
    raise Exception.Create('Critical failure');
  except
    on Ex: Exception do
    begin
      E := Ex;
      LComposite.Fatal('Fatal error in operation #%d', [42], E);
    end;
  end;

  Writeln;
end;

/// <summary>
/// Demonstrates avoiding duplicate logger registration
/// </summary>
procedure DemoDuplicatePrevention;
var
  LComposite: ILogger;
  LConsole: ILogger;
begin
  Writeln('=== Demo 7: Duplicate Logger Prevention ===');
  Writeln;

  // Create composite logger
  LComposite := TCompositeLogger.Create('DuplicateTest');

  // Create console logger
  LConsole := TConsoleLogger.Create('Console', llInfo, True);

  Writeln('Adding logger for the first time...');
  TCompositeLogger(LComposite).AddLogger(LConsole);
  Writeln('Logger count: ', TCompositeLogger(LComposite).GetLoggerCount);
  Writeln;

  Writeln('Attempting to add the same logger again...');
  TCompositeLogger(LComposite).AddLogger(LConsole);
  Writeln('Logger count: ', TCompositeLogger(LComposite).GetLoggerCount);
  Writeln('(Count is still 1 - duplicate was prevented)');
  Writeln;

  Writeln('Sending a test message:');
  LComposite.Info('This message appears only once');
  Writeln('(Message not duplicated even though we tried to add logger twice)');
  Writeln;
end;

begin
  try
    Writeln('LoggingFacade - Composite Logger Examples');
    Writeln('==========================================');
    Writeln;

    DemoBasicComposite;
    DemoDynamicLoggers;
    DemoSinglePointFiltering;
    DemoDynamicLevelChange;
    DemoRealWorldScenario;
    DemoExceptionLogging;
    DemoDuplicatePrevention;

    Writeln('==========================================');
    Writeln('All composite logger demos completed!');
    Writeln;
    Writeln('Key Benefits of Composite Logger:');
    Writeln('  1. Log to multiple destinations simultaneously');
    Writeln('  2. Add/remove loggers dynamically at runtime');
    Writeln('  3. Single-point filtering (efficient, no double-filtering)');
    Writeln('  4. Dynamic level changes affect all sub-loggers');
    Writeln('  5. Thread-safe for concurrent access');
    Writeln('  6. Prevents duplicate logger registration');
    Writeln;
    Writeln('Press ENTER to exit...');
    Readln;
  except
    on E: Exception do
    begin
      Writeln('FATAL ERROR: ', E.ClassName, ': ', E.Message);
      Readln;
      ExitCode := 1;
    end;
  end;
end.
