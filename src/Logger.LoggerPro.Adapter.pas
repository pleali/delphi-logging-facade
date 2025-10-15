unit Logger.LoggerPro.Adapter;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  System.SysUtils,
  System.StrUtils,
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
  ///   var LogWriter: ILogWriter;
  ///   LogWriter := BuildLogWriter([TLoggerProFileAppender.Create]);
  ///   TLoggerFactory.SetLogger(TLoggerProAdapter.Create(LogWriter));
  ///
  /// Note: This unit has a dependency on the LoggerPro library.
  /// Only include this unit if you're using LoggerPro.
  /// </summary>
  TLoggerProAdapter = class(TInterfacedObject, Logger.Intf.ILogger)
  private
    FName: string;
    FMinLevel: Logger.Types.TLogLevel;
    FLogWriter: ILogWriter;

    function IsLevelEnabled(ALevel: Logger.Types.TLogLevel): Boolean;
  public
    constructor Create(const AName: string; ALogWriter: ILogWriter; AMinLevel: Logger.Types.TLogLevel = Logger.Types.llInfo);

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

    function GetName: string;
  end;

implementation

{ TLoggerProAdapter }

constructor TLoggerProAdapter.Create(const AName: string; ALogWriter: ILogWriter; AMinLevel: Logger.Types.TLogLevel);
begin
  inherited Create;
  FName := AName;
  FLogWriter := ALogWriter;
  FMinLevel := AMinLevel;
end;

function TLoggerProAdapter.IsLevelEnabled(ALevel: Logger.Types.TLogLevel): Boolean;
begin
  Result := ALevel >= FMinLevel;
end;

procedure TLoggerProAdapter.Trace(const AMessage: string);
var
  LTag: string;
begin
  if IsLevelEnabled(Logger.Types.llTrace) then
  begin
    LTag := IfThen(FName <> '', FName, 'TRACE');
    FLogWriter.Debug(AMessage, LTag);
  end;
end;

procedure TLoggerProAdapter.Trace(const AMessage: string; const AArgs: array of const);
var
  LTag: string;
begin
  if IsLevelEnabled(Logger.Types.llTrace) then
  begin
    LTag := IfThen(FName <> '', FName, 'TRACE');
    FLogWriter.Debug(Format(AMessage, AArgs), LTag);
  end;
end;

procedure TLoggerProAdapter.Debug(const AMessage: string);
var
  LTag: string;
begin
  if IsLevelEnabled(Logger.Types.llDebug) then
  begin
    LTag := IfThen(FName <> '', FName, 'APP');
    FLogWriter.Debug(AMessage, LTag);
  end;
end;

procedure TLoggerProAdapter.Debug(const AMessage: string; const AArgs: array of const);
var
  LTag: string;
begin
  if IsLevelEnabled(Logger.Types.llDebug) then
  begin
    LTag := IfThen(FName <> '', FName, 'APP');
    FLogWriter.Debug(Format(AMessage, AArgs), LTag);
  end;
end;

procedure TLoggerProAdapter.Info(const AMessage: string);
var
  LTag: string;
begin
  if IsLevelEnabled(Logger.Types.llInfo) then
  begin
    LTag := IfThen(FName <> '', FName, 'APP');
    FLogWriter.Info(AMessage, LTag);
  end;
end;

procedure TLoggerProAdapter.Info(const AMessage: string; const AArgs: array of const);
var
  LTag: string;
begin
  if IsLevelEnabled(Logger.Types.llInfo) then
  begin
    LTag := IfThen(FName <> '', FName, 'APP');
    FLogWriter.Info(Format(AMessage, AArgs), LTag);
  end;
end;

procedure TLoggerProAdapter.Warn(const AMessage: string);
var
  LTag: string;
begin
  if IsLevelEnabled(Logger.Types.llWarn) then
  begin
    LTag := IfThen(FName <> '', FName, 'APP');
    FLogWriter.Warn(AMessage, LTag);
  end;
end;

procedure TLoggerProAdapter.Warn(const AMessage: string; const AArgs: array of const);
var
  LTag: string;
begin
  if IsLevelEnabled(Logger.Types.llWarn) then
  begin
    LTag := IfThen(FName <> '', FName, 'APP');
    FLogWriter.Warn(Format(AMessage, AArgs), LTag);
  end;
end;

procedure TLoggerProAdapter.Error(const AMessage: string);
var
  LTag: string;
begin
  if IsLevelEnabled(Logger.Types.llError) then
  begin
    LTag := IfThen(FName <> '', FName, 'APP');
    FLogWriter.Error(AMessage, LTag);
  end;
end;

procedure TLoggerProAdapter.Error(const AMessage: string; const AArgs: array of const);
var
  LTag: string;
begin
  if IsLevelEnabled(Logger.Types.llError) then
  begin
    LTag := IfThen(FName <> '', FName, 'APP');
    FLogWriter.Error(Format(AMessage, AArgs), LTag);
  end;
end;

procedure TLoggerProAdapter.Error(const AMessage: string; AException: Exception);
var
  LTag: string;
begin
  if IsLevelEnabled(Logger.Types.llError) then
  begin
    LTag := IfThen(FName <> '', FName, 'APP');
    if AException <> nil then
      FLogWriter.Error(Format('%s - Exception: %s: %s',
        [AMessage, AException.ClassName, AException.Message]), LTag)
    else
      FLogWriter.Error(AMessage, LTag);
  end;
end;

procedure TLoggerProAdapter.Fatal(const AMessage: string);
var
  LTag: string;
begin
  if IsLevelEnabled(Logger.Types.llFatal) then
  begin
    LTag := IfThen(FName <> '', FName, 'FATAL');
    FLogWriter.Error(AMessage, LTag);
  end;
end;

procedure TLoggerProAdapter.Fatal(const AMessage: string; const AArgs: array of const);
var
  LTag: string;
begin
  if IsLevelEnabled(Logger.Types.llFatal) then
  begin
    LTag := IfThen(FName <> '', FName, 'FATAL');
    FLogWriter.Error(Format(AMessage, AArgs), LTag);
  end;
end;

procedure TLoggerProAdapter.Fatal(const AMessage: string; AException: Exception);
var
  LTag: string;
begin
  if IsLevelEnabled(Logger.Types.llFatal) then
  begin
    LTag := IfThen(FName <> '', FName, 'FATAL');
    if AException <> nil then
      FLogWriter.Error(Format('%s - Exception: %s: %s',
        [AMessage, AException.ClassName, AException.Message]), LTag)
    else
      FLogWriter.Error(AMessage, LTag);
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

function TLoggerProAdapter.GetName: string;
begin
  Result := FName;
end;

end.
