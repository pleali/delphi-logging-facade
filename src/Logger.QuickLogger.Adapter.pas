unit Logger.QuickLogger.Adapter;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  System.SysUtils,
  Logger.Intf,
  Logger.Types,
  Quick.Logger;  // External dependency: QuickLogger library

type
  /// <summary>
  /// Adapter that bridges our ILogger interface to QuickLogger.
  /// This allows using QuickLogger as the underlying logging implementation
  /// while keeping application code independent of QuickLogger specifics.
  ///
  /// Usage:
  ///   TLoggerFactory.SetLogger(TQuickLoggerAdapter.Create);
  ///
  /// Note: This unit has a dependency on the QuickLogger library.
  /// Only include this unit if you're using QuickLogger.
  /// </summary>
  TQuickLoggerAdapter = class(TInterfacedObject, ILogger)
  private
    FMinLevel: Logger.Types.TLogLevel;

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

{ TQuickLoggerAdapter }

constructor TQuickLoggerAdapter.Create(AMinLevel: Logger.Types.TLogLevel);
begin
  inherited Create;
  FMinLevel := AMinLevel;
end;

function TQuickLoggerAdapter.IsLevelEnabled(ALevel: Logger.Types.TLogLevel): Boolean;
begin
  Result := ALevel >= FMinLevel;
end;

procedure TQuickLoggerAdapter.Trace(const AMessage: string);
begin
  if IsLevelEnabled(Logger.Types.llTrace) then
    Quick.Logger.Logger.Add(AMessage, etTrace);
end;

procedure TQuickLoggerAdapter.Trace(const AMessage: string; const AArgs: array of const);
begin
  if IsLevelEnabled(Logger.Types.llTrace) then
    Quick.Logger.Logger.Add(Format(AMessage, AArgs), etTrace);
end;

procedure TQuickLoggerAdapter.Debug(const AMessage: string);
begin
  if IsLevelEnabled(Logger.Types.llDebug) then
    Quick.Logger.Logger.Add(AMessage, etDebug);
end;

procedure TQuickLoggerAdapter.Debug(const AMessage: string; const AArgs: array of const);
begin
  if IsLevelEnabled(Logger.Types.llDebug) then
    Quick.Logger.Logger.Add(Format(AMessage, AArgs), etDebug);
end;

procedure TQuickLoggerAdapter.Info(const AMessage: string);
begin
  if IsLevelEnabled(Logger.Types.llInfo) then
    Quick.Logger.Logger.Add(AMessage, etInfo);
end;

procedure TQuickLoggerAdapter.Info(const AMessage: string; const AArgs: array of const);
begin
  if IsLevelEnabled(Logger.Types.llInfo) then
    Quick.Logger.Logger.Add(Format(AMessage, AArgs), etInfo);
end;

procedure TQuickLoggerAdapter.Warn(const AMessage: string);
begin
  if IsLevelEnabled(Logger.Types.llWarn) then
    Quick.Logger.Logger.Add(AMessage, etWarning);
end;

procedure TQuickLoggerAdapter.Warn(const AMessage: string; const AArgs: array of const);
begin
  if IsLevelEnabled(Logger.Types.llWarn) then
    Quick.Logger.Logger.Add(Format(AMessage, AArgs), etWarning);
end;

procedure TQuickLoggerAdapter.Error(const AMessage: string);
begin
  if IsLevelEnabled(Logger.Types.llError) then
    Quick.Logger.Logger.Add(AMessage, etError);
end;

procedure TQuickLoggerAdapter.Error(const AMessage: string; const AArgs: array of const);
begin
  if IsLevelEnabled(Logger.Types.llError) then
    Quick.Logger.Logger.Add(Format(AMessage, AArgs), etError);
end;

procedure TQuickLoggerAdapter.Error(const AMessage: string; AException: Exception);
begin
  if IsLevelEnabled(Logger.Types.llError) then
  begin
    if AException <> nil then
      Quick.Logger.Logger.Add(Format('%s - Exception: %s: %s',
        [AMessage, AException.ClassName, AException.Message]), etError)
    else
      Quick.Logger.Logger.Add(AMessage, etError);
  end;
end;

procedure TQuickLoggerAdapter.Fatal(const AMessage: string);
begin
  if IsLevelEnabled(Logger.Types.llFatal) then
    Quick.Logger.Logger.Add(AMessage, etCritical);
end;

procedure TQuickLoggerAdapter.Fatal(const AMessage: string; const AArgs: array of const);
begin
  if IsLevelEnabled(Logger.Types.llFatal) then
    Quick.Logger.Logger.Add(Format(AMessage, AArgs), etCritical);
end;

procedure TQuickLoggerAdapter.Fatal(const AMessage: string; AException: Exception);
begin
  if IsLevelEnabled(Logger.Types.llFatal) then
  begin
    if AException <> nil then
      Quick.Logger.Logger.Add(Format('%s - Exception: %s: %s',
        [AMessage, AException.ClassName, AException.Message]), etCritical)
    else
      Quick.Logger.Logger.Add(AMessage, etCritical);
  end;
end;

function TQuickLoggerAdapter.IsTraceEnabled: Boolean;
begin
  Result := IsLevelEnabled(Logger.Types.llTrace);
end;

function TQuickLoggerAdapter.IsDebugEnabled: Boolean;
begin
  Result := IsLevelEnabled(Logger.Types.llDebug);
end;

function TQuickLoggerAdapter.IsInfoEnabled: Boolean;
begin
  Result := IsLevelEnabled(Logger.Types.llInfo);
end;

function TQuickLoggerAdapter.IsWarnEnabled: Boolean;
begin
  Result := IsLevelEnabled(Logger.Types.llWarn);
end;

function TQuickLoggerAdapter.IsErrorEnabled: Boolean;
begin
  Result := IsLevelEnabled(Logger.Types.llError);
end;

function TQuickLoggerAdapter.IsFatalEnabled: Boolean;
begin
  Result := IsLevelEnabled(Logger.Types.llFatal);
end;

procedure TQuickLoggerAdapter.SetLevel(ALevel: Logger.Types.TLogLevel);
begin
  FMinLevel := ALevel;
end;

function TQuickLoggerAdapter.GetLevel: Logger.Types.TLogLevel;
begin
  Result := FMinLevel;
end;

end.
