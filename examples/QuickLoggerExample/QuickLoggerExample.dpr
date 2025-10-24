program QuickLoggerExample;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.DateUtils,
  Logger.Types,
  Logger.Intf,
  Logger.Factory,
  Logger.QuickLogger.Adapter,
  Quick.Logger,
  Quick.Logger.Provider.Console,
  Quick.Logger.Provider.Files;

/// <summary>
/// Configures QuickLogger with console and file providers
/// </summary>
procedure ConfigureQuickLogger;
var
  LConsoleProvider: TLogConsoleProvider;
  LFileProvider: TLogFileProvider;
begin
  // Configure QuickLogger with multiple providers

  // Add console provider
  LConsoleProvider := TLogConsoleProvider.Create;
  LConsoleProvider.LogLevel := LOG_ALL;
  LConsoleProvider.ShowEventColors := True;
  Quick.Logger.Logger.Providers.Add(LConsoleProvider);

  // Add file provider
  LFileProvider := TLogFileProvider.Create;
  LFileProvider.LogLevel := LOG_ALL;
  LFileProvider.FileName := 'app.log';
  LFileProvider.MaxFileSizeInMB := 10;
  // LFileProvider.MaxBackupFiles := 5;  // Property may not exist in all QuickLogger versions
  Quick.Logger.Logger.Providers.Add(LFileProvider);

  Writeln('QuickLogger configured with console and file providers');
  Writeln('Log file: app.log');
  Writeln;
end;

/// <summary>
/// Demonstrates using QuickLogger through our facade
/// </summary>
procedure DemoQuickLogger;
var
  LLogger: ILogger;
begin
  Writeln('=== QuickLogger Adapter Demo ===');
  Writeln;

  // Configure our factory to use QuickLogger adapter (root logger with no name)
  TLoggerFactory.SetLogger(TQuickLoggerAdapter.Create('', llDebug));

  // Get logger instance - application code doesn't know it's using QuickLogger
  LLogger := TLoggerFactory.GetLogger;

  LLogger.Trace('Trace message - very detailed');
  LLogger.Debug('Debug information - check the log file!');
  LLogger.Info('Application started');
  LLogger.Warn('This is a warning message');
  LLogger.Error('This is an error message');

  try
    raise Exception.Create('Simulated error for logging');
  except
    on E: Exception do
      LLogger.Error('Exception occurred during processing', E);
  end;

  LLogger.Info('Application completed');
  Writeln;
end;

/// <summary>
/// Simulates an API service using logging
/// </summary>
type
  TApiService = class
  private
    FLogger: ILogger;
  public
    constructor Create;
    function ProcessRequest(const AEndpoint, AMethod: string): Boolean;
    procedure HandleError(const AMessage: string; AException: Exception);
  end;

constructor TApiService.Create;
begin
  inherited Create;
  // Service gets logger from factory
  FLogger := TLoggerFactory.GetLogger;
end;

function TApiService.ProcessRequest(const AEndpoint, AMethod: string): Boolean;
begin
  FLogger.Info('Received %s request for %s', [AMethod, AEndpoint]);
  FLogger.Debug('Processing request...');

  try
    // Simulate request processing
    Sleep(Random(200) + 50);

    if Random(10) > 7 then
    begin
      FLogger.Warn('Request took longer than expected');
    end;

    // Simulate occasional errors
    if AEndpoint = '/error' then
      raise Exception.Create('Simulated API error');

    FLogger.Info('Request completed successfully');
    Result := True;
  except
    on E: Exception do
    begin
      HandleError('Request failed', E);
      Result := False;
    end;
  end;
end;

procedure TApiService.HandleError(const AMessage: string; AException: Exception);
begin
  FLogger.Error(AMessage, AException);
  // Additional error handling logic here
end;

/// <summary>
/// Demonstrates using the logger in an API service
/// </summary>
procedure DemoApiServiceWithLogging;
var
  LApiService: TApiService;
begin
  Writeln('=== API Service with Logging Demo ===');
  Writeln;

  LApiService := TApiService.Create;
  try
    LApiService.ProcessRequest('/api/users', 'GET');
    Writeln;

    LApiService.ProcessRequest('/api/users/123', 'GET');
    Writeln;

    LApiService.ProcessRequest('/api/users', 'POST');
    Writeln;

    // This will trigger an error
    LApiService.ProcessRequest('/error', 'GET');
    Writeln;
  finally
    LApiService.Free;
  end;
end;

/// <summary>
/// Demonstrates performance-conscious logging with level checks
/// </summary>
procedure DemoPerformanceLogging;
var
  LLogger: ILogger;
  I: Integer;
  LStartTime: TDateTime;
  LElapsedMs: Int64;
begin
  Writeln('=== Performance-Conscious Logging Demo ===');
  Writeln;

  TLoggerFactory.SetLogger(TQuickLoggerAdapter.Create('', llInfo));
  LLogger := TLoggerFactory.GetLogger;

  Writeln('** Without level checking (inefficient) **');
  LStartTime := Now;
  for I := 1 to 10000 do
  begin
    LLogger.Debug('Iteration: %d with data: %s', [I, 'some expensive string']);
  end;
  LElapsedMs := MilliSecondsBetween(Now, LStartTime);
  Writeln(Format('Time: %d ms', [LElapsedMs]));
  Writeln;

  Writeln('** With level checking (efficient) **');
  LStartTime := Now;
  for I := 1 to 10000 do
  begin
    if LLogger.IsDebugEnabled then
      LLogger.Debug('Iteration: %d with data: %s', [I, 'some expensive string']);
  end;
  LElapsedMs := MilliSecondsBetween(Now, LStartTime);
  Writeln(Format('Time: %d ms (much faster because debug is disabled)', [LElapsedMs]));
  Writeln;
end;

/// <summary>
/// Demonstrates structured logging approach
/// </summary>
procedure DemoStructuredLogging;
var
  LLogger: ILogger;
begin
  Writeln('=== Structured Logging Demo ===');
  Writeln;

  TLoggerFactory.SetLogger(TQuickLoggerAdapter.Create('', llDebug));
  LLogger := TLoggerFactory.GetLogger;

  // Log with context information
  LLogger.Info('User login successful | UserID: %d | IP: %s | Duration: %dms',
    [12345, '192.168.1.100', 150]);

  LLogger.Warn('Database query slow | Query: %s | Duration: %dms | Threshold: %dms',
    ['SELECT * FROM users', 2500, 1000]);

  LLogger.Error('Payment processing failed | OrderID: %d | Amount: %.2f | Reason: %s',
    [78901, 99.99, 'Insufficient funds']);

  Writeln;
end;

begin
  try
    Randomize;

    Writeln('LoggingFacade - QuickLogger Integration Example');
    Writeln('================================================');
    Writeln;

    // Configure QuickLogger
    ConfigureQuickLogger;

    // Run demos
    DemoQuickLogger;
    DemoApiServiceWithLogging;
    DemoPerformanceLogging;
    DemoStructuredLogging;

    Writeln('=======================================================');
    Writeln('All demos completed successfully!');
    Writeln('Check "app.log" for the complete log file.');
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
