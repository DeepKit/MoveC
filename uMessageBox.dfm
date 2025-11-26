object frmMessageBox: TfrmMessageBox
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #28040#24687#26694
  ClientHeight = 200
  ClientWidth = 400
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Microsoft YaHei UI'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 13
  object pnlMain: TPanel
    Left = 0
    Top = 0
    Width = 400
    Height = 200
    Align = alClient
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    object pnlIcon: TPanel
      Left = 0
      Top = 0
      Width = 60
      Height = 150
      Align = alLeft
      BevelOuter = bvNone
      Color = 4227327
      ParentBackground = False
      TabOrder = 0
      object imgIcon: TImage
        Left = 15
        Top = 50
        Width = 32
        Height = 32
        Center = True
        Proportional = True
        Stretch = True
      end
    end
    object pnlContent: TPanel
      Left = 60
      Top = 0
      Width = 340
      Height = 150
      Align = alClient
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 1
      object lblTitle: TLabel
        Left = 20
        Top = 20
        Width = 300
        Height = 20
        Caption = #26631#39064
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4227327
        Font.Height = -16
        Font.Name = 'Microsoft YaHei UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblMessage: TLabel
        Left = 20
        Top = 50
        Width = 300
        Height = 80
        Caption = #28040#24687#20869#23481
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 4342338
        Font.Height = -12
        Font.Name = 'Microsoft YaHei UI'
        Font.Style = []
        ParentFont = False
        WordWrap = True
      end
    end
    object pnlButtons: TPanel
      Left = 0
      Top = 150
      Width = 400
      Height = 50
      Align = alBottom
      BevelOuter = bvNone
      Color = 15987699
      ParentBackground = False
      TabOrder = 2
      object btnOK: TButton
        Left = 160
        Top = 10
        Width = 80
        Height = 30
        Caption = #30830#23450
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Microsoft YaHei UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        OnClick = btnOKClick
      end
      object btnCancel: TButton
        Left = 250
        Top = 10
        Width = 80
        Height = 30
        Caption = #21462#28040
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Microsoft YaHei UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 1
        OnClick = btnCancelClick
      end
      object btnYes: TButton
        Left = 70
        Top = 10
        Width = 80
        Height = 30
        Caption = #26159
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Microsoft YaHei UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 2
        OnClick = btnYesClick
      end
      object btnNo: TButton
        Left = 160
        Top = 10
        Width = 80
        Height = 30
        Caption = #21542
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Microsoft YaHei UI'
        Font.Style = []
        ParentFont = False
        TabOrder = 3
        OnClick = btnNoClick
      end
    end
  end
end
