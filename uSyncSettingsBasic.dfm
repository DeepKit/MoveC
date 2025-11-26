object frmSyncSettingsBasic: TfrmSyncSettingsBasic
  Left = 0
  Top = 0
  Caption = '同步盘设置'
  ClientHeight = 600
  ClientWidth = 900
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 13
  object pnlMain: TPanel
    Left = 0
    Top = 0
    Width = 900
    Height = 600
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object pnlHeader: TPanel
      Left = 0
      Top = 0
      Width = 900
      Height = 70
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
      Top = 70
      Width = 900
      Height = 50
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 1
      object btnNew: TBitBtn
        Left = 16
        Top = 12
        Width = 75
        Height = 25
        Caption = '新建'
        TabOrder = 0
        OnClick = btnNewClick
      end
      object btnEdit: TBitBtn
        Left = 97
        Top = 12
        Width = 75
        Height = 25
        Caption = '编辑'
        TabOrder = 1
        OnClick = btnEditClick
      end
      object btnDelete: TBitBtn
        Left = 178
        Top = 12
        Width = 75
        Height = 25
        Caption = '删除'
        TabOrder = 2
        OnClick = btnDeleteClick
      end
      object btnToggleEnable: TBitBtn
        Left = 259
        Top = 12
        Width = 85
        Height = 25
        Caption = '启用/禁用'
        TabOrder = 3
        OnClick = btnToggleEnableClick
      end
      object btnSyncNow: TBitBtn
        Left = 350
        Top = 12
        Width = 75
        Height = 25
        Caption = '立即同步'
        TabOrder = 4
        OnClick = btnSyncNowClick
      end
      object btnClose: TBitBtn
        Left = 809
        Top = 12
        Width = 75
        Height = 25
        Caption = '关闭'
        TabOrder = 5
        OnClick = btnCloseClick
      end
    end
    object lvTasks: TListView
      Left = 0
      Top = 120
      Width = 900
      Height = 300
      Align = alClient
      Columns = <
        item
          Caption = '任务名称'
          Width = 200
        end
        item
          Caption = '源路径'
          Width = 250
        end
        item
          Caption = '目标路径'
          Width = 250
        end
        item
          Caption = '状态'
          Width = 80
        end>
      ReadOnly = True
      RowSelect = True
      TabOrder = 2
      ViewStyle = vsReport
      OnSelectItem = lvTasksSelectItem
    end
    object pnlEdit: TPanel
      Left = 0
      Top = 420
      Width = 900
      Height = 150
      Align = alBottom
      BevelOuter = bvLowered
      Color = clWindow
      TabOrder = 3
      object lblEditTitle: TLabel
        Left = 16
        Top = 8
        Width = 84
        Height = 13
        Caption = '任务编辑区域'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblTaskName: TLabel
        Left = 16
        Top = 35
        Width = 52
        Height = 13
        Caption = '任务名称'
      end
      object lblSourcePath: TLabel
        Left = 16
        Top = 62
        Width = 52
        Height = 13
        Caption = '源路径'
      end
      object lblTargetPath: TLabel
        Left = 16
        Top = 89
        Width = 52
        Height = 13
        Caption = '目标路径'
      end
      object edtTaskName: TEdit
        Left = 80
        Top = 32
        Width = 300
        Height = 21
        TabOrder = 0
        TextHint = '请输入任务名称'
      end
      object edtSourcePath: TEdit
        Left = 80
        Top = 59
        Width = 500
        Height = 21
        TabOrder = 1
        TextHint = '请选择源目录'
      end
      object edtTargetPath: TEdit
        Left = 80
        Top = 86
        Width = 500
        Height = 21
        TabOrder = 2
        TextHint = '请选择目标目录'
      end
      object btnBrowseSource: TButton
        Left = 586
        Top = 57
        Width = 75
        Height = 25
        Caption = '浏览...'
        TabOrder = 3
        OnClick = btnBrowseSourceClick
      end
      object btnBrowseTarget: TButton
        Left = 586
        Top = 84
        Width = 75
        Height = 25
        Caption = '浏览...'
        TabOrder = 4
        OnClick = btnBrowseTargetClick
      end
      object btnSaveTask: TButton
        Left = 700
        Top = 57
        Width = 75
        Height = 25
        Caption = '保存任务'
        TabOrder = 5
        OnClick = btnSaveTaskClick
      end
      object btnCancelEdit: TButton
        Left = 700
        Top = 84
        Width = 75
        Height = 25
        Caption = '取消'
        TabOrder = 6
        OnClick = btnCancelEditClick
      end
      object chkEnabled: TCheckBox
        Left = 80
        Top = 115
        Width = 97
        Height = 17
        Caption = '启用任务'
        TabOrder = 7
      end
    end
    object pnlStatus: TPanel
      Left = 0
      Top = 570
      Width = 900
      Height = 30
      Align = alBottom
      BevelOuter = bvLowered
      TabOrder = 4
      object lblStatus: TLabel
        Left = 16
        Top = 8
        Width = 28
        Height = 13
        Caption = '就绪'
      end
    end
  end
end
