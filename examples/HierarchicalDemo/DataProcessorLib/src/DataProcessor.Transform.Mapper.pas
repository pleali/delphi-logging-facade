unit DataProcessor.Transform.Mapper;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Logger.Intf,
  Logger.Factory;

type
  /// <summary>
  /// Data mapper component
  /// Logger context: 'dataprocessor.transform.mapper'
  /// </summary>
  TDataMapper = class
  private
    FLogger: ILogger;
    FMappings: TDictionary<string, string>;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>
    /// Maps a field from source to target
    /// </summary>
    procedure AddMapping(const ASourceField, ATargetField: string);

    /// <summary>
    /// Applies all mappings
    /// </summary>
    function ApplyMappings(const ASourceData: string): string;
  end;

implementation

{ TDataMapper }

constructor TDataMapper.Create;
begin
  inherited Create;
  FMappings := TDictionary<string, string>.Create;

  // Logger automatically gets context 'dataprocessor.transform.mapper'
  FLogger := TLoggerFactory.GetLogger('DataProcessor.Transform.Mapper');
  FLogger.Info('Data mapper initialized');
end;

destructor TDataMapper.Destroy;
begin
  FLogger.Info('Data mapper shutting down (mappings: %d)', [FMappings.Count]);
  FreeAndNil(FMappings);
  inherited;
end;

procedure TDataMapper.AddMapping(const ASourceField, ATargetField: string);
begin
  FLogger.Debug('Adding mapping: %s -> %s', [ASourceField, ATargetField]);
  FMappings.AddOrSetValue(ASourceField, ATargetField);
  FLogger.Info('Mapping added (total: %d)', [FMappings.Count]);
end;

function TDataMapper.ApplyMappings(const ASourceData: string): string;
var
  LPair: TPair<string, string>;
begin
  FLogger.Info('Applying mappings (count: %d)', [FMappings.Count]);
  FLogger.Trace('Source data: %s', [ASourceData]);

  Result := ASourceData;

  for LPair in FMappings do
  begin
    FLogger.Trace('Processing mapping: %s -> %s', [LPair.Key, LPair.Value]);
    // Simulate mapping
  end;

  FLogger.Info('Mappings applied successfully');
  FLogger.Debug('Result length: %d', [Length(Result)]);
end;

end.
