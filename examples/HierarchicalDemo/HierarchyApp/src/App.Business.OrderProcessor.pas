unit App.Business.OrderProcessor;

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
  /// Order processing business logic
  /// Logger context: 'app.business.orderprocessor'
  /// </summary>
  TOrderProcessor = class
  private
    FLogger: ILogger;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>
    /// Creates a new order
    /// </summary>
    function CreateOrder(const ACustomerId: Integer; const AAmount: Double): Integer;

    /// <summary>
    /// Validates an order
    /// </summary>
    function ValidateOrder(AOrderId: Integer): Boolean;

    /// <summary>
    /// Processes payment for an order
    /// </summary>
    function ProcessPayment(AOrderId: Integer): Boolean;

    /// <summary>
    /// Completes an order
    /// </summary>
    procedure CompleteOrder(AOrderId: Integer);
  end;

implementation

{ TOrderProcessor }

constructor TOrderProcessor.Create;
begin
  inherited Create;
  // Logger automatically gets context 'app.business.orderprocessor'
  FLogger := TLoggerFactory.GetLogger('App.Business.OrderProcessor');
  FLogger.Info('Order processor initialized');
end;

destructor TOrderProcessor.Destroy;
begin
  FLogger.Info('Order processor shutting down');
  inherited;
end;

function TOrderProcessor.CreateOrder(const ACustomerId: Integer; const AAmount: Double): Integer;
begin
  FLogger.Info('Creating new order for customer: %d', [ACustomerId]);
  FLogger.Debug('Order amount: %.2f', [AAmount]);

  if AAmount <= 0 then
  begin
    FLogger.Error('Invalid order amount: %.2f', [AAmount]);
    raise Exception.Create('Invalid order amount');
  end;

  // Simulate order creation
  Result := Random(10000) + 1000;

  FLogger.Info('Order created successfully (ID: %d)', [Result]);
  FLogger.Trace('Order details - Customer: %d, Amount: %.2f, OrderID: %d',
    [ACustomerId, AAmount, Result]);
end;

function TOrderProcessor.ValidateOrder(AOrderId: Integer): Boolean;
begin
  FLogger.Info('Validating order: %d', [AOrderId]);
  FLogger.Debug('Checking order integrity');

  // Simulate validation
  Result := AOrderId > 0;

  if Result then
    FLogger.Info('Order validation passed: %d', [AOrderId])
  else
    FLogger.Warn('Order validation failed: %d', [AOrderId]);
end;

function TOrderProcessor.ProcessPayment(AOrderId: Integer): Boolean;
begin
  FLogger.Info('Processing payment for order: %d', [AOrderId]);
  FLogger.Debug('Contacting payment gateway');
  FLogger.Trace('Payment processing details for order: %d', [AOrderId]);

  // Simulate payment processing
  Sleep(100);
  Result := True;

  if Result then
    FLogger.Info('Payment processed successfully for order: %d', [AOrderId])
  else
    FLogger.Error('Payment processing failed for order: %d', [AOrderId]);
end;

procedure TOrderProcessor.CompleteOrder(AOrderId: Integer);
begin
  FLogger.Info('Completing order: %d', [AOrderId]);
  FLogger.Debug('Updating order status to completed');

  // Simulate order completion
  Sleep(50);

  FLogger.Info('Order completed successfully: %d', [AOrderId]);
end;

end.
