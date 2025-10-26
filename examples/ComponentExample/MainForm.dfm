object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'LoggingFacade - Component Example with Colored Output'
  ClientHeight = 600
  ClientWidth = 900
  Color = clWhitesmoke
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object pnlButtons: TPanel
    Left = 0
    Top = 0
    Width = 900
    Height = 289
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    object grpSettings: TGroupBox
      Left = 16
      Top = 8
      Width = 440
      Height = 105
      Caption = ' Settings '
      TabOrder = 0
      object lblMinLevel: TLabel
        Left = 16
        Top = 24
        Width = 86
        Height = 15
        Caption = 'Minimum Level:'
      end
      object cboMinLevel: TComboBox
        Left = 16
        Top = 43
        Width = 200
        Height = 23
        Style = csDropDownList
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        OnChange = cboMinLevelChange
      end
      object chkAsyncEvents: TCheckBox
        Left = 232
        Top = 43
        Width = 193
        Height = 17
        Caption = 'Async Events (non-blocking)'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 1
        OnClick = chkAsyncEventsClick
      end
    end
    object grpFactoryTest: TGroupBox
      Left = 470
      Top = 8
      Width = 416
      Height = 105
      Caption = ' Factory Integration Test '
      TabOrder = 1
      object lblFactoryStatus: TLabel
        Left = 16
        Top = 72
        Width = 81
        Height = 13
        Caption = 'Not registered'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object btnRegisterWithFactory: TButton
        Left = 16
        Top = 24
        Width = 384
        Height = 25
        Caption = 'Register Component with Factory'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        OnClick = btnRegisterWithFactoryClick
      end
      object btnLogViaFactory: TButton
        Left = 16
        Top = 55
        Width = 384
        Height = 25
        Caption = 'Log via Factory (test all levels)'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 1
        OnClick = btnLogViaFactoryClick
      end
    end
    object btnTrace: TButton
      Left = 16
      Top = 128
      Width = 140
      Height = 35
      Caption = 'TRACE'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
      OnClick = btnTraceClick
    end
    object btnDebug: TButton
      Left = 162
      Top = 128
      Width = 140
      Height = 35
      Caption = 'DEBUG'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 16744576
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
      OnClick = btnDebugClick
    end
    object btnInfo: TButton
      Left = 308
      Top = 128
      Width = 140
      Height = 35
      Caption = 'INFO'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGreen
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 4
      OnClick = btnInfoClick
    end
    object btnWarn: TButton
      Left = 454
      Top = 128
      Width = 140
      Height = 35
      Caption = 'WARN'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clOrange
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 5
      OnClick = btnWarnClick
    end
    object btnError: TButton
      Left = 600
      Top = 128
      Width = 140
      Height = 35
      Caption = 'ERROR'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 6
      OnClick = btnErrorClick
    end
    object btnFatal: TButton
      Left = 746
      Top = 128
      Width = 140
      Height = 35
      Caption = 'FATAL'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clMaroon
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 7
      OnClick = btnFatalClick
    end
    object btnClear: TButton
      Left = 16
      Top = 175
      Width = 870
      Height = 35
      Caption = 'Clear Log'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 8
      OnClick = btnClearClick
    end
    object btnMultiThread: TButton
      Left = 16
      Top = 220
      Width = 427
      Height = 30
      Caption = 'Multi-Thread Test (5 threads x 10 messages)'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 9
      OnClick = btnMultiThreadClick
    end
    object btnWithException: TButton
      Left = 449
      Top = 220
      Width = 437
      Height = 30
      Caption = 'Log with Exception'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 10
      OnClick = btnWithExceptionClick
    end
  end
  object richLog: TRichEdit
    Left = 0
    Top = 289
    Width = 900
    Height = 311
    Align = alClient
    Color = 16776176
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Consolas'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 1
  end
  object LoggerComponent1: TLoggerComponent
    LoggerName = 'MainLogger'
    Left = 56
    Top = 256
  end
end
