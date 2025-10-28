program ChainExample;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Logger.Types,
  Logger.Intf,
  Logger.Console,
  Logger.Null,
  Logger.Debug;

/// <summary>
/// Demonstrates basic chained logger usage with console loggers
/// </summary>
procedure DemoBasicChain;
var
  LChain: ILogger;
  LConsole2: ILogger;
begin
  Writeln('=== Demo 1: Basic Chained Loggers ===');
  Writeln;

  // Create first logger in chain
  LChain := TConsoleLogger.Create('Console1', llDebug, True);

  // Create second logger and add to chain
  LConsole2 := TConsoleLogger.Create('Console2', llInfo, False);
  LChain.AddToChain(LConsole2);

  Writeln('** Logging to both console loggers **');
  Writeln;

  // This message goes to both loggers
  LChain.Info('This message appears twice (from both loggers)');
  LChain.Debug('Debug message (both loggers show it if level allows)');

  Writeln;
  Writeln('Chain count: ', LChain.GetChainCount);
  Writeln;
end;

/// <summary>
/// Demonstrates adding and removing loggers dynamically from chain
/// </summary>
procedure DemoDynamicChain;
var
  LChain: ILogger;
  LNull: ILogger;
begin
  Writeln('=== Demo 2: Dynamic Add/Remove in Chain ===');
  Writeln;

  // Start with console logger
  LChain := TConsoleLogger.Create('Console', llInfo, True);

  Writeln('** Console logger active **');
  LChain.Info('Message 1: Console is active');
  Writeln;

  // Add null logger to chain
  LNull := TNullLogger.Create;
  LChain.AddToChain(LNull);

  Writeln('** Console + Null logger chain **');
  LChain.Info('Message 2: Both loggers in chain');
  Writeln('Chain count: ', LChain.GetChainCount);
  Writeln;

  // Remove null logger from chain
  LChain.RemoveFromChain(LNull);

  Writeln('** Null logger removed, only Console remains **');
  LChain.Info('Message 3: Back to single logger');
  Writeln('Chain count: ', LChain.GetChainCount);
  Writeln;

  // Clear all from chain (keeps only first)
  LChain.ClearChain;
  Writeln('** Chain cleared **');
  LChain.Info('Message 4: Single logger after clear');
  Writeln('Chain count: ', LChain.GetChainCount);
  Writeln;
end;

/// <summary>
/// Demonstrates level filtering in chained loggers
/// </summary>
procedure DemoLevelFiltering;
var
  LChain: ILogger;
  LConsole2: ILogger;
begin
  Writeln('=== Demo 3: Level Filtering in Chain ===');
  Writeln;

  // Create chain with different levels
  LChain := TConsoleLogger.Create('Console1', llDebug, True);
  LConsole2 := TConsoleLogger.Create('Console2', llError, True);
  LChain.AddToChain(LConsole2);

  Writeln('** Chain setup: **');
  Writeln('  Console1 level: DEBUG');
  Writeln('  Console2 level: ERROR');
  Writeln;

  Writeln('Sending DEBUG message:');
  LChain.Debug('This DEBUG message only shows in Console1');
  Writeln;

  Writeln('Sending INFO message:');
  LChain.Info('This INFO message only shows in Console1');
  Writeln;

  Writeln('Sending ERROR message:');
  LChain.Error('This ERROR message shows in both');
  Writeln;
end;

/// <summary>
/// Demonstrates dynamic level changes in chain
/// </summary>
procedure DemoDynamicLevelChange;
var
  LChain: ILogger;
  LConsole2: ILogger;
begin
  Writeln('=== Demo 4: Dynamic Level Changes ===');
  Writeln;

  // Create chain with INFO level
  LChain := TConsoleLogger.Create('Console1', llInfo, True);
  LConsole2 := TConsoleLogger.Create('Console2', llInfo, False);
  LChain.AddToChain(LConsole2);

  Writeln('** Both loggers initially set to INFO level **');
  Writeln;

  Writeln('Attempting DEBUG message:');
  LChain.Debug('This DEBUG is filtered by both');
  Writeln('(No output - INFO level blocks DEBUG)');
  Writeln;

  Writeln('INFO message:');
  LChain.Info('This INFO message appears in both');
  Writeln;

  // Change first logger level to DEBUG
  Writeln('** Changing Console1 level to DEBUG **');
  LChain.SetLevel(llDebug);
  Writeln;

  Writeln('Now DEBUG message:');
  LChain.Debug('Now DEBUG appears in Console1 only!');
  Writeln;

  // Change second logger level to ERROR
  Writeln('** Changing Console2 level to ERROR **');
  LConsole2.SetLevel(llError);
  Writeln;

  Writeln('Attempting INFO message:');
  LChain.Info('This INFO only in Console1 now');
  Writeln;

  Writeln('ERROR message:');
  LChain.Error('ERROR appears in both');
  Writeln;
end;

/// <summary>
/// Demonstrates a realistic use case: logging to multiple destinations via chaining
/// </summary>
procedure DemoRealWorldScenario;
var
  LChain: ILogger;
  LErrorLogger: ILogger;
  LDebugLogger: ILogger;
  I: Integer;
begin
  Writeln('=== Demo 5: Real-World Scenario with Chain ===');
  Writeln('Simulating an application that logs to:');
  Writeln('  - Console: All messages (INFO+)');
  Writeln('  - Error log: Only errors (ERROR+)');
  Writeln('  - Debug output: Debug and above (DEBUG+)');
  Writeln;

  // Create chain starting with console logger
  LChain := TConsoleLogger.Create('Console', llInfo, True);

  // Add error logger to chain (simulated with different name prefix)
  LErrorLogger := TConsoleLogger.Create('ErrorLog', llError, True);
  LChain.AddToChain(LErrorLogger);

  // Add debug logger to chain
  LDebugLogger := TDebugLogger.Create('DebugLog', llDebug);
  LChain.AddToChain(LDebugLogger);

  Writeln('** Simulating application workflow **');
  Writeln;

  LChain.Info('Application starting...');
  LChain.Debug('Configuration loaded from app.config');

  for I := 1 to 3 do
  begin
    LChain.Debug('Processing item #%d', [I]);

    if I = 2 then
    begin
      LChain.Warn('Item #%d requires special handling', [I]);
    end;

    if I = 3 then
    begin
      try
        raise Exception.Create('Simulated error in processing');
      except
        on E: Exception do
          LChain.Error('Failed to process item #%d: %s', [I, E.Message]);
      end;
    end;
  end;

  LChain.Info('Processing completed (with errors)');
  Writeln;

  Writeln('** Summary **');
  Writeln('In a real application with chain:');
  Writeln('  - Console logger showed: INFO, WARN, ERROR messages');
  Writeln('  - ErrorLog logger showed only: ERROR messages');
  Writeln('  - DebugLog logger showed: DEBUG, INFO, WARN, ERROR messages');
  Writeln;
end;

/// <summary>
/// Demonstrates exception logging with chained loggers
/// </summary>
procedure DemoExceptionLogging;
var
  LChain: ILogger;
  LLogger2: ILogger;
  E: Exception;
begin
  Writeln('=== Demo 6: Exception Logging with Chain ===');
  Writeln;

  // Create chain
  LChain := TConsoleLogger.Create('Logger1', llInfo, True);
  LLogger2 := TConsoleLogger.Create('Logger2', llWarn, True);
  LChain.AddToChain(LLogger2);

  Writeln('** Testing exception logging **');
  Writeln;

  try
    raise Exception.Create('Sample exception for logging');
  except
    on Ex: Exception do
    begin
      E := Ex;
      LChain.Error('An error occurred', E);
    end;
  end;

  Writeln;

  try
    raise Exception.Create('Critical failure');
  except
    on Ex: Exception do
    begin
      E := Ex;
      LChain.Fatal('Fatal error in operation #%d', [42], E);
    end;
  end;

  Writeln;
end;

/// <summary>
/// Demonstrates avoiding duplicate logger registration in chain
/// </summary>
procedure DemoDuplicatePrevention;
var
  LChain: ILogger;
  LConsole: ILogger;
begin
  Writeln('=== Demo 7: Duplicate Logger Prevention in Chain ===');
  Writeln;

  // Create chain
  LChain := TConsoleLogger.Create('MainConsole', llInfo, True);

  // Create another logger
  LConsole := TConsoleLogger.Create('SecondConsole', llInfo, True);

  Writeln('Adding logger to chain for the first time...');
  LChain.AddToChain(LConsole);
  Writeln('Chain count: ', LChain.GetChainCount);
  Writeln;

  Writeln('Attempting to add the same logger again...');
  LChain.AddToChain(LConsole);
  Writeln('Chain count: ', LChain.GetChainCount);
  Writeln('(Count is still 2 - duplicate was prevented)');
  Writeln;

  Writeln('Sending a test message:');
  LChain.Info('This message appears in both loggers, but not duplicated');
  Writeln;
end;

/// <summary>
/// Demonstrates building complex chains
/// </summary>
procedure DemoComplexChain;
var
  LChain: ILogger;
  LConsoleLogger: ILogger;
  LNullLogger: ILogger;
begin
  Writeln('=== Demo 8: Building Complex Chains ===');
  Writeln;

  // Start with debug logger
  LChain := TDebugLogger.Create('Debug', llTrace);
  Writeln('Chain started with Debug logger');

  // Add console logger
  LConsoleLogger := TConsoleLogger.Create('Console', llInfo, True);
  LChain.AddToChain(LConsoleLogger);
  Writeln('Added Console logger to chain');

  // Add null logger (for demonstration)
  LNullLogger := TNullLogger.Create('Null');
  LChain.AddToChain(LNullLogger);
  Writeln('Added Null logger to chain');

  Writeln;
  Writeln('Final chain has ' + IntToStr(LChain.GetChainCount) + ' loggers');
  Writeln;

  Writeln('Testing the chain:');
  LChain.Trace('TRACE: Goes to Debug only');
  LChain.Debug('DEBUG: Goes to Debug only');
  LChain.Info('INFO: Goes to Debug and Console');
  LChain.Error('ERROR: Goes to Debug and Console');
  Writeln;
end;

begin
  try
    Writeln('LoggingFacade - Chain of Responsibility Examples');
    Writeln('=================================================');
    Writeln;

    DemoBasicChain;
    DemoDynamicChain;
    DemoLevelFiltering;
    DemoDynamicLevelChange;
    DemoRealWorldScenario;
    DemoExceptionLogging;
    DemoDuplicatePrevention;
    DemoComplexChain;

    Writeln('=================================================');
    Writeln('All chain examples completed!');
    Writeln;
    Writeln('Key Benefits of Chain of Responsibility:');
    Writeln('  1. Dynamic composition - add/remove loggers at runtime');
    Writeln('  2. Zero overhead for single loggers');
    Writeln('  3. No separate composite class needed');
    Writeln('  4. Each logger can have its own filtering level');
    Writeln('  5. Thread-safe chain modifications');
    Writeln('  6. Automatic duplicate prevention');
    Writeln('  7. Flexible chain building');
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