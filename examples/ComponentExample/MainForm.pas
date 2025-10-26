{******************************************************************************
  DelphiLoggingFacade - Component Example
  Copyright (c) 2025 Paul LEALI
  MIT License - See LICENSE file for details
******************************************************************************}
unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls,
  Logger.Types, Logger.Component, Logger.Component.Adapter, Logger.Intf,
  Logger.Factory;

type
  TfrmMain = class(TForm)
    richLog: TRichEdit;
    pnlButtons: TPanel;
    btnTrace: TButton;
    btnDebug: TButton;
    btnInfo: TButton;
    btnWarn: TButton;
    btnError: TButton;
    btnFatal: TButton;
    btnClear: TButton;
    grpSettings: TGroupBox;
    lblMinLevel: TLabel;
    cboMinLevel: TComboBox;
    chkAsyncEvents: TCheckBox;
    btnMultiThread: TButton;
    btnWithException: TButton;
    grpFactoryTest: TGroupBox;
    btnRegisterWithFactory: TButton;
    btnLogViaFactory: TButton;
    lblFactoryStatus: TLabel;
    LoggerComponent1: TLoggerComponent;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnTraceClick(Sender: TObject);
    procedure btnDebugClick(Sender: TObject);
    procedure btnInfoClick(Sender: TObject);
    procedure btnWarnClick(Sender: TObject);
    procedure btnErrorClick(Sender: TObject);
    procedure btnFatalClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure cboMinLevelChange(Sender: TObject);
    procedure chkAsyncEventsClick(Sender: TObject);
    procedure btnMultiThreadClick(Sender: TObject);
    procedure btnWithExceptionClick(Sender: TObject);
    procedure btnRegisterWithFactoryClick(Sender: TObject);
    procedure btnLogViaFactoryClick(Sender: TObject);
  private
    FMessageCount: Integer;
    FAdapter: ILogger;

    procedure OnLogMessage(Sender: TObject; const EventData: TLogEventData);
    procedure AddLogToRichEdit(const EventData: TLogEventData);
    function GetLevelColor(ALevel: TLogLevel): TColor;
    procedure AppendColoredText(const AText: string; AColor: TColor; ABold: Boolean = False);
  public
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

uses
  System.Threading;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FMessageCount := 0;

  // Configure component
  LoggerComponent1.LoggerName := 'ComponentExample';
  LoggerComponent1.MinLevel := llTrace;
  LoggerComponent1.AsyncEvents := True;

  // Assign event handlers
  LoggerComponent1.OnMessage := OnLogMessage;

  // Initialize combo box
  cboMinLevel.Items.Clear;
  cboMinLevel.Items.Add('TRACE');
  cboMinLevel.Items.Add('DEBUG');
  cboMinLevel.Items.Add('INFO');
  cboMinLevel.Items.Add('WARN');
  cboMinLevel.Items.Add('ERROR');
  cboMinLevel.Items.Add('FATAL');
  cboMinLevel.ItemIndex := 0;

  chkAsyncEvents.Checked := LoggerComponent1.AsyncEvents;

  lblFactoryStatus.Caption := 'Not registered';
  btnLogViaFactory.Enabled := False;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FAdapter := nil;
end;

procedure TfrmMain.OnLogMessage(Sender: TObject; const EventData: TLogEventData);
begin
  AddLogToRichEdit(EventData);
end;

function TfrmMain.GetLevelColor(ALevel: TLogLevel): TColor;
begin
  case ALevel of
    llTrace: Result := clGray;
    llDebug: Result := $00FF8080; // Light blue
    llInfo:  Result := clGreen;
    llWarn:  Result := $0000A5FF; // Orange
    llError: Result := clRed;
    llFatal: Result := clMaroon;
  else
    Result := clBlack;
  end;
end;

procedure TfrmMain.AppendColoredText(const AText: string; AColor: TColor; ABold: Boolean);
begin
  richLog.SelStart := Length(richLog.Text);
  richLog.SelLength := 0;
  richLog.SelAttributes.Color := AColor;
  if ABold then
    richLog.SelAttributes.Style := [fsBold]
  else
    richLog.SelAttributes.Style := [];
  richLog.SelText := AText;
end;

procedure TfrmMain.AddLogToRichEdit(const EventData: TLogEventData);
var
  LevelColor: TColor;
  TimeStr, LevelStr: string;
begin
  Inc(FMessageCount);

  LevelColor := GetLevelColor(EventData.Level);
  TimeStr := FormatDateTime('hh:nn:ss.zzz', EventData.TimeStamp);
  LevelStr := EventData.Level.ToString;

  // Add timestamp in gray
  AppendColoredText('[' + TimeStr + '] ', clGray);

  // Add level in color with bold
  AppendColoredText('[' + Format('%-5s', [LevelStr]) + '] ', LevelColor, True);

  // Add thread ID in dark gray
  AppendColoredText(Format('[Thread:%4d] ', [EventData.ThreadId]), $00666666);

  // Add message in level color
  AppendColoredText(EventData.Message, LevelColor);

  // Add exception info if present (in red)
  if EventData.ExceptionClass <> '' then
    AppendColoredText(Format(' - Exception: %s: %s',
      [EventData.ExceptionClass, EventData.ExceptionMessage]), clMaroon, True);

  // New line
  AppendColoredText(#13#10, clBlack);

  // Scroll to bottom
  richLog.Perform(EM_SCROLLCARET, 0, 0);
end;

procedure TfrmMain.btnTraceClick(Sender: TObject);
begin
  LoggerComponent1.Trace('This is a TRACE message');
end;

procedure TfrmMain.btnDebugClick(Sender: TObject);
begin
  LoggerComponent1.Debug('This is a DEBUG message');
end;

procedure TfrmMain.btnInfoClick(Sender: TObject);
begin
  LoggerComponent1.Info('This is an INFO message');
end;

procedure TfrmMain.btnWarnClick(Sender: TObject);
begin
  LoggerComponent1.Warn('This is a WARN message');
end;

procedure TfrmMain.btnErrorClick(Sender: TObject);
begin
  LoggerComponent1.Error('This is an ERROR message');
end;

procedure TfrmMain.btnFatalClick(Sender: TObject);
begin
  LoggerComponent1.Fatal('This is a FATAL message');
end;

procedure TfrmMain.btnClearClick(Sender: TObject);
begin
  richLog.Clear;
  FMessageCount := 0;
end;

procedure TfrmMain.cboMinLevelChange(Sender: TObject);
begin
  LoggerComponent1.MinLevel := TLogLevel(cboMinLevel.ItemIndex);
  LoggerComponent1.Info('Minimum log level changed to: ' + cboMinLevel.Text);
end;

procedure TfrmMain.chkAsyncEventsClick(Sender: TObject);
begin
  LoggerComponent1.AsyncEvents := chkAsyncEvents.Checked;
  LoggerComponent1.Info('Async events: ' + BoolToStr(chkAsyncEvents.Checked, True));
end;

procedure TfrmMain.btnMultiThreadClick(Sender: TObject);
var
  I: Integer;
  ThreadNum: Integer;
begin
  LoggerComponent1.Info('Starting multi-threaded logging test...');

  // Create 5 parallel threads that log messages
  for I := 1 to 5 do
  begin
    ThreadNum := I;  // Capture loop variable
    TTask.Run(
      procedure
      var
        J: Integer;
        LocalThreadNum: Integer;
      begin
        LocalThreadNum := ThreadNum;
        for J := 1 to 10 do
        begin
          LoggerComponent1.Info(Format('Thread %d - Message %d', [LocalThreadNum, J]));
          Sleep(Random(100)); // Random delay
        end;
      end);
  end;

  LoggerComponent1.Info('Multi-threaded test started (5 threads, 10 messages each)');
end;

procedure TfrmMain.btnWithExceptionClick(Sender: TObject);
var
  E: Exception;
begin
  E := Exception.Create('This is a sample exception');
  try
    LoggerComponent1.Error('Error occurred during processing', E);
  finally
    E.Free;
  end;
end;

procedure TfrmMain.btnRegisterWithFactoryClick(Sender: TObject);
begin
  // Create adapter and register with factory
  FAdapter := TComponentLoggerAdapter.Create(LoggerComponent1, False);

  TLoggerFactory.SetNamedLoggerFactory(
    function(const AName: string): ILogger
    begin
      Result := FAdapter;
    end);

  lblFactoryStatus.Caption := 'Registered with factory';
  lblFactoryStatus.Font.Color := clGreen;
  btnLogViaFactory.Enabled := True;
  btnRegisterWithFactory.Enabled := False;

  LoggerComponent1.Info('Component registered with LoggerFactory');
end;

procedure TfrmMain.btnLogViaFactoryClick(Sender: TObject);
var
  Logger: ILogger;
begin
  // Get logger from factory and use it
  Logger := TLoggerFactory.GetLogger('TestLogger');

  Logger.Trace('Trace via factory');
  Logger.Debug('Debug via factory');
  Logger.Info('Info via factory');
  Logger.Warn('Warning via factory');
  Logger.Error('Error via factory');
  Logger.Fatal('Fatal via factory');
end;

end.
