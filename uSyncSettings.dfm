object frmSyncSettings: TfrmSyncSettings
  Left = 0
  Top = 0
  Caption = '同步盘设置'
  ClientHeight = 480
  ClientWidth = 760
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  TextHeight = 15
  object lblFilter: TLabel
    Left = 16
    Top = 16
    Width = 52
    Height = 15
    Caption = '任务筛选'
  end
  object lblHint: TLabel
    Left = 256
    Top = 16
    Width = 300
    Height = 15
    Caption = '双击任务可编辑，右键可查看更多选项。实时监控需要管理员权限。'
  end
  object cbFilter: TComboBox
    Left = 80
    Top = 12
    Width = 160
    Height = 24
    Style = csDropDownList
    TabOrder = 0
    OnChange = cbFilterChange
  end
  object lvTasks: TListView
    Left = 16
    Top = 48
    Width = 728
    Height = 360
    Columns = <>
    GridLines = True
    HideSelection = False
    ReadOnly = True
    RowSelect = True
    TabOrder = 1
    ViewStyle = vsReport
    OnDblClick = lvTasksDblClick
    OnKeyDown = lvTasksKeyDown
  end
  object btnNew: TButton
    Left = 16
    Top = 420
    Width = 80
    Height = 28
    Caption = '新建'
    TabOrder = 2
    OnClick = btnNewClick
  end
  object btnEdit: TButton
    Left = 104
    Top = 420
    Width = 80
    Height = 28
    Caption = '编辑'
    TabOrder = 3
    OnClick = btnEditClick
  end
  object btnDelete: TButton
    Left = 192
    Top = 420
    Width = 80
    Height = 28
    Caption = '删除'
    TabOrder = 4
    OnClick = btnDeleteClick
  end
  object btnToggleEnable: TButton
    Left = 280
    Top = 420
    Width = 96
    Height = 28
    Caption = '启用/禁用'
    TabOrder = 5
    OnClick = btnToggleEnableClick
  end
  object btnHistory: TButton
    Left = 384
    Top = 420
    Width = 96
    Height = 28
    Caption = '同步历史'
    TabOrder = 6
    OnClick = btnHistoryClick
  end
  object btnSyncNow: TButton
    Left = 504
    Top = 420
    Width = 112
    Height = 28
    Caption = '立即同步'
    TabOrder = 7
    OnClick = btnSyncNowClick
  end
  object btnClose: TButton
    Left = 624
    Top = 420
    Width = 120
    Height = 28
    Caption = '关闭'
    ModalResult = 1
    TabOrder = 8
  end
end
