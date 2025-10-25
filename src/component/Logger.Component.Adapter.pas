{******************************************************************************
  DelphiLoggingFacade
  Copyright (c) 2025 Paul LEALI
  MIT License - See LICENSE file for details
******************************************************************************}
unit Logger.Component.Adapter;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  System.SysUtils,
  Logger.Types,
  Logger.Intf,
  Logger.Component;

type
  /// <summary>
  /// Adapter that implements ILogger interface and delegates to TLoggerComponent.
  /// This allows TLoggerComponent to be used as a logger implementation in the facade.
  /// </summary>
  TComponentLoggerAdapter = class(TInterfacedObject, ILogger)
  private
    FComponent: TLoggerComponent;
    FOwnsComponent: Boolean;
    FLoggerName: string;

    function GetComponent: TLoggerComponent;
  public
    /// <summary>
    /// Creates an adapter for an existing component.
    /// </summary>
    /// <param name="AComponent">The component to wrap. Must not be nil.</param>
    /// <param name="AOwnsComponent">If True, the adapter will free the component when destroyed.</param>
    constructor Create(AComponent: TLoggerComponent; AOwnsComponent: Boolean = False); overload;

    /// <summary>
    /// Creates an adapter with a new component instance.
    /// </summary>
    /// <param name="ALoggerName">Name for the logger.</param>
    constructor Create(const ALoggerName: string = ''); overload;

    destructor Destroy; override;

    // ILogger implementation

    procedure Trace(const AMessage: string); overload;
    procedure Trace(const AMessage: string; const AArgs: array of const); overload;
    procedure Trace(const AMessage: string; const AArgs: array of const; AException: Exception); overload;

    procedure Debug(const AMessage: string); overload;
    procedure Debug(const AMessage: string; const AArgs: array of const); overload;
    procedure Debug(const AMessage: string; const AArgs: array of const; AException: Exception); overload;

    procedure Info(const AMessage: string); overload;
    procedure Info(const AMessage: string; const AArgs: array of const); overload;
    procedure Info(const AMessage: string; const AArgs: array of const; AException: Exception); overload;

    procedure Warn(const AMessage: string); overload;
    procedure Warn(const AMessage: string; const AArgs: array of const); overload;
    procedure Warn(const AMessage: string; const AArgs: array of const; AException: Exception); overload;

    procedure Error(const AMessage: string); overload;
    procedure Error(const AMessage: string; const AArgs: array of const); overload;
    procedure Error(const AMessage: string; AException: Exception); overload;
    procedure Error(const AMessage: string; const AArgs: array of const; AException: Exception); overload;

    procedure Fatal(const AMessage: string); overload;
    procedure Fatal(const AMessage: string; const AArgs: array of const); overload;
    procedure Fatal(const AMessage: string; AException: Exception); overload;
    procedure Fatal(const AMessage: string; const AArgs: array of const; AException: Exception); overload;

    function IsTraceEnabled: Boolean;
    function IsDebugEnabled: Boolean;
    function IsInfoEnabled: Boolean;
    function IsWarnEnabled: Boolean;
    function IsErrorEnabled: Boolean;
    function IsFatalEnabled: Boolean;

    procedure SetLevel(ALevel: TLogLevel);
    function GetLevel: TLogLevel;
    function GetName: string;

    /// <summary>
    /// Provides access to the underlying component.
    /// </summary>
    property Component: TLoggerComponent read GetComponent;
  end;

implementation

{ TComponentLoggerAdapter }

constructor TComponentLoggerAdapter.Create(AComponent: TLoggerComponent;
  AOwnsComponent: Boolean);
begin
  inherited Create;

  if not Assigned(AComponent) then
    raise Exception.Create('Component cannot be nil');

  FComponent := AComponent;
  FOwnsComponent := AOwnsComponent;
  FLoggerName := AComponent.LoggerName;
end;

constructor TComponentLoggerAdapter.Create(const ALoggerName: string);
begin
  inherited Create;

  FComponent := TLoggerComponent.Create(nil);
  FComponent.LoggerName := ALoggerName;
  FOwnsComponent := True;
  FLoggerName := ALoggerName;
end;

destructor TComponentLoggerAdapter.Destroy;
begin
  if FOwnsComponent and Assigned(FComponent) then
    FComponent.Free;

  inherited;
end;

function TComponentLoggerAdapter.GetComponent: TLoggerComponent;
begin
  Result := FComponent;
end;

// Trace methods

procedure TComponentLoggerAdapter.Trace(const AMessage: string);
begin
  FComponent.Trace(AMessage);
end;

procedure TComponentLoggerAdapter.Trace(const AMessage: string;
  const AArgs: array of const);
begin
  FComponent.Trace(Format(AMessage, AArgs));
end;

procedure TComponentLoggerAdapter.Trace(const AMessage: string;
  const AArgs: array of const; AException: Exception);
begin
  FComponent.Log(llTrace, Format(AMessage, AArgs), AException);
end;

// Debug methods

procedure TComponentLoggerAdapter.Debug(const AMessage: string);
begin
  FComponent.Debug(AMessage);
end;

procedure TComponentLoggerAdapter.Debug(const AMessage: string;
  const AArgs: array of const);
begin
  FComponent.Debug(Format(AMessage, AArgs));
end;

procedure TComponentLoggerAdapter.Debug(const AMessage: string;
  const AArgs: array of const; AException: Exception);
begin
  FComponent.Log(llDebug, Format(AMessage, AArgs), AException);
end;

// Info methods

procedure TComponentLoggerAdapter.Info(const AMessage: string);
begin
  FComponent.Info(AMessage);
end;

procedure TComponentLoggerAdapter.Info(const AMessage: string;
  const AArgs: array of const);
begin
  FComponent.Info(Format(AMessage, AArgs));
end;

procedure TComponentLoggerAdapter.Info(const AMessage: string;
  const AArgs: array of const; AException: Exception);
begin
  FComponent.Log(llInfo, Format(AMessage, AArgs), AException);
end;

// Warn methods

procedure TComponentLoggerAdapter.Warn(const AMessage: string);
begin
  FComponent.Warn(AMessage);
end;

procedure TComponentLoggerAdapter.Warn(const AMessage: string;
  const AArgs: array of const);
begin
  FComponent.Warn(Format(AMessage, AArgs));
end;

procedure TComponentLoggerAdapter.Warn(const AMessage: string;
  const AArgs: array of const; AException: Exception);
begin
  FComponent.Log(llWarn, Format(AMessage, AArgs), AException);
end;

// Error methods

procedure TComponentLoggerAdapter.Error(const AMessage: string);
begin
  FComponent.Error(AMessage);
end;

procedure TComponentLoggerAdapter.Error(const AMessage: string;
  const AArgs: array of const);
begin
  FComponent.Error(Format(AMessage, AArgs));
end;

procedure TComponentLoggerAdapter.Error(const AMessage: string;
  AException: Exception);
begin
  FComponent.Error(AMessage, AException);
end;

procedure TComponentLoggerAdapter.Error(const AMessage: string;
  const AArgs: array of const; AException: Exception);
begin
  FComponent.Error(Format(AMessage, AArgs), AException);
end;

// Fatal methods

procedure TComponentLoggerAdapter.Fatal(const AMessage: string);
begin
  FComponent.Fatal(AMessage);
end;

procedure TComponentLoggerAdapter.Fatal(const AMessage: string;
  const AArgs: array of const);
begin
  FComponent.Fatal(Format(AMessage, AArgs));
end;

procedure TComponentLoggerAdapter.Fatal(const AMessage: string;
  AException: Exception);
begin
  FComponent.Fatal(AMessage, AException);
end;

procedure TComponentLoggerAdapter.Fatal(const AMessage: string;
  const AArgs: array of const; AException: Exception);
begin
  FComponent.Fatal(Format(AMessage, AArgs), AException);
end;

// Level checking methods

function TComponentLoggerAdapter.IsTraceEnabled: Boolean;
begin
  Result := FComponent.MinLevel <= llTrace;
end;

function TComponentLoggerAdapter.IsDebugEnabled: Boolean;
begin
  Result := FComponent.MinLevel <= llDebug;
end;

function TComponentLoggerAdapter.IsInfoEnabled: Boolean;
begin
  Result := FComponent.MinLevel <= llInfo;
end;

function TComponentLoggerAdapter.IsWarnEnabled: Boolean;
begin
  Result := FComponent.MinLevel <= llWarn;
end;

function TComponentLoggerAdapter.IsErrorEnabled: Boolean;
begin
  Result := FComponent.MinLevel <= llError;
end;

function TComponentLoggerAdapter.IsFatalEnabled: Boolean;
begin
  Result := FComponent.MinLevel <= llFatal;
end;

// Configuration methods

procedure TComponentLoggerAdapter.SetLevel(ALevel: TLogLevel);
begin
  FComponent.MinLevel := ALevel;
end;

function TComponentLoggerAdapter.GetLevel: TLogLevel;
begin
  Result := FComponent.MinLevel;
end;

function TComponentLoggerAdapter.GetName: string;
begin
  Result := FLoggerName;
end;

end.
