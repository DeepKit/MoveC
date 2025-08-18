unit DataTypes;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections;

type
  // 文件类型枚举
  TFileType = (ftUnknown, ftExecutable, ftText, ftImage, ftMedia, ftDocument);

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

  // 数据库相关类型定义

  // 备份信息记录
  TBackupInfo = record
    BackupId: string;
    SourcePath: string;
    TargetPath: string;
    BackupTime: TDateTime;
    BackupSize: Int64;
    FileCount: Integer;
    Status: string;
    Description: string;
  end;

  // 操作日志记录
  TOperationLog = record
    Id: Integer;
    OperationType: string;
    OperationDetail: string;
    SourcePath: string;
    TargetPath: string;
    Result: string;
    ErrorMessage: string;
    ExecutionTime: Integer;
    UserName: string;
    MachineCode: string;
    CreatedAt: TDateTime;
  end;

  // 配置项记录
  TConfigItem = record
    Category: string;
    KeyName: string;
    ValueData: string;
    ValueType: string;
    IsEncrypted: Boolean;
    Description: string;
    CreatedAt: TDateTime;
    UpdatedAt: TDateTime;
  end;

  // 打赏地址记录（数据库版本）
  TDonationAddress = record
    AddressType: string;
    AddressValue: string;
    Description: string;
    IsActive: Boolean;
    DisplayOrder: Integer;
    CreatedAt: TDateTime;
    UpdatedAt: TDateTime;
  end;

  // 语言字符串项记录
  TLanguageStringItem = record
    LanguageCode: string;
    StringKey: string;
    StringValue: string;
    CreatedAt: TDateTime;
    UpdatedAt: TDateTime;
  end;

  // 数据库信息记录
  TDatabaseInfo = record
    DatabasePath: string;
    FileSize: Int64;
    IsConnected: Boolean;
    BackupRecordCount: Integer;
    LogRecordCount: Integer;
    ConfigRecordCount: Integer;
    DonationRecordCount: Integer;
    LanguageStringCount: Integer;
  end;

implementation

end.