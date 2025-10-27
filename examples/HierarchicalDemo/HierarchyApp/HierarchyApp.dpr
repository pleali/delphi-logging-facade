program HierarchyApp;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  Logger.Types,
  Logger.Intf,
  Logger.Factory,
  Logger.Console,
  // Application units
  App.UI.MainForm in 'src\App.UI.MainForm.pas',
  App.Business.OrderProcessor in 'src\App.Business.OrderProcessor.pas',
  App.Database.Connection in 'src\App.Database.Connection.pas',
  App.Database.Repository.Orders in 'src\App.Database.Repository.Orders.pas',
  App.Database.Repository.Customers in 'src\App.Database.Repository.Customers.pas',
  // BPL units
  DataProcessor.Validation in '..\DataProcessorLib\src\DataProcessor.Validation.pas',
  DataProcessor.Transform.Converter in '..\DataProcessorLib\src\DataProcessor.Transform.Converter.pas',
  DataProcessor.Transform.Mapper in '..\DataProcessorLib\src\DataProcessor.Transform.Mapper.pas',
  DataProcessor.Export.Csv in '..\DataProcessorLib\src\DataProcessor.Export.Csv.pas',
  DataProcessor.Export.Json in '..\DataProcessorLib\src\DataProcessor.Export.Json.pas';

/// <summary>
/// Demonstrates logging from application UI layer
/// </summary>
procedure DemoUILayer;
var
  LMainForm: TMainForm;
begin
  Writeln;
  Writeln('========================================');
  Writeln('  UI LAYER (app.ui.*)');
  Writeln('========================================');

  LMainForm := TMainForm.Create;
  try
    LMainForm.Initialize;
    LMainForm.ProcessUserAction('LoadData');
    LMainForm.ProcessUserAction('SaveSettings');
    LMainForm.UpdateStatus('Ready');
  finally
    LMainForm.Free;
  end;
end;

/// <summary>
/// Demonstrates logging from business logic layer
/// </summary>
procedure DemoBusinessLayer;
var
  LOrderProcessor: TOrderProcessor;
  LOrderId: Integer;
begin
  Writeln;
  Writeln('========================================');
  Writeln('  BUSINESS LAYER (app.business.*)');
  Writeln('========================================');

  LOrderProcessor := TOrderProcessor.Create;
  try
    LOrderId := LOrderProcessor.CreateOrder(1001, 299.99);
    LOrderProcessor.ValidateOrder(LOrderId);
    LOrderProcessor.ProcessPayment(LOrderId);
    LOrderProcessor.CompleteOrder(LOrderId);
  finally
    LOrderProcessor.Free;
  end;
end;

/// <summary>
/// Demonstrates logging from database layer
/// </summary>
procedure DemoDatabaseLayer;
var
  LConnection: TDatabaseConnection;
  LOrdersRepo: TOrdersRepository;
  LCustomersRepo: TCustomersRepository;
begin
  Writeln;
  Writeln('========================================');
  Writeln('  DATABASE LAYER (app.database.*)');
  Writeln('========================================');

  LConnection := TDatabaseConnection.Create('Server=localhost;Database=TestDB');
  try
    LConnection.Connect;

    // Orders Repository
    Writeln;
    Writeln('--- Orders Repository ---');
    LOrdersRepo := TOrdersRepository.Create(LConnection);
    try
      LOrdersRepo.FindById(1001);
      LOrdersRepo.Save(1002, 'OrderData123');
      LOrdersRepo.Delete(1003);
    finally
      LOrdersRepo.Free;
    end;

    // Customers Repository
    Writeln;
    Writeln('--- Customers Repository ---');
    LCustomersRepo := TCustomersRepository.Create(LConnection);
    try
      LCustomersRepo.FindById(501);
      LCustomersRepo.FindByName('Smith');
      LCustomersRepo.Save(502, 'John Doe', 'john@example.com');
    finally
      LCustomersRepo.Free;
    end;

    LConnection.Disconnect;
  finally
    LConnection.Free;
  end;
end;

/// <summary>
/// Demonstrates logging from BPL - DataProcessor library
/// </summary>
procedure DemoDataProcessorLib;
var
  LValidator: TDataValidator;
  LConverter: TDataConverter;
  LMapper: TDataMapper;
  LCsvExporter: TCsvExporter;
  LJsonExporter: TJsonExporter;
  LData: TStringList;
begin
  Writeln;
  Writeln('========================================');
  Writeln('  DATA PROCESSOR LIB (dataprocessor.*)');
  Writeln('========================================');

  // Validation
  Writeln;
  Writeln('--- Validation Layer ---');
  LValidator := TDataValidator.Create;
  try
    LValidator.ValidateData('Sample data');
    LValidator.ValidateEmail('user@example.com');
    LValidator.ValidatePhone('+1234567890');
  finally
    LValidator.Free;
  end;

  // Transform - Converter
  Writeln;
  Writeln('--- Transform: Converter ---');
  LConverter := TDataConverter.Create;
  try
    LConverter.ToUpperCase('hello world');
    LConverter.ToJson('name', 'John');
    LConverter.ConvertEncoding('data123');
  finally
    LConverter.Free;
  end;

  // Transform - Mapper
  Writeln;
  Writeln('--- Transform: Mapper ---');
  LMapper := TDataMapper.Create;
  try
    LMapper.AddMapping('source_field', 'target_field');
    LMapper.AddMapping('old_name', 'new_name');
    LMapper.ApplyMappings('sample data');
  finally
    LMapper.Free;
  end;

  // Export - CSV
  Writeln;
  Writeln('--- Export: CSV ---');
  LCsvExporter := TCsvExporter.Create;
  try
    LData := TStringList.Create;
    try
      LData.Add('Name,Age,City');
      LData.Add('John,30,Paris');
      LData.Add('Jane,25,London');
      LCsvExporter.ExportToCsv(LData);
    finally
      LData.Free;
    end;
  finally
    LCsvExporter.Free;
  end;

  // Export - JSON
  Writeln;
  Writeln('--- Export: JSON ---');
  LJsonExporter := TJsonExporter.Create;
  try
    LData := TStringList.Create;
    try
      LData.Add('Item 1');
      LData.Add('Item 2');
      LData.Add('Item 3');
      LJsonExporter.ExportToJson(LData);
    finally
      LData.Free;
    end;
  finally
    LJsonExporter.Free;
  end;
end;

/// <summary>
/// Main program
/// </summary>
begin
  Randomize;

  // Setup console logger factory
  TLoggerFactory.SetNamedLoggerFactory(
    function(const AName: string): ILogger
    begin
      Result := TConsoleLogger.Create(AName, llTrace, True);
    end
  );

  try
    Writeln('================================================================================');
    Writeln('  HIERARCHICAL LOGGING DEMONSTRATION');
    Writeln('================================================================================');
    Writeln;
    Writeln('This demo shows hierarchical logging with automatic context prefixing.');
    Writeln('Configuration loaded from:');
    {$IFDEF DEBUG}
    Writeln('  - logging-debug.properties (DEBUG mode)');
    {$ELSE}
    Writeln('  - logging.properties (RELEASE mode)');
    {$ENDIF}
    Writeln;
    Writeln('Logger hierarchy demonstrates:');
    Writeln('  - Application layers: app.ui.*, app.business.*, app.database.*');
    Writeln('  - BPL library: dataprocessor.validation, dataprocessor.transform.*,');
    Writeln('                 dataprocessor.export.*');
    Writeln('  - Wildcard configuration at multiple levels');
    Writeln('  - Most specific rule wins (Logback-style resolution)');
    Writeln;

    // Execute all demos
    DemoUILayer;
    DemoBusinessLayer;
    DemoDatabaseLayer;
    DemoDataProcessorLib;

    Writeln;
    Writeln('================================================================================');
    Writeln('  DEMO COMPLETED');
    Writeln('================================================================================');
    Writeln;
    Writeln('Check the log output above to see hierarchical logging in action!');
    Writeln;
    Writeln('Key points demonstrated:');
    Writeln('  1. Logs from both application (app.*) and BPL (dataprocessor.*)');
    Writeln('  2. Automatic context prefixing via Logger.AutoContext.inc');
    Writeln('  3. Multiple hierarchy levels (up to 4 levels deep)');
    Writeln('  4. Configuration via wildcard patterns in .properties files');
    Writeln;
    Writeln('Press ENTER to exit...');
    Readln;
  except
    on E: Exception do
    begin
      Writeln;
      Writeln('FATAL ERROR: ', E.ClassName, ': ', E.Message);
      Writeln('Press ENTER to exit...');
      Readln;
      ExitCode := 1;
    end;
  end;
end.
