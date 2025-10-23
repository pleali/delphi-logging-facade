unit App.Database.Repository.Customers;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  System.SysUtils,
  Logger.Intf,
  Logger.Factory,
  App.Database.Connection;

type
  /// <summary>
  /// Customers repository
  /// Logger context: 'app.database.repository.customers'
  /// </summary>
  TCustomersRepository = class
  private
    FLogger: ILogger;
    FConnection: TDatabaseConnection;
  public
    constructor Create(AConnection: TDatabaseConnection);
    destructor Destroy; override;

    /// <summary>
    /// Finds a customer by ID
    /// </summary>
    function FindById(ACustomerId: Integer): Boolean;

    /// <summary>
    /// Finds customers by name
    /// </summary>
    function FindByName(const AName: string): Integer;

    /// <summary>
    /// Saves customer data
    /// </summary>
    procedure Save(ACustomerId: Integer; const AName, AEmail: string);
  end;

implementation

{ TCustomersRepository }

constructor TCustomersRepository.Create(AConnection: TDatabaseConnection);
begin
  inherited Create;
  FConnection := AConnection;

  // Logger automatically gets context 'app.database.repository.customers'
  FLogger := TLoggerFactory.GetLogger('App.Database.Repository.Customers');
  FLogger.Info('Customers repository initialized');
end;

destructor TCustomersRepository.Destroy;
begin
  FLogger.Info('Customers repository destroyed');
  inherited;
end;

function TCustomersRepository.FindById(ACustomerId: Integer): Boolean;
var
  LQuery: string;
begin
  FLogger.Info('Finding customer by ID: %d', [ACustomerId]);
  FLogger.Debug('Building SELECT query');

  LQuery := Format('SELECT * FROM Customers WHERE Id = %d', [ACustomerId]);
  FLogger.Trace('SQL Query: %s', [LQuery]);

  FConnection.ExecuteQuery(LQuery);
  Result := True;

  if Result then
    FLogger.Info('Customer found: %d', [ACustomerId])
  else
    FLogger.Warn('Customer not found: %d', [ACustomerId]);
end;

function TCustomersRepository.FindByName(const AName: string): Integer;
var
  LQuery: string;
begin
  FLogger.Info('Finding customers by name: %s', [AName]);
  FLogger.Debug('Performing LIKE search');

  LQuery := Format('SELECT * FROM Customers WHERE Name LIKE ''%%%s%%''', [AName]);
  FLogger.Trace('SQL Query: %s', [LQuery]);

  Result := FConnection.ExecuteQuery(LQuery);
  FLogger.Info('Found %d customers matching: %s', [Result, AName]);
end;

procedure TCustomersRepository.Save(ACustomerId: Integer; const AName, AEmail: string);
var
  LQuery: string;
begin
  FLogger.Info('Saving customer: %d (%s)', [ACustomerId, AName]);
  FLogger.Debug('Email: %s', [AEmail]);

  LQuery := Format('INSERT INTO Customers (Id, Name, Email) VALUES (%d, ''%s'', ''%s'')',
    [ACustomerId, AName, AEmail]);
  FLogger.Trace('SQL Query: %s', [LQuery]);

  FConnection.ExecuteQuery(LQuery);
  FLogger.Info('Customer saved successfully: %d', [ACustomerId]);
end;

end.
