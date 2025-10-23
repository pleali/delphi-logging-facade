unit DataProcessor.Transform.Converter;

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
  /// Data converter component
  /// Logger context: 'dataprocessor.transform.converter'
  /// </summary>
  TDataConverter = class
  private
    FLogger: ILogger;
  public
    constructor Create;

    /// <summary>
    /// Converts string to uppercase
    /// </summary>
    function ToUpperCase(const AText: string): string;

    /// <summary>
    /// Converts string to JSON format
    /// </summary>
    function ToJson(const AKey, AValue: string): string;

    /// <summary>
    /// Converts data encoding
    /// </summary>
    function ConvertEncoding(const AData: string): string;
  end;

implementation

{ TDataConverter }

constructor TDataConverter.Create;
begin
  inherited Create;
  // Logger automatically gets context 'dataprocessor.transform.converter'
  FLogger := TLoggerFactory.GetLogger('DataProcessor.Transform.Converter');
  FLogger.Info('Data converter initialized');
end;

function TDataConverter.ToUpperCase(const AText: string): string;
begin
  FLogger.Trace('Converting to uppercase: %s', [AText]);
  Result := UpperCase(AText);
  FLogger.Debug('Converted to uppercase: %s', [Result]);
end;

function TDataConverter.ToJson(const AKey, AValue: string): string;
begin
  FLogger.Debug('Converting to JSON: %s = %s', [AKey, AValue]);
  Result := Format('{ "%s": "%s" }', [AKey, AValue]);
  FLogger.Info('JSON conversion complete');
  FLogger.Trace('JSON result: %s', [Result]);
end;

function TDataConverter.ConvertEncoding(const AData: string): string;
begin
  FLogger.Info('Converting data encoding');
  FLogger.Trace('Input data: %s', [AData]);

  // Simulate encoding conversion
  Result := AData;

  FLogger.Debug('Encoding conversion complete (length: %d)', [Length(Result)]);
end;

end.
