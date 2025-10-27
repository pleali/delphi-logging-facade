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
    Height = 220
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    object grpSettings: TGroupBox
      Left = 16
      Top = 8
      Width = 870
      Height = 89
      Caption = ' Logger Component Settings '
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
      object chkActive: TCheckBox
        Left = 232
        Top = 43
        Width = 265
        Height = 17
        Caption = 'Active (Register with LoggerFactory)'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 1
        OnClick = chkActiveClick
      end
    end
    object btnTrace: TButton
      Left = 16
      Top = 107
      Width = 140
      Height = 35
      Caption = 'TRACE'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
      OnClick = btnTraceClick
    end
    object btnDebug: TButton
      Left = 162
      Top = 107
      Width = 140
      Height = 35
      Caption = 'DEBUG'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 16744576
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
      OnClick = btnDebugClick
    end
    object btnInfo: TButton
      Left = 308
      Top = 107
      Width = 140
      Height = 35
      Caption = 'INFO'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGreen
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
      OnClick = btnInfoClick
    end
    object btnWarn: TButton
      Left = 454
      Top = 107
      Width = 140
      Height = 35
      Caption = 'WARN'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clOrange
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 4
      OnClick = btnWarnClick
    end
    object btnError: TButton
      Left = 600
      Top = 107
      Width = 140
      Height = 35
      Caption = 'ERROR'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 5
      OnClick = btnErrorClick
    end
    object btnFatal: TButton
      Left = 746
      Top = 107
      Width = 140
      Height = 35
      Caption = 'FATAL'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clMaroon
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 6
      OnClick = btnFatalClick
    end
    object btnClear: TButton
      Left = 16
      Top = 154
      Width = 870
      Height = 35
      Caption = 'Clear Log'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 7
      OnClick = btnClearClick
    end
    object btnMultiThread: TButton
      Left = 16
      Top = 195
      Width = 427
      Height = 25
      Caption = 'Multi-Thread Test (5 threads x 10 messages)'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 8
      OnClick = btnMultiThreadClick
    end
    object btnWithException: TButton
      Left = 449
      Top = 195
      Width = 437
      Height = 25
      Caption = 'Log with Exception'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 9
      OnClick = btnWithExceptionClick
    end
  end
  object richLog: TRichEdit
    Left = 0
    Top = 220
    Width = 900
    Height = 380
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
    LoggerName = 'ComponentExample'
    Left = 56
    Top = 192
  end
end
