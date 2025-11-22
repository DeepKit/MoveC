object frmSyncHistory: TfrmSyncHistory
  Caption = '同步历史记录'
  ClientHeight = 460
  ClientWidth = 720
  Position = poScreenCenter
  OnShow = FormShow
  OnDestroy = FormDestroy
  object lblTask: TLabel
    Left = 16
    Top = 16
    Width = 48
    Height = 16
    Caption = '任务筛选'
  end
  object cbTasks: TComboBox
    Left = 80
    Top = 12
    Width = 280
    Height = 24
    Style = csDropDownList
    TabOrder = 0
    OnChange = cbTasksChange
  end
  object lvHistory: TListView
    Left = 16
    Top = 48
    Width = 688
    Height = 360
    ViewStyle = vsReport
    ReadOnly = True
    RowSelect = True
    HideSelection = False
    GridLines = True
    TabOrder = 1
  end
  object btnRefresh: TButton
    Left = 488
    Top = 416
    Width = 96
    Height = 28
    Caption = '刷新'
    TabOrder = 2
    OnClick = btnRefreshClick
  end
  object btnClose: TButton
    Left = 608
    Top = 416
    Width = 96
    Height = 28
    Caption = '关闭'
    ModalResult = 1
    TabOrder = 3
  end
end
