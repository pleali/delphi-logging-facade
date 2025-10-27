program BasicExample;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.IOUtils,
  Logger.Types,
  Logger.Intf,
  Logger.Console,
  Logger.Null,
  Logger.Factory;

/// <summary>
/// Simulates processing some business logic
/// </summary>
procedure ProcessOrder(AOrderId: Integer);
var
  LLogger: ILogger;
begin
  LLogger := Log;  // Get the global logger

  LLogger.Info('Starting order processing for order #%d', [AOrderId]);

  try
    LLogger.Debug('Validating order #%d', [AOrderId]);
    // Simulate validation
    Sleep(100);

    if AOrderId = 999 then
    begin
      LLogger.Warn('Order #%d has unusual amount', [AOrderId]);
    end;

    LLogger.Debug('Saving order #%d to database', [AOrderId]);
    // Simulate database save
    Sleep(150);

    if AOrderId = 666 then
      raise Exception.Create('Database connection failed');

    LLogger.Info('Order #%d processed successfully', [AOrderId]);
  except
    on E: Exception do
    begin
      LLogger.Error('Failed to process order #%d', E);
      raise;
    end;
  end;
end;

/// <summary>
/// Demonstrates basic logging with the default console logger
/// </summary>
procedure DemoBasicLogging;
var
  LLogger: ILogger;
begin
  Writeln('=== Demo 1: Basic Console Logging ===');
  Writeln;

  // Use default console logger (automatically created by factory)
  LLogger := Log;

  LLogger.Trace('This is a TRACE message (won''t show with default INFO level)');
  LLogger.Debug('This is a DEBUG message (won''t show with default INFO level)');
  LLogger.Info('This is an INFO message');
  LLogger.Warn('This is a WARN message');
  LLogger.Error('This is an ERROR message');
  LLogger.Fatal('This is a FATAL message');

  Writeln;
end;

/// <summary>
/// Demonstrates changing the log level at runtime
/// </summary>
procedure DemoLogLevels;
var
  LLogger: ILogger;
begin
  Writeln('=== Demo 2: Changing Log Levels ===');
  Writeln;

  // Configure factory to use DEBUG level
  TLoggerFactory.UseConsoleLogger(llDebug);
  LLogger := Log;

  Writeln('** Log level set to DEBUG **');
  LLogger.Trace('This TRACE message still won''t show');
  LLogger.Debug('This DEBUG message will now show');
  LLogger.Info('This INFO message shows');

  Writeln;

  // Change to TRACE level
  LLogger.SetLevel(llTrace);
  Writeln('** Log level changed to TRACE **');
  LLogger.Trace('Now TRACE messages appear!');
  LLogger.Debug('DEBUG still shows');

  Writeln;

  // Change to WARN level
  LLogger.SetLevel(llWarn);
  Writeln('** Log level changed to WARN **');
  LLogger.Debug('This DEBUG won''t show anymore');
  LLogger.Info('This INFO won''t show anymore');
  LLogger.Warn('But WARN still shows');
  LLogger.Error('And ERROR shows');

  Writeln;
end;

/// <summary>
/// Demonstrates the null logger (no output)
/// </summary>
procedure DemoNullLogger;
var
  LLogger: ILogger;
begin
  Writeln('=== Demo 3: Null Logger (no output) ===');
  Writeln;

  // Switch to null logger
  TLoggerFactory.UseNullLogger;
  LLogger := Log;

  Writeln('** Null logger configured - the following log calls produce no output **');
  LLogger.Info('You should not see this message');
  LLogger.Error('You should not see this error either');
  LLogger.Fatal('Even fatal messages are suppressed');

  Writeln('** All logging is disabled **');
  Writeln;

  // Switch back to console logger for remaining demos
  TLoggerFactory.UseConsoleLogger(llInfo);
end;

/// <summary>
/// Demonstrates using logger in business logic
/// </summary>
procedure DemoBusinessLogic;
begin
  Writeln('=== Demo 4: Logger in Business Logic ===');
  Writeln;

  // Reset to debug level to see all messages
  TLoggerFactory.UseConsoleLogger(llDebug);

  try
    ProcessOrder(100);
  except
    // Swallow exception for demo
  end;

  Writeln;

  try
    ProcessOrder(999);  // Will trigger warning
  except
    // Swallow exception for demo
  end;

  Writeln;

  try
    ProcessOrder(666);  // Will trigger error
  except
    on E: Exception do
      Writeln('Caught exception: ', E.Message);
  end;

  Writeln;
end;

/// <summary>
/// Demonstrates checking if log level is enabled before expensive operations
/// </summary>
procedure DemoLevelChecks;
var
  LLogger: ILogger;
  LExpensiveData: string;
begin
  Writeln('=== Demo 5: Conditional Logging for Performance ===');
  Writeln;

  TLoggerFactory.UseConsoleLogger(llInfo);
  LLogger := Log;

  // Bad practice - always constructs the expensive string
  Writeln('** Without level check (inefficient) **');
  LLogger.Debug('Debug data: ' + 'expensive operation result');

  Writeln;

  // Good practice - only constructs string if debug is enabled
  Writeln('** With level check (efficient) **');
  if LLogger.IsDebugEnabled then
  begin
    LExpensiveData := 'expensive operation result';
    LLogger.Debug('Debug data: ' + LExpensiveData);
  end
  else
  begin
    Writeln('(Debug logging is disabled, expensive operation skipped)');
  end;

  Writeln;
end;

/// <summary>
/// Demonstrates using named loggers for different components
/// </summary>
procedure DemoNamedLoggers;
var
  LLoggerMain: ILogger;
  LLoggerDb: ILogger;
  LLoggerApi: ILogger;
begin
  Writeln('=== Demo 6: Named Loggers (Spring Boot style) ===');
  Writeln;

  // Configure factory with debug level
  TLoggerFactory.UseConsoleLogger(llDebug);

  // Get named loggers for different components
  LLoggerMain := TLoggerFactory.GetLogger('MyApp.Main');
  LLoggerDb := TLoggerFactory.GetLogger('MyApp.Database');
  LLoggerApi := TLoggerFactory.GetLogger('MyApp.ApiClient');

  // Also works with root logger (no name)
  Writeln('** Root logger (no name) **');
  Log.Info('Application starting');

  Writeln;
  Writeln('** Named loggers with aligned output **');

  LLoggerMain.Info('Application initialized');
  LLoggerMain.Debug('Loading configuration from app.config');

  LLoggerDb.Info('Connecting to database');
  LLoggerDb.Debug('Connection string: localhost:5432');
  LLoggerDb.Info('Database connection established');

  LLoggerApi.Info('Initializing API client');
  LLoggerApi.Debug('Base URL: https://api.example.com');
  LLoggerApi.Warn('API rate limit: 100 requests/min');

  LLoggerMain.Info('All systems ready');

  Writeln;
end;

/// <summary>
/// Demonstrates automatic configuration loading from .properties files
/// </summary>
procedure DemoAutoConfiguration;
var
  LConfigFile: string;
begin
  Writeln('=== Demo 7: Automatic Configuration (NEW!) ===');
  Writeln;

  {$IFDEF DEBUG}
  Writeln('** DEBUG build - looking for logging-debug.properties **');
  LConfigFile := 'logging-debug.properties';
  {$ELSE}
  Writeln('** RELEASE build - looking for logging.properties **');
  LConfigFile := 'logging.properties';
  {$ENDIF}

  Writeln('Configuration is loaded automatically on first GetLogger() call');
  Writeln('Config file: ', LConfigFile);
  Writeln;

  if TFile.Exists(LConfigFile) or
     TFile.Exists(TPath.Combine(ExtractFilePath(ParamStr(0)), LConfigFile)) then
  begin
    Writeln('Config file found! Logger levels will be loaded from file.');
    Writeln('Example: Set MyApp.Main=DEBUG in the .properties file');
  end
  else
  begin
    Writeln('Config file not found - using default levels (INFO)');
    Writeln('To enable config: Create ' + LConfigFile + ' in the executable directory');
    Writeln;
    Writeln('Example content:');
    Writeln('  root=INFO');
    Writeln('  MyApp.*=DEBUG');
    Writeln('  mqtt.*=TRACE');
  end;

  Writeln;
  Writeln('For more advanced configuration examples, see ConfigExample.dpr');
  Writeln;
end;

{ NOTE: Logger Context functionality is not yet implemented.
  Demo 8 has been disabled. To enable it, implement:
  - Logger.Context.pas with TLoggerContext class
  - PushContext/PopContext methods
  - Logger.AutoContext.inc include file
}

begin
  try
    Writeln('LoggingFacade - Basic Examples');
    Writeln('==============================');
    Writeln;

    DemoBasicLogging;
    DemoLogLevels;
    DemoNullLogger;
    DemoBusinessLogic;
    DemoLevelChecks;
    DemoNamedLoggers;
    DemoAutoConfiguration;
    // DemoLoggerContext;  // Disabled - Logger.Context not implemented

    Writeln('======================================');
    Writeln('All demos completed successfully!');
    Writeln;
    Writeln('Next: Try ConfigExample.dpr for advanced features!');
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
