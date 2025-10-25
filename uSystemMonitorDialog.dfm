object frmSystemMonitorDialog: TfrmSystemMonitorDialog
  Left = 0
  Top = 0
  Caption = #31995#32479#30417#25511#22120
  ClientHeight = 820
  ClientWidth = 1200
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
  object pnlBottom: TPanel
    Left = 0
    Top = 768
    Width = 1200
    Height = 52
    Align = alBottom
    TabOrder = 0
    object btnStartMonitoring: TBitBtn
      Left = 800
      Top = 10
      Width = 120
      Height = 32
      Caption = #24320#22987#30417#25511
      OnClick = btnStartMonitoringClick
      TabOrder = 0
    end
    object btnStopMonitoring: TBitBtn
      Left = 930
      Top = 10
      Width = 120
      Height = 32
      Caption = #20572#27490#30417#25511
      OnClick = btnStopMonitoringClick
      TabOrder = 1
    end
    object btnExportData: TBitBtn
      Left = 1060
      Top = 10
      Width = 120
      Height = 32
      Caption = #23548#20986#25968#25454
      OnClick = btnExportDataClick
      TabOrder = 2
    end
    object btnClose: TBitBtn
      Left = 20
      Top = 10
      Width = 100
      Height = 32
      Caption = #20851#38381
      OnClick = btnCloseClick
      TabOrder = 3
    end
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 744
    Width = 1200
    Height = 24
    Panels = <
      item
        Text = ''
        Width = 250
      end
      item
        Text = ''
        Width = 200
      end>
  end
  object pnlMain: TPanel
    Left = 0
    Top = 0
    Width = 1200
    Height = 744
    Align = alClient
    TabOrder = 2
    object pgcMonitor: TPageControl
      Left = 8
      Top = 8
      Width = 1184
      Height = 728
      ActivePage = tsOverview
      TabOrder = 0
      object tsOverview: TTabSheet
        Caption = #27010#35266
        object gbSystemInfo: TGroupBox
          Left = 16
          Top = 16
          Width = 1140
          Height = 140
          Caption = #31995#32479#24773#20917
          TabOrder = 0
          object lblCPUUsage: TLabel
            Left = 16
            Top = 24
            Width = 80
            Height = 16
            Caption = 'CPU'
          end
          object lblCPUValue: TLabel
            Left = 920
            Top = 24
            Width = 100
            Height = 16
            Caption = '0%'
          end
          object pbCPU: TProgressBar
            Left = 120
            Top = 20
            Width = 780
            Height = 20
            Max = 100
            Position = 0
            TabOrder = 0
          end
          object lblMemoryUsage: TLabel
            Left = 16
            Top = 52
            Width = 80
            Height = 16
            Caption = #20869#23384
          end
          object lblMemoryValue: TLabel
            Left = 920
            Top = 52
            Width = 200
            Height = 16
            Caption = '0%'
          end
          object pbMemory: TProgressBar
            Left = 120
            Top = 48
            Width = 780
            Height = 20
            Max = 100
            Position = 0
            TabOrder = 1
          end
          object lblDiskUsage: TLabel
            Left = 16
            Top = 80
            Width = 80
            Height = 16
            Caption = #30913#30424
          end
          object lblDiskValue: TLabel
            Left = 920
            Top = 80
            Width = 100
            Height = 16
            Caption = '0%'
          end
          object pbDisk: TProgressBar
            Left = 120
            Top = 76
            Width = 780
            Height = 20
            Max = 100
            Position = 0
            TabOrder = 2
          end
          object lblNetworkUsage: TLabel
            Left = 16
            Top = 108
            Width = 80
            Height = 16
            Caption = #32593#32476
          end
          object lblNetworkValue: TLabel
            Left = 920
            Top = 108
            Width = 180
            Height = 16
            Caption = '0MB/s'
          end
          object pbNetwork: TProgressBar
            Left = 120
            Top = 104
            Width = 780
            Height = 20
            Max = 100
            Position = 0
            TabOrder = 3
          end
        end
        object gbSystemDetails: TGroupBox
          Left = 16
          Top = 168
          Width = 1140
          Height = 120
          Caption = #31995#32479#35814#24773
          TabOrder = 1
          object lblOSVersion: TLabel
            Left = 16
            Top = 24
            Width = 80
            Height = 16
            Caption = 'OS'
          end
          object lblOSVersionValue: TLabel
            Left = 120
            Top = 24
            Width = 200
            Height = 16
            Caption = ''
          end
          object lblTotalRAM: TLabel
            Left = 16
            Top = 48
            Width = 80
            Height = 16
            Caption = #24635#20869#23384
          end
          object lblTotalRAMValue: TLabel
            Left = 120
            Top = 48
            Width = 200
            Height = 16
            Caption = ''
          end
          object lblUptime: TLabel
            Left = 16
            Top = 72
            Width = 80
            Height = 16
            Caption = #36816#34892#26102#38271
          end
          object lblUptimeValue: TLabel
            Left = 120
            Top = 72
            Width = 200
            Height = 16
            Caption = ''
          end
          object lblProcessCount: TLabel
            Left = 16
            Top = 96
            Width = 80
            Height = 16
            Caption = #36827#31243#25968
          end
          object lblProcessCountValue: TLabel
            Left = 120
            Top = 96
            Width = 200
            Height = 16
            Caption = ''
          end
        end
      end
      object tsCharts: TTabSheet
        Caption = #22270#34920
        object pnlChartControls: TPanel
          Left = 16
          Top = 16
          Width = 1140
          Height = 40
          TabOrder = 0
          object lblChartType: TLabel
            Left = 8
            Top = 12
            Width = 60
            Height = 16
            Caption = #31867#22411
          end
          object cmbChartType: TComboBox
            Left = 72
            Top = 8
            Width = 160
            Height = 24
            Style = csDropDownList
            TabOrder = 0
            OnChange = cmbChartTypeChange
          end
          object lblTimeRange: TLabel
            Left = 252
            Top = 12
            Width = 60
            Height = 16
            Caption = #26102#38388
          end
          object cmbTimeRange: TComboBox
            Left = 316
            Top = 8
            Width = 160
            Height = 24
            Style = csDropDownList
            TabOrder = 1
            OnChange = cmbTimeRangeChange
          end
          object chkAutoScale: TCheckBox
            Left = 496
            Top = 10
            Width = 100
            Height = 20
            Caption = #33258#21160#32553#25918
            TabOrder = 2
            Checked = True
            State = cbChecked
          end
          object btnResetZoom: TBitBtn
            Left = 612
            Top = 8
            Width = 100
            Height = 24
            Caption = #37325#32622
            OnClick = btnResetZoomClick
            TabOrder = 3
          end
        end
        object pnlChart: TPanel
          Left = 16
          Top = 64
          Width = 1140
          Height = 580
          BevelOuter = bvLowered
          Color = clWhite
          TabOrder = 1
        end
      end
      object tsProcesses: TTabSheet
        Caption = #36827#31243
        object pnlProcessControls: TPanel
          Left = 16
          Top = 16
          Width = 1140
          Height = 40
          TabOrder = 0
          object lblProcessFilter: TLabel
            Left = 8
            Top = 12
            Width = 60
            Height = 16
            Caption = #36807#28388
          end
          object edtProcessFilter: TEdit
            Left = 72
            Top = 8
            Width = 200
            Height = 24
            TabOrder = 0
          end
          object btnRefreshProcesses: TBitBtn
            Left = 284
            Top = 8
            Width = 100
            Height = 24
            Caption = #21047#26032
            OnClick = btnRefreshProcessesClick
            TabOrder = 1
          end
          object btnKillProcess: TBitBtn
            Left = 392
            Top = 8
            Width = 100
            Height = 24
            Caption = #32456#27490
            OnClick = btnKillProcessClick
            TabOrder = 2
          end
        end
        object lvProcesses: TListView
          Left = 16
          Top = 64
          Width = 1140
          Height = 580
          ViewStyle = vsReport
          ReadOnly = True
          RowSelect = True
          TabOrder = 1
          OnDblClick = lvProcessesDblClick
        end
      end
      object tsAlerts: TTabSheet
        Caption = #35686#25253
        object Splitter1: TSplitter
          Left = 16
          Top = 304
          Width = 1140
          Height = 6
        end
        object lvAlerts: TListView
          Left = 16
          Top = 16
          Width = 1140
          Height = 280
          ViewStyle = vsReport
          ReadOnly = True
          RowSelect = True
          TabOrder = 0
        end
        object memoRecommendations: TMemo
          Left = 16
          Top = 316
          Width = 1140
          Height = 328
          ScrollBars = ssVertical
          TabOrder = 1
        end
      end
      object tsSettings: TTabSheet
        Caption = #35774#32622
        object pnlSettings: TPanel
          Left = 16
          Top = 16
          Width = 1140
          Height = 120
          TabOrder = 0
          object lblRefreshInterval: TLabel
            Left = 8
            Top = 12
            Width = 120
            Height = 16
            Caption = #21047#26032#38388#38548
          end
          object seRefreshInterval: TSpinEdit
            Left = 132
            Top = 8
            Width = 80
            Height = 24
            MaxValue = 60
            MinValue = 1
            TabOrder = 0
            Value = 2
            OnChange = seRefreshIntervalChange
          end
          object lblSeconds: TLabel
            Left = 216
            Top = 12
            Width = 24
            Height = 16
            Caption = #31186
          end
          object chkEnableAlerts: TCheckBox
            Left = 260
            Top = 10
            Width = 120
            Height = 20
            Caption = #21551#29992#35686#25253
            TabOrder = 1
            Checked = True
            State = cbChecked
            OnClick = chkEnableAlertsClick
          end
          object chkLogToFile: TCheckBox
            Left = 388
            Top = 10
            Width = 120
            Height = 20
            Caption = #20889#20837#26085#24535
            TabOrder = 2
          end
          object chkShowNotifications: TCheckBox
            Left = 516
            Top = 10
            Width = 140
            Height = 20
            Caption = #36890#30693#36890#30693
            TabOrder = 3
          end
        end
        object gbThresholds: TGroupBox
          Left = 16
          Top = 144
          Width = 1140
          Height = 120
          Caption = #38480#20540
          TabOrder = 1
          object lblCPUThreshold: TLabel
            Left = 16
            Top = 24
            Width = 80
            Height = 16
            Caption = 'CPU %'
          end
          object seCPUThreshold: TSpinEdit
            Left = 100
            Top = 20
            Width = 80
            Height = 24
            MaxValue = 99
            MinValue = 50
            TabOrder = 0
            Value = 80
          end
          object lblMemoryThreshold: TLabel
            Left = 200
            Top = 24
            Width = 80
            Height = 16
            Caption = #20869#23384' %'
          end
          object seMemoryThreshold: TSpinEdit
            Left = 284
            Top = 20
            Width = 80
            Height = 24
            MaxValue = 99
            MinValue = 60
            TabOrder = 1
            Value = 85
          end
          object lblDiskThreshold: TLabel
            Left = 384
            Top = 24
            Width = 80
            Height = 16
            Caption = #30913#30424' %'
          end
          object seDiskThreshold: TSpinEdit
            Left = 468
            Top = 20
            Width = 80
            Height = 24
            MaxValue = 99
            MinValue = 70
            TabOrder = 2
            Value = 90
          end
        end
      end
    end
  end
  object pmProcesses: TPopupMenu
    Left = 16
    Top = 712
    object miProcessDetails: TMenuItem
      Caption = #35814#24773
      OnClick = miProcessDetailsClick
    end
    object miKillProcess: TMenuItem
      Caption = #32456#27490
      OnClick = miKillProcessClick
    end
    object miSeparator1: TMenuItem
      Caption = '-'
    end
    object miProcessPriority: TMenuItem
      Caption = #20248#20808#32423
    end
    object miProcessLocation: TMenuItem
      Caption = #25171#24320#20301#32622
      OnClick = miProcessLocationClick
    end
  end
  object SaveDialog: TSaveDialog
    Left = 96
    Top = 712
  end
  object TimerUpdate: TTimer
    Enabled = False
    Interval = 2000
    OnTimer = TimerUpdateTimer
    Left = 152
    Top = 712
  end
  object TimerChart: TTimer
    Enabled = False
    Interval = 1000
    OnTimer = TimerChartTimer
    Left = 208
    Top = 712
  end
end
