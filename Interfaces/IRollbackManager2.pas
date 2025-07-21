unit IRollbackManager2;

interface

uses
  System.SysUtils, System.Classes, DataTypes, IMigrationManager2;

type
  // 回退管理器接口
  IRollbackManager = interface
    ['{C3D4E5F6-A7B8-9012-CDEF-345678901234}']
    function CreateBackup(const AMigrationPlan: TMigrationPlan): string; // 返回BackupId
    function GetBackupManifest(const ABackupId: string): TBackupManifest;
    function CanRollback(const ABackupId: string): Boolean;
    function ExecuteRollback(const ABackupId: string; AProgressCallback: TProgressCallback): Boolean;
    function CreateEmergencyScript(const ABackupId: string): string;
  end;

implementation

end.
