unit App.UI.MainForm;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  System.SysUtils,
  Logger.Intf,
  Logger.Factory;

type
  /// <summary>
  /// Main UI Form
  /// Logger context: 'app.ui.mainform'
  /// </summary>
  TMainForm = class
  private
    FLogger: ILogger;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>
    /// Initializes the UI
    /// </summary>
    procedure Initialize;

    /// <summary>
    /// Processes user action
    /// </summary>
    procedure ProcessUserAction(const AAction: string);

    /// <summary>
    /// Updates status bar
    /// </summary>
    procedure UpdateStatus(const AMessage: string);
  end;

implementation

{ TMainForm }

constructor TMainForm.Create;
begin
  inherited Create;
  // Logger automatically gets context 'app.ui.mainform'
  FLogger := TLoggerFactory.GetLogger('App.UI.MainForm');
  FLogger.Info('Main form created');
end;

destructor TMainForm.Destroy;
begin
  FLogger.Info('Main form destroyed');
  inherited;
end;

procedure TMainForm.Initialize;
begin
  FLogger.Info('Initializing main form UI');
  FLogger.Debug('Loading UI components');
  FLogger.Trace('Setting up event handlers');

  // Simulate UI initialization
  Sleep(50);

  FLogger.Info('Main form initialized successfully');
end;

procedure TMainForm.ProcessUserAction(const AAction: string);
begin
  FLogger.Info('Processing user action: %s', [AAction]);
  FLogger.Debug('Validating action: %s', [AAction]);

  if AAction = '' then
  begin
    FLogger.Warn('Empty action received');
    Exit;
  end;

  FLogger.Trace('Action details: %s', [AAction]);
  FLogger.Info('User action processed successfully');
end;

procedure TMainForm.UpdateStatus(const AMessage: string);
begin
  FLogger.Debug('Updating status bar: %s', [AMessage]);
  FLogger.Trace('Status message length: %d', [Length(AMessage)]);
end;

end.
