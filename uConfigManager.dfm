object frmConfigManager: TfrmConfigManager
  Left = 0
  Top = 0
  Caption = #37197#32622#31649#29702#22120
  ClientHeight = 500
  ClientWidth = 600
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
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object pnlMain: TPanel
    Left = 0
    Top = 0
    Width = 600
    Height = 500
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object pnlTop: TPanel
      Left = 0
      Top = 0
      Width = 600
      Height = 60
      Align = alTop
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 0
      object lblTitle: TLabel
        Left = 16
        Top = 12
        Width = 120
        Height = 16
        Caption = #9881#65039' '#31995#32479#37197#32622#31649#29702
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblSubtitle: TLabel
        Left = 16
        Top = 35
        Width = 192
        Height = 13
        Caption = #33258#23450#20041#24212#29992#31243#24207#34892#20026#21644#22806#35266#35774#32622
      end
    end
    object pnlBottom: TPanel
      Left = 0
      Top = 450
      Width = 600
      Height = 50
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 1
      object btnOK: TButton
        Left = 350
        Top = 12
        Width = 75
        Height = 25
        Caption = #30830#23450
        Default = True
        TabOrder = 0
        OnClick = btnOKClick
      end
      object btnCancel: TButton
        Left = 431
        Top = 12
        Width = 75
        Height = 25
        Cancel = True
        Caption = #21462#28040
        TabOrder = 1
        OnClick = btnCancelClick
      end
      object btnApply: TButton
        Left = 512
        Top = 12
        Width = 75
        Height = 25
        Caption = #24212#29992
        TabOrder = 2
        OnClick = btnApplyClick
      end
      object btnReset: TButton
        Left = 16
        Top = 12
        Width = 75
        Height = 25
        Caption = #37325#32622
        TabOrder = 3
        OnClick = btnResetClick
      end
    end
    object pnlCenter: TPanel
      Left = 0
      Top = 60
      Width = 600
      Height = 390
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 2
      object PageControl: TPageControl
        Left = 8
        Top = 8
        Width = 584
        Height = 374
        ActivePage = tsGeneral
        Anchors = [akLeft, akTop, akRight, akBottom]
        TabOrder = 0
        object tsGeneral: TTabSheet
          Caption = #24120#35268
          object gbLanguage: TGroupBox
            Left = 16
            Top = 16
            Width = 250
            Height = 80
            Caption = #35821#35328#35774#32622
            TabOrder = 0
            object cbLanguage: TComboBox
              Left = 16
              Top = 32
              Width = 200
              Height = 21
              Style = csDropDownList
              TabOrder = 0
              OnChange = cbLanguageChange
            end
          end
          object gbTheme: TGroupBox
            Left = 290
            Top = 16
            Width = 250
            Height = 80
            Caption = #20027#39064#35774#32622
            TabOrder = 1
            object rbLightTheme: TRadioButton
              Left = 16
              Top = 24
              Width = 80
              Height = 17
              Caption = #28145#33394#20027#39064
              Checked = True
              TabOrder = 0
              TabStop = True
              OnClick = rbThemeClick
            end
            object rbDarkTheme: TRadioButton
              Left = 16
              Top = 47
              Width = 80
              Height = 17
              Caption = #28145#33394#20027#39064
              TabOrder = 1
              OnClick = rbThemeClick
            end
            object rbAutoTheme: TRadioButton
              Left = 120
              Top = 24
              Width = 80
              Height = 17
              Caption = #36319#38543#31995#32479
              TabOrder = 2
              OnClick = rbThemeClick
            end
          end
        end
        object tsMigration: TTabSheet
          Caption = #36801#31227
          ImageIndex = 1
          object gbMigrationOptions: TGroupBox
            Left = 16
            Top = 16
            Width = 520
            Height = 200
            Caption = #36801#31227#36873#39033
            TabOrder = 0
            object lblBufferSize: TLabel
              Left = 16
              Top = 160
              Width = 96
              Height = 13
              Caption = #32531#20914#21306#22823#23567' (KB):'
            end
            object chkCreateBackup: TCheckBox
              Left = 16
              Top = 32
              Width = 150
              Height = 17
              Caption = #36801#31227#21069#21019#24314#22791#20221
              Checked = True
              State = cbChecked
              TabOrder = 0
            end
            object chkVerifyAfterCopy: TCheckBox
              Left = 16
              Top = 55
              Width = 150
              Height = 17
              Caption = #22797#21046#21518#39564#35777#23436#25972#24615
              Checked = True
              State = cbChecked
              TabOrder = 1
            end
            object chkUseJunctionFirst: TCheckBox
              Left = 16
              Top = 78
              Width = 150
              Height = 17
              Caption = #20248#20808#20351#29992#30446#24405#32852#25509
              Checked = True
              State = cbChecked
              TabOrder = 2
            end
            object chkShowProgress: TCheckBox
              Left = 16
              Top = 101
              Width = 150
              Height = 17
              Caption = #26174#31034#35814#32454#36827#24230
              Checked = True
              State = cbChecked
              TabOrder = 3
            end
            object edtBufferSize: TEdit
              Left = 130
              Top = 157
              Width = 60
              Height = 21
              ReadOnly = True
              TabOrder = 4
              Text = '64'
            end
            object udBufferSize: TUpDown
              Left = 190
              Top = 157
              Width = 16
              Height = 21
              Associate = edtBufferSize
              Min = 1
              Max = 100
              Position = 64
              TabOrder = 5
            end
          end
        end
        object tsCleanup: TTabSheet
          Caption = #28165#29702
          ImageIndex = 2
          object gbCleanupOptions: TGroupBox
            Left = 16
            Top = 16
            Width = 520
            Height = 200
            Caption = #28165#29702#36873#39033
            TabOrder = 0
            object lblMaxLogSize: TLabel
              Left = 16
              Top = 160
              Width = 108
              Height = 13
              Caption = #26368#22823#26085#24535#22823#23567' (MB):'
            end
            object chkConfirmCleanup: TCheckBox
              Left = 16
              Top = 32
              Width = 150
              Height = 17
              Caption = #28165#29702#21069#30830#35748
              Checked = True
              State = cbChecked
              TabOrder = 0
            end
            object chkMoveToRecycleBin: TCheckBox
              Left = 16
              Top = 55
              Width = 150
              Height = 17
              Caption = #31227#21160#21040#22238#25910#31449
              Checked = True
              State = cbChecked
              TabOrder = 1
            end
            object chkCleanupLogs: TCheckBox
              Left = 16
              Top = 78
              Width = 150
              Height = 17
              Caption = #33258#21160#28165#29702#26085#24535
              TabOrder = 2
            end
            object edtMaxLogSize: TEdit
              Left = 140
              Top = 157
              Width = 60
              Height = 21
              ReadOnly = True
              TabOrder = 3
              Text = '10'
            end
            object udMaxLogSize: TUpDown
              Left = 200
              Top = 157
              Width = 16
              Height = 21
              Associate = edtMaxLogSize
              Min = 1
              Max = 1000
              Position = 10
              TabOrder = 4
            end
          end
        end
        object tsAdvanced: TTabSheet
          Caption = #39640#32423
          ImageIndex = 3
          object gbPerformance: TGroupBox
            Left = 16
            Top = 16
            Width = 250
            Height = 150
            Caption = #24615#33021#35774#32622
            TabOrder = 0
            object lblThreadCount: TLabel
              Left = 16
              Top = 110
              Width = 60
              Height = 13
              Caption = #32447#31243#25968#37327':'
            end
            object chkEnableMultiThread: TCheckBox
              Left = 16
              Top = 32
              Width = 100
              Height = 17
              Caption = #21551#29992#22810#32447#31243
              Checked = True
              State = cbChecked
              TabOrder = 0
            end
            object chkEnableCompression: TCheckBox
              Left = 16
              Top = 55
              Width = 100
              Height = 17
              Caption = #21551#29992#21387#32553
              TabOrder = 1
            end
            object chkEnableEncryption: TCheckBox
              Left = 16
              Top = 78
              Width = 100
              Height = 17
              Caption = #21551#29992#21152#23494
              TabOrder = 2
            end
            object edtThreadCount: TEdit
              Left = 90
              Top = 107
              Width = 40
              Height = 21
              ReadOnly = True
              TabOrder = 3
              Text = '4'
            end
            object udThreadCount: TUpDown
              Left = 130
              Top = 107
              Width = 16
              Height = 21
              Associate = edtThreadCount
              Min = 1
              Max = 16
              Position = 4
              TabOrder = 4
            end
          end
          object gbSecurity: TGroupBox
            Left = 290
            Top = 16
            Width = 250
            Height = 150
            Caption = #23433#20840#35774#32622
            TabOrder = 1
            object chkRequireElevation: TCheckBox
              Left = 16
              Top = 32
              Width = 150
              Height = 17
              Caption = #38656#35201#31649#29702#21592#26435#38480
              TabOrder = 0
            end
            object chkAuditOperations: TCheckBox
              Left = 16
              Top = 55
              Width = 150
              Height = 17
              Caption = #23457#35745#25152#26377#25805#20316
              Checked = True
              State = cbChecked
              TabOrder = 1
            end
            object chkSecureDelete: TCheckBox
              Left = 16
              Top = 78
              Width = 100
              Height = 17
              Caption = #23433#20840#21024#38500
              TabOrder = 2
            end
          end
        end
      end
    end
  end
end
