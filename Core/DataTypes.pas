unit DataTypes;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections;

type
  // 打赏地址类型枚举
  TDonationAddressType = (datWechat, datAlipay, datBTC, datUSDT);

  // 打赏地址信息记录
  TDonationAddressInfo = record
    AddressType: TDonationAddressType;
    Address: string;
    Description: string;
    QRCodeData: TBytes;
    IsValid: Boolean;
  end;

  // 应用程序状态记录
  TApplicationState = record
    IsInitialized: Boolean;
    CurrentLanguage: string;
    SecurityLevel: Integer;
    LastBackupId: string;
    ActiveMigrations: TArray<string>;
  end;

  // 迁移状态枚举
  TMigrationState = (msIdle, msAnalyzing, msPreparing, msExecuting, msCompleted, msFailed, msRollingBack);

  // 系统信息记录
  TSystemInfo = record
    OSVersion: string;
    Architecture: string;
    AvailableSpace: TDictionary<string, Int64>; // 驱动器 -> 可用空间
    IsAdminMode: Boolean;
    MachineFingerprint: string;
  end;

  // 主题颜色记录
  TThemeColors = record
    ActiveColor: Cardinal;
    InactiveColor: Cardinal;
    TextColor: Cardinal;
    BackgroundColor: Cardinal;
  end;

  // 符号链接可行性级别枚举
  TSymlinkFeasibility = (sfCanLink, sfRisky, sfCannotMove);

  // 文件分析结果记录
  TFileAnalysisResult = record
    FilePath: string;
    SymlinkFeasibility: TSymlinkFeasibility;
    Dependencies: TArray<string>;
    Size: Int64;
    IsSystemFile: Boolean;
    RequiresRestart: Boolean;
    CanCreateSymlink: Boolean;
    Reason: string;
  end;

  // 迁移计划记录
  TMigrationPlan = record
    SourcePath: string;
    TargetPath: string;
    Files: TArray<TFileAnalysisResult>;
    EstimatedTime: Integer;
    SpaceSavings: Int64;
    RequiresRestart: Boolean;
  end;

  // 进度回调过程类型
  TProgressCallback = reference to procedure(AProgress: Integer; const AMessage: string);

  // 备份清单记录
  TBackupManifest = record
    BackupId: string;
    CreatedDate: TDateTime;
    SourcePath: string;
    TargetPath: string;
    Files: TArray<string>;
    RegistryEntries: TArray<string>;
    SymbolicLinks: TArray<string>;
  end;

implementation

end.