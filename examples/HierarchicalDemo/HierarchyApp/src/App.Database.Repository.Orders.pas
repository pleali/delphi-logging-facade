unit App.Database.Repository.Orders;

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
  /// Orders repository
  /// Logger context: 'app.database.repository.orders'
  /// </summary>
  TOrdersRepository = class
  private
    FLogger: ILogger;
    FConnection: TDatabaseConnection;
  public
    constructor Create(AConnection: TDatabaseConnection);
    destructor Destroy; override;

    /// <summary>
    /// Finds an order by ID
    /// </summary>
    function FindById(AOrderId: Integer): Boolean;

    /// <summary>
    /// Saves an order
    /// </summary>
    procedure Save(AOrderId: Integer; const AData: string);

    /// <summary>
    /// Deletes an order
    /// </summary>
    procedure Delete(AOrderId: Integer);
  end;

implementation

{ TOrdersRepository }

constructor TOrdersRepository.Create(AConnection: TDatabaseConnection);
begin
  inherited Create;
  FConnection := AConnection;

  // Logger automatically gets context 'app.database.repository.orders'
  FLogger := TLoggerFactory.GetLogger('App.Database.Repository.Orders');
  FLogger.Info('Orders repository initialized');
end;

destructor TOrdersRepository.Destroy;
begin
  FLogger.Info('Orders repository destroyed');
  inherited;
end;

function TOrdersRepository.FindById(AOrderId: Integer): Boolean;
var
  LQuery: string;
begin
  FLogger.Info('Finding order by ID: %d', [AOrderId]);
  FLogger.Debug('Building SELECT query');

  LQuery := Format('SELECT * FROM Orders WHERE Id = %d', [AOrderId]);
  FLogger.Trace('SQL Query: %s', [LQuery]);

  FConnection.ExecuteQuery(LQuery);
  Result := True;

  if Result then
    FLogger.Info('Order found: %d', [AOrderId])
  else
    FLogger.Warn('Order not found: %d', [AOrderId]);
end;

procedure TOrdersRepository.Save(AOrderId: Integer; const AData: string);
var
  LQuery: string;
begin
  FLogger.Info('Saving order: %d', [AOrderId]);
  FLogger.Debug('Data length: %d', [Length(AData)]);
  FLogger.Trace('Order data: %s', [AData]);

  LQuery := Format('INSERT INTO Orders (Id, Data) VALUES (%d, ''%s'')', [AOrderId, AData]);
  FLogger.Trace('SQL Query: %s', [LQuery]);

  FConnection.ExecuteQuery(LQuery);
  FLogger.Info('Order saved successfully: %d', [AOrderId]);
end;

procedure TOrdersRepository.Delete(AOrderId: Integer);
var
  LQuery: string;
begin
  FLogger.Info('Deleting order: %d', [AOrderId]);

  LQuery := Format('DELETE FROM Orders WHERE Id = %d', [AOrderId]);
  FLogger.Debug('SQL Query: %s', [LQuery]);

  FConnection.ExecuteQuery(LQuery);
  FLogger.Info('Order deleted: %d', [AOrderId]);
end;

end.
