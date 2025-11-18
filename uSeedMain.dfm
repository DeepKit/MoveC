object frmSeedMain: TfrmSeedMain
  Left = 0
  Top = 0
  Caption = #38450#31735#25913#25773#31181#24037#20855
  ClientHeight = 600
  ClientWidth = 800
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Size = 9
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 800
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = 3355443
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      AlignWithMargins = True
      Left = 20
      Top = 15
      Width = 760
      Height = 30
      Margins.Left = 20
      Margins.Top = 15
      Margins.Right = 20
      Margins.Bottom = 15
      Align = alClient
      Caption = #22270#20687#36164#28304#21152#23494#25773#31181#24037#20855
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -21
      Font.Name = 'Segoe UI'
      Font.Size = 16
      Font.Style = [fsBold]
      ParentFont = False
      ExplicitWidth = 196
      ExplicitHeight = 30
    end
  end
  object pnlCenter: TPanel
    Left = 0
    Top = 60
    Width = 800
    Height = 400
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object gbPassword: TGroupBox
      AlignWithMargins = True
      Left = 10
      Top = 10
      Width = 780
      Height = 80
      Margins.Left = 10
      Margins.Top = 10
      Margins.Right = 10
      Margins.Bottom = 5
      Align = alTop
      Caption = ' '#31649#29702#21592#23494#30721' '
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Size = 10
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
      object lblPasswordHint: TLabel
        AlignWithMargins = True
        Left = 15
        Top = 50
        Width = 750
        Height = 15
        Margins.Left = 13
        Margins.Top = 5
        Margins.Right = 13
        Margins.Bottom = 13
        Align = alBottom
        Caption = #25552#31034#65306#27492#23494#30721#23558#29992#20110#21152#23494#22270#20687#25968#25454
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Size = 9
        Font.Style = []
        ParentFont = False
        ExplicitWidth = 180
      end
      object edtPassword: TEdit
        AlignWithMargins = True
        Left = 15
        Top = 23
        Width = 750
        Height = 22
        Margins.Left = 13
        Margins.Top = 8
        Margins.Right = 13
        Margins.Bottom = 0
        Align = alTop
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Size = 9
        Font.Style = []
        ParentFont = False
        TabOrder = 0
      end
    end
    object gbImages: TGroupBox
      AlignWithMargins = True
      Left = 10
      Top = 100
      Width = 780
      Height = 290
      Margins.Left = 10
      Margins.Top = 5
      Margins.Right = 10
      Margins.Bottom = 10
      Align = alClient
      Caption = ' '#22270#20687#25991#20214#21015#34920' '
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Size = 10
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
      object lblImageCount: TLabel
        AlignWithMargins = True
        Left = 15
        Top = 260
        Width = 750
        Height = 15
        Margins.Left = 13
        Margins.Top = 5
        Margins.Right = 13
        Margins.Bottom = 13
        Align = alBottom
        Caption = #24050#28155#21152' 0 '#20010#22270#20687
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Size = 9
        Font.Style = []
        ParentFont = False
        ExplicitWidth = 72
      end
      object lstImages: TListBox
        AlignWithMargins = True
        Left = 15
        Top = 23
        Width = 650
        Height = 227
        Margins.Left = 13
        Margins.Top = 8
        Margins.Right = 0
        Margins.Bottom = 5
        Align = alClient
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Consolas'
        Font.Size = 9
        Font.Style = []
        ItemHeight = 14
        ParentFont = False
        TabOrder = 0
      end
      object btnAddImage: TBitBtn
        Left = 680
        Top = 30
        Width = 90
        Height = 30
        Caption = #28155#21152#22270#20687
        TabOrder = 1
        OnClick = btnAddImageClick
      end
      object btnRemoveImage: TBitBtn
        Left = 680
        Top = 70
        Width = 90
        Height = 30
        Caption = #31227#38500#36873#20013
        TabOrder = 2
        OnClick = btnRemoveImageClick
      end
      object btnClearAll: TBitBtn
        Left = 680
        Top = 110
        Width = 90
        Height = 30
        Caption = #28165#31354#25152#26377
        TabOrder = 3
        OnClick = btnClearAllClick
      end
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 460
    Width = 800
    Height = 140
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object memoLog: TMemo
      AlignWithMargins = True
      Left = 10
      Top = 5
      Width = 780
      Height = 90
      Margins.Left = 10
      Margins.Top = 5
      Margins.Right = 10
      Margins.Bottom = 5
      Align = alClient
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Consolas'
      Font.Size = 8
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 0
    end
    object btnSeed: TBitBtn
      Left = 480
      Top = 105
      Width = 150
      Height = 30
      Caption = #24320#22987#25773#31181
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Size = 10
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
      OnClick = btnSeedClick
    end
    object btnClose: TBitBtn
      Left = 650
      Top = 105
      Width = 120
      Height = 30
      Caption = #20851#38381
      TabOrder = 2
      OnClick = btnCloseClick
    end
  end
  object OpenDialog: TOpenDialog
    Left = 720
    Top = 20
  end
end
