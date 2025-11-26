object frmSyncSettingsFull: TfrmSyncSettingsFull
  Left = 0
  Top = 0
  Caption = '同步盘设置'
  ClientHeight = 600
  ClientWidth = 1000
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  OnClose = FormClose
  TextHeight = 13
  object pnlMain: TPanel
    Left = 0
    Top = 0
    Width = 1000
    Height = 600
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object pnlHeader: TPanel
      Left = 0
      Top = 0
      Width = 1000
      Height = 60
      Align = alTop
      BevelOuter = bvNone
      Color = clWindow
      TabOrder = 0
      object lblTitle: TLabel
        Left = 16
        Top = 12
        Width = 120
        Height = 21
        Caption = '同步盘设置'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblDescription: TLabel
        Left = 16
        Top = 37
        Width = 300
        Height = 13
        Caption = '管理文件同步任务，支持手动和实时同步模式'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGrayText
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
    end
    object pnlToolbar: TPanel
      Left = 0
      Top = 60
      Width = 1000
      Height = 40
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 1
      object btnNew: TBitBtn
        Left = 16
        Top = 8
        Width = 75
        Height = 25
        Caption = '新建'
        TabOrder = 0
        OnClick = btnNewClick
      end
      object btnEdit: TBitBtn
        Left = 97
        Top = 8
        Width = 75
        Height = 25
        Caption = '编辑'
        TabOrder = 1
        OnClick = btnEditClick
      end
      object btnDelete: TBitBtn
        Left = 178
        Top = 8
        Width = 75
        Height = 25
        Caption = '删除'
        TabOrder = 2
        OnClick = btnDeleteClick
      end
      object btnToggleEnable: TBitBtn
        Left = 259
        Top = 8
        Width = 75
        Height = 25
        Caption = '启用/禁用'
        TabOrder = 3
        OnClick = btnToggleEnableClick
      end
      object btnSyncNow: TBitBtn
        Left = 340
        Top = 8
        Width = 75
        Height = 25
        Caption = '立即同步'
        TabOrder = 4
        OnClick = btnSyncNowClick
      end
      object btnHistory: TBitBtn
        Left = 421
        Top = 8
        Width = 75
        Height = 25
        Caption = '历史记录'
        TabOrder = 5
        OnClick = btnHistoryClick
      end
      object btnPresets: TBitBtn
        Left = 502
        Top = 8
        Width = 75
        Height = 25
        Caption = '预设模板'
        TabOrder = 6
        OnClick = btnPresetsClick
      end
      object btnClose: TBitBtn
        Left = 909
        Top = 8
        Width = 75
        Height = 25
        Caption = '关闭'
        TabOrder = 7
        OnClick = btnCloseClick
      end
    end
    object pnlFilter: TPanel
      Left = 0
      Top = 100
      Width = 1000
      Height = 35
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 2
      object lblFilter: TLabel
        Left = 16
        Top = 10
        Width = 52
        Height = 13
        Caption = '任务筛选'
      end
      object cbFilter: TComboBox
        Left = 74
        Top = 7
        Width = 100
        Height = 21
        Style = csDropDownList
        TabOrder = 0
        OnChange = cbFilterChange
      end
      object chkShowEnabled: TCheckBox
        Left = 190
        Top = 9
        Width = 60
        Height = 17
        Caption = '已启用'
        Checked = True
        State = cbChecked
        TabOrder = 1
        OnClick = chkShowEnabledClick
      end
      object chkShowDisabled: TCheckBox
        Left = 256
        Top = 9
        Width = 60
        Height = 17
        Caption = '已禁用'
        Checked = True
        State = cbChecked
        TabOrder = 2
        OnClick = chkShowDisabledClick
      end
    end
    object pnlTasks: TPanel
      Left = 0
      Top = 135
      Width = 1000
      Height = 400
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 3
      object lvTasks: TListView
        Left = 0
        Top = 0
        Width = 650
        Height = 400
        Align = alLeft
        Columns = <>
        PopupMenu = pmTasks
        TabOrder = 0
        ViewStyle = vsReport
        OnSelectItem = lvTasksSelectItem
        OnDblClick = lvTasksDblClick
        OnKeyDown = lvTasksKeyDown
        OnCustomDrawItem = lvTasksCustomDrawItem
      end
      object Splitter1: TSplitter
        Left = 650
        Top = 0
        Width = 5
        Height = 400
        Align = alLeft
        ExplicitLeft = 640
      end
      object pnlDetails: TPanel
        Left = 655
        Top = 0
        Width = 345
        Height = 400
        Align = alClient
        BevelOuter = bvLowered
        TabOrder = 1
        object lblDetails: TLabel
          Left = 8
          Top = 8
          Width = 65
          Height = 13
          Caption = '任务详细信息'
        end
        object memoDetails: TMemo
          Left = 8
          Top = 24
          Width = 329
          Height = 368
          Align = alCustom
          Anchors = [akLeft, akTop, akRight, akBottom]
          ReadOnly = True
          ScrollBars = ssVertical
          TabOrder = 0
        end
      end
    end
    object pnlStatus: TPanel
      Left = 0
      Top = 535
      Width = 1000
      Height = 65
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 4
      object lblStatus: TLabel
        Left = 16
        Top = 8
        Width = 31
        Height = 13
        Caption = '就绪'
      end
      object ProgressBar1: TProgressBar
        Left = 16
        Top = 27
        Width = 968
        Height = 16
        Align = alCustom
        Anchors = [akLeft, akTop, akRight]
        TabOrder = 0
        Visible = False
      end
    end
  end
  object pmTasks: TPopupMenu
    Left = 840
    Top = 200
    object miNew: TMenuItem
      Caption = '新建任务'
      OnClick = miNewClick
    end
    object miEdit: TMenuItem
      Caption = '编辑任务'
      OnClick = miEditClick
    end
    object miDelete: TMenuItem
      Caption = '删除任务'
      OnClick = miDeleteClick
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object miToggleEnable: TMenuItem
      Caption = '启用/禁用'
      OnClick = miToggleEnableClick
    end
    object miSyncNow: TMenuItem
      Caption = '立即同步'
      OnClick = miSyncNowClick
    end
    object N2: TMenuItem
      Caption = '-'
    end
    object miViewHistory: TMenuItem
      Caption = '查看历史'
      OnClick = miViewHistoryClick
    end
    object N3: TMenuItem
      Caption = '-'
    end
    object miCopyPath: TMenuItem
      Caption = '复制路径'
      OnClick = miCopyPathClick
    end
    object miOpenSource: TMenuItem
      Caption = '打开源目录'
      OnClick = miOpenSourceClick
    end
    object miOpenTarget: TMenuItem
      Caption = '打开目标目录'
      OnClick = miOpenTargetClick
    end
  end
end
