unit Logger.Null;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  System.SysUtils,
  Logger.Intf,
  Logger.Types;

type
  /// <summary>
  /// Null Object Pattern implementation for ILogger.
  /// This logger discards all log messages - useful for testing,
  /// benchmarking, or completely disabling logging without modifying application code.
  /// All methods are no-ops and all IsXxxEnabled methods return False.
  /// </summary>
  TNullLogger = class(TInterfacedObject, ILogger)
  private
    FLevel: TLogLevel;
  public
    constructor Create;

    // ILogger implementation - all methods do nothing
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

    // All level checks return False
    function IsTraceEnabled: Boolean;
    function IsDebugEnabled: Boolean;
    function IsInfoEnabled: Boolean;
    function IsWarnEnabled: Boolean;
    function IsErrorEnabled: Boolean;
    function IsFatalEnabled: Boolean;

    procedure SetLevel(ALevel: TLogLevel);
    function GetLevel: TLogLevel;
  end;

implementation

{ TNullLogger }

constructor TNullLogger.Create;
begin
  inherited Create;
  FLevel := llFatal; // Highest level - effectively disables all logging
end;

// All logging methods are no-ops
procedure TNullLogger.Trace(const AMessage: string);
begin
  // Do nothing
end;

procedure TNullLogger.Trace(const AMessage: string; const AArgs: array of const);
begin
  // Do nothing
end;

procedure TNullLogger.Debug(const AMessage: string);
begin
  // Do nothing
end;

procedure TNullLogger.Debug(const AMessage: string; const AArgs: array of const);
begin
  // Do nothing
end;

procedure TNullLogger.Info(const AMessage: string);
begin
  // Do nothing
end;

procedure TNullLogger.Info(const AMessage: string; const AArgs: array of const);
begin
  // Do nothing
end;

procedure TNullLogger.Warn(const AMessage: string);
begin
  // Do nothing
end;

procedure TNullLogger.Warn(const AMessage: string; const AArgs: array of const);
begin
  // Do nothing
end;

procedure TNullLogger.Error(const AMessage: string);
begin
  // Do nothing
end;

procedure TNullLogger.Error(const AMessage: string; const AArgs: array of const);
begin
  // Do nothing
end;

procedure TNullLogger.Error(const AMessage: string; AException: Exception);
begin
  // Do nothing
end;

procedure TNullLogger.Fatal(const AMessage: string);
begin
  // Do nothing
end;

procedure TNullLogger.Fatal(const AMessage: string; const AArgs: array of const);
begin
  // Do nothing
end;

procedure TNullLogger.Fatal(const AMessage: string; AException: Exception);
begin
  // Do nothing
end;

// All level checks return False
function TNullLogger.IsTraceEnabled: Boolean;
begin
  Result := False;
end;

function TNullLogger.IsDebugEnabled: Boolean;
begin
  Result := False;
end;

function TNullLogger.IsInfoEnabled: Boolean;
begin
  Result := False;
end;

function TNullLogger.IsWarnEnabled: Boolean;
begin
  Result := False;
end;

function TNullLogger.IsErrorEnabled: Boolean;
begin
  Result := False;
end;

function TNullLogger.IsFatalEnabled: Boolean;
begin
  Result := False;
end;

procedure TNullLogger.SetLevel(ALevel: TLogLevel);
begin
  FLevel := ALevel;
  // Note: Even if level is set, this logger still does nothing
end;

function TNullLogger.GetLevel: TLogLevel;
begin
  Result := FLevel;
end;

end.
