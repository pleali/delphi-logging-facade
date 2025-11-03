program AutoReloadExample;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Logger.Factory,
  Logger.Intf,
  Logger.Types;

var
  Logger: ILogger;
  Counter: Integer;
begin
  WriteLn('========================================');
  WriteLn(' Automatic Configuration Reload Demo');
  WriteLn('========================================');
  WriteLn;
  WriteLn('This example demonstrates automatic configuration file reloading.');
  WriteLn('The configuration file is monitored for changes and reloaded automatically.');
  WriteLn;
  WriteLn('Configuration file: logging-debug.properties');
  WriteLn('Current settings: scan=true, scan.period=10 seconds');
  WriteLn;
  WriteLn('Instructions:');
  WriteLn('1. Let the application run and observe the log output');
  WriteLn('2. Open logging-debug.properties in a text editor');
  WriteLn('3. Change the log levels (e.g., root=TRACE or root=ERROR)');
  WriteLn('4. Save the file');
  WriteLn('5. Within 10 seconds, you''ll see the changes take effect!');
  WriteLn('6. Try changing levels multiple times to see dynamic updates');
  WriteLn;
  WriteLn('Press Ctrl+C to exit');
  WriteLn;
  WriteLn('========================================');
  WriteLn;

  // Get logger - configuration will be loaded from logging-debug.properties
  Logger := TLoggerFactory.GetLogger('AutoReloadExample');
  Counter := 0;

  // Continuous logging loop
  while True do
  begin
    Inc(Counter);

    Logger.Trace('[%d] TRACE: Very detailed trace information', [Counter]);
    Logger.Debug('[%d] DEBUG: Debug information for developers', [Counter]);
    Logger.Info('[%d] INFO: General informational message', [Counter]);
    Logger.Warn('[%d] WARN: Warning message', [Counter]);
    Logger.Error('[%d] ERROR: Error message', [Counter]);

    WriteLn;
    WriteLn(Format('--- Message batch #%d completed ---', [Counter]));
    WriteLn('(Waiting 2 seconds before next batch...)');
    WriteLn;

    Sleep(2000);  // Wait 2 seconds between log batches
  end;
end.
