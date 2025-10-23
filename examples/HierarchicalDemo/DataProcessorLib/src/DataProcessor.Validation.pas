unit DataProcessor.Validation;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  System.SysUtils,
  System.Classes,
  Logger.Intf,
  Logger.Factory;

type
  /// <summary>
  /// Data validation component
  /// Logger context: 'dataprocessor.validation'
  /// </summary>
  TDataValidator = class
  private
    FLogger: ILogger;
  public
    constructor Create;

    /// <summary>
    /// Validates input data
    /// </summary>
    function ValidateData(const AData: string): Boolean;

    /// <summary>
    /// Validates email format
    /// </summary>
    function ValidateEmail(const AEmail: string): Boolean;

    /// <summary>
    /// Validates phone number
    /// </summary>
    function ValidatePhone(const APhone: string): Boolean;
  end;

implementation

{ TDataValidator }

constructor TDataValidator.Create;
begin
  inherited Create;
  // Explicitly pass the unit context to the logger
  FLogger := TLoggerFactory.GetLogger('DataProcessor.Validation');
  FLogger.Info('Data validator initialized');
end;

function TDataValidator.ValidateData(const AData: string): Boolean;
begin
  FLogger.Debug('Validating data (length: %d)', [Length(AData)]);
  FLogger.Trace('Data content: %s', [AData]);

  Result := Length(AData) > 0;

  if Result then
    FLogger.Info('Data validation passed')
  else
  begin
    FLogger.Error('Data validation failed: empty data');
  end;
end;

function TDataValidator.ValidateEmail(const AEmail: string): Boolean;
begin
  FLogger.Debug('Validating email: %s', [AEmail]);

  Result := Pos('@', AEmail) > 0;

  if Result then
    FLogger.Info('Email validation passed: %s', [AEmail])
  else
    FLogger.Warn('Email validation failed: %s (missing @)', [AEmail]);
end;

function TDataValidator.ValidatePhone(const APhone: string): Boolean;
begin
  FLogger.Debug('Validating phone: %s', [APhone]);

  Result := Length(APhone) >= 10;

  if Result then
    FLogger.Info('Phone validation passed: %s', [APhone])
  else
    FLogger.Warn('Phone validation failed: %s (too short)', [APhone]);
end;

end.
