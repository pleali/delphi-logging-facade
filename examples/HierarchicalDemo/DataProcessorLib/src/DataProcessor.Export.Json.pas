unit DataProcessor.Export.Json;

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
  /// JSON exporter component
  /// Logger context: 'dataprocessor.export.json'
  /// </summary>
  TJsonExporter = class
  private
    FLogger: ILogger;
    FPrettyPrint: Boolean;
  public
    constructor Create;

    /// <summary>
    /// Exports data to JSON format
    /// </summary>
    function ExportToJson(const AData: TStrings): string;

    /// <summary>
    /// Saves JSON to file
    /// </summary>
    procedure SaveToFile(const AFileName, AJsonData: string);

    property PrettyPrint: Boolean read FPrettyPrint write FPrettyPrint;
  end;

implementation

{ TJsonExporter }

constructor TJsonExporter.Create;
begin
  inherited Create;
  FPrettyPrint := True;

  // Logger automatically gets context 'dataprocessor.export.json'
  FLogger := TLoggerFactory.GetLogger('DataProcessor.Export.Json');
  FLogger.Info('JSON exporter initialized (pretty print: %s)', [BoolToStr(FPrettyPrint, True)]);
end;

function TJsonExporter.ExportToJson(const AData: TStrings): string;
var
  I: Integer;
begin
  FLogger.Info('Exporting data to JSON (items: %d)', [AData.Count]);
  FLogger.Debug('Pretty print: %s', [BoolToStr(FPrettyPrint, True)]);

  Result := '[';
  if FPrettyPrint then
    Result := Result + sLineBreak;

  for I := 0 to AData.Count - 1 do
  begin
    FLogger.Trace('Processing item %d: %s', [I, AData[I]]);

    if FPrettyPrint then
      Result := Result + '  ';
    Result := Result + Format('"%s"', [AData[I]]);
    if I < AData.Count - 1 then
      Result := Result + ',';
    if FPrettyPrint then
      Result := Result + sLineBreak;
  end;

  Result := Result + ']';

  FLogger.Info('JSON export complete (size: %d bytes)', [Length(Result)]);
  FLogger.Trace('JSON output: %s', [Result]);
end;

procedure TJsonExporter.SaveToFile(const AFileName, AJsonData: string);
var
  LFile: TextFile;
begin
  FLogger.Info('Saving JSON to file: %s', [AFileName]);
  FLogger.Debug('Data size: %d bytes', [Length(AJsonData)]);

  try
    AssignFile(LFile, AFileName);
    try
      Rewrite(LFile);
      Write(LFile, AJsonData);
      FLogger.Info('JSON file saved successfully');
    finally
      CloseFile(LFile);
    end;
  except
    on E: Exception do
    begin
      FLogger.Error('Failed to save JSON file', E);
      raise;
    end;
  end;
end;

end.
