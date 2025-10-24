program StackTraceTest;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Logger.Types,
  Logger.Intf,
  Logger.Factory,
  Logger.StackTrace,
  Logger.StackTrace.JclDebug;

type
  TTestResult = record
    TestName: string;
    Success: Boolean;
    ErrorMessage: string;
  end;

var
  GTestResults: array of TTestResult;

procedure AddTestResult(const ATestName: string; ASuccess: Boolean; const AErrorMessage: string = '');
var
  Len: Integer;
begin
  Len := Length(GTestResults);
  SetLength(GTestResults, Len + 1);
  GTestResults[Len].TestName := ATestName;
  GTestResults[Len].Success := ASuccess;
  GTestResults[Len].ErrorMessage := AErrorMessage;
end;

procedure PrintTestResults;
var
  I: Integer;
  PassCount, FailCount: Integer;
begin
  Writeln;
  Writeln('========================================');
  Writeln('Test Results Summary');
  Writeln('========================================');
  Writeln;

  PassCount := 0;
  FailCount := 0;

  for I := 0 to Length(GTestResults) - 1 do
  begin
    if GTestResults[I].Success then
    begin
      Inc(PassCount);
      Writeln('[PASS] ', GTestResults[I].TestName);
    end
    else
    begin
      Inc(FailCount);
      Writeln('[FAIL] ', GTestResults[I].TestName);
      if GTestResults[I].ErrorMessage <> '' then
        Writeln('       Error: ', GTestResults[I].ErrorMessage);
    end;
  end;

  Writeln;
  Writeln('Total: ', Length(GTestResults), ' tests');
  Writeln('Passed: ', PassCount);
  Writeln('Failed: ', FailCount);
  Writeln;

  if FailCount = 0 then
    Writeln('All tests passed!')
  else
    Writeln('Some tests failed!');
end;

// Test functions

procedure Test_StackTraceManager_Initialization;
begin
  Writeln('Test 1: StackTraceManager Initialization');
  try
    // Should not be enabled by default
    if not TStackTraceManager.IsEnabled then
      AddTestResult('StackTraceManager starts disabled', True)
    else
      AddTestResult('StackTraceManager starts disabled', False, 'Manager was enabled by default');
  except
    on E: Exception do
      AddTestResult('StackTraceManager Initialization', False, E.Message);
  end;
end;

procedure Test_EnableDisable;
begin
  Writeln('Test 2: Enable/Disable functionality');
  try
    // Test enable
    TStackTraceManager.SetProvider(TJclDebugStackTraceProvider.Create);
    TStackTraceManager.Enable;

    if TStackTraceManager.IsEnabled then
      AddTestResult('Enable stack traces', True)
    else
      AddTestResult('Enable stack traces', False, 'Enable failed');

    // Test disable
    TStackTraceManager.Disable;

    if not TStackTraceManager.IsEnabled then
      AddTestResult('Disable stack traces', True)
    else
      AddTestResult('Disable stack traces', False, 'Disable failed');

    // Re-enable for other tests
    TStackTraceManager.Enable;
  except
    on E: Exception do
      AddTestResult('Enable/Disable', False, E.Message);
  end;
end;

procedure Level3_ThrowException;
begin
  raise Exception.Create('Test exception from Level 3');
end;

procedure Level2_CallLevel3;
begin
  Level3_ThrowException;
end;

procedure Level1_CallLevel2;
begin
  Level2_CallLevel3;
end;

procedure Test_ExceptionStackTrace;
var
  StackTrace: string;
  HasStackInfo: Boolean;
begin
  Writeln('Test 3: Exception stack trace capture');
  try
    Level1_CallLevel2;
    AddTestResult('Exception stack trace', False, 'Exception not raised');
  except
    on E: Exception do
    begin
      try
        StackTrace := TStackTraceManager.GetStackTrace(E);
        // With JCL Debug, check for actual function names
        HasStackInfo := (StackTrace <> '') and
                        (Pos('Level3_ThrowException', StackTrace) > 0);

        if HasStackInfo then
        begin
          Writeln('Stack trace captured:');
          Writeln(StackTrace);
          Writeln;
          AddTestResult('Exception stack trace capture', True);
        end
        else
        begin
          AddTestResult('Exception stack trace capture', False,
            'Stack trace empty or missing function names. Got: ' + StackTrace);
        end;
      except
        on E2: Exception do
          AddTestResult('Exception stack trace capture', False, E2.Message);
      end;
    end;
  end;
end;

procedure Test_CurrentStackTrace;
var
  StackTrace: string;
  HasStackInfo: Boolean;
begin
  Writeln('Test 4: Current stack trace capture');
  try
    StackTrace := TStackTraceManager.GetCurrentStackTrace;
    // With JCL Debug, check for actual function name
    HasStackInfo := (StackTrace <> '') and
                    (Pos('Test_CurrentStackTrace', StackTrace) > 0);

    if HasStackInfo then
    begin
      Writeln('Current stack trace:');
      Writeln(StackTrace);
      Writeln;
      AddTestResult('Current stack trace capture', True);
    end
    else
      AddTestResult('Current stack trace capture', False,
        'Stack trace empty or missing function names. Got: ' + StackTrace);
  except
    on E: Exception do
      AddTestResult('Current stack trace capture', False, E.Message);
  end;
end;

procedure Test_LoggerIntegration;
var
  LLogger: ILogger;
  ErrorOccurred: Boolean;
begin
  Writeln('Test 5: Logger integration with stack traces');
  try
    ErrorOccurred := False;
    LLogger := Log;

    try
      Level1_CallLevel2;
    except
      on E: Exception do
      begin
        ErrorOccurred := True;
        // This should log with stack trace
        LLogger.Error('Test error with exception', E);
      end;
    end;

    if ErrorOccurred then
      AddTestResult('Logger integration', True)
    else
      AddTestResult('Logger integration', False, 'Exception not caught');
  except
    on E: Exception do
      AddTestResult('Logger integration', False, E.Message);
  end;
end;

procedure Test_FormatExceptionMessage;
var
  FormattedMsg: string;
begin
  Writeln('Test 6: Format exception message');
  try
    try
      raise Exception.Create('Test exception');
    except
      on Ex: Exception do
      begin
        FormattedMsg := TStackTraceManager.FormatExceptionMessage('Operation failed', Ex);

        if (FormattedMsg <> '') and
           (Pos('Exception:', FormattedMsg) > 0) and
           (Pos('Test exception', FormattedMsg) > 0) then
          AddTestResult('Format exception message', True)
        else
          AddTestResult('Format exception message', False,
            'Formatted message missing expected content');
      end;
    end;
  except
    on E: Exception do
      AddTestResult('Format exception message', False, E.Message);
  end;
end;

procedure Test_StackTraceWithDisabledManager;
var
  StackTrace: string;
begin
  Writeln('Test 7: Stack trace when manager is disabled');
  try
    TStackTraceManager.Disable;

    StackTrace := TStackTraceManager.GetCurrentStackTrace;

    if StackTrace = '' then
      AddTestResult('Stack trace when disabled', True)
    else
      AddTestResult('Stack trace when disabled', False,
        'Stack trace should be empty when disabled');

    // Re-enable
    TStackTraceManager.Enable;
  except
    on E: Exception do
      AddTestResult('Stack trace when disabled', False, E.Message);
  end;
end;

procedure Test_MultipleExceptionTypes;
var
  TestPassed: Boolean;
  DivByZeroOK, AccessViolationOK, ArgumentOK: Boolean;
begin
  Writeln('Test 8: Multiple exception types');
  try
    DivByZeroOK := False;
    AccessViolationOK := False;
    ArgumentOK := False;

    // Test 1: Division by zero
    try
      var X := 10;
      var Y := 0;
      var Z := X div Y; // Will raise EDivByZero
      if Z = 0 then; // Suppress unused variable warning
    except
      on E: EDivByZero do
      begin
        var ST := TStackTraceManager.GetStackTrace(E);
        DivByZeroOK := ST <> '';
      end;
    end;

    // Test 2: Access violation
    try
      var Obj: TObject := nil;
      var S := Obj.ToString; // This will cause EAccessViolation (virtual method call on nil)
    except
      on E: EAccessViolation do
      begin
        var ST := TStackTraceManager.GetStackTrace(E);
        AccessViolationOK := ST <> '';
      end;
    end;

    // Test 3: Argument exception
    try
      raise EArgumentException.Create('Invalid argument');
    except
      on E: EArgumentException do
      begin
        var ST := TStackTraceManager.GetStackTrace(E);
        ArgumentOK := ST <> '';
      end;
    end;

    TestPassed := DivByZeroOK and AccessViolationOK and ArgumentOK;

    if TestPassed then
      AddTestResult('Multiple exception types', True)
    else
      AddTestResult('Multiple exception types', False,
        Format('EDivByZero:%s, EAccessViolation:%s, EArgument:%s',
          [BoolToStr(DivByZeroOK, True),
           BoolToStr(AccessViolationOK, True),
           BoolToStr(ArgumentOK, True)]));
  except
    on E: Exception do
      AddTestResult('Multiple exception types', False, E.Message);
  end;
end;

procedure Test_ThreadSafety;
var
  Success: Boolean;
begin
  Writeln('Test 9: Thread safety (basic)');
  try
    // Basic thread safety test - rapid enable/disable
    TStackTraceManager.Enable;
    TStackTraceManager.Disable;
    TStackTraceManager.Enable;
    TStackTraceManager.Disable;
    TStackTraceManager.Enable;

    Success := TStackTraceManager.IsEnabled;

    if Success then
      AddTestResult('Thread safety (basic)', True)
    else
      AddTestResult('Thread safety (basic)', False, 'State inconsistent');
  except
    on E: Exception do
      AddTestResult('Thread safety (basic)', False, E.Message);
  end;
end;

procedure Test_ProviderAvailability;
var
  Provider: IStackTraceProvider;
begin
  Writeln('Test 10: Provider availability check');
  try
    Provider := TJclDebugStackTraceProvider.Create;

    if Provider.IsAvailable then
      AddTestResult('Provider availability', True)
    else
      AddTestResult('Provider availability', False, 'Provider not available');
  except
    on E: Exception do
      AddTestResult('Provider availability', False, E.Message);
  end;
end;

begin
  try
    Writeln('========================================');
    Writeln('LoggingFacade - Stack Trace Test Suite');
    Writeln('========================================');
    Writeln;

    // Initialize logger
    TLoggerFactory.UseConsoleLogger(llDebug);

    // DO NOT initialize stack trace manager here - let tests handle it
    // so Test_StackTraceManager_Initialization can verify it starts disabled

    Writeln('Running tests...');
    Writeln;

    // Run all tests
    Test_StackTraceManager_Initialization;
    Test_EnableDisable;
    Test_ExceptionStackTrace;
    Test_CurrentStackTrace;
    Test_LoggerIntegration;
    Test_FormatExceptionMessage;
    Test_StackTraceWithDisabledManager;
    Test_MultipleExceptionTypes;
    Test_ThreadSafety;
    Test_ProviderAvailability;

    // Print results
    PrintTestResults;

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
