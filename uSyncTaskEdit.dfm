object frmSyncTaskEdit: TfrmSyncTaskEdit
  Caption = '编辑同步任务'
  ClientHeight = 400
  ClientWidth = 560
  Position = poScreenCenter
  object lblName: TLabel
    Left = 16
    Top = 16
    Width = 48
    Height = 16
    Caption = '任务名称'
  end
  object edtName: TEdit
    Left = 88
    Top = 12
    Width = 448
    Height = 24
    TabOrder = 0
  end
  object lblSource: TLabel
    Left = 16
    Top = 52
    Width = 48
    Height = 16
    Caption = '源路径'
  end
  object edtSource: TEdit
    Left = 88
    Top = 48
    Width = 368
    Height = 24
    TabOrder = 1
  end
  object btnBrowseSrc: TButton
    Left = 464
    Top = 48
    Width = 72
    Height = 24
    Caption = '浏览...'
    TabOrder = 2
    OnClick = btnBrowseSrcClick
  end
  object lblTarget: TLabel
    Left = 16
    Top = 84
    Width = 48
    Height = 16
    Caption = '目标路径'
  end
  object edtTarget: TEdit
    Left = 88
    Top = 80
    Width = 368
    Height = 24
    TabOrder = 3
  end
  object btnBrowseDst: TButton
    Left = 464
    Top = 80
    Width = 72
    Height = 24
    Caption = '浏览...'
    TabOrder = 4
    OnClick = btnBrowseDstClick
  end
  object lblCategory: TLabel
    Left = 16
    Top = 116
    Width = 32
    Height = 16
    Caption = '分类'
  end
  object cbCategory: TComboBox
    Left = 88
    Top = 112
    Width = 160
    Height = 24
    Style = csDropDownList
    TabOrder = 5
  end
  object rgMode: TRadioGroup
    Left = 264
    Top = 112
    Width = 200
    Height = 48
    Caption = '模式'
    TabOrder = 6
  end
  object chkEnabled: TCheckBox
    Left = 480
    Top = 120
    Width = 56
    Height = 17
    Caption = '启用'
    TabOrder = 7
  end
  object lblRealtime: TLabel
    Left = 16
    Top = 168
    Width = 64
    Height = 16
    Caption = '实时参数'
  end
  object lblInterval: TLabel
    Left = 88
    Top = 192
    Width = 120
    Height = 16
    Caption = '轮询间隔(毫秒)'
  end
  object edtInterval: TEdit
    Left = 216
    Top = 188
    Width = 80
    Height = 24
    TabOrder = 8
    Text = '300'
  end
  object chkRecursive: TCheckBox
    Left = 320
    Top = 192
    Width = 88
    Height = 17
    Caption = '递归监控'
    TabOrder = 9
    Checked = True
    State = cbChecked
  end
  object rgWatchMode: TRadioGroup
    Left = 88
    Top = 220
    Width = 344
    Height = 48
    Caption = '监控方式'
    TabOrder = 10
  end
  object lblIgnore: TLabel
    Left = 16
    Top = 276
    Width = 64
    Height = 16
    Caption = '忽略规则'
  end
  object edtIgnoreRules: TEdit
    Left = 88
    Top = 272
    Width = 448
    Height = 24
    TabOrder = 11
    Text = ''
  end
  object btnOK: TButton
    Left = 360
    Top = 352
    Width = 88
    Height = 28
    Caption = '确定'
    ModalResult = 1
    TabOrder = 12
    OnClick = btnOKClick
  end
  object btnCancel: TButton
    Left = 448
    Top = 352
    Width = 88
    Height = 28
    Caption = '取消'
    ModalResult = 2
    TabOrder = 13
    OnClick = btnCancelClick
  end
end
