object frmLoggerSettings: TfrmLoggerSettings
  Left = 0
  Top = 0
  Caption = '日志设置'
  ClientHeight = 600
  ClientWidth = 500
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object pnlMain: TPanel
    Left = 0
    Top = 0
    Width = 500
    Height = 600
    Align = alClient
    BevelOuter = bvNone
    BorderWidth = 8
    TabOrder = 0
    object pnlTop: TPanel
      Left = 8
      Top = 8
      Width = 484
      Height = 60
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 0
      object lblTitle: TLabel
        Left = 0
        Top = 0
        Width = 80
        Height = 19
        Caption = '日志设置'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblSubtitle: TLabel
        Left = 0
        Top = 30
        Width = 200
        Height = 13
        Caption = '配置日志记录选项和输出目标'
      end
    end
    object pnlSettings: TPanel
      Left = 8
      Top = 68
      Width = 484
      Height = 480
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 1
      object pgcSettings: TPageControl
        Left = 0
        Top = 0
        Width = 484
        Height = 480
        ActivePage = tsGeneral
        Align = alClient
        TabOrder = 0
        object tsGeneral: TTabSheet
          Caption = '常规设置'
          object grpLogOutput: TGroupBox
            Left = 8
            Top = 8
            Width = 460
            Height = 100
            Caption = '日志输出'
            TabOrder = 0
            object chkLogToFile: TCheckBox
              Left = 12
              Top = 20
              Width = 200
              Height = 17
              Caption = '输出到文件'
              TabOrder = 0
              OnClick = chkLogToFileClick
            end
            object chkLogToDebug: TCheckBox
              Left = 12
              Top = 45
              Width = 200
              Height = 17
              Caption = '输出到调试器'
              TabOrder = 1
            end
            object chkLogToConsole: TCheckBox
              Left = 12
              Top = 70
              Width = 200
              Height = 17
              Caption = '输出到控制台'
              TabOrder = 2
            end
          end
          object grpLogLevel: TGroupBox
            Left = 8
            Top = 115
            Width = 460
            Height = 120
            Caption = '日志级别'
            TabOrder = 1
            object rbDebug: TRadioButton
              Left = 12
              Top = 20
              Width = 80
              Height = 17
              Caption = 'Debug'
              TabOrder = 0
            end
            object rbInfo: TRadioButton
              Left = 12
              Top = 40
              Width = 80
              Height = 17
              Caption = 'Info'
              Checked = True
              TabOrder = 1
              TabStop = True
            end
            object rbWarning: TRadioButton
              Left = 12
              Top = 60
              Width = 80
              Height = 17
              Caption = 'Warning'
              TabOrder = 2
            end
            object rbError: TRadioButton
              Left = 12
              Top = 80
              Width = 80
              Height = 17
              Caption = 'Error'
              TabOrder = 3
            end
            object rbCritical: TRadioButton
              Left = 12
              Top = 100
              Width = 80
              Height = 17
              Caption = 'Critical'
              TabOrder = 4
            end
          end
          object grpLogFiles: TGroupBox
            Left = 8
            Top = 240
            Width = 460
            Height = 150
            Caption = '文件设置'
            TabOrder = 2
            object lblLogDirectory: TLabel
              Left = 12
              Top = 20
              Width = 60
              Height = 13
              Caption = '日志目录:'
            end
            object edtLogDirectory: TEdit
              Left = 80
              Top = 17
              Width = 300
              Height = 21
              TabOrder = 0
            end
            object btnBrowseDirectory: TButton
              Left = 386
              Top = 16
              Width = 60
              Height = 23
              Caption = '浏览...'
              TabOrder = 1
              OnClick = btnBrowseDirectoryClick
            end
            object lblLogFileName: TLabel
              Left = 12
              Top = 50
              Width = 60
              Height = 13
              Caption = '文件名:'
            end
            object edtLogFileName: TEdit
              Left = 80
              Top = 47
              Width = 150
              Height = 21
              TabOrder = 2
            end
            object lblMaxFileSize: TLabel
              Left = 12
              Top = 80
              Width = 60
              Height = 13
              Caption = '最大大小:'
            end
            object edtMaxFileSize: TEdit
              Left = 80
              Top = 77
              Width = 80
              Height = 21
              TabOrder = 3
            end
            object lblMaxFileSizeUnit: TLabel
              Left = 166
              Top = 80
              Width = 15
              Height = 13
              Caption = 'MB'
            end
            object lblMaxFiles: TLabel
              Left = 12
              Top = 110
              Width = 60
              Height = 13
              Caption = '最大文件:'
            end
            object sedMaxFiles: TSpinEdit
              Left = 80
              Top = 107
              Width = 80
              Height = 22
              MaxValue = 100
              MinValue = 1
              TabOrder = 4
              Value = 5
            end
          end
        end
        object tsAdvanced: TTabSheet
          Caption = '高级设置'
          object grpPerformance: TGroupBox
            Left = 8
            Top = 8
            Width = 460
            Height = 120
            Caption = '性能设置'
            TabOrder = 0
            object chkEnableCache: TCheckBox
              Left = 12
              Top = 20
              Width = 200
              Height = 17
              Caption = '启用日志缓存'
              TabOrder = 0
              OnClick = chkEnableCacheClick
            end
            object lblCacheSize: TLabel
              Left = 12
              Top = 50
              Width = 60
              Height = 13
              Caption = '缓存大小:'
            end
            object sedCacheSize: TSpinEdit
              Left = 80
              Top = 47
              Width = 80
              Height = 22
              MaxValue = 10000
              MinValue = 10
              TabOrder = 1
              Value = 1000
            end
            object lblAutoFlushInterval: TLabel
              Left = 12
              Top = 80
              Width = 60
              Height = 13
              Caption = '自动刷新:'
            end
            object sedAutoFlushInterval: TSpinEdit
              Left = 80
              Top = 77
              Width = 80
              Height = 22
              MaxValue = 300
              MinValue = 0
              TabOrder = 2
              Value = 30
            end
            object lblAutoFlushUnit: TLabel
              Left = 166
              Top = 80
              Width = 15
              Height = 13
              Caption = '秒'
            end
          end
          object grpStatistics: TGroupBox
            Left = 8
            Top = 135
            Width = 460
            Height = 120
            Caption = '统计信息'
            TabOrder = 1
            object lblCurrentLogCount: TLabel
              Left = 12
              Top = 20
              Width = 100
              Height = 13
              Caption = '当前缓存日志: 0 条'
            end
            object lblLogFilesCount: TLabel
              Left = 12
              Top = 45
              Width = 100
              Height = 13
              Caption = '日志文件数量: 0 个'
            end
            object btnClearLogs: TButton
              Left = 12
              Top = 75
              Width = 75
              Height = 25
              Caption = '清空日志'
              TabOrder = 0
              OnClick = btnClearLogsClick
            end
            object btnViewLogs: TButton
              Left = 93
              Top = 75
              Width = 75
              Height = 25
              Caption = '查看日志'
              TabOrder = 1
              OnClick = btnViewLogsClick
            end
            object btnExportLogs: TButton
              Left = 174
              Top = 75
              Width = 75
              Height = 25
              Caption = '导出日志'
              TabOrder = 2
              OnClick = btnExportLogsClick
            end
          end
        end
      end
    end
    object pnlButtons: TPanel
      Left = 8
      Top = 548
      Width = 484
      Height = 44
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 2
      object btnOK: TButton
        Left = 220
        Top = 8
        Width = 75
        Height = 25
        Caption = '确定'
        Default = True
        ModalResult = 1
        TabOrder = 0
        OnClick = btnOKClick
      end
      object btnCancel: TButton
        Left = 301
        Top = 8
        Width = 75
        Height = 25
        Caption = '取消'
        ModalResult = 2
        TabOrder = 1
        OnClick = btnCancelClick
      end
      object btnApply: TButton
        Left = 382
        Top = 8
        Width = 75
        Height = 25
        Caption = '应用'
        TabOrder = 2
        OnClick = btnApplyClick
      end
      object btnReset: TButton
        Left = 139
        Top = 8
        Width = 75
        Height = 25
        Caption = '重置'
        TabOrder = 3
        OnClick = btnResetClick
      end
      object btnTest: TButton
        Left = 58
        Top = 8
        Width = 75
        Height = 25
        Caption = '测试'
        TabOrder = 4
        OnClick = btnTestClick
      end
    end
  end
end
