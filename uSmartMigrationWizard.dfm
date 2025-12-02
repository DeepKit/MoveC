object frmSmartMigrationWizard: TfrmSmartMigrationWizard
  Left = 0
  Top = 0
Caption = 'Smart Migration Wizard'
  ClientHeight = 720
  ClientWidth = 1000
  Color = clBtnFace
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 1000
    Height = 80
    Align = alTop
    Caption = ''
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 200
      Height = 24
      Caption = #27426#36814#20351#29992#26234#33021#36716#31227#21521#23548
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblSubtitle: TLabel
      Left = 16
      Top = 40
      Width = 320
      Height = 16
      Caption = #23433#20840#12289#26234#33021#12289#19968#38190#23436#25104#30446#24405#36716#31227
    end
  end
  object pnlButtons: TPanel
    Left = 0
    Top = 664
    Width = 1000
    Height = 56
    Align = alBottom
    TabOrder = 1
    object btnBack: TBitBtn
      Left = 600
      Top = 12
      Width = 90
      Height = 32
      Caption = #36820#22238
      OnClick = btnBackClick
      TabOrder = 0
    end
    object btnNext: TBitBtn
      Left = 700
      Top = 12
      Width = 110
      Height = 32
      Caption = #19979#19968#27493' >'
      OnClick = btnNextClick
      TabOrder = 1
    end
    object btnFinish: TBitBtn
      Left = 820
      Top = 12
      Width = 80
      Height = 32
      Caption = #23436#25104
      OnClick = btnFinishClick
      TabOrder = 2
      Visible = False
    end
    object btnCancel: TBitBtn
      Left = 910
      Top = 12
      Width = 80
      Height = 32
      Caption = #21462#28040
      OnClick = btnCancelClick
      TabOrder = 3
    end
  end
  object pnlContent: TPanel
    Left = 0
    Top = 80
    Width = 1000
    Height = 584
    Align = alClient
    TabOrder = 2
  end
  object pnlWelcome: TPanel
    Left = 0
    Top = 80
    Width = 1000
    Height = 584
    Align = alClient
    Caption = ''
    TabOrder = 3
    Visible = False
    object lblWelcome: TLabel
      Left = 16
      Top = 16
      Width = 200
      Height = 16
      Caption = #27426#36814#20351#29992#26234#33021#36716#31227#21521#23548'!'
    end
    object memoWelcomeText: TMemo
      Left = 16
      Top = 40
      Width = 960
      Height = 520
      Anchors = [akLeft, akTop, akRight, akBottom]
      TabOrder = 0
    end
  end
  object pnlSourceSelection: TPanel
    Left = 0
    Top = 80
    Width = 1000
    Height = 584
    Align = alClient
    TabOrder = 4
    Visible = False
    object lblSelectSource: TLabel
      Left = 16
      Top = 16
      Width = 280
      Height = 16
      Caption = #35831#36873#25321#35201#36716#31227#30340#30446#24405#65288#25903#25345#22810#36873#65289
    end
    object lblTemplates: TLabel
      Left = 16
      Top = 44
      Width = 80
      Height = 16
      Caption = #24555#36895#36873#25321#65306
    end
    object cboTemplates: TComboBox
      Left = 100
      Top = 40
      Width = 280
      Height = 24
      Style = csDropDownList
      TabOrder = 0
      OnChange = cboTemplatesChange
    end
    object btnSelectAll: TBitBtn
      Left = 400
      Top = 40
      Width = 80
      Height = 24
      Caption = #20840#36873
      TabOrder = 1
      OnClick = btnSelectAllClick
    end
    object btnSelectNone: TBitBtn
      Left = 488
      Top = 40
      Width = 80
      Height = 24
      Caption = #21462#28040#20840#36873
      TabOrder = 2
      OnClick = btnSelectNoneClick
    end
    object btnAddCustomPath: TBitBtn
      Left = 576
      Top = 40
      Width = 120
      Height = 24
      Caption = #28155#21152#33258#23450#20041#30446#24405'...'
      TabOrder = 3
      OnClick = btnAddCustomPathClick
    end
    object clbSourcePaths: TCheckListBox
      Left = 16
      Top = 72
      Width = 960
      Height = 460
      Anchors = [akLeft, akTop, akRight, akBottom]
      ItemHeight = 20
      TabOrder = 4
      OnClickCheck = clbSourcePathsClickCheck
    end
    object lblSelectedInfo: TLabel
      Left = 16
      Top = 540
      Width = 960
      Height = 16
      Anchors = [akLeft, akBottom]
      Caption = #24050#36873#25321' 0 '#20010#30446#24405#65292#20849#35745' 0 '#65292#25991#20214#25968#65306' 0'
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object pnlAnalysis: TPanel
    Left = 0
    Top = 80
    Width = 1000
    Height = 584
    Align = alClient
    TabOrder = 5
    Visible = False
    object lblAnalyzing: TLabel
      Left = 16
      Top = 16
      Width = 120
      Height = 16
      Caption = #27491#22312#20998#26512#30446#24405'...'
    end
    object lblAnalysisStatus: TLabel
      Left = 16
      Top = 40
      Width = 200
      Height = 16
      Caption = ''
    end
    object ProgressBarAnalysis: TProgressBar
      Left = 16
      Top = 64
      Width = 960
      Height = 20
      TabOrder = 0
    end
    object memoAnalysisResults: TMemo
      Left = 16
      Top = 96
      Width = 960
      Height = 456
      Anchors = [akLeft, akTop, akRight, akBottom]
      TabOrder = 1
    end
  end
  object pnlTargetSelection: TPanel
    Left = 0
    Top = 80
    Width = 1000
    Height = 584
    Align = alClient
    TabOrder = 6
    Visible = False
    object lblSelectTarget: TLabel
      Left = 16
      Top = 16
      Width = 120
      Height = 16
      Caption = #35831#36873#25321#30446#26631#20301#32622
    end
    object edtTargetPath: TEdit
      Left = 16
      Top = 40
      Width = 840
      Height = 24
      TabOrder = 0
    end
    object btnBrowseTarget: TBitBtn
      Left = 868
      Top = 40
      Width = 108
      Height = 24
      Caption = #27983#35272'...'
      OnClick = btnBrowseTargetClick
      TabOrder = 1
    end
    object lblAvailableDrives: TLabel
      Left = 16
      Top = 80
      Width = 120
      Height = 16
      Caption = #21487#29992#30828#30424#21644#24378#21046#24320#35270
    end
    object lvAvailableDrives: TListView
      Left = 16
      Top = 104
      Width = 960
      Height = 416
      Anchors = [akLeft, akTop, akRight, akBottom]
      ReadOnly = True
      RowSelect = True
      ViewStyle = vsReport
      TabOrder = 2
      OnDblClick = lvAvailableDrivesDblClick
    end
    object lblTargetInfo: TLabel
      Left = 16
      Top = 528
      Width = 960
      Height = 16
      Caption = ''
    end
  end
  object pnlSafetyCheck: TPanel
    Left = 0
    Top = 80
    Width = 1000
    Height = 584
    Align = alClient
    TabOrder = 7
    Visible = False
    object lblSafetyCheck: TLabel
      Left = 16
      Top = 16
      Width = 120
      Height = 16
      Caption = #23433#20840#26816#26597
    end
    object lvSafetyChecks: TListView
      Left = 16
      Top = 40
      Width = 960
      Height = 280
      Anchors = [akLeft, akTop, akRight]
      ReadOnly = True
      RowSelect = True
      ViewStyle = vsReport
      TabOrder = 0
    end
    object memoSafetyWarnings: TMemo
      Left = 16
      Top = 328
      Width = 960
      Height = 240
      Anchors = [akLeft, akTop, akRight, akBottom]
      TabOrder = 1
    end
  end
  object pnlConfirmation: TPanel
    Left = 0
    Top = 80
    Width = 1000
    Height = 584
    Align = alClient
    TabOrder = 8
    Visible = False
    object lblConfirmation: TLabel
      Left = 16
      Top = 16
      Width = 120
      Height = 16
      Caption = #30830#35748#36716#31227#35745#21010
    end
    object memoMigrationPlan: TMemo
      Left = 16
      Top = 40
      Width = 960
      Height = 440
      Anchors = [akLeft, akTop, akRight, akBottom]
      TabOrder = 0
    end
    object chkCreateBackup: TCheckBox
      Left = 16
      Top = 488
      Width = 200
      Height = 24
      Caption = #21019#24314#22791#20221
      TabOrder = 1
    end
    object chkVerifyFiles: TCheckBox
      Left = 200
      Top = 488
      Width = 200
      Height = 24
      Caption = #39564#35777#25991#20214#23436#25972#24615
      TabOrder = 2
    end
    object chkCreateJunction: TCheckBox
      Left = 420
      Top = 488
      Width = 200
      Height = 24
      Caption = #21019#24314#30446#24405#38142#25509
      TabOrder = 3
    end
  end
  object pnlExecution: TPanel
    Left = 0
    Top = 80
    Width = 1000
    Height = 584
    Align = alClient
    TabOrder = 9
    Visible = False
    object lblExecution: TLabel
      Left = 16
      Top = 16
      Width = 120
      Height = 16
      Caption = #25191#34892#36716#31227
    end
    object lblExecutionStatus: TLabel
      Left = 16
      Top = 40
      Width = 400
      Height = 16
      Caption = ''
    end
    object ProgressBarExecution: TProgressBar
      Left = 16
      Top = 64
      Width = 960
      Height = 20
      TabOrder = 0
    end
    object memoExecutionLog: TMemo
      Left = 16
      Top = 96
      Width = 960
      Height = 440
      Anchors = [akLeft, akTop, akRight, akBottom]
      TabOrder = 1
    end
    object btnCancelExecution: TBitBtn
      Left = 16
      Top = 544
      Width = 140
      Height = 28
      Caption = #21462#28040#36816#34892
      TabOrder = 2
      OnClick = btnCancelExecutionClick
    end
  end
  object pnlComplete: TPanel
    Left = 0
    Top = 80
    Width = 1000
    Height = 584
    Align = alClient
    TabOrder = 10
    Visible = False
    object lblComplete: TLabel
      Left = 16
      Top = 16
      Width = 120
      Height = 16
      Caption = #36716#31227#23436#25104
    end
    object memoCompleteSummary: TMemo
      Left = 16
      Top = 40
      Width = 960
      Height = 480
      Anchors = [akLeft, akTop, akRight, akBottom]
      TabOrder = 0
    end
    object chkDeleteBackup: TCheckBox
      Left = 16
      Top = 528
      Width = 200
      Height = 24
      Caption = #23436#25104#21518#21024#38500#22791#20221
      TabOrder = 1
    end
    object chkOpenTargetFolder: TCheckBox
      Left = 220
      Top = 528
      Width = 240
      Height = 24
      Caption = #23436#25104#21518#25171#24320#30446#26631#25991#20214#22841
      TabOrder = 2
    end
  end
end
