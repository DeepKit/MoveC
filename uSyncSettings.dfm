object frmSyncSettings: TfrmSyncSettings
  Left = 0
  Top = 0
  Caption = #37722#24225#24436#37722#23678#57630#29825#21095#30086
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
    Width = 76
    Height = 15
    Caption = #37714#21977#34987#32475#28066#8364'?'
  end
  object lblHint: TLabel
    Left = 256
    Top = 16
    Width = 457
    Height = 15
    Caption = #37819#24878#12378#38171#27692#24379#37713#35763#25442#37716#8243#24434#32514#26668#32235#38171#28066#8364#22795#23272#37722#24225#24434#37904#29808#22190#37413#28357#29659#37719#20914#24723#23005#12514#8364#28612#8364'?'
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
    Caption = #37826#26495#32531
    TabOrder = 2
    OnClick = btnNewClick
  end
  object btnEdit: TButton
    Left = 104
    Top = 420
    Width = 80
    Height = 28
    Caption = #32514#26668#32235
    TabOrder = 3
    OnClick = btnEditClick
  end
  object btnDelete: TButton
    Left = 192
    Top = 420
    Width = 80
    Height = 28
    Caption = #37714#29371#27342
    TabOrder = 4
    OnClick = btnDeleteClick
  end
  object btnToggleEnable: TButton
    Left = 280
    Top = 420
    Width = 96
    Height = 28
    Caption = #37722#57884#25956'/'#32450#20346#25956
    TabOrder = 5
    OnClick = btnToggleEnableClick
  end
  object btnHistory: TButton
    Left = 384
    Top = 420
    Width = 96
    Height = 28
    Caption = #37720#21975#24438#29825#26495#32141
    TabOrder = 6
    OnClick = btnHistoryClick
  end
  object btnSyncNow: TButton
    Left = 504
    Top = 420
    Width = 112
    Height = 28
    Caption = #32468#23338#23878#37722#23678#57630
    TabOrder = 7
    OnClick = btnSyncNowClick
  end
  object btnClose: TButton
    Left = 624
    Top = 420
    Width = 120
    Height = 28
    Caption = #37711#25277#26868
    ModalResult = 1
    TabOrder = 8
  end
end
