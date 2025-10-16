program LoggerProExample;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Logger.Types,
  Logger.Intf,
  Logger.Factory,
  Logger.LoggerPro.Adapter,
  LoggerPro,
  LoggerPro.FileAppender,
  LoggerPro.OutputDebugStringAppender;

var
  GLogWriter: ILogWriter;

/// <summary>
/// Configures LoggerPro with file and debug appenders
/// </summary>
procedure ConfigureLoggerPro;
begin
  // Create LoggerPro with multiple appenders
  GLogWriter := BuildLogWriter([
    TLoggerProFileAppender.Create(10, 5, 'logs'),
    TLoggerProOutputDebugStringAppender.Create
  ]);

  Writeln('LoggerPro configured with file and debug appenders');
  Writeln('Log files will be written to: logs\');
  Writeln;
end;

/// <summary>
/// Demonstrates using LoggerPro through our facade
/// </summary>
procedure DemoLoggerPro;
var
  LLogger: ILogger;
begin
  Writeln('=== LoggerPro Adapter Demo ===');
  Writeln;

  // Configure our factory to use LoggerPro adapter (root logger with no name)
  TLoggerFactory.SetLogger(TLoggerProAdapter.Create('', GLogWriter, llDebug));

  // Get logger instance - application code doesn't know it's using LoggerPro
  LLogger := Log;

  LLogger.Info('Application started');
  LLogger.Debug('Debug information - check the log file!');
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
/// Simulates a business service using logging
/// </summary>
type
  TUserService = class
  private
    FLogger: ILogger;
  public
    constructor Create;
    procedure RegisterUser(const AUsername, AEmail: string);
    procedure DeleteUser(const AUsername: string);
  end;

constructor TUserService.Create;
begin
  inherited Create;
  // Service gets logger from factory - doesn't care about implementation
  FLogger := Log;
end;

procedure TUserService.RegisterUser(const AUsername, AEmail: string);
begin
  FLogger.Info('Registering new user: %s', [AUsername]);
  FLogger.Debug('User email: %s', [AEmail]);

  // Simulate validation
  if Length(AUsername) < 3 then
  begin
    FLogger.Warn('Username too short: %s', [AUsername]);
    raise Exception.Create('Username must be at least 3 characters');
  end;

  // Simulate database operation
  FLogger.Debug('Saving user to database');
  Sleep(100);

  FLogger.Info('User registered successfully: %s', [AUsername]);
end;

procedure TUserService.DeleteUser(const AUsername: string);
begin
  FLogger.Info('Deleting user: %s', [AUsername]);

  try
    // Simulate database operation
    FLogger.Debug('Removing user from database');
    Sleep(50);

    if AUsername = 'admin' then
      raise Exception.Create('Cannot delete admin user');

    FLogger.Info('User deleted successfully: %s', [AUsername]);
  except
    on E: Exception do
    begin
      FLogger.Error('Failed to delete user: %s', E);
      raise;
    end;
  end;
end;

/// <summary>
/// Demonstrates using the logger in a service class
/// </summary>
procedure DemoServiceWithLogging;
var
  LUserService: TUserService;
begin
  Writeln('=== Service with Logging Demo ===');
  Writeln;

  LUserService := TUserService.Create;
  try
    // Successful registration
    try
      LUserService.RegisterUser('john_doe', 'john@example.com');
    except
      on E: Exception do
        Writeln('Registration failed: ', E.Message);
    end;

    Writeln;

    // Failed registration (username too short)
    try
      LUserService.RegisterUser('ab', 'short@example.com');
    except
      on E: Exception do
        Writeln('Registration failed: ', E.Message);
    end;

    Writeln;

    // Successful deletion
    try
      LUserService.DeleteUser('john_doe');
    except
      on E: Exception do
        Writeln('Deletion failed: ', E.Message);
    end;

    Writeln;

    // Failed deletion (admin user)
    try
      LUserService.DeleteUser('admin');
    except
      on E: Exception do
        Writeln('Deletion failed: ', E.Message);
    end;
  finally
    LUserService.Free;
  end;

  Writeln;
end;

/// <summary>
/// Demonstrates switching between different logger implementations at runtime
/// </summary>
procedure DemoSwitchingLoggers;
var
  LLogger: ILogger;
begin
  Writeln('=== Switching Logger Implementations ===');
  Writeln;

  // Start with LoggerPro
  Writeln('** Using LoggerPro **');
  TLoggerFactory.SetLogger(TLoggerProAdapter.Create('', GLogWriter, llInfo));
  LLogger := Log;
  LLogger.Info('This message goes through LoggerPro');

  Writeln;

  // Switch to default console logger
  Writeln('** Switching to Console Logger **');
  TLoggerFactory.Reset;  // Reset to default
  LLogger := Log;
  LLogger.Info('This message goes through the default console logger');

  Writeln;

  // Switch back to LoggerPro
  Writeln('** Switching back to LoggerPro **');
  TLoggerFactory.SetLogger(TLoggerProAdapter.Create('', GLogWriter, llInfo));
  LLogger := Log;
  LLogger.Info('Back to LoggerPro');

  Writeln;
end;

begin
  try
    Writeln('LoggingFacade - LoggerPro Integration Example');
    Writeln('==============================================');
    Writeln;

    // Configure LoggerPro
    ConfigureLoggerPro;

    // Run demos
    DemoLoggerPro;
    DemoServiceWithLogging;
    DemoSwitchingLoggers;

    Writeln('==============================================');
    Writeln('All demos completed successfully!');
    Writeln('Check the "logs" directory for log files.');
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
