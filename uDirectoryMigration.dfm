object frmDirectoryMigration: TfrmDirectoryMigration
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = '智能目录迁移 - C盘空间释放专家'
  ClientHeight = 600
  ClientWidth = 800
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object pnlMain: TPanel
    Left = 0
    Top = 0
    Width = 800
    Height = 600
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object pnlTop: TPanel
      Left = 0
      Top = 0
      Width = 800
      Height = 80
      Align = alTop
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 0
      object lblTitle: TLabel
        Left = 24
        Top = 16
        Width = 280
        Height = 19
        Caption = '🎯 智能目录迁移 - 永久解决C盘空间问题'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblSubtitle: TLabel
        Left = 24
        Top = 45
        Width = 300
        Height = 13
        Caption = '智能识别可迁移目录，安全迁移到D盘，系统自动重定向，一劳永逸'
      end
    end
    object pnlCenter: TPanel
      Left = 0
      Top = 80
      Width = 800
      Height = 460
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 1
      object gbMigrationItems: TGroupBox
        Left = 24
        Top = 16
        Width = 400
        Height = 320
        Caption = '可迁移目录列表'
        TabOrder = 0
        object clbMigrationItems: TCheckListBox
          Left = 16
          Top = 24
          Width = 368
          Height = 280
          ItemHeight = 13
          TabOrder = 0
          OnClick = clbMigrationItemsClick
          OnClickCheck = clbMigrationItemsClickCheck
        end
      end
      object pnlItemDetails: TPanel
        Left = 440
        Top = 16
        Width = 336
        Height = 320
        BevelOuter = bvLowered
        TabOrder = 1
        object lblItemName: TLabel
          Left = 16
          Top = 16
          Width = 304
          Height = 16
          Caption = '选择左侧项目查看详情'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Tahoma'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblItemPath: TLabel
          Left = 16
          Top = 40
          Width = 304
          Height = 13
          Caption = '路径信息'
          WordWrap = True
        end
        object lblItemSize: TLabel
          Left = 16
          Top = 64
          Width = 304
          Height = 13
          Caption = '大小信息'
        end
        object lblItemRisk: TLabel
          Left = 16
          Top = 88
          Width = 304
          Height = 13
          Caption = '风险等级'
        end
        object memoItemDesc: TMemo
          Left = 16
          Top = 112
          Width = 304
          Height = 192
          ReadOnly = True
          ScrollBars = ssVertical
          TabOrder = 0
        end
      end
      object pnlSummary: TPanel
        Left = 24
        Top = 352
        Width = 752
        Height = 80
        BevelOuter = bvLowered
        TabOrder = 2
        object lblTotalItems: TLabel
          Left = 16
          Top = 16
          Width = 120
          Height = 13
          Caption = '选中项目：0 个'
        end
        object lblTotalSize: TLabel
          Left = 200
          Top = 16
          Width = 120
          Height = 13
          Caption = '预计释放：0 B'
        end
        object lblEstimatedTime: TLabel
          Left = 400
          Top = 16
          Width = 120
          Height = 13
          Caption = '预计用时：0 分钟'
        end
      end
      object pnlProgress: TPanel
        Left = 24
        Top = 352
        Width = 752
        Height = 80
        BevelOuter = bvLowered
        TabOrder = 3
        Visible = False
        object lblProgress: TLabel
          Left = 16
          Top = 16
          Width = 720
          Height = 13
          Caption = '正在处理...'
        end
        object ProgressBar: TProgressBar
          Left = 16
          Top = 40
          Width = 720
          Height = 25
          TabOrder = 0
        end
      end
    end
    object pnlBottom: TPanel
      Left = 0
      Top = 540
      Width = 800
      Height = 60
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 2
      object btnScan: TButton
        Left = 440
        Top = 16
        Width = 100
        Height = 32
        Caption = '🔍 重新扫描'
        TabOrder = 0
        OnClick = btnScanClick
      end
      object btnMigrate: TButton
        Left = 560
        Top = 16
        Width = 120
        Height = 32
        Caption = '🚀 开始迁移'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 1
        OnClick = btnMigrateClick
      end
      object btnCancel: TButton
        Left = 700
        Top = 16
        Width = 75
        Height = 32
        Caption = '取消'
        TabOrder = 2
        OnClick = btnCancelClick
      end
    end
  end
  object ImageList: TImageList
    Left = 720
    Top = 48
  end
end
