object frmLogViewer: TfrmLogViewer
  Left = 0
  Top = 0
Caption = 'Log Viewer'
  ClientHeight = 720
  ClientWidth = 1100
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  OnClose = FormClose
  object pnlToolbar: TPanel
    Left = 0
    Top = 0
    Width = 1100
    Height = 64
    Align = alTop
    TabOrder = 0
    object lblFilter: TLabel
      Left = 12
      Top = 12
      Width = 48
      Height = 16
Caption = 'Filter'
    end
    object lblTo: TLabel
      Left = 520
      Top = 12
      Width = 16
      Height = 16
Caption = '-'
    end
    object cmbLogLevel: TComboBox
      Left = 72
      Top = 8
      Width = 140
      Height = 24
      Style = csDropDownList
      TabOrder = 0
    end
    object dtpStartDate: TDateTimePicker
      Left = 224
      Top = 8
      Width = 140
      Height = 24
      Date = 45400.000000000000000000
      Time = 0.500000000000000000
      TabOrder = 1
    end
    object dtpEndDate: TDateTimePicker
      Left = 544
      Top = 8
      Width = 140
      Height = 24
      Date = 45400.000000000000000000
      Time = 0.500000000000000000
      TabOrder = 2
    end
    object edtModuleFilter: TEdit
      Left = 704
      Top = 8
      Width = 120
      Height = 24
      TabOrder = 3
TextHint = 'Module'
    end
    object edtSearchText: TEdit
      Left = 832
      Top = 8
      Width = 160
      Height = 24
      TabOrder = 4
TextHint = 'Search'
    end
    object btnFilter: TBitBtn
      Left = 1000
      Top = 8
      Width = 80
      Height = 24
Caption = 'Apply'
      TabOrder = 5
      OnClick = btnFilterClick
    end
    object btnClear: TBitBtn
      Left = 72
      Top = 36
      Width = 80
      Height = 22
Caption = 'Clear'
      TabOrder = 6
      OnClick = btnClearClick
    end
    object btnRefresh: TBitBtn
      Left = 160
      Top = 36
      Width = 80
      Height = 22
Caption = 'Refresh'
      TabOrder = 7
      OnClick = btnRefreshClick
    end
    object btnExport: TBitBtn
      Left = 248
      Top = 36
      Width = 80
      Height = 22
Caption = 'Export'
      TabOrder = 8
      OnClick = btnExportClick
    end
  end
  object pnlMain: TPanel
    Left = 0
    Top = 64
    Width = 1100
    Height = 624
    Align = alClient
    TabOrder = 1
    object lvLogs: TListView
      Left = 1
      Top = 1
      Width = 1098
      Height = 400
      Align = alTop
      ReadOnly = True
      RowSelect = True
      ViewStyle = vsReport
      TabOrder = 0
      PopupMenu = pmLogContext
      OnSelectItem = lvLogsSelectItem
      OnDblClick = lvLogsDblClick
      OnCustomDrawItem = lvLogsCustomDrawItem
    end
    object Splitter1: TSplitter
      Left = 1
      Top = 401
      Width = 1098
      Height = 6
      Cursor = crVSplit
      Align = alTop
      Visible = True
    end
    object pnlDetails: TPanel
      Left = 1
      Top = 407
      Width = 1098
      Height = 216
      Align = alClient
      TabOrder = 1
      object memoDetails: TMemo
        Left = 1
        Top = 1
        Width = 1096
        Height = 214
        Align = alClient
        TabOrder = 0
        ScrollBars = ssVertical
      end
    end
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 696
    Width = 1100
    Height = 24
    Panels = <
      item
        Text = ''
        Width = 250
      end
      item
        Text = ''
        Width = 250
      end>
    SimplePanel = False
  end
  object pmLogContext: TPopupMenu
    Left = 16
    Top = 680
    object miCopyEntry: TMenuItem
Caption = 'Copy Entry'
      OnClick = miCopyEntryClick
    end
    object miCopyMessage: TMenuItem
Caption = 'Copy Message'
      OnClick = miCopyMessageClick
    end
    object miSeparator1: TMenuItem
      Caption = '-' 
    end
    object miShowDetails: TMenuItem
Caption = 'Toggle Details'
      OnClick = miShowDetailsClick
    end
    object miFilterByLevel: TMenuItem
Caption = 'Filter by Level'
      OnClick = miFilterByLevelClick
    end
    object miFilterByModule: TMenuItem
Caption = 'Filter by Module'
      OnClick = miFilterByModuleClick
    end
  end
  object SaveDialog: TSaveDialog
    Left = 112
    Top = 680
    Filter = 'Text (*.txt)|*.txt|CSV (*.csv)|*.csv|HTML (*.html)|*.html'
    DefaultExt = 'txt'
  end
end
