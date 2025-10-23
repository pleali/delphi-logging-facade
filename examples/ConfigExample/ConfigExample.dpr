program ConfigExample;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.IOUtils,
  Logger.Types,
  Logger.Intf,
  Logger.Factory,
  Logger.Context,
  Logger.Config;

/// <summary>
/// Demonstrates automatic configuration loading based on DEBUG/RELEASE
/// </summary>
procedure DemoAutoConfig;
var
  LLogger: ILogger;
begin
  Writeln('=== Demo 1: Automatic Configuration Loading ===');
  Writeln;

  {$IFDEF DEBUG}
  Writeln('** DEBUG mode detected **');
  Writeln('Automatically loading: logging-debug.properties');
  {$ELSE}
  Writeln('** RELEASE mode detected **');
  Writeln('Automatically loading: logging.properties');
  {$ENDIF}

  // Configuration is loaded automatically on first GetLogger() call
  LLogger := TLoggerFactory.GetLogger('MyApp.Main');

  Writeln;
  Writeln('Testing different loggers with configured levels:');
  Writeln;

  // These will respect the levels defined in the config file
  LLogger.Trace('TRACE from MyApp.Main');
  LLogger.Debug('DEBUG from MyApp.Main');
  LLogger.Info('INFO from MyApp.Main');

  Writeln;
end;

/// <summary>
/// Demonstrates hierarchical configuration (Logback-style)
/// </summary>
procedure DemoHierarchicalConfig;
var
  LLoggerMqtt: ILogger;
  LLoggerMqttTransport: ILogger;
  LLoggerMqttCore: ILogger;
begin
  Writeln('=== Demo 2: Hierarchical Configuration ===');
  Writeln;
  Writeln('Config file defines:');
  Writeln('  mqtt.* = DEBUG');
  Writeln('  mqtt.transport.ics = TRACE');
  Writeln('  mqtt.core = INFO');
  Writeln;

  LLoggerMqtt := TLoggerFactory.GetLogger('mqtt');
  LLoggerMqttTransport := TLoggerFactory.GetLogger('mqtt.transport.ics');
  LLoggerMqttCore := TLoggerFactory.GetLogger('mqtt.core');

  Writeln('Testing mqtt (inherits mqtt.* = DEBUG):');
  LLoggerMqtt.Debug('DEBUG message from mqtt');
  LLoggerMqtt.Info('INFO message from mqtt');

  Writeln;
  Writeln('Testing mqtt.transport.ics (configured as TRACE):');
  LLoggerMqttTransport.Trace('TRACE message from mqtt.transport.ics');
  LLoggerMqttTransport.Debug('DEBUG message from mqtt.transport.ics');

  Writeln;
  Writeln('Testing mqtt.core (configured as INFO):');
  LLoggerMqttCore.Debug('DEBUG message from mqtt.core (won''t show)');
  LLoggerMqttCore.Info('INFO message from mqtt.core');

  Writeln;
end;

/// <summary>
/// Demonstrates runtime level changes
/// </summary>
procedure DemoRuntimeLevelChange;
var
  LLogger: ILogger;
begin
  Writeln('=== Demo 3: Runtime Level Changes ===');
  Writeln;

  LLogger := TLoggerFactory.GetLogger('MyApp.Database');

  Writeln('Initial configuration (from file):');
  LLogger.Debug('DEBUG message (depends on config)');
  LLogger.Info('INFO message');

  Writeln;
  Writeln('** Changing MyApp.Database level to TRACE at runtime **');
  TLoggerFactory.SetLoggerLevel('MyApp.Database', llTrace);

  LLogger.Trace('TRACE message (now visible!)');
  LLogger.Debug('DEBUG message');
  LLogger.Info('INFO message');

  Writeln;
  Writeln('** Changing to WARN level **');
  TLoggerFactory.SetLoggerLevel('MyApp.Database', llWarn);

  LLogger.Debug('DEBUG message (hidden)');
  LLogger.Info('INFO message (hidden)');
  LLogger.Warn('WARN message (visible)');

  Writeln;
end;

/// <summary>
/// Demonstrates wildcard configuration changes at runtime
/// </summary>
procedure DemoWildcardConfig;
var
  LLogger1: ILogger;
  LLogger2: ILogger;
  LLogger3: ILogger;
begin
  Writeln('=== Demo 4: Wildcard Configuration ===');
  Writeln;

  LLogger1 := TLoggerFactory.GetLogger('mqtt.client');
  LLogger2 := TLoggerFactory.GetLogger('mqtt.broker');
  LLogger3 := TLoggerFactory.GetLogger('mqtt.protocol');

  Writeln('Before: Individual loggers at default levels');
  LLogger1.Debug('DEBUG from mqtt.client');
  LLogger2.Debug('DEBUG from mqtt.broker');
  LLogger3.Debug('DEBUG from mqtt.protocol');

  Writeln;
  Writeln('** Setting mqtt.* = ERROR (affects all mqtt.* loggers) **');
  TLoggerFactory.SetLoggerLevel('mqtt.*', llError);

  // Note: This only affects NEW logger instances
  // To see the change, we need to clear and recreate loggers
  TLoggerFactory.Reset;
  TLoggerFactory.SetLoggerLevel('mqtt.*', llError);

  LLogger1 := TLoggerFactory.GetLogger('mqtt.client');
  LLogger2 := TLoggerFactory.GetLogger('mqtt.broker');
  LLogger3 := TLoggerFactory.GetLogger('mqtt.protocol');

  LLogger1.Debug('DEBUG from mqtt.client (hidden)');
  LLogger1.Error('ERROR from mqtt.client (visible)');
  LLogger2.Debug('DEBUG from mqtt.broker (hidden)');
  LLogger2.Error('ERROR from mqtt.broker (visible)');

  Writeln;
end;

/// <summary>
/// Simulates a library unit with automatic context
/// </summary>
procedure SimulateLibraryWithContext;
var
  LLogger: ILogger;
begin
  Writeln('=== Demo 5: Automatic Context from Namespace ===');
  Writeln;

  Writeln('Simulating unit: Mqtt.Transport.Ics');
  Writeln('Unit would have: {$I Logger.AutoContext.inc}');
  Writeln;

  // Simulate what the unit's initialization would do
  TLoggerContext.RegisterUnitContext('Mqtt.Transport.Ics');
  try
    Writeln('** Inside Mqtt.Transport.Ics unit context **');
    Writeln;

    // When this unit calls GetLogger('client'), it automatically becomes
    // 'mqtt.transport.ics.client' due to the context
    LLogger := TLoggerFactory.GetLogger('client');
    // The logger name is now: mqtt.transport.ics.client

    LLogger.Info('Connection established (from mqtt.transport.ics.client)');
    LLogger.Debug('Socket opened on port 1883');

    // GetLogger('') in this context becomes 'mqtt.transport.ics'
    LLogger := TLoggerFactory.GetLogger('');
    LLogger.Info('Transport layer initialized (from mqtt.transport.ics)');

    Writeln;
  finally
    // Unit's finalization would do this
    TLoggerContext.UnregisterUnitContext;
  end;

  Writeln('** After leaving unit context **');
  LLogger := TLoggerFactory.GetLogger('client');
  LLogger.Info('Now just plain ''client'' logger');

  Writeln;
end;

/// <summary>
/// Demonstrates context stacking
/// </summary>
procedure DemoContextStacking;
var
  LLogger: ILogger;
begin
  Writeln('=== Demo 6: Context Stacking ===');
  Writeln;

  Writeln('** No context **');
  LLogger := TLoggerFactory.GetLogger('component');
  LLogger.Info('From plain ''component''');

  Writeln;
  Writeln('** Push context: mqtt **');
  TLoggerContext.PushContext('mqtt');
  LLogger := TLoggerFactory.GetLogger('component');
  LLogger.Info('From ''mqtt.component''');

  Writeln;
  Writeln('** Push context: transport **');
  TLoggerContext.PushContext('transport');
  LLogger := TLoggerFactory.GetLogger('component');
  LLogger.Info('From ''mqtt.transport.component''');

  Writeln;
  Writeln('** Pop context (back to mqtt) **');
  TLoggerContext.PopContext;
  LLogger := TLoggerFactory.GetLogger('component');
  LLogger.Info('From ''mqtt.component'' again');

  Writeln;
  Writeln('** Pop context (back to root) **');
  TLoggerContext.PopContext;
  LLogger := TLoggerFactory.GetLogger('component');
  LLogger.Info('Back to plain ''component''');

  Writeln;
end;

/// <summary>
/// Demonstrates manual config loading
/// </summary>
procedure DemoManualConfigLoad;
var
  LConfigFile: string;
  LLogger: ILogger;
begin
  Writeln('=== Demo 7: Manual Configuration Loading ===');
  Writeln;

  // Find a config file
  LConfigFile := TPath.Combine(ExtractFilePath(ParamStr(0)), '..\..\config\logging-debug.properties');

  if TFile.Exists(LConfigFile) then
  begin
    Writeln('Loading config from: ', LConfigFile);
    try
      TLoggerFactory.LoadConfig(LConfigFile);
      Writeln('Configuration loaded successfully!');

      Writeln;
      LLogger := TLoggerFactory.GetLogger('MyApp.Main');
      LLogger.Info('Testing with manually loaded config');
    except
      on E: Exception do
        Writeln('Error loading config: ', E.Message);
    end;
  end
  else
  begin
    Writeln('Config file not found at: ', LConfigFile);
    Writeln('Skipping manual config demo');
  end;

  Writeln;
end;

/// <summary>
/// Demonstrates querying configured levels
/// </summary>
procedure DemoQueryConfiguredLevels;
var
  LLevel: TLogLevel;
begin
  Writeln('=== Demo 8: Query Configured Levels ===');
  Writeln;

  LLevel := TLoggerFactory.GetConfiguredLevel('MyApp.Main');
  Writeln('MyApp.Main level: ', LLevel.ToString);

  LLevel := TLoggerFactory.GetConfiguredLevel('mqtt.transport');
  Writeln('mqtt.transport level: ', LLevel.ToString);

  LLevel := TLoggerFactory.GetConfiguredLevel('unconfigured.logger');
  Writeln('unconfigured.logger level: ', LLevel.ToString, ' (default)');

  Writeln;
end;

begin
  try
    Writeln('LoggingFacade - Configuration & Context Examples');
    Writeln('================================================');
    Writeln;

    DemoAutoConfig;
    DemoHierarchicalConfig;
    DemoRuntimeLevelChange;
    DemoWildcardConfig;
    DemoContextStacking;
    SimulateLibraryWithContext;
    DemoManualConfigLoad;
    DemoQueryConfiguredLevels;

    Writeln('=================================================');
    Writeln('All demos completed successfully!');
    Writeln;
    Writeln('Note: Copy logging-debug.properties or logging.properties');
    Writeln('      to the executable directory to test automatic loading.');
    Writeln;
    Writeln('Press ENTER to exit...');
    Readln;
  except
    on E: Exception do
    begin
      Writeln('FATAL ERROR: ', E.ClassName, ': ', E.Message);
      Writeln('Press ENTER to exit...');
      Readln;
      ExitCode := 1;
    end;
  end;
end.
