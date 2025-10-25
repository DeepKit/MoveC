object frmSystemMonitor: TfrmSystemMonitor
  Left = 0
  Top = 0
  Caption = '系统监控工具 v2.2.0'
  ClientHeight = 600
  ClientWidth = 900
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  WindowState = wsMaximized
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  
  object pgcMain: TPageControl
    Left = 0
    Top = 0
    Width = 900
    Height = 555
    ActivePage = tsMonitoring
    Align = alClient
    TabOrder = 0
    
    object tsMonitoring: TTabSheet
      Caption = '实时监控'
      
      object pnlMonitorTop: TPanel
        Left = 0
        Top = 0
        Width = 892
        Height = 120
        Align = alTop
        BevelInner = bvRaised
        BevelOuter = bvLowered
        TabOrder = 0
        
        object lblCPUUsage: TLabel
          Left = 16
          Top = 16
          Width = 80
          Height = 13
          Caption = 'CPU使用率: 0%'
        end
        
        object pbCPU: TProgressBar
          Left = 120
          Top = 13
          Width = 250
          Height = 17
          TabOrder = 0
        end
        
        object lblMemoryUsage: TLabel
          Left = 16
          Top = 48
          Width = 80
          Height = 13
          Caption = '内存使用率: 0%'
        end
        
        object pbMemory: TProgressBar
          Left = 120
          Top = 45
          Width = 250
          Height = 17
          TabOrder = 1
        end
        
        object lblDiskUsage: TLabel
          Left = 16
          Top = 80
          Width = 80
          Height = 13
          Caption = '磁盘使用率: 0%'
        end
        
        object pbDisk: TProgressBar
          Left = 120
          Top = 77
          Width = 250
          Height = 17
          TabOrder = 2
        end
      end
      
      object pnlMonitorBottom: TPanel
        Left = 0
        Top = 120
        Width = 892
        Height = 407
        Align = alClient
        BevelOuter = bvNone
        TabOrder = 1
        
        object memoSystemInfo: TMemo
          Left = 0
          Top = 0
          Width = 892
          Height = 407
          Align = alClient
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Courier New'
          Font.Style = []
          ParentFont = False
          ReadOnly = True
          ScrollBars = ssVertical
          TabOrder = 0
        end
      end
    end
    
    object tsAnalysis: TTabSheet
      Caption = '性能分析'
      ImageIndex = 1
      
      object pnlAnalysisTop: TPanel
        Left = 0
        Top = 0
        Width = 892
        Height = 50
        Align = alTop
        BevelInner = bvRaised
        BevelOuter = bvLowered
        TabOrder = 0
        
        object btnRunAnalysis: TBitBtn
          Left = 16
          Top = 13
          Width = 100
          Height = 25
          Caption = '运行分析'
          TabOrder = 0
          OnClick = btnRunAnalysisClick
        end
        
        object btnGenerateReport: TBitBtn
          Left = 130
          Top = 13
          Width = 100
          Height = 25
          Caption = '基准测试'
          TabOrder = 1
          OnClick = btnGenerateReportClick
        end
      end
      
      object memoAnalysisResult: TMemo
        Left = 0
        Top = 50
        Width = 892
        Height = 477
        Align = alClient
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Courier New'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 1
      end
    end
    
    object tsOptimization: TTabSheet
      Caption = '系统优化'
      ImageIndex = 2
      
      object pnlOptimizationTop: TPanel
        Left = 0
        Top = 0
        Width = 892
        Height = 50
        Align = alTop
        BevelInner = bvRaised
        BevelOuter = bvLowered
        TabOrder = 0
        
        object btnRunCleanup: TBitBtn
          Left = 16
          Top = 13
          Width = 100
          Height = 25
          Caption = '系统清理'
          TabOrder = 0
          OnClick = btnRunCleanupClick
        end
        
        object btnOptimizeMemory: TBitBtn
          Left = 130
          Top = 13
          Width = 100
          Height = 25
          Caption = '内存优化'
          TabOrder = 1
          OnClick = btnOptimizeMemoryClick
        end
        
        object btnFlushDNS: TBitBtn
          Left = 244
          Top = 13
          Width = 100
          Height = 25
          Caption = 'DNS清理'
          TabOrder = 2
          OnClick = btnFlushDNSClick
        end
      end
      
      object memoOptimizationResult: TMemo
        Left = 0
        Top = 50
        Width = 892
        Height = 477
        Align = alClient
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Courier New'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 1
      end
    end
  end
  
  object pnlBottom: TPanel
    Left = 0
    Top = 555
    Width = 900
    Height = 45
    Align = alBottom
    BevelInner = bvRaised
    BevelOuter = bvLowered
    TabOrder = 1
    
    object lblStatus: TLabel
      Left = 16
      Top = 16
      Width = 120
      Height = 13
      Caption = '就绪 - 点击开始监控'
    end
    
    object btnStart: TBitBtn
      Left = 700
      Top = 10
      Width = 75
      Height = 25
      Caption = '开始监控'
      TabOrder = 0
      OnClick = btnStartClick
    end
    
    object btnStop: TBitBtn
      Left = 785
      Top = 10
      Width = 75
      Height = 25
      Caption = '停止监控'
      Enabled = False
      TabOrder = 1
      OnClick = btnStopClick
    end
  end
  
  object Timer1: TTimer
    Enabled = False
    Interval = 2000
    OnTimer = Timer1Timer
    Left = 100
    Top = 100
  end
end