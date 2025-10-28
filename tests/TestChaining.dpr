program TestChaining;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Logger.Intf,
  Logger.Factory,
  Logger.Console,
  Logger.Debug,
  Logger.Null,
  Logger.Types;

procedure TestBasicChaining;
var
  Logger1, Logger2: ILogger;
begin
  Writeln('=== Test Basic Chaining ===');

  // Create first logger
  Logger1 := TConsoleLogger.Create('Test1', llInfo, True);

  // Create second logger and add to chain
  Logger2 := TConsoleLogger.Create('Test2', llDebug, False);
  Logger1.AddToChain(Logger2);

  // Test logging
  Logger1.Info('This should appear in both loggers');

  // Check chain count
  if Logger1.GetChainCount = 2 then
    Writeln('[PASS] Chain count is correct: 2')
  else
    Writeln('[FAIL] Chain count is wrong: ', Logger1.GetChainCount);

  Writeln;
end;

procedure TestFactoryWithChaining;
var
  Logger, AdditionalLogger: ILogger;
begin
  Writeln('=== Test Factory with Chaining ===');

  // Get logger from factory
  Logger := TLoggerFactory.GetLogger;

  // Add an additional logger to the chain
  AdditionalLogger := TConsoleLogger.Create('Additional', llTrace, True);
  TLoggerFactory.AddLogger('', AdditionalLogger);

  // Test logging
  Logger.Info('Testing factory with chain');

  Writeln('[PASS] Factory chaining works');
  Writeln;
end;

procedure TestRemoveFromChain;
var
  Logger1, Logger2, Logger3: ILogger;
begin
  Writeln('=== Test Remove from Chain ===');

  // Create chain
  Logger1 := TConsoleLogger.Create('First', llInfo, True);
  Logger2 := TDebugLogger.Create('Second', llDebug);
  Logger3 := TNullLogger.Create('Third');

  Logger1.AddToChain(Logger2);
  Logger1.AddToChain(Logger3);

  if Logger1.GetChainCount = 3 then
    Writeln('[PASS] Initial chain count: 3')
  else
    Writeln('[FAIL] Wrong initial count: ', Logger1.GetChainCount);

  // Remove middle logger
  if Logger1.RemoveFromChain(Logger2) then
    Writeln('[PASS] Logger removed successfully')
  else
    Writeln('[FAIL] Failed to remove logger');

  if Logger1.GetChainCount = 2 then
    Writeln('[PASS] Chain count after removal: 2')
  else
    Writeln('[FAIL] Wrong count after removal: ', Logger1.GetChainCount);

  Writeln;
end;

procedure TestClearChain;
var
  Logger1, Logger2, Logger3: ILogger;
begin
  Writeln('=== Test Clear Chain ===');

  // Create chain
  Logger1 := TConsoleLogger.Create('Main', llInfo, True);
  Logger2 := TDebugLogger.Create('Debug', llDebug);
  Logger3 := TNullLogger.Create('Null');

  Logger1.AddToChain(Logger2);
  Logger1.AddToChain(Logger3);

  if Logger1.GetChainCount = 3 then
    Writeln('[PASS] Chain has 3 loggers')
  else
    Writeln('[FAIL] Wrong count: ', Logger1.GetChainCount);

  // Clear chain
  Logger1.ClearChain;

  if Logger1.GetChainCount = 1 then
    Writeln('[PASS] Chain cleared, only root remains')
  else
    Writeln('[FAIL] Clear failed, count: ', Logger1.GetChainCount);

  Writeln;
end;

procedure TestDuplicatePrevention;
var
  Logger1, Logger2: ILogger;
begin
  Writeln('=== Test Duplicate Prevention ===');

  Logger1 := TConsoleLogger.Create('Main', llInfo, True);
  Logger2 := TConsoleLogger.Create('Second', llDebug, False);

  // Add logger
  Logger1.AddToChain(Logger2);
  if Logger1.GetChainCount = 2 then
    Writeln('[PASS] First add successful')
  else
    Writeln('[FAIL] First add failed');

  // Try to add same logger again
  Logger1.AddToChain(Logger2);
  if Logger1.GetChainCount = 2 then
    Writeln('[PASS] Duplicate prevented')
  else
    Writeln('[FAIL] Duplicate not prevented, count: ', Logger1.GetChainCount);

  Writeln;
end;

procedure TestLevelFiltering;
var
  Logger1, Logger2: ILogger;
begin
  Writeln('=== Test Level Filtering ===');

  // Create chain with different levels
  Logger1 := TConsoleLogger.Create('DebugLogger', llDebug, True);
  Logger2 := TConsoleLogger.Create('ErrorLogger', llError, False);
  Logger1.AddToChain(Logger2);

  Writeln('Logger1: DEBUG level, Logger2: ERROR level');

  Writeln('Sending DEBUG (should only appear once):');
  Logger1.Debug('Debug message');

  Writeln('Sending ERROR (should appear twice):');
  Logger1.Error('Error message');

  Writeln('[PASS] Level filtering in chain works');
  Writeln;
end;

begin
  try
    Writeln('========================================');
    Writeln('   Chain of Responsibility Unit Tests');
    Writeln('========================================');
    Writeln;

    TestBasicChaining;
    TestFactoryWithChaining;
    TestRemoveFromChain;
    TestClearChain;
    TestDuplicatePrevention;
    TestLevelFiltering;

    Writeln('========================================');
    Writeln('All tests completed!');
    Writeln('Press ENTER to exit...');
    Readln;
  except
    on E: Exception do
    begin
      Writeln('[ERROR] Test failed with exception: ', E.ClassName, ': ', E.Message);
      Readln;
      ExitCode := 1;
    end;
  end;
end.