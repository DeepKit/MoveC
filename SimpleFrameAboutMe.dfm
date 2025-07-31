object FrameAboutMe: TFrameAboutMe
  Left = 0
  Top = 0
  Width = 600
  Height = 200
  TabOrder = 0
  object pcAboutMe: TPageControl
    Left = 0
    Top = 0
    Width = 600
    Height = 200
    ActivePage = tsWechat
    Align = alClient
    TabOrder = 0
    object tsWechat: TTabSheet
      Caption = #24494#20449#25171#36175
      object lblWechatTip: TLabel
        Left = 16
        Top = 16
        Width = 60
        Height = 13
        Caption = #24494#20449#25910#27454#30721
      end
      object lblWechatAddress: TLabel
        Left = 16
        Top = 40
        Width = 300
        Height = 13
        Caption = #35831#25195#25551#20108#32500#30721
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlue
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
    end
    object tsAlipay: TTabSheet
      Caption = #25903#20184#23453#25171#36175
      ImageIndex = 1
      object lblAlipayTip: TLabel
        Left = 16
        Top = 16
        Width = 72
        Height = 13
        Caption = #25903#20184#23453#25910#27454#30721
      end
      object lblAlipayAddress: TLabel
        Left = 16
        Top = 40
        Width = 300
        Height = 13
        Caption = #35831#25195#25551#20108#32500#30721
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlue
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
    end
    object tsBTC: TTabSheet
      Caption = 'BTC'#25171#36175
      ImageIndex = 2
      object lblBTCTip: TLabel
        Left = 16
        Top = 16
        Width = 60
        Height = 13
        Caption = 'BTC'#25910#27454#22320#22336
      end
      object lblBTCAddress: TLabel
        Left = 16
        Top = 40
        Width = 300
        Height = 13
        Caption = 'bc1qze0ggsrdtjqwjpjfufydsuyjxc08tgcq5xkct3'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlue
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object btnCopyBTC: TButton
        Left = 16
        Top = 64
        Width = 75
        Height = 25
        Caption = #22797#21046#22320#22336
        TabOrder = 0
        OnClick = btnCopyBTCClick
      end
    end
    object tsUSDT: TTabSheet
      Caption = 'USDT'#25171#36175
      ImageIndex = 3
      object lblUSDTTip: TLabel
        Left = 16
        Top = 16
        Width = 66
        Height = 13
        Caption = 'USDT'#25910#27454#22320#22336
      end
      object lblUSDTAddress: TLabel
        Left = 16
        Top = 40
        Width = 300
        Height = 13
        Caption = 'TH1NazpoEpUqcEotGzLPHs13SbLDJKKCys'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlue
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object btnCopyUSDT: TButton
        Left = 16
        Top = 64
        Width = 75
        Height = 25
        Caption = #22797#21046#22320#22336
        TabOrder = 0
        OnClick = btnCopyUSDTClick
      end
    end
    object tsAboutMe: TTabSheet
      Caption = #20851#20110#25105
      ImageIndex = 4
      object lblAboutMeTip: TLabel
        Left = 16
        Top = 16
        Width = 300
        Height = 13
        Caption = #24863#35874#24320#21457#32773#65292#22914#26524#36719#20214#23545#24744#26377#24110#21161#65292#35831#25171#36175#25903#25345#65281
      end
      object lblMachineCode: TLabel
        Left = 16
        Top = 40
        Width = 36
        Height = 13
        Caption = #26426#22120#30721':'
      end
      object lblMachineCodeValue: TLabel
        Left = 60
        Top = 40
        Width = 200
        Height = 13
        Caption = 'XXXX-XXXX-XXXX-XXXX'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlue
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsUnderline]
        ParentFont = False
        OnClick = lblMachineCodeValueClick
      end
    end
  end
end
