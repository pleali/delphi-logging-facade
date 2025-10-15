unit Logger.LoggerPro.Adapter;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  System.SysUtils,
  Logger.Intf,
  Logger.Types,
  LoggerPro;  // External dependency: LoggerPro library

type
  /// <summary>
  /// Adapter that bridges our ILogger interface to LoggerPro.
  /// This allows using LoggerPro as the underlying logging implementation
  /// while keeping application code independent of LoggerPro specifics.
  ///
  /// Usage:
  ///   TLoggerFactory.SetLogger(TLoggerProAdapter.Create);
  ///
  /// Note: This unit has a dependency on the LoggerPro library.
  /// Only include this unit if you're using LoggerPro.
  /// </summary>
  TLoggerProAdapter = class(TInterfacedObject, ILogger)
  private
    FMinLevel: Logger.Types.TLogLevel;

    function MapLogLevel(ALevel: Logger.Types.TLogLevel): LoggerPro.TLogType;
    function IsLevelEnabled(ALevel: Logger.Types.TLogLevel): Boolean;
  public
    constructor Create(AMinLevel: Logger.Types.TLogLevel = Logger.Types.llInfo);

    // ILogger implementation
    procedure Trace(const AMessage: string); overload;
    procedure Trace(const AMessage: string; const AArgs: array of const); overload;

    procedure Debug(const AMessage: string); overload;
    procedure Debug(const AMessage: string; const AArgs: array of const); overload;

    procedure Info(const AMessage: string); overload;
    procedure Info(const AMessage: string; const AArgs: array of const); overload;

    procedure Warn(const AMessage: string); overload;
    procedure Warn(const AMessage: string; const AArgs: array of const); overload;

    procedure Error(const AMessage: string); overload;
    procedure Error(const AMessage: string; const AArgs: array of const); overload;
    procedure Error(const AMessage: string; AException: Exception); overload;

    procedure Fatal(const AMessage: string); overload;
    procedure Fatal(const AMessage: string; const AArgs: array of const); overload;
    procedure Fatal(const AMessage: string; AException: Exception); overload;

    function IsTraceEnabled: Boolean;
    function IsDebugEnabled: Boolean;
    function IsInfoEnabled: Boolean;
    function IsWarnEnabled: Boolean;
    function IsErrorEnabled: Boolean;
    function IsFatalEnabled: Boolean;

    procedure SetLevel(ALevel: Logger.Types.TLogLevel);
    function GetLevel: Logger.Types.TLogLevel;
  end;

implementation

{ TLoggerProAdapter }

constructor TLoggerProAdapter.Create(AMinLevel: Logger.Types.TLogLevel);
begin
  inherited Create;
  FMinLevel := AMinLevel;
end;

function TLoggerProAdapter.MapLogLevel(ALevel: Logger.Types.TLogLevel): LoggerPro.TLogType;
begin
  // Map our log levels to LoggerPro's TLogType
  case ALevel of
    Logger.Types.llTrace: Result := LoggerPro.TLogType.Debug;      // LoggerPro doesn't have Trace, use Debug
    Logger.Types.llDebug: Result := LoggerPro.TLogType.Debug;
    Logger.Types.llInfo:  Result := LoggerPro.TLogType.Info;
    Logger.Types.llWarn:  Result := LoggerPro.TLogType.Warning;
    Logger.Types.llError: Result := LoggerPro.TLogType.Error;
    Logger.Types.llFatal: Result := LoggerPro.TLogType.Error;      // LoggerPro doesn't have Fatal, use Error
  else
    Result := LoggerPro.TLogType.Info;
  end;
end;

function TLoggerProAdapter.IsLevelEnabled(ALevel: Logger.Types.TLogLevel): Boolean;
begin
  Result := ALevel >= FMinLevel;
end;

procedure TLoggerProAdapter.Trace(const AMessage: string);
begin
  if IsLevelEnabled(Logger.Types.llTrace) then
    Log.Debug(AMessage, 'TRACE');
end;

procedure TLoggerProAdapter.Trace(const AMessage: string; const AArgs: array of const);
begin
  if IsLevelEnabled(Logger.Types.llTrace) then
    Log.Debug(Format(AMessage, AArgs), 'TRACE');
end;

procedure TLoggerProAdapter.Debug(const AMessage: string);
begin
  if IsLevelEnabled(Logger.Types.llDebug) then
    Log.Debug(AMessage, 'APP');
end;

procedure TLoggerProAdapter.Debug(const AMessage: string; const AArgs: array of const);
begin
  if IsLevelEnabled(Logger.Types.llDebug) then
    Log.Debug(Format(AMessage, AArgs), 'APP');
end;

procedure TLoggerProAdapter.Info(const AMessage: string);
begin
  if IsLevelEnabled(Logger.Types.llInfo) then
    Log.Info(AMessage, 'APP');
end;

procedure TLoggerProAdapter.Info(const AMessage: string; const AArgs: array of const);
begin
  if IsLevelEnabled(Logger.Types.llInfo) then
    Log.Info(Format(AMessage, AArgs), 'APP');
end;

procedure TLoggerProAdapter.Warn(const AMessage: string);
begin
  if IsLevelEnabled(Logger.Types.llWarn) then
    Log.Warn(AMessage, 'APP');
end;

procedure TLoggerProAdapter.Warn(const AMessage: string; const AArgs: array of const);
begin
  if IsLevelEnabled(Logger.Types.llWarn) then
    Log.Warn(Format(AMessage, AArgs), 'APP');
end;

procedure TLoggerProAdapter.Error(const AMessage: string);
begin
  if IsLevelEnabled(Logger.Types.llError) then
    Log.Error(AMessage, 'APP');
end;

procedure TLoggerProAdapter.Error(const AMessage: string; const AArgs: array of const);
begin
  if IsLevelEnabled(Logger.Types.llError) then
    Log.Error(Format(AMessage, AArgs), 'APP');
end;

procedure TLoggerProAdapter.Error(const AMessage: string; AException: Exception);
begin
  if IsLevelEnabled(Logger.Types.llError) then
  begin
    if AException <> nil then
      Log.Error(Format('%s - Exception: %s: %s',
        [AMessage, AException.ClassName, AException.Message]), 'APP')
    else
      Log.Error(AMessage, 'APP');
  end;
end;

procedure TLoggerProAdapter.Fatal(const AMessage: string);
begin
  if IsLevelEnabled(Logger.Types.llFatal) then
    Log.Error(AMessage, 'FATAL');
end;

procedure TLoggerProAdapter.Fatal(const AMessage: string; const AArgs: array of const);
begin
  if IsLevelEnabled(Logger.Types.llFatal) then
    Log.Error(Format(AMessage, AArgs), 'FATAL');
end;

procedure TLoggerProAdapter.Fatal(const AMessage: string; AException: Exception);
begin
  if IsLevelEnabled(Logger.Types.llFatal) then
  begin
    if AException <> nil then
      Log.Error(Format('%s - Exception: %s: %s',
        [AMessage, AException.ClassName, AException.Message]), 'FATAL')
    else
      Log.Error(AMessage, 'FATAL');
  end;
end;

function TLoggerProAdapter.IsTraceEnabled: Boolean;
begin
  Result := IsLevelEnabled(Logger.Types.llTrace);
end;

function TLoggerProAdapter.IsDebugEnabled: Boolean;
begin
  Result := IsLevelEnabled(Logger.Types.llDebug);
end;

function TLoggerProAdapter.IsInfoEnabled: Boolean;
begin
  Result := IsLevelEnabled(Logger.Types.llInfo);
end;

function TLoggerProAdapter.IsWarnEnabled: Boolean;
begin
  Result := IsLevelEnabled(Logger.Types.llWarn);
end;

function TLoggerProAdapter.IsErrorEnabled: Boolean;
begin
  Result := IsLevelEnabled(Logger.Types.llError);
end;

function TLoggerProAdapter.IsFatalEnabled: Boolean;
begin
  Result := IsLevelEnabled(Logger.Types.llFatal);
end;

procedure TLoggerProAdapter.SetLevel(ALevel: Logger.Types.TLogLevel);
begin
  FMinLevel := ALevel;
end;

function TLoggerProAdapter.GetLevel: Logger.Types.TLogLevel;
begin
  Result := FMinLevel;
end;

end.
