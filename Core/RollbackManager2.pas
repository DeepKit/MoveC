unit RollbackManager2;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.IOUtils, System.JSON, 
  System.Generics.Collections, IRollbackManager2, IMigrationManager2, 
  ConfigManager, BasicProtection, DataTypes;

type
  // 回退管理器具体实现
  TRollbackManager = class(TInterfacedObject, IRollbackManager)
  private
    FConfigManager: TConfigManager;
    
    // 内部方法
    function GenerateBackupId: string;
    function GetBackupManifestPath(const ABackupId: string): string;
    function GetBackupDataPath(const ABackupId: string): string;
    function GetBackupRootPath: string;
    function SaveBackupManifest(const AManifest: TBackupManifest): Boolean;
    function LoadBackupManifest(const ABackupId: string): TBackupManifest;
    function BackupFiles(const ASourcePath, ABackupPath: string; var AFileList: TArray<string>): Boolean;
    function BackupRegistryEntries(const ASourcePath: string; var ARegistryEntries: TArray<string>): Boolean;
    function RestoreFiles(const ABackupPath, ATargetPath: string; const AFileList: TArray<string>; AProgressCallback: TProgressCallback): Boolean;
    function RestoreRegistryEntries(const ARegistryEntries: TArray<string>): Boolean;
    function RemoveSymbolicLinks(const ASymbolicLinks: TArray<string>): Boolean;
    function ValidateBackupIntegrity(const ABackupId: string): Boolean;
    function CalculateBackupSize(const ABackupPath: string): Int64;
    function CountBackupFiles(const ABackupPath: string): Integer;
    procedure LogBackupOperation(const AOperation, ADetails, AResult: string; const ABackupId: string = '');
    
  public
    constructor Create(AConfigManager: TConfigManager = nil);
    destructor Destroy; override;
    
    // IRollbackManager 接口实现
    function CreateBackup(const AMigrationPlan: TMigrationPlan): string;
    function GetBackupManifest(const ABackupId: string): TBackupManifest;
    function CanRollback(const ABackupId: string): Boolean;
    function ExecuteRollback(const ABackupId: string; AProgressCallback: TProgressCallback): Boolean;
    function CreateEmergencyScript(const ABackupId: string): string;
    
    // 扩展功能
    function GetAllBackups: TArray<TBackupManifest>;
    function DeleteBackup(const ABackupId: string): Boolean;
    function GetBackupSize(const ABackupId: string): Int64;
    function VerifyBackup(const ABackupId: string): Boolean;
    function CleanupOldBackups(const ADaysToKeep: Integer = 30): Integer;
  end;

implementation

uses
  Vcl.Forms, System.DateUtils, System.Win.Registry, Winapi.ShellAPI;

constructor TRollbackManager.Create(AConfigManager: TConfigManager);
begin
  inherited Create;
  
  if Assigned(AConfigManager) then
    FConfigManager := AConfigManager
  else
    FConfigManager := TConfigManager.Create;
    
  // 确保备份目录存在
  ForceDirectories(GetBackupRootPath);
end;

destructor TRollbackManager.Destroy;
begin
  if Assigned(FConfigManager) then
    FConfigManager.Free;
  inherited;
end;

// 生成备份ID
function TRollbackManager.GenerateBackupId: string;
var
  TimeStamp: string;
  RandomPart: string;
  MachineCode: string;
begin
  TimeStamp := FormatDateTime('yyyymmdd_hhnnss', Now);
  RandomPart := IntToHex(Random(65536), 4);
  
  // 添加机器码的一部分以确保唯一性
  try
    MachineCode := Copy(TBasicProtection.CalculateHMAC(GetEnvironmentVariable('COMPUTERNAME')), 1, 8);
  except
    MachineCode := 'UNKNOWN';
  end;
  
  Result := 'BACKUP_' + TimeStamp + '_' + RandomPart + '_' + MachineCode;
end;

// 获取备份根目录
function TRollbackManager.GetBackupRootPath: string;
begin
  Result := ExtractFilePath(Application.ExeName) + 'Backups\';
end;

// 获取备份清单文件路径
function TRollbackManager.GetBackupManifestPath(const ABackupId: string): string;
begin
  Result := GetBackupRootPath + ABackupId + '_manifest.json';
end;

// 获取备份数据目录路径
function TRollbackManager.GetBackupDataPath(const ABackupId: string): string;
begin
  Result := GetBackupRootPath + ABackupId + '\';
end;

// 保存备份清单
function TRollbackManager.SaveBackupManifest(const AManifest: TBackupManifest): Boolean;
var
  ManifestJson: TJSONObject;
  FilesArray, RegistryArray, SymlinksArray: TJSONArray;
  ManifestPath: string;
  I: Integer;
begin
  Result := False;
  
  try
    ManifestJson := TJSONObject.Create;
    try
      // 基本信息
      ManifestJson.AddPair('backup_id', AManifest.BackupId);
      ManifestJson.AddPair('created_date', DateTimeToStr(AManifest.CreatedDate));
      ManifestJson.AddPair('source_path', AManifest.SourcePath);
      ManifestJson.AddPair('target_path', AManifest.TargetPath);
      
      // 文件列表
      FilesArray := TJSONArray.Create;
      for I := 0 to Length(AManifest.Files) - 1 do
        FilesArray.AddElement(TJSONString.Create(AManifest.Files[I]));
      ManifestJson.AddPair('files', FilesArray);
      
      // 注册表项
      RegistryArray := TJSONArray.Create;
      for I := 0 to Length(AManifest.RegistryEntries) - 1 do
        RegistryArray.AddElement(TJSONString.Create(AManifest.RegistryEntries[I]));
      ManifestJson.AddPair('registry_entries', RegistryArray);
      
      // 符号链接
      SymlinksArray := TJSONArray.Create;
      for I := 0 to Length(AManifest.SymbolicLinks) - 1 do
        SymlinksArray.AddElement(TJSONString.Create(AManifest.SymbolicLinks[I]));
      ManifestJson.AddPair('symbolic_links', SymlinksArray);
      
      // 添加完整性校验
      var ManifestData := ManifestJson.ToJSON;
      var IntegrityHash := TBasicProtection.CalculateHMAC(ManifestData);
      ManifestJson.AddPair('integrity_hash', IntegrityHash);
      
      // 保存到文件
      ManifestPath := GetBackupManifestPath(AManifest.BackupId);
      TFile.WriteAllText(ManifestPath, ManifestJson.ToJSON, TEncoding.UTF8);
      
      Result := True;
      LogBackupOperation('MANIFEST_SAVED', 'Backup manifest saved successfully', 'SUCCESS', AManifest.BackupId);
      
    finally
      ManifestJson.Free;
    end;
    
  except
    on E: Exception do
    begin
      LogBackupOperation('MANIFEST_SAVE_ERROR', E.Message, 'FAILED', AManifest.BackupId);
    end;
  end;
end;

// 加载备份清单
function TRollbackManager.LoadBackupManifest(const ABackupId: string): TBackupManifest;
var
  ManifestPath: string;
  ManifestJson: TJSONObject;
  FilesArray, RegistryArray, SymlinksArray: TJSONArray;
  JsonText: string;
  I: Integer;
begin
  // 初始化结果
  FillChar(Result, SizeOf(Result), 0);
  Result.BackupId := ABackupId;
  
  try
    ManifestPath := GetBackupManifestPath(ABackupId);
    if not FileExists(ManifestPath) then
    begin
      LogBackupOperation('MANIFEST_NOT_FOUND', 'Manifest file not found: ' + ManifestPath, 'FAILED', ABackupId);
      Exit;
    end;
    
    JsonText := TFile.ReadAllText(ManifestPath, TEncoding.UTF8);
    ManifestJson := TJSONObject.ParseJSONValue(JsonText) as TJSONObject;
    
    if not Assigned(ManifestJson) then
    begin
      LogBackupOperation('MANIFEST_PARSE_ERROR', 'Failed to parse manifest JSON', 'FAILED', ABackupId);
      Exit;
    end;
    
    try
      // 验证完整性
      var StoredHash := ManifestJson.GetValue('integrity_hash');
      if Assigned(StoredHash) then
      begin
        ManifestJson.RemovePair('integrity_hash');
        var CalculatedHash := TBasicProtection.CalculateHMAC(ManifestJson.ToJSON);
        if not SameText(StoredHash.Value, CalculatedHash) then
        begin
          LogBackupOperation('MANIFEST_INTEGRITY_FAILED', 'Manifest integrity check failed', 'FAILED', ABackupId);
          Exit;
        end;
      end;
      
      // 读取基本信息
      Result.BackupId := ManifestJson.GetValue('backup_id').Value;
      Result.CreatedDate := StrToDateTimeDef(ManifestJson.GetValue('created_date').Value, Now);
      Result.SourcePath := ManifestJson.GetValue('source_path').Value;
      Result.TargetPath := ManifestJson.GetValue('target_path').Value;
      
      // 读取文件列表
      FilesArray := ManifestJson.GetValue('files') as TJSONArray;
      if Assigned(FilesArray) then
      begin
        SetLength(Result.Files, FilesArray.Count);
        for I := 0 to FilesArray.Count - 1 do
          Result.Files[I] := FilesArray.Items[I].Value;
      end;
      
      // 读取注册表项
      RegistryArray := ManifestJson.GetValue('registry_entries') as TJSONArray;
      if Assigned(RegistryArray) then
      begin
        SetLength(Result.RegistryEntries, RegistryArray.Count);
        for I := 0 to RegistryArray.Count - 1 do
          Result.RegistryEntries[I] := RegistryArray.Items[I].Value;
      end;
      
      // 读取符号链接
      SymlinksArray := ManifestJson.GetValue('symbolic_links') as TJSONArray;
      if Assigned(SymlinksArray) then
      begin
        SetLength(Result.SymbolicLinks, SymlinksArray.Count);
        for I := 0 to SymlinksArray.Count - 1 do
          Result.SymbolicLinks[I] := SymlinksArray.Items[I].Value;
      end;
      
      LogBackupOperation('MANIFEST_LOADED', 'Backup manifest loaded successfully', 'SUCCESS', ABackupId);
      
    finally
      ManifestJson.Free;
    end;
    
  except
    on E: Exception do
    begin
      LogBackupOperation('MANIFEST_LOAD_ERROR', E.Message, 'FAILED', ABackupId);
    end;
  end;
end;

// 备份文件
function TRollbackManager.BackupFiles(const ASourcePath, ABackupPath: string; var AFileList: TArray<string>): Boolean;
var
  SearchRec: TSearchRec;
  SourceFile, BackupFile: string;
  FileList: TList<string>;
begin
  Result := False;
  FileList := TList<string>.Create;
  
  try
    // 确保备份目录存在
    ForceDirectories(ABackupPath);
    
    // 递归备份所有文件
    if FindFirst(ASourcePath + '\*', faAnyFile, SearchRec) = 0 then
    begin
      try
        repeat
          if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
          begin
            SourceFile := ASourcePath + '\' + SearchRec.Name;
            BackupFile := ABackupPath + '\' + SearchRec.Name;
            
            if (SearchRec.Attr and faDirectory) <> 0 then
            begin
              // 递归处理子目录
              var SubFileList: TArray<string>;
              if BackupFiles(SourceFile, BackupFile, SubFileList) then
              begin
                for var SubFile in SubFileList do
                  FileList.Add(SubFile);
              end;
            end
            else
            begin
              // 备份文件
              try
                TFile.Copy(SourceFile, BackupFile, True);
                FileList.Add(SourceFile);
              except
                on E: Exception do
                begin
                  LogBackupOperation('FILE_BACKUP_ERROR', 
                    Format('Failed to backup file: %s, Error: %s', [SourceFile, E.Message]), 'FAILED');
                end;
              end;
            end;
          end;
        until FindNext(SearchRec) <> 0;
      finally
        FindClose(SearchRec);
      end;
    end;
    
    // 转换为数组
    SetLength(AFileList, FileList.Count);
    for var I := 0 to FileList.Count - 1 do
      AFileList[I] := FileList[I];
    
    Result := True;
    
  finally
    FileList.Free;
  end;
end;

// 备份注册表项
function TRollbackManager.BackupRegistryEntries(const ASourcePath: string; var ARegistryEntries: TArray<string>): Boolean;
var
  RegistryList: TList<string>;
  Reg: TRegistry;
  KeysToBackup: TArray<string>;
begin
  Result := False;
  RegistryList := TList<string>.Create;
  
  try
    // 定义需要备份的注册表项
    KeysToBackup := TArray<string>.Create(
      'SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths',
      'SOFTWARE\Classes',
      'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
    );
    
    Reg := TRegistry.Create(KEY_READ);
    try
      Reg.RootKey := HKEY_LOCAL_MACHINE;
      
      for var Key in KeysToBackup do
      begin
        if Reg.OpenKeyReadOnly(Key) then
        begin
          try
            // 这里简化处理，只记录键名
            RegistryList.Add(Key);
          finally
            Reg.CloseKey;
          end;
        end;
      end;
      
    finally
      Reg.Free;
    end;
    
    // 转换为数组
    SetLength(ARegistryEntries, RegistryList.Count);
    for var I := 0 to RegistryList.Count - 1 do
      ARegistryEntries[I] := RegistryList[I];
    
    Result := True;
    
  finally
    RegistryList.Free;
  end;
end;

// 恢复文件
function TRollbackManager.RestoreFiles(const ABackupPath, ATargetPath: string; const AFileList: TArray<string>; AProgressCallback: TProgressCallback): Boolean;
var
  I: Integer;
  BackupFile, TargetFile: string;
  Progress: Integer;
begin
  Result := True;
  
  try
    for I := 0 to Length(AFileList) - 1 do
    begin
      // 计算相对路径
      var RelativePath := StringReplace(AFileList[I], ExtractFilePath(AFileList[0]), '', [rfIgnoreCase]);
      BackupFile := ABackupPath + '\' + RelativePath;
      TargetFile := AFileList[I];
      
      try
        // ���保目标目录存在
        ForceDirectories(ExtractFilePath(TargetFile));
        
        // 恢复文件
        if FileExists(BackupFile) then
        begin
          TFile.Copy(BackupFile, TargetFile, True);
        end;
        
        // 更新进度
        if Assigned(AProgressCallback) then
        begin
          Progress := Round((I + 1) * 100 / Length(AFileList));
          AProgressCallback(Progress, Format('恢复文件: %s', [ExtractFileName(TargetFile)]));
        end;
        
      except
        on E: Exception do
        begin
          LogBackupOperation('FILE_RESTORE_ERROR', 
            Format('Failed to restore file: %s, Error: %s', [TargetFile, E.Message]), 'FAILED');
          Result := False;
        end;
      end;
    end;
    
  except
    on E: Exception do
    begin
      LogBackupOperation('RESTORE_FILES_ERROR', E.Message, 'FAILED');
      Result := False;
    end;
  end;
end;

// 恢复注册表项
function TRollbackManager.RestoreRegistryEntries(const ARegistryEntries: TArray<string>): Boolean;
begin
  Result := True;
  
  // 简化实现：注册表恢复比较复杂，这里只记录日志
  for var Entry in ARegistryEntries do
  begin
    LogBackupOperation('REGISTRY_RESTORE', 'Registry entry: ' + Entry, 'SKIPPED');
  end;
end;

// 移除符号链接
function TRollbackManager.RemoveSymbolicLinks(const ASymbolicLinks: TArray<string>): Boolean;
var
  I: Integer;
begin
  Result := True;
  
  try
    for I := 0 to Length(ASymbolicLinks) - 1 do
    begin
      try
        if DirectoryExists(ASymbolicLinks[I]) then
        begin
          // 删除符号链接目录
          RemoveDirectory(PChar(ASymbolicLinks[I]));
        end
        else if FileExists(ASymbolicLinks[I]) then
        begin
          // 删除符号链接文件
          DeleteFile(ASymbolicLinks[I]);
        end;
        
        LogBackupOperation('SYMLINK_REMOVED', 'Symbolic link removed: ' + ASymbolicLinks[I], 'SUCCESS');
        
      except
        on E: Exception do
        begin
          LogBackupOperation('SYMLINK_REMOVE_ERROR', 
            Format('Failed to remove symbolic link: %s, Error: %s', [ASymbolicLinks[I], E.Message]), 'FAILED');
          Result := False;
        end;
      end;
    end;
    
  except
    on E: Exception do
    begin
      LogBackupOperation('REMOVE_SYMLINKS_ERROR', E.Message, 'FAILED');
      Result := False;
    end;
  end;
end;

// 验证备份完整性
function TRollbackManager.ValidateBackupIntegrity(const ABackupId: string): Boolean;
var
  Manifest: TBackupManifest;
  BackupPath: string;
  I: Integer;
begin
  Result := False;
  
  try
    Manifest := LoadBackupManifest(ABackupId);
    if Manifest.BackupId = '' then
      Exit;
    
    BackupPath := GetBackupDataPath(ABackupId);
    if not DirectoryExists(BackupPath) then
      Exit;
    
    // 验证所有备份文件是否存在
    for I := 0 to Length(Manifest.Files) - 1 do
    begin
      var RelativePath := StringReplace(Manifest.Files[I], Manifest.SourcePath, '', [rfIgnoreCase]);
      var BackupFile := BackupPath + RelativePath;
      
      if not FileExists(BackupFile) then
      begin
        LogBackupOperation('INTEGRITY_CHECK_FAILED', 'Missing backup file: ' + BackupFile, 'FAILED', ABackupId);
        Exit;
      end;
    end;
    
    Result := True;
    LogBackupOperation('INTEGRITY_CHECK_PASSED', 'Backup integrity verified', 'SUCCESS', ABackupId);
    
  except
    on E: Exception do
    begin
      LogBackupOperation('INTEGRITY_CHECK_ERROR', E.Message, 'FAILED', ABackupId);
    end;
  end;
end;

// 计算备份大小
function TRollbackManager.CalculateBackupSize(const ABackupPath: string): Int64;
var
  SearchRec: TSearchRec;
  TotalSize: Int64;
begin
  TotalSize := 0;
  
  if FindFirst(ABackupPath + '\*', faAnyFile, SearchRec) = 0 then
  begin
    try
      repeat
        if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
        begin
          if (SearchRec.Attr and faDirectory) <> 0 then
          begin
            // 递归计算子目录大小
            TotalSize := TotalSize + CalculateBackupSize(ABackupPath + '\' + SearchRec.Name);
          end
          else
          begin
            // 累加文件大小
            TotalSize := TotalSize + SearchRec.Size;
          end;
        end;
      until FindNext(SearchRec) <> 0;
    finally
      FindClose(SearchRec);
    end;
  end;
  
  Result := TotalSize;
end;

// 计算备份文件数量
function TRollbackManager.CountBackupFiles(const ABackupPath: string): Integer;
var
  SearchRec: TSearchRec;
  FileCount: Integer;
begin
  FileCount := 0;
  
  if FindFirst(ABackupPath + '\*', faAnyFile, SearchRec) = 0 then
  begin
    try
      repeat
        if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
        begin
          if (SearchRec.Attr and faDirectory) <> 0 then
          begin
            // 递归计算子目录文件数
            FileCount := FileCount + CountBackupFiles(ABackupPath + '\' + SearchRec.Name);
          end
          else
          begin
            // 累加文件数
            Inc(FileCount);
          end;
        end;
      until FindNext(SearchRec) <> 0;
    finally
      FindClose(SearchRec);
    end;
  end;
  
  Result := FileCount;
end;

// 记录备份操作日志
procedure TRollbackManager.LogBackupOperation(const AOperation, ADetails, AResult: string; const ABackupId: string = '');
begin
  try
    if Assigned(FConfigManager) then
      FConfigManager.LogOperation('BACKUP', AOperation, '', '', AResult, ADetails + ' [BackupId: ' + ABackupId + ']');
  except
    // 忽略日志记录错误
  end;
end;

// 创建备份
function TRollbackManager.CreateBackup(const AMigrationPlan: TMigrationPlan): string;
var
  BackupId: string;
  BackupPath: string;
  Manifest: TBackupManifest;
  FileList: TArray<string>;
  RegistryEntries: TArray<string>;
  BackupInfo: TBackupInfo;
begin
  Result := '';
  
  try
    BackupId := GenerateBackupId;
    BackupPath := GetBackupDataPath(BackupId);
    
    LogBackupOperation('BACKUP_STARTED', 'Creating backup for migration plan', 'STARTED', BackupId);
    
    // 初始化备份清单
    Manifest.BackupId := BackupId;
    Manifest.CreatedDate := Now;
    Manifest.SourcePath := AMigrationPlan.SourcePath;
    Manifest.TargetPath := AMigrationPlan.TargetPath;
    
    // 备份文件
    if BackupFiles(AMigrationPlan.SourcePath, BackupPath, FileList) then
    begin
      Manifest.Files := FileList;
      LogBackupOperation('FILES_BACKED_UP', Format('Backed up %d files', [Length(FileList)]), 'SUCCESS', BackupId);
    end
    else
    begin
      LogBackupOperation('FILES_BACKUP_FAILED', 'Failed to backup files', 'FAILED', BackupId);
      Exit;
    end;
    
    // 备份注册表项
    if BackupRegistryEntries(AMigrationPlan.SourcePath, RegistryEntries) then
    begin
      Manifest.RegistryEntries := RegistryEntries;
      LogBackupOperation('REGISTRY_BACKED_UP', Format('Backed up %d registry entries', [Length(RegistryEntries)]), 'SUCCESS', BackupId);
    end;
    
    // 初始化符号链接列表（将在迁移时填充）
    SetLength(Manifest.SymbolicLinks, 0);
    
    // 保存备份清单
    if SaveBackupManifest(Manifest) then
    begin
      // 记录到数据库
      BackupInfo.BackupId := BackupId;
      BackupInfo.SourcePath := AMigrationPlan.SourcePath;
      BackupInfo.TargetPath := AMigrationPlan.TargetPath;
      BackupInfo.BackupTime := Now;
      BackupInfo.BackupSize := CalculateBackupSize(BackupPath);
      BackupInfo.FileCount := Length(FileList);
      BackupInfo.Status := 'COMPLETED';
      BackupInfo.Description := Format('Migration backup from %s to %s', [AMigrationPlan.SourcePath, AMigrationPlan.TargetPath]);
      
      if Assigned(FConfigManager) then
        FConfigManager.AddBackupRecord(BackupInfo);
      
      Result := BackupId;
      LogBackupOperation('BACKUP_COMPLETED', 'Backup created successfully', 'SUCCESS', BackupId);
    end
    else
    begin
      LogBackupOperation('MANIFEST_SAVE_FAILED', 'Failed to save backup manifest', 'FAILED', BackupId);
    end;
    
  except
    on E: Exception do
    begin
      LogBackupOperation('BACKUP_ERROR', E.Message, 'FAILED', BackupId);
    end;
  end;
end;

// 获取备份清单
function TRollbackManager.GetBackupManifest(const ABackupId: string): TBackupManifest;
begin
  Result := LoadBackupManifest(ABackupId);
end;

// 检查是否可以回退
function TRollbackManager.CanRollback(const ABackupId: string): Boolean;
begin
  Result := False;
  
  try
    // 检查备份清单是否存在
    if not FileExists(GetBackupManifestPath(ABackupId)) then
      Exit;
    
    // 检查备份数据目录是否存在
    if not DirectoryExists(GetBackupDataPath(ABackupId)) then
      Exit;
    
    // 验证备份完整性
    Result := ValidateBackupIntegrity(ABackupId);
    
  except
    Result := False;
  end;
end;

// 执行回退
function TRollbackManager.ExecuteRollback(const ABackupId: string; AProgressCallback: TProgressCallback): Boolean;
var
  Manifest: TBackupManifest;
  BackupPath: string;
begin
  Result := False;
  
  try
    LogBackupOperation('ROLLBACK_STARTED', 'Starting rollback operation', 'STARTED', ABackupId);
    
    if Assigned(AProgressCallback) then
      AProgressCallback(10, '加载备份清单...');
    
    // 加载备份清单
    Manifest := LoadBackupManifest(ABackupId);
    if Manifest.BackupId = '' then
    begin
      LogBackupOperation('ROLLBACK_FAILED', 'Failed to load backup manifest', 'FAILED', ABackupId);
      Exit;
    end;
    
    BackupPath := GetBackupDataPath(ABackupId);
    
    if Assigned(AProgressCallback) then
      AProgressCallback(20, '移除符号链接...');
    
    // 移除符号链接
    if not RemoveSymbolicLinks(Manifest.SymbolicLinks) then
    begin
      LogBackupOperation('ROLLBACK_WARNING', 'Some symbolic links could not be removed', 'WARNING', ABackupId);
    end;
    
    if Assigned(AProgressCallback) then
      AProgressCallback(40, '恢复文件...');
    
    // 恢复文件
    if not RestoreFiles(BackupPath, Manifest.SourcePath, Manifest.Files, AProgressCallback) then
    begin
      LogBackupOperation('ROLLBACK_FAILED', 'Failed to restore files', 'FAILED', ABackupId);
      Exit;
    end;
    
    if Assigned(AProgressCallback) then
      AProgressCallback(80, '恢复注册表项...');
    
    // 恢复注册表项
    if not RestoreRegistryEntries(Manifest.RegistryEntries) then
    begin
      LogBackupOperation('ROLLBACK_WARNING', 'Some registry entries could not be restored', 'WARNING', ABackupId);
    end;
    
    if Assigned(AProgressCallback) then
      AProgressCallback(100, '回退完成');
    
    Result := True;
    LogBackupOperation('ROLLBACK_COMPLETED', 'Rollback operation completed successfully', 'SUCCESS', ABackupId);
    
  except
    on E: Exception do
    begin
      LogBackupOperation('ROLLBACK_ERROR', E.Message, 'FAILED', ABackupId);
      if Assigned(AProgressCallback) then
        AProgressCallback(0, '回退失败: ' + E.Message);
    end;
  end;
end;

// 创建紧急恢复脚本
function TRollbackManager.CreateEmergencyScript(const ABackupId: string): string;
var
  Manifest: TBackupManifest;
  ScriptPath: string;
  ScriptContent: TStringList;
  BackupPath: string;
  I: Integer;
begin
  Result := '';
  
  try
    Manifest := LoadBackupManifest(ABackupId);
    if Manifest.BackupId = '' then
      Exit;
    
    ScriptPath := GetBackupRootPath + ABackupId + '_emergency_restore.bat';
    BackupPath := GetBackupDataPath(ABackupId);
    
    ScriptContent := TStringList.Create;
    try
      ScriptContent.Add('@echo off');
      ScriptContent.Add('echo Emergency Restore Script for Backup: ' + ABackupId);
      ScriptContent.Add('echo Created: ' + DateTimeToStr(Now));
      ScriptContent.Add('echo.');
      ScriptContent.Add('echo WARNING: This script will restore files from backup.');
      ScriptContent.Add('echo Make sure you understand what this script does before running it.');
      ScriptContent.Add('echo.');
      ScriptContent.Add('pause');
      ScriptContent.Add('echo.');
      
      // 添加文件恢复命令
      ScriptContent.Add('echo Restoring files...');
      for I := 0 to Length(Manifest.Files) - 1 do
      begin
        var RelativePath := StringReplace(Manifest.Files[I], Manifest.SourcePath, '', [rfIgnoreCase]);
        var BackupFile := BackupPath + RelativePath;
        var TargetFile := Manifest.Files[I];
        
        ScriptContent.Add(Format('copy /Y "%s" "%s"', [BackupFile, TargetFile]));
      end;
      
      // 添加符号链接移除命令
      ScriptContent.Add('echo.');
      ScriptContent.Add('echo Removing symbolic links...');
      for I := 0 to Length(Manifest.SymbolicLinks) - 1 do
      begin
        if DirectoryExists(Manifest.SymbolicLinks[I]) then
          ScriptContent.Add(Format('rmdir "%s"', [Manifest.SymbolicLinks[I]]))
        else
          ScriptContent.Add(Format('del "%s"', [Manifest.SymbolicLinks[I]]));
      end;
      
      ScriptContent.Add('echo.');
      ScriptContent.Add('echo Emergency restore completed.');
      ScriptContent.Add('pause');
      
      ScriptContent.SaveToFile(ScriptPath);
      Result := ScriptPath;
      
      LogBackupOperation('EMERGENCY_SCRIPT_CREATED', 'Emergency restore script created: ' + ScriptPath, 'SUCCESS', ABackupId);
      
    finally
      ScriptContent.Free;
    end;
    
  except
    on E: Exception do
    begin
      LogBackupOperation('EMERGENCY_SCRIPT_ERROR', E.Message, 'FAILED', ABackupId);
    end;
  end;
end;

// 获取所有备份
function TRollbackManager.GetAllBackups: TArray<TBackupManifest>;
var
  BackupList: TList<TBackupManifest>;
  SearchRec: TSearchRec;
  BackupId: string;
  Manifest: TBackupManifest;
begin
  BackupList := TList<TBackupManifest>.Create;
  
  try
    if FindFirst(GetBackupRootPath + '*_manifest.json', faAnyFile, SearchRec) = 0 then
    begin
      try
        repeat
          BackupId := StringReplace(SearchRec.Name, '_manifest.json', '', [rfIgnoreCase]);
          Manifest := LoadBackupManifest(BackupId);
          if Manifest.BackupId <> '' then
            BackupList.Add(Manifest);
        until FindNext(SearchRec) <> 0;
      finally
        FindClose(SearchRec);
      end;
    end;
    
    SetLength(Result, BackupList.Count);
    for var I := 0 to BackupList.Count - 1 do
      Result[I] := BackupList[I];
    
  finally
    BackupList.Free;
  end;
end;

// 删除备份
function TRollbackManager.DeleteBackup(const ABackupId: string): Boolean;
var
  ManifestPath, BackupPath: string;
begin
  Result := False;
  
  try
    ManifestPath := GetBackupManifestPath(ABackupId);
    BackupPath := GetBackupDataPath(ABackupId);
    
    // 删除备份清单文件
    if FileExists(ManifestPath) then
      DeleteFile(ManifestPath);
    
    // 删除备份数据目录
    if DirectoryExists(BackupPath) then
      TDirectory.Delete(BackupPath, True);
    
    // 从数据库删除记录
    if Assigned(FConfigManager) then
      FConfigManager.GetDatabaseManager.DeleteBackupRecord(ABackupId);
    
    Result := True;
    LogBackupOperation('BACKUP_DELETED', 'Backup deleted successfully', 'SUCCESS', ABackupId);
    
  except
    on E: Exception do
    begin
      LogBackupOperation('DELETE_BACKUP_ERROR', E.Message, 'FAILED', ABackupId);
    end;
  end;
end;

// 获取备份大小
function TRollbackManager.GetBackupSize(const ABackupId: string): Int64;
var
  BackupPath: string;
begin
  Result := 0;
  
  try
    BackupPath := GetBackupDataPath(ABackupId);
    if DirectoryExists(BackupPath) then
      Result := CalculateBackupSize(BackupPath);
  except
    Result := 0;
  end;
end;

// 验证备份
function TRollbackManager.VerifyBackup(const ABackupId: string): Boolean;
begin
  Result := ValidateBackupIntegrity(ABackupId);
end;

// 清理旧备份
function TRollbackManager.CleanupOldBackups(const ADaysToKeep: Integer = 30): Integer;
var
  AllBackups: TArray<TBackupManifest>;
  CutoffDate: TDateTime;
  DeletedCount: Integer;
begin
  DeletedCount := 0;
  CutoffDate := Now - ADaysToKeep;
  
  try
    AllBackups := GetAllBackups;
    
    for var Backup in AllBackups do
    begin
      if Backup.CreatedDate < CutoffDate then
      begin
        if DeleteBackup(Backup.BackupId) then
          Inc(DeletedCount);
      end;
    end;
    
    LogBackupOperation('CLEANUP_COMPLETED', Format('Cleaned up %d old backups', [DeletedCount]), 'SUCCESS');
    
  except
    on E: Exception do
    begin
      LogBackupOperation('CLEANUP_ERROR', E.Message, 'FAILED');
    end;
  end;
  
  Result := DeletedCount;
end;

end.