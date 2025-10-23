unit DataProcessor.Export.Csv;

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
  /// CSV exporter component
  /// Logger context: 'dataprocessor.export.csv'
  /// </summary>
  TCsvExporter = class
  private
    FLogger: ILogger;
    FDelimiter: Char;
  public
    constructor Create;

    /// <summary>
    /// Exports data to CSV format
    /// </summary>
    function ExportToCsv(const AData: TStrings): string;

    /// <summary>
    /// Saves CSV to file
    /// </summary>
    procedure SaveToFile(const AFileName, ACsvData: string);

    property Delimiter: Char read FDelimiter write FDelimiter;
  end;

implementation

{ TCsvExporter }

constructor TCsvExporter.Create;
begin
  inherited Create;
  FDelimiter := ',';

  // Logger automatically gets context 'dataprocessor.export.csv'
  FLogger := TLoggerFactory.GetLogger('DataProcessor.Export.Csv');
  FLogger.Info('CSV exporter initialized (delimiter: %s)', [FDelimiter]);
end;

function TCsvExporter.ExportToCsv(const AData: TStrings): string;
var
  I: Integer;
begin
  FLogger.Info('Exporting data to CSV (rows: %d)', [AData.Count]);
  FLogger.Debug('Delimiter: %s', [FDelimiter]);

  Result := '';
  for I := 0 to AData.Count - 1 do
  begin
    FLogger.Trace('Processing row %d: %s', [I, AData[I]]);
    Result := Result + AData[I];
    if I < AData.Count - 1 then
      Result := Result + sLineBreak;
  end;

  FLogger.Info('CSV export complete (size: %d bytes)', [Length(Result)]);
end;

procedure TCsvExporter.SaveToFile(const AFileName, ACsvData: string);
var
  LFile: TextFile;
begin
  FLogger.Info('Saving CSV to file: %s', [AFileName]);
  FLogger.Debug('Data size: %d bytes', [Length(ACsvData)]);

  try
    AssignFile(LFile, AFileName);
    try
      Rewrite(LFile);
      Write(LFile, ACsvData);
      FLogger.Info('CSV file saved successfully');
    finally
      CloseFile(LFile);
    end;
  except
    on E: Exception do
    begin
      FLogger.Error('Failed to save CSV file', E);
      raise;
    end;
  end;
end;

end.
