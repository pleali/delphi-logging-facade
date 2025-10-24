program StackTraceExample;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Logger.Types,
  Logger.Intf,
  Logger.Factory,
  Logger.StackTrace,
  Logger.StackTrace.JclDebug;

/// <summary>
/// Simulates a nested call stack to demonstrate stack trace capture
/// </summary>
procedure Level3Procedure;
begin
  raise Exception.Create('Something went wrong at level 3!');
end;

procedure Level2Procedure;
begin
  Log.Debug('Entering Level2Procedure');
  Level3Procedure;
end;

procedure Level1Procedure;
begin
  Log.Debug('Entering Level1Procedure');
  Level2Procedure;
end;

/// <summary>
/// Demonstrates basic stack trace capture with JclDebug
/// </summary>
procedure DemoBasicStackTrace;
var
  LLogger: ILogger;
begin
  Writeln('=== Demo 1: Basic Stack Trace Capture ===');
  Writeln;

  // Configure logger
  TLoggerFactory.UseConsoleLogger(llDebug);
  LLogger := Log;

  // Enable stack trace with JclDebug provider
  TStackTraceManager.SetProvider(TJclDebugStackTraceProvider.Create);
  TStackTraceManager.Enable;

  Writeln('Stack trace capture enabled with JclDebug');
  Writeln;

  try
    Level1Procedure;
  except
    on E: Exception do
    begin
      LLogger.Error('An error occurred in nested calls', E);
      Writeln;
      Writeln('Notice the stack trace showing the call chain above.');
    end;
  end;

  Writeln;
end;

/// <summary>
/// Demonstrates logging without stack trace for comparison
/// </summary>
procedure DemoWithoutStackTrace;
var
  LLogger: ILogger;
begin
  Writeln('=== Demo 2: Without Stack Trace (for comparison) ===');
  Writeln;

  // Disable stack trace
  TStackTraceManager.Disable;

  TLoggerFactory.UseConsoleLogger(llDebug);
  LLogger := Log;

  Writeln('Stack trace capture disabled');
  Writeln;

  try
    Level1Procedure;
  except
    on E: Exception do
    begin
      LLogger.Error('An error occurred in nested calls', E);
      Writeln;
      Writeln('Notice: No stack trace is shown.');
    end;
  end;

  Writeln;
end;

/// <summary>
/// Demonstrates getting current stack trace at any point
/// </summary>
procedure DemoCurrentStackTrace;
var
  LStackTrace: string;
begin
  Writeln('=== Demo 3: Current Stack Trace ===');
  Writeln;

  // Re-enable stack trace
  TStackTraceManager.Enable;

  Writeln('Getting current call stack at this point...');
  Writeln;

  LStackTrace := TStackTraceManager.GetCurrentStackTrace;

  if LStackTrace <> '' then
  begin
    Writeln('Current Stack Trace:');
    Writeln(LStackTrace);
  end
  else
  begin
    Writeln('(Stack trace not available)');
  end;

  Writeln;
end;

/// <summary>
/// Demonstrates multiple exception types with stack traces
/// </summary>
procedure DemoMultipleExceptions;
var
  LLogger: ILogger;
begin
  Writeln('=== Demo 4: Different Exception Types ===');
  Writeln;

  TLoggerFactory.UseConsoleLogger(llDebug);
  LLogger := Log;
  TStackTraceManager.Enable;

  // Division by zero
  Writeln('** Division by Zero Exception **');
  try
    var X := 10;
    var Y := 0;
    var Z := X div Y;  // This will raise EDivByZero
  except
    on E: Exception do
      LLogger.Error('Math operation failed', E);
  end;

  Writeln;

  // Access violation simulation (via nil pointer)
  Writeln('** Access Violation (Nil Pointer) **');
  try
    var Obj: TObject := nil;
    Obj.Free;  // This will raise EAccessViolation
  except
    on E: Exception do
      LLogger.Fatal('Critical system error', E);
  end;

  Writeln;

  // Custom exception
  Writeln('** Custom Exception **');
  try
    raise EArgumentException.Create('Invalid parameter value');
  except
    on E: Exception do
      LLogger.Error('Validation failed', E);
  end;

  Writeln;
end;

/// <summary>
/// Demonstrates using stack trace in production-like scenarios
/// </summary>
procedure DemoProductionUsage;
var
  LLogger: ILogger;

  procedure SimulateApiCall(const AUrl: string);
  begin
    if AUrl = '' then
      raise EArgumentException.Create('URL cannot be empty');

    // Simulate network error
    raise Exception.Create('Connection timeout');
  end;

  procedure ProcessRequest(const ARequestId: Integer);
  begin
    LLogger.Debug('Processing request #%d', [ARequestId]);

    try
      SimulateApiCall('');
    except
      on E: Exception do
      begin
        LLogger.Error('Request #%d failed', E);
        raise;
      end;
    end;
  end;

begin
  Writeln('=== Demo 5: Production-Like Usage ===');
  Writeln;

  TLoggerFactory.UseConsoleLogger(llInfo);
  LLogger := Log;
  TStackTraceManager.Enable;

  Writeln('Simulating production error handling...');
  Writeln;

  try
    ProcessRequest(12345);
  except
    on E: Exception do
    begin
      Writeln;
      Writeln('Error caught at top level. Stack trace shows full call chain.');
    end;
  end;

  Writeln;
end;

/// <summary>
/// Provides setup instructions for JclDebug
/// </summary>
procedure ShowSetupInstructions;
begin
  Writeln('========================================');
  Writeln('JclDebug Stack Trace Setup Instructions');
  Writeln('========================================');
  Writeln;
  Writeln('For best results with stack traces:');
  Writeln;
  Writeln('1. Install JEDI Code Library (JCL)');
  Writeln('   Download from: https://github.com/project-jedi/jcl');
  Writeln;
  Writeln('2. Compiler Settings (for detailed stack traces):');
  Writeln('   Option A: Use detailed map files');
  Writeln('     - Project -> Options -> Linking');
  Writeln('     - Set "Map file" to "Detailed"');
  Writeln;
  Writeln('   Option B: Use JCL Debug Information (recommended)');
  Writeln('     - Use JCL''s "Insert JCL Debug Data" tool');
  Writeln('     - This embeds debug info directly in the .exe');
  Writeln;
  Writeln('3. Add to your project:');
  Writeln('   uses');
  Writeln('     Logger.Factory,');
  Writeln('     Logger.StackTrace,');
  Writeln('     Logger.StackTrace.JclDebug;');
  Writeln;
  Writeln('4. Enable stack traces:');
  Writeln('   TStackTraceManager.SetProvider(TJclDebugStackTraceProvider.Create);');
  Writeln('   TStackTraceManager.Enable;');
  Writeln;
  Writeln('========================================');
  Writeln;
  Writeln('Press ENTER to continue to examples...');
  Readln;
  Writeln;
end;

begin
  try
    Writeln('LoggingFacade - Stack Trace Examples');
    Writeln('====================================');
    Writeln;

    ShowSetupInstructions;

    DemoBasicStackTrace;
    DemoWithoutStackTrace;
    DemoCurrentStackTrace;
    DemoMultipleExceptions;
    DemoProductionUsage;

    Writeln('======================================');
    Writeln('All demos completed successfully!');
    Writeln;
    Writeln('Stack traces provide valuable debugging information');
    Writeln('by showing the exact call chain that led to an error.');
    Writeln;
    Writeln('Remember to compile with debug information for');
    Writeln('best results (detailed map file or JCL debug data).');
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
