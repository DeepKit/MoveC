object frmCleanupPreview: TfrmCleanupPreview
  Left = 0
  Top = 0
  Caption = '清理预览'
  ClientHeight = 600
  ClientWidth = 800
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
      BorderWidth = 8
      TabOrder = 0
      object lblTitle: TLabel
        Left = 8
        Top = 8
        Width = 120
        Height = 19
        Caption = '智能清理预览'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblSubtitle: TLabel
        Left = 8
        Top = 35
        Width = 250
        Height = 13
        Caption = '预览将要清理的项目，选择安全级别并确认操作'
      end
      object pnlSafety: TPanel
        Left = 8
        Top = 54
        Width = 300
        Height = 26
        BevelOuter = bvNone
        TabOrder = 0
        object lblSafety: TLabel
          Left = 0
          Top = 4
          Width = 60
          Height = 13
          Caption = '安全级别:'
        end
        object cbSafetyLevel: TComboBox
          Left = 66
          Top = 0
          Width = 120
          Height = 21
          Style = csDropDownList
          TabOrder = 0
          OnChange = cbSafetyLevelChange
        end
        object btnPreview: TButton
          Left = 192
          Top = 0
          Width = 75
          Height = 23
          Caption = '刷新预览'
          TabOrder = 1
          OnClick = btnPreviewClick
        end
      end
    end
    object pnlProgress: TPanel
      Left = 0
      Top = 80
      Width = 800
      Height = 60
      Align = alTop
      BevelOuter = bvNone
      BorderWidth = 8
      TabOrder = 1
      Visible = False
      object ProgressBar: TProgressBar
        Left = 8
        Top = 8
        Width = 784
        Height = 16
        Align = alTop
        TabOrder = 0
      end
      object lblProgress: TLabel
        Left = 8
        Top = 32
        Width = 784
        Height = 13
        Align = alTop
        Caption = '正在预览...'
      end
    end
    object pnlResults: TPanel
      Left = 0
      Top = 140
      Width = 800
      Height = 460
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 2
      object pnlSummary: TPanel
        Left = 0
        Top = 0
        Width = 800
        Height = 80
        Align = alTop
        BevelOuter = bvLowered
        BorderWidth = 8
        TabOrder = 0
        object lblTotalItems: TLabel
          Left = 8
          Top = 8
          Width = 60
          Height = 13
          Caption = '清理项目: 0'
        end
        object lblTotalSize: TLabel
          Left = 8
          Top = 27
          Width = 60
          Height = 13
          Caption = '总大小: 0'
        end
        object lblSafeItems: TLabel
          Left = 200
          Top = 8
          Width = 60
          Height = 13
          Caption = '安全项目: 0'
        end
        object lblRiskyItems: TLabel
          Left = 200
          Top = 27
          Width = 60
          Height = 13
          Caption = '风险项目: 0'
        end
        object lblEstimatedTime: TLabel
          Left = 400
          Top = 8
          Width = 60
          Height = 13
          Caption = '预计时间: 0'
        end
        object chkShowRisky: TCheckBox
          Left = 400
          Top = 26
          Width = 120
          Height = 17
          Caption = '显示风险项目'
          TabOrder = 0
          OnClick = chkShowRiskyClick
        end
      end
      object pnlItems: TPanel
        Left = 0
        Top = 80
        Width = 800
        Height = 300
        Align = alClient
        BevelOuter = bvNone
        BorderWidth = 8
        TabOrder = 1
        object lvItems: TListView
          Left = 8
          Top = 8
          Width = 784
          Height = 284
          Align = alClient
          Checkboxes = True
          Columns = <
            item
              Caption = '项目名称'
              Width = 200
            end
            item
              Caption = '类型'
              Width = 100
            end
            item
              Alignment = taRightJustify
              Caption = '大小'
              Width = 120
            end
            item
              Alignment = taRightJustify
              Caption = '文件数量'
              Width = 80
            end
            item
              Caption = '风险等级'
              Width = 80
            end
            item
              Caption = '描述'
              Width = 200
            end>
          GridLines = True
          RowSelect = True
          TabOrder = 0
          ViewStyle = vsReport
          OnCustomDrawItem = lvItemsCustomDrawItem
          OnColumnClick = lvItemsColumnClick
        end
      end
      object pnlButtons: TPanel
        Left = 0
        Top = 380
        Width = 800
        Height = 80
        Align = alBottom
        BevelOuter = bvNone
        BorderWidth = 8
        TabOrder = 2
        object btnSelectAll: TButton
          Left = 8
          Top = 8
          Width = 75
          Height = 25
          Caption = '全选'
          TabOrder = 0
          OnClick = btnSelectAllClick
        end
        object btnSelectSafe: TButton
          Left = 89
          Top = 8
          Width = 75
          Height = 25
          Caption = '选择安全'
          TabOrder = 1
          OnClick = btnSelectSafeClick
        end
        object btnDeselectAll: TButton
          Left = 170
          Top = 8
          Width = 75
          Height = 25
          Caption = '全不选'
          TabOrder = 2
          OnClick = btnDeselectAllClick
        end
        object btnCleanSelected: TButton
          Left = 251
          Top = 8
          Width = 100
          Height = 25
          Caption = '清理选中'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Tahoma'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 3
          OnClick = btnCleanSelectedClick
        end
        object btnCancel: TButton
          Left = 640
          Top = 8
          Width = 75
          Height = 25
          Caption = '取消'
          TabOrder = 4
          OnClick = btnCancelClick
        end
        object btnClose: TButton
          Left = 721
          Top = 8
          Width = 75
          Height = 25
          Caption = '关闭'
          TabOrder = 5
          OnClick = btnCloseClick
        end
      end
    end
  end
end
