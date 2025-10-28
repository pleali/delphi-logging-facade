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
  Logger.Base,
  Logger.Component;

type
  /// <summary>
  /// Adapter that implements ILogger interface and delegates to TLoggerComponent.
  /// This allows TLoggerComponent to be used as a logger implementation in the facade.
  /// Inherits from TBaseLogger for Chain of Responsibility support.
  /// </summary>
  TComponentLoggerAdapter = class(TBaseLogger)
  private
    FComponent: TLoggerComponent;
    FOwnsComponent: Boolean;

    function GetComponent: TLoggerComponent;
  protected
    /// <summary>
    /// Delegates to the component's Log method.
    /// Called by base class when message passes level filter.
    /// </summary>
    procedure DoLog(ALevel: Logger.Types.TLogLevel; const AMessage: string); override;
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
  if not Assigned(AComponent) then
    raise Exception.Create('Component cannot be nil');

  inherited Create(AComponent.LoggerName, AComponent.MinLevel);

  FComponent := AComponent;
  FOwnsComponent := AOwnsComponent;
end;

constructor TComponentLoggerAdapter.Create(const ALoggerName: string);
begin
  inherited Create(ALoggerName, llInfo);

  FComponent := TLoggerComponent.Create(nil);
  FComponent.LoggerName := ALoggerName;
  FOwnsComponent := True;
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

procedure TComponentLoggerAdapter.DoLog(ALevel: Logger.Types.TLogLevel; const AMessage: string);
begin
  FComponent.Log(ALevel, AMessage);
end;

end.
