unit ISecurityManager2;

interface

uses
  System.SysUtils, System.Classes;

type
  // 安全管理器接口
  ISecurityManager = interface
    ['{D4E5F6A7-B8C9-0123-DEFA-456789012345}']
    function PerformSelfCheck: Boolean;
    function ValidateFileIntegrity(const AFilePath: string): Boolean;
    function EncryptSensitiveData(const AData: string): string;
    function DecryptSensitiveData(const AEncryptedData: string): string;
    function GenerateMachineFingerprint: string;
    function IsRunningAsAdmin: Boolean;
  end;

implementation

end.
