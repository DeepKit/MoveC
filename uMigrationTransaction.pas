unit uMigrationTransaction;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.IniFiles,
  System.IOUtils, System.Generics.Collections, System.Hash;

type
  // 事务状态枚举
  TMigrationStatus = (
    msNotStarted,      // 未开始
    msInProgress,      // 进行中
    msCompleted,       // 已完成
    msFailed,          // 失败
    msRolledBack       // 已回滚
  );

  // 文件迁移记录
  TFileRecord = record
    SourcePath: string;
    TargetPath: string;
    SHA256Hash: string;
    FileSize: Int64;
    IsVerified: Boolean;
    ErrorMessage: string;
  end;

  // 迁移事务管理器
  TMigrationTransaction = class
  private
    FTransactionID: string;
    FSourceDir: string;
    FTargetDir: string;
    FBackupDir: string;
    FStatus: TMigrationStatus;
    FStartTime: TDateTime;
    FEndTime: TDateTime;
    FFileRecords: TList<TFileRecord>;
    FLogFile: string;
    FTransactionFile: string;
    FTotalFiles: Integer;
    FProcessedFiles: Integer;
    FTotalBytes: Int64;
    FProcessedBytes: Int64;
    FLastError: string;

    function GetTransactionDir: string;
    function GetTransactionFile: string;
    function GetLogFile: string;
    procedure WriteLog(const AMessage: string);
    function StatusToString(AStatus: TMigrationStatus): string;
    function StringToStatus(const AStatusStr: string): TMigrationStatus;

  public
    constructor Create;
    destructor Destroy; override;

    // 事务管理
    procedure StartTransaction(const ASourceDir, ATargetDir: string);
    procedure LoadTransaction(const ATransactionID: string);
    procedure SaveTransaction;
    procedure CompleteTransaction;
    procedure FailTransaction(const AErrorMessage: string);
    procedure RollbackTransaction;

    // 文件记录管理
    procedure AddFileRecord(const ASourcePath, ATargetPath: string; 
      AFileSize: Int64; const ASHA256Hash: string = '');
    procedure UpdateFileRecord(const ASourcePath: string; 
      const ASHA256Hash: string; AIsVerified: Boolean);
    procedure MarkFileError(const ASourcePath, AErrorMessage: string);

    // 进度管理
    procedure UpdateProgress(AProcessedFiles, ATotalFiles: Integer;
      AProcessedBytes, ATotalBytes: Int64);

    // 查询方法
    function GetFileRecord(const ASourcePath: string): TFileRecord;
    function IsFileProcessed(const ASourcePath: string): Boolean;
    function GetProcessedFiles: TArray<TFileRecord>;
    function GetFailedFiles: TArray<TFileRecord>;
    function GetProgress: Double;

    // 事务恢复检测
    class function FindIncompleteTransactions: TArray<string>;
    class function HasIncompleteTransaction: Boolean;

    // 日志方法
    procedure LogInfo(const AMessage: string);
    procedure LogWarning(const AMessage: string);
    procedure LogError(const AMessage: string);

    // 属性
    property TransactionID: string read FTransactionID;
    property SourceDir: string read FSourceDir;
    property TargetDir: string read FTargetDir;
    property BackupDir: string read FBackupDir;
    property Status: TMigrationStatus read FStatus;
    property StartTime: TDateTime read FStartTime;
    property EndTime: TDateTime read FEndTime;
    property TotalFiles: Integer read FTotalFiles;
    property ProcessedFiles: Integer read FProcessedFiles;
    property TotalBytes: Int64 read FTotalBytes;
    property ProcessedBytes: Int64 read FProcessedBytes;
    property LastError: string read FLastError;
    property FileRecords: TList<TFileRecord> read FFileRecords;
  end;

implementation

uses
  System.DateUtils;

{ TMigrationTransaction }

constructor TMigrationTransaction.Create;
begin
  inherited Create;
  FFileRecords := TList<TFileRecord>.Create;
  FStatus := msNotStarted;
  FTotalFiles := 0;
  FProcessedFiles := 0;
  FTotalBytes := 0;
  FProcessedBytes := 0;
end;

destructor TMigrationTransaction.Destroy;
begin
  FFileRecords.Free;
  inherited;
end;

function TMigrationTransaction.GetTransactionDir: string;
begin
  Result := TPath.Combine(ExtractFilePath(ParamStr(0)), 'Transactions');
  if not TDirectory.Exists(Result) then
    TDirectory.CreateDirectory(Result);
end;

function TMigrationTransaction.GetTransactionFile: string;
begin
  if FTransactionID = '' then
    Result := ''
  else
    Result := TPath.Combine(GetTransactionDir, FTransactionID + '.ini');
end;

function TMigrationTransaction.GetLogFile: string;
begin
  if FTransactionID = '' then
    Result := ''
  else
    Result := TPath.Combine(GetTransactionDir, FTransactionID + '.log');
end;

procedure TMigrationTransaction.WriteLog(const AMessage: string);
var
  LogFile: TextFile;
  LogMsg: string;
begin
  if FLogFile = '' then
    FLogFile := GetLogFile;

  if FLogFile = '' then Exit;

  try
    AssignFile(LogFile, FLogFile);
    if TFile.Exists(FLogFile) then
      Append(LogFile)
    else
      Rewrite(LogFile);

    try
      LogMsg := Format('[%s] %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now), AMessage]);
      WriteLn(LogFile, LogMsg);
    finally
      CloseFile(LogFile);
    end;
  except
    // 忽略日志写入错误
  end;
end;

function TMigrationTransaction.StatusToString(AStatus: TMigrationStatus): string;
begin
  case AStatus of
    msNotStarted: Result := 'NotStarted';
    msInProgress: Result := 'InProgress';
    msCompleted: Result := 'Completed';
    msFailed: Result := 'Failed';
    msRolledBack: Result := 'RolledBack';
  else
    Result := 'Unknown';
  end;
end;

function TMigrationTransaction.StringToStatus(const AStatusStr: string): TMigrationStatus;
begin
  if SameText(AStatusStr, 'NotStarted') then
    Result := msNotStarted
  else if SameText(AStatusStr, 'InProgress') then
    Result := msInProgress
  else if SameText(AStatusStr, 'Completed') then
    Result := msCompleted
  else if SameText(AStatusStr, 'Failed') then
    Result := msFailed
  else if SameText(AStatusStr, 'RolledBack') then
    Result := msRolledBack
  else
    Result := msNotStarted;
end;

procedure TMigrationTransaction.StartTransaction(const ASourceDir, ATargetDir: string);
begin
  // 生成唯一的事务ID
  FTransactionID := 'MIG_' + FormatDateTime('yyyymmdd_hhnnss', Now) + 
                    '_' + IntToStr(Random(10000));
  FSourceDir := ASourceDir;
  FTargetDir := ATargetDir;
  FBackupDir := ASourceDir + '.backup_' + FormatDateTime('yyyymmdd_hhnnss', Now);
  FStatus := msInProgress;
  FStartTime := Now;
  FEndTime := 0;

  FTransactionFile := GetTransactionFile;
  FLogFile := GetLogFile;

  LogInfo('事务开始: ' + FTransactionID);
  LogInfo('源目录: ' + FSourceDir);
  LogInfo('目标目录: ' + FTargetDir);
  LogInfo('备份目录: ' + FBackupDir);

  SaveTransaction;
end;

procedure TMigrationTransaction.LoadTransaction(const ATransactionID: string);
var
  IniFile: TIniFile;
  FileCount, I: Integer;
  FileRec: TFileRecord;
  SectionName: string;
begin
  FTransactionID := ATransactionID;
  FTransactionFile := GetTransactionFile;
  FLogFile := GetLogFile;

  if not TFile.Exists(FTransactionFile) then
    raise Exception.CreateFmt('事务文件不存在: %s', [FTransactionFile]);

  IniFile := TIniFile.Create(FTransactionFile);
  try
    // 读取基本信息
    FSourceDir := IniFile.ReadString('Transaction', 'SourceDir', '');
    FTargetDir := IniFile.ReadString('Transaction', 'TargetDir', '');
    FBackupDir := IniFile.ReadString('Transaction', 'BackupDir', '');
    FStatus := StringToStatus(IniFile.ReadString('Transaction', 'Status', 'NotStarted'));
    FStartTime := IniFile.ReadDateTime('Transaction', 'StartTime', Now);
    FEndTime := IniFile.ReadDateTime('Transaction', 'EndTime', 0);
    FTotalFiles := IniFile.ReadInteger('Transaction', 'TotalFiles', 0);
    FProcessedFiles := IniFile.ReadInteger('Transaction', 'ProcessedFiles', 0);
    FTotalBytes := IniFile.ReadInt64('Transaction', 'TotalBytes', 0);
    FProcessedBytes := IniFile.ReadInt64('Transaction', 'ProcessedBytes', 0);
    FLastError := IniFile.ReadString('Transaction', 'LastError', '');

    // 读取文件记录
    FFileRecords.Clear;
    FileCount := IniFile.ReadInteger('Files', 'Count', 0);
    for I := 0 to FileCount - 1 do
    begin
      SectionName := Format('File_%d', [I]);
      FileRec.SourcePath := IniFile.ReadString(SectionName, 'SourcePath', '');
      FileRec.TargetPath := IniFile.ReadString(SectionName, 'TargetPath', '');
      FileRec.SHA256Hash := IniFile.ReadString(SectionName, 'SHA256Hash', '');
      FileRec.FileSize := IniFile.ReadInt64(SectionName, 'FileSize', 0);
      FileRec.IsVerified := IniFile.ReadBool(SectionName, 'IsVerified', False);
      FileRec.ErrorMessage := IniFile.ReadString(SectionName, 'ErrorMessage', '');
      FFileRecords.Add(FileRec);
    end;
  finally
    IniFile.Free;
  end;

  LogInfo('事务已加载: ' + FTransactionID);
end;

procedure TMigrationTransaction.SaveTransaction;
var
  IniFile: TIniFile;
  I: Integer;
  SectionName: string;
begin
  if FTransactionFile = '' then
    FTransactionFile := GetTransactionFile;

  IniFile := TIniFile.Create(FTransactionFile);
  try
    // 写入基本信息
    IniFile.WriteString('Transaction', 'TransactionID', FTransactionID);
    IniFile.WriteString('Transaction', 'SourceDir', FSourceDir);
    IniFile.WriteString('Transaction', 'TargetDir', FTargetDir);
    IniFile.WriteString('Transaction', 'BackupDir', FBackupDir);
    IniFile.WriteString('Transaction', 'Status', StatusToString(FStatus));
    IniFile.WriteDateTime('Transaction', 'StartTime', FStartTime);
    IniFile.WriteDateTime('Transaction', 'EndTime', FEndTime);
    IniFile.WriteInteger('Transaction', 'TotalFiles', FTotalFiles);
    IniFile.WriteInteger('Transaction', 'ProcessedFiles', FProcessedFiles);
    IniFile.WriteInt64('Transaction', 'TotalBytes', FTotalBytes);
    IniFile.WriteInt64('Transaction', 'ProcessedBytes', FProcessedBytes);
    IniFile.WriteString('Transaction', 'LastError', FLastError);

    // 写入文件记录
    IniFile.WriteInteger('Files', 'Count', FFileRecords.Count);
    for I := 0 to FFileRecords.Count - 1 do
    begin
      SectionName := Format('File_%d', [I]);
      IniFile.WriteString(SectionName, 'SourcePath', FFileRecords[I].SourcePath);
      IniFile.WriteString(SectionName, 'TargetPath', FFileRecords[I].TargetPath);
      IniFile.WriteString(SectionName, 'SHA256Hash', FFileRecords[I].SHA256Hash);
      IniFile.WriteInt64(SectionName, 'FileSize', FFileRecords[I].FileSize);
      IniFile.WriteBool(SectionName, 'IsVerified', FFileRecords[I].IsVerified);
      IniFile.WriteString(SectionName, 'ErrorMessage', FFileRecords[I].ErrorMessage);
    end;

    IniFile.UpdateFile;
  finally
    IniFile.Free;
  end;
end;

procedure TMigrationTransaction.CompleteTransaction;
begin
  FStatus := msCompleted;
  FEndTime := Now;
  LogInfo('事务完成: ' + FTransactionID);
  SaveTransaction;
end;

procedure TMigrationTransaction.FailTransaction(const AErrorMessage: string);
begin
  FStatus := msFailed;
  FEndTime := Now;
  FLastError := AErrorMessage;
  LogError('事务失败: ' + AErrorMessage);
  SaveTransaction;
end;

procedure TMigrationTransaction.RollbackTransaction;
begin
  FStatus := msRolledBack;
  FEndTime := Now;
  LogInfo('事务已回滚: ' + FTransactionID);
  SaveTransaction;
end;

procedure TMigrationTransaction.AddFileRecord(const ASourcePath, ATargetPath: string;
  AFileSize: Int64; const ASHA256Hash: string);
var
  FileRec: TFileRecord;
begin
  FileRec.SourcePath := ASourcePath;
  FileRec.TargetPath := ATargetPath;
  FileRec.FileSize := AFileSize;
  FileRec.SHA256Hash := ASHA256Hash;
  FileRec.IsVerified := False;
  FileRec.ErrorMessage := '';
  FFileRecords.Add(FileRec);
end;

procedure TMigrationTransaction.UpdateFileRecord(const ASourcePath: string;
  const ASHA256Hash: string; AIsVerified: Boolean);
var
  I: Integer;
  FileRec: TFileRecord;
begin
  for I := 0 to FFileRecords.Count - 1 do
  begin
    if SameText(FFileRecords[I].SourcePath, ASourcePath) then
    begin
      FileRec := FFileRecords[I];
      FileRec.SHA256Hash := ASHA256Hash;
      FileRec.IsVerified := AIsVerified;
      FFileRecords[I] := FileRec;
      Break;
    end;
  end;
end;

procedure TMigrationTransaction.MarkFileError(const ASourcePath, AErrorMessage: string);
var
  I: Integer;
  FileRec: TFileRecord;
begin
  for I := 0 to FFileRecords.Count - 1 do
  begin
    if SameText(FFileRecords[I].SourcePath, ASourcePath) then
    begin
      FileRec := FFileRecords[I];
      FileRec.ErrorMessage := AErrorMessage;
      FFileRecords[I] := FileRec;
      LogError(Format('文件错误 [%s]: %s', [ASourcePath, AErrorMessage]));
      Break;
    end;
  end;
end;

procedure TMigrationTransaction.UpdateProgress(AProcessedFiles, ATotalFiles: Integer;
  AProcessedBytes, ATotalBytes: Int64);
begin
  FProcessedFiles := AProcessedFiles;
  FTotalFiles := ATotalFiles;
  FProcessedBytes := AProcessedBytes;
  FTotalBytes := ATotalBytes;

  // 定期保存进度（每10个文件）
  if (FProcessedFiles mod 10 = 0) then
    SaveTransaction;
end;

function TMigrationTransaction.GetFileRecord(const ASourcePath: string): TFileRecord;
var
  I: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  for I := 0 to FFileRecords.Count - 1 do
  begin
    if SameText(FFileRecords[I].SourcePath, ASourcePath) then
    begin
      Result := FFileRecords[I];
      Break;
    end;
  end;
end;

function TMigrationTransaction.IsFileProcessed(const ASourcePath: string): Boolean;
var
  FileRec: TFileRecord;
begin
  FileRec := GetFileRecord(ASourcePath);
  Result := (FileRec.SourcePath <> '') and FileRec.IsVerified;
end;

function TMigrationTransaction.GetProcessedFiles: TArray<TFileRecord>;
var
  List: TList<TFileRecord>;
  FileRec: TFileRecord;
begin
  List := TList<TFileRecord>.Create;
  try
    for FileRec in FFileRecords do
    begin
      if FileRec.IsVerified then
        List.Add(FileRec);
    end;
    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

function TMigrationTransaction.GetFailedFiles: TArray<TFileRecord>;
var
  List: TList<TFileRecord>;
  FileRec: TFileRecord;
begin
  List := TList<TFileRecord>.Create;
  try
    for FileRec in FFileRecords do
    begin
      if FileRec.ErrorMessage <> '' then
        List.Add(FileRec);
    end;
    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

function TMigrationTransaction.GetProgress: Double;
begin
  if FTotalBytes = 0 then
    Result := 0
  else
    Result := (FProcessedBytes / FTotalBytes) * 100;
end;

class function TMigrationTransaction.FindIncompleteTransactions: TArray<string>;
var
  TransactionDir: string;
  Files: TArray<string>;
  List: TList<string>;
  IniFile: TIniFile;
  FileName, Status: string;
begin
  List := TList<string>.Create;
  try
    TransactionDir := TPath.Combine(ExtractFilePath(ParamStr(0)), 'Transactions');
    if TDirectory.Exists(TransactionDir) then
    begin
      Files := TDirectory.GetFiles(TransactionDir, '*.ini');
      for FileName in Files do
      begin
        IniFile := TIniFile.Create(FileName);
        try
          Status := IniFile.ReadString('Transaction', 'Status', 'NotStarted');
          if SameText(Status, 'InProgress') or SameText(Status, 'Failed') then
          begin
            List.Add(TPath.GetFileNameWithoutExtension(FileName));
          end;
        finally
          IniFile.Free;
        end;
      end;
    end;
    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

class function TMigrationTransaction.HasIncompleteTransaction: Boolean;
var
  Transactions: TArray<string>;
begin
  Transactions := FindIncompleteTransactions;
  Result := Length(Transactions) > 0;
end;

procedure TMigrationTransaction.LogInfo(const AMessage: string);
begin
  WriteLog('[INFO] ' + AMessage);
end;

procedure TMigrationTransaction.LogWarning(const AMessage: string);
begin
  WriteLog('[WARN] ' + AMessage);
end;

procedure TMigrationTransaction.LogError(const AMessage: string);
begin
  WriteLog('[ERROR] ' + AMessage);
end;

end.
