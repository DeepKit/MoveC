unit IDonationManager2;

interface

uses
  System.SysUtils, System.Classes, DataTypes;

type
  // 打赏管理器接口
  IDonationManager = interface
    ['{E5F6A7B8-C9D0-1234-EFAB-567890123456}']
    function LoadDonationAddress(AType: TDonationAddressType): TDonationAddressInfo;
    function ValidateAddressIntegrity(const AAddress: TDonationAddressInfo): Boolean;
    function GetBackupAddress(AType: TDonationAddressType): string;
    function LoadQRCodeImage(AType: TDonationAddressType): TBytes;
  end;

implementation

end.
