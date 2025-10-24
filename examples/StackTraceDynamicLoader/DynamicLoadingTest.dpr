program DynamicLoadingTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Logger.Types,
  Logger.Intf,
  Logger.Factory,
  Logger.StackTrace;

procedure Level3_ThrowException;
begin
  raise Exception.Create('Test exception with dynamically loaded stack trace');
end;

procedure Level2_CallLevel3;
begin
  Level3_ThrowException;
end;

procedure Level1_CallLevel2;
begin
  Level2_CallLevel3;
end;

var
  LLogger: ILogger;

begin
  try
    Writeln('========================================');
    Writeln('Dynamic BPL Loading Test');
    Writeln('========================================');
    Writeln;

    // Initialize logger
    TLoggerFactory.UseConsoleLogger(llDebug);
    LLogger := Log;

    Writeln('Stack trace enabled: ', TStackTraceManager.IsEnabled);
    Writeln;

    if TStackTraceManager.IsEnabled then
    begin
      Writeln('Stack trace provider loaded successfully!');
      Writeln;

      // Test current stack trace
      Writeln('Current stack trace:');
      Writeln(TStackTraceManager.GetCurrentStackTrace);
      Writeln;
    end
    else
    begin
      Writeln('No stack trace provider loaded.');
      {$IFDEF MSWINDOWS}
      if TStackTraceManager.GetLastError <> '' then
      begin
        Writeln('Last error: ', TStackTraceManager.GetLastError);
      end;
      {$ENDIF}
      Writeln;
    end;

    // Test exception with stack trace
    Writeln('Testing exception handling...');
    Writeln('-----------------------------------');
    try
      Level1_CallLevel2;
    except
      on E: Exception do
      begin
        LLogger.Error('An error occurred', E);
      end;
    end;

    Writeln;
    Writeln('Test completed!');
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
