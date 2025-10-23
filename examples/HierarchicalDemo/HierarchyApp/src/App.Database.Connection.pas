unit App.Database.Connection;

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
  /// Database connection manager
  /// Logger context: 'app.database.connection'
  /// </summary>
  TDatabaseConnection = class
  private
    FLogger: ILogger;
    FConnected: Boolean;
    FConnectionString: string;
  public
    constructor Create(const AConnectionString: string);
    destructor Destroy; override;

    /// <summary>
    /// Opens database connection
    /// </summary>
    procedure Connect;

    /// <summary>
    /// Closes database connection
    /// </summary>
    procedure Disconnect;

    /// <summary>
    /// Executes a query
    /// </summary>
    function ExecuteQuery(const AQuery: string): Integer;

    property Connected: Boolean read FConnected;
  end;

implementation

{ TDatabaseConnection }

constructor TDatabaseConnection.Create(const AConnectionString: string);
begin
  inherited Create;
  FConnectionString := AConnectionString;
  FConnected := False;

  // Logger automatically gets context 'app.database.connection'
  FLogger := TLoggerFactory.GetLogger('App.Database.Connection');
  FLogger.Info('Database connection created');
  FLogger.Debug('Connection string: %s', [AConnectionString]);
end;

destructor TDatabaseConnection.Destroy;
begin
  if FConnected then
    Disconnect;

  FLogger.Info('Database connection destroyed');
  inherited;
end;

procedure TDatabaseConnection.Connect;
begin
  FLogger.Info('Opening database connection');
  FLogger.Debug('Connection string: %s', [FConnectionString]);
  FLogger.Trace('Establishing TCP connection to database server');

  try
    // Simulate connection
    Sleep(150);
    FConnected := True;

    FLogger.Info('Database connection established successfully');
  except
    on E: Exception do
    begin
      FLogger.Error('Failed to connect to database', E);
      raise;
    end;
  end;
end;

procedure TDatabaseConnection.Disconnect;
begin
  if not FConnected then
  begin
    FLogger.Warn('Already disconnected');
    Exit;
  end;

  FLogger.Info('Closing database connection');
  FConnected := False;
  FLogger.Info('Database connection closed');
end;

function TDatabaseConnection.ExecuteQuery(const AQuery: string): Integer;
begin
  if not FConnected then
  begin
    FLogger.Error('Cannot execute query: not connected');
    raise Exception.Create('Not connected to database');
  end;

  FLogger.Info('Executing query');
  FLogger.Debug('Query: %s', [AQuery]);
  FLogger.Trace('Query length: %d characters', [Length(AQuery)]);

  // Simulate query execution
  Sleep(50);
  Result := Random(100);

  FLogger.Info('Query executed (affected rows: %d)', [Result]);
end;

end.
