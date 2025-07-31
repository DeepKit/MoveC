object frmSplash: TfrmSplash
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'C'#30424#28165#29702#24037#20855' - '#21551#21160#20013
  ClientHeight = 320
  ClientWidth = 480
  Color = 15790320
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Microsoft YaHei UI'
  Font.Style = []
  FormStyle = fsStayOnTop
  Position = poScreenCenter
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 17
  object pnlMain: TPanel
    Left = 20
    Top = 20
    Width = 440
    Height = 280
    BevelOuter = bvNone
    BorderStyle = bsSingle
    BorderWidth = 1
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 40
      Top = 60
      Width = 360
      Height = 25
      Alignment = taCenter
      Caption = 'C'#30424#28165#29702#24037#20855' v3.0 Enterprise'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 3355443
      Font.Height = -18
      Font.Name = 'Microsoft YaHei UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblVersion: TLabel
      Left = 40
      Top = 95
      Width = 360
      Height = 17
      Alignment = taCenter
      Caption = #20225#19994#29256' - '#19987#19994#32423#30913#30424#31354#38388#31649#29702#35299#20915#26041#26696
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 6710886
      Font.Height = -13
      Font.Name = 'Microsoft YaHei UI'
      Font.Style = []
      ParentFont = False
    end
    object lblStatus: TLabel
      Left = 40
      Top = 180
      Width = 360
      Height = 15
      Alignment = taCenter
      Caption = #27491#22312#21551#21160'...'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 13395660
      Font.Height = -12
      Font.Name = 'Microsoft YaHei UI'
      Font.Style = []
      ParentFont = False
    end
    object lblCopyright: TLabel
      Left = 40
      Top = 240
      Width = 360
      Height = 14
      Alignment = taCenter
      Caption = #169' 2025 C'#30424#28165#29702#24037#20855'. '#20445#30041#25152#26377#26435#21033'.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 10066329
      Font.Height = -11
      Font.Name = 'Microsoft YaHei UI'
      Font.Style = []
      ParentFont = False
    end
    object ProgressBar: TProgressBar
      Left = 40
      Top = 210
      Width = 360
      Height = 16
      Smooth = True
      TabOrder = 0
    end
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 300
    OnTimer = Timer1Timer
    Left = 24
    Top = 24
  end
end
