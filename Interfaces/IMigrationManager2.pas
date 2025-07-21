unit IMigrationManager2;

interface

uses
  System.SysUtils, System.Classes, DataTypes;

type
  // 迁移管理器接口
  IMigrationManager = interface
    ['{B2C3D4E5-F6A7-8901-BCDE-F23456789012}']
    function CreateMigrationPlan(const ASourcePath, ATargetPath: string): TMigrationPlan;
    function ValidateMigrationPlan(const APlan: TMigrationPlan): Boolean;
    function ExecuteMigration(const APlan: TMigrationPlan; AProgressCallback: TProgressCallback): Boolean;
    function CanRollback(const APlan: TMigrationPlan): Boolean;
  end;

implementation

end.
