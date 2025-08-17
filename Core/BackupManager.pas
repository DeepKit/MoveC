unit BackupManager;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections,
  System.JSON, Winapi.Windows, System.Win.Registry, DataTypes, ConfigManager;

type
  // 备份项类型
  TBackupItemType = (bitFile, bitDirectory, bitRegistry, bitSymlink, bitService);
  
  // 备份项信息
  TBackupItem = record
    ItemType: TBackupItemType;
    SourcePath: string;
    BackupPath: string;
    Size: Int64;
    Checksum: string;
    Timestamp: TDateTime;
    Attributes: DWORD;
    IsCompressed: Boolean;
    Priority: Integer;
    Description: string;
  end;
  
  // 备份清单
  TBackupManifest = record
    BackupId: string;
    CreatedTime: TDateTime;
    Description: string;
    TotalItems: Integer;
    TotalSize: Int64;
    BackupPath: string;
    Items: TArray<TBackupItem>;
    Metadata: TDictionary<string, string>;
  end;
  
  // 备份选项
  TBackupOptions = record
    CompressFiles: Boolean;
    VerifyBackup: Boolean;
    IncludeRegistry: Boolean;
    IncludeServices: Boolean;
    MaxBackupSize: Int64;
    RetentionDays: Integer;
    BackupLocation: string;
  end;
  
  // 备份管理器
  TBackupManager = class
  private
    FConfigManager: TConfigManager;
    FOptions: TBackupOptions;
    FCurrentManifest: TBackupManifest;
    
    function CreateBackupItem(const ASourcePath: string; AType: TBackupItemType): TBackupItem;
    function BackupFile(const AItem: TBackupItem): Boolean;
    function BackupDirectory(const AItem: TBackupItem): Boolean;
    function BackupRegistry(const AItem: TBackupItem): Boolean;
    function BackupSymlink(const AItem: TBackupItem): Boolean;
    function CalculateChecksum(const AFilePath: string): string;
    function CompressFile(const ASourcePath, ATargetPath: string): Boolean;
    
  public
    constructor Create(AConfigManager: TConfigManager = nil);
    destructor Destroy; override;
    
    function CreateBackup(const APaths: TArray<string>; const ADescription: string): string;
    function SaveManifest(const AManifest: TBackupManifest; const AFilePath: string): Boolean;
    function LoadManifest(const AFilePath: string): TBackupManifest;
    function VerifyBackup(const ABackupId: string): Boolean;
    function CleanupOldBackups: Integer;
    
    procedure SetOptions(const AOptions: TBackupOptions);
    function GetOptions: TBackupOptions;
  end;

implementation

uses
  System.Hash, System.DateUtils, System.Zip;

constructor TBackupManager.Create(AConfigManager: TConfigManager);
begin
  inherited Create;
  
  if Assigned(AConfigManager) then
    FConfigManager := AConfigManager
  else
    FConfigManager := TConfigManager.Create;
    
  // 设置默认选项
  FOptions.CompressFiles := True;
  FOptions.VerifyBackup := True;
  FOptions.IncludeRegistry := True;
  FOptions.IncludeServices := False;
  FOptions.MaxBackupSize := 10 * 1024 * 1024 * 1024; // 10GB
  FOptions.RetentionDays := 30;
  FOptions.BackupLocation := TPath.Combine(TPath.GetDocumentsPath, 'DiskCleanup_Backups');
end;

destructor TBackupManager.Destroy;
begin
  if Assigned(FCurrentManifest.Metadata) then
    FCurrentManifest.Metadata.Free;
    
  if Assigned(FConfigManager) then
    FConfigManager.Free;
    
  inherited;
end;

function TBackupManager.CreateBackup(const APaths: TArray<string>; const ADescription: string): string;
var
  I: Integer;
  Item: TBackupItem;
  BackupItems: TList<TBackupItem>;
  BackupDir: string;
begin
  Result := '';
  BackupItems := TList<TBackupItem>.Create;
  
  try
    // 初始化备份清单
    FillChar(FCurrentManifest, SizeOf(FCurrentManifest), 0);
    FCurrentManifest.BackupId := FormatDateTime('yyyymmdd_hhnnss', Now) + '_' + IntToStr(Random(1000));
    FCurrentManifest.CreatedTime := Now;
    FCurrentManifest.Description := ADescription;
    FCurrentManifest.Metadata := TDictionary<string, string>.Create;
    
    // 创建备份目录
    BackupDir := TPath.Combine(FOptions.BackupLocation, FCurrentManifest.BackupId);
    if not TDirectory.Exists(BackupDir) then
      TDirectory.CreateDirectory(BackupDir);
    
    FCurrentManifest.BackupPath := BackupDir;
    
    // 处理每个路径
    for I := 0 to Length(APaths) - 1 do
    begin
      if TFile.Exists(APaths[I]) then
        Item := CreateBackupItem(APaths[I], bitFile)
      else if TDirectory.Exists(APaths[I]) then
        Item := CreateBackupItem(APaths[I], bitDirectory)
      else
        Continue;
      
      BackupItems.Add(Item);
    end;
    
    // 执行备份
    FCurrentManifest.TotalItems := BackupItems.Count;
    FCurrentManifest.TotalSize := 0;
    
    SetLength(FCurrentManifest.Items, BackupItems.Count);
    for I := 0 to BackupItems.Count - 1 do
    begin
      Item := BackupItems[I];
      
      case Item.ItemType of
        bitFile: BackupFile(Item);
        bitDirectory: BackupDirectory(Item);
        bitRegistry: BackupRegistry(Item);
        bitSymlink: BackupSymlink(Item);
      end;
      
      FCurrentManifest.Items[I] := Item;
      FCurrentManifest.TotalSize := FCurrentManifest.TotalSize + Item.Size;
    end;
    
    // 保存清单
    var ManifestPath := TPath.Combine(BackupDir, 'manifest.json');
    if SaveManifest(FCurrentManifest, ManifestPath) then
      Result := FCurrentManifest.BackupId;
    
    if Assigned(FConfigManager) then
      FConfigManager.LogOperation('BACKUP', 'Backup created', '', BackupDir, 'SUCCESS', 
        Format('Items: %d, Size: %d', [FCurrentManifest.TotalItems, FCurrentManifest.TotalSize]));
    
  finally
    BackupItems.Free;
  end;
end;

function TBackupManager.CreateBackupItem(const ASourcePath: string; AType: TBackupItemType): TBackupItem;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.ItemType := AType;
  Result.SourcePath := ASourcePath;
  Result.BackupPath := TPath.Combine(FCurrentManifest.BackupPath, ExtractFileName(ASourcePath));
  Result.Timestamp := Now;
  Result.Priority := 1;
  Result.Description := ExtractFileName(ASourcePath);
  
  if TFile.Exists(ASourcePath) then
  begin
    Result.Size := TFile.GetSize(ASourcePath);
    Result.Attributes := GetFileAttributes(PChar(ASourcePath));
    if FOptions.VerifyBackup then
      Result.Checksum := CalculateChecksum(ASourcePath);
  end;
end;

function TBackupManager.BackupFile(const AItem: TBackupItem): Boolean;
begin
  Result := False;
  
  try
    if FOptions.CompressFiles then
      Result := CompressFile(AItem.SourcePath, AItem.BackupPath + '.zip')
    else
      Result := TFile.Copy(AItem.SourcePath, AItem.BackupPath, True);
    
  except
    on E: Exception do
    begin
      Result := False;
      if Assigned(FConfigManager) then
        FConfigManager.LogOperation('BACKUP', 'File backup failed', AItem.SourcePath, AItem.BackupPath, 'ERROR', E.Message);
    end;
  end;
end;

function TBackupManager.BackupDirectory(const AItem: TBackupItem): Boolean;
begin
  Result := False;
  
  try
    if FOptions.CompressFiles then
    begin
      TZipFile.ZipDirectoryContents(AItem.BackupPath + '.zip', AItem.SourcePath);
      Result := TFile.Exists(AItem.BackupPath + '.zip');
    end
    else
    begin
      TDirectory.Copy(AItem.SourcePath, AItem.BackupPath);
      Result := TDirectory.Exists(AItem.BackupPath);
    end;
    
  except
    on E: Exception do
    begin
      Result := False;
      if Assigned(FConfigManager) then
        FConfigManager.LogOperation('BACKUP', 'Directory backup failed', AItem.SourcePath, AItem.BackupPath, 'ERROR', E.Message);
    end;
  end;
end;

function TBackupManager.BackupRegistry(const AItem: TBackupItem): Boolean;
begin
  Result := False;
  
  try
    // 简化实现：使用reg export命令
    var CmdLine := Format('reg export "%s" "%s.reg" /y', [AItem.SourcePath, AItem.BackupPath]);
    var ExitCode := 0;
    
    if ShellExecute(0, 'open', 'cmd.exe', PChar('/C ' + CmdLine), nil, SW_HIDE) > 32 then
    begin
      Sleep(2000); // 等待命令执行
      Result := TFile.Exists(AItem.BackupPath + '.reg');
    end;
    
  except
    Result := False;
  end;
end;

function TBackupManager.BackupSymlink(const AItem: TBackupItem): Boolean;
begin
  Result := False;
  
  try
    // 备份符号链接信息到JSON文件
    var LinkInfo := TJSONObject.Create;
    try
      LinkInfo.AddPair('source', AItem.SourcePath);
      LinkInfo.AddPair('target', ''); // 这里应该获取实际目标
      LinkInfo.AddPair('type', 'symlink');
      LinkInfo.AddPair('timestamp', DateTimeToStr(Now));
      
      TFile.WriteAllText(AItem.BackupPath + '.json', LinkInfo.ToString);
      Result := True;
      
    finally
      LinkInfo.Free;
    end;
    
  except
    Result := False;
  end;
end;

function TBackupManager.CalculateChecksum(const AFilePath: string): string;
var
  FileStream: TFileStream;
  Hash: THashMD5;
begin
  Result := '';
  
  try
    FileStream := TFileStream.Create(AFilePath, fmOpenRead or fmShareDenyWrite);
    try
      Hash := THashMD5.Create;
      Hash.Update(FileStream);
      Result := Hash.HashAsString;
    finally
      FileStream.Free;
    end;
  except
    Result := '';
  end;
end;

function TBackupManager.CompressFile(const ASourcePath, ATargetPath: string): Boolean;
begin
  Result := False;
  
  try
    var ZipFile := TZipFile.Create;
    try
      ZipFile.Open(ATargetPath, zmWrite);
      ZipFile.Add(ASourcePath, ExtractFileName(ASourcePath));
      ZipFile.Close;
      Result := True;
    finally
      ZipFile.Free;
    end;
  except
    Result := False;
  end;
end;

function TBackupManager.SaveManifest(const AManifest: TBackupManifest; const AFilePath: string): Boolean;
var
  JSONObj, ItemsArray, ItemObj: TJSONObject;
  I: Integer;
begin
  Result := False;
  
  try
    JSONObj := TJSONObject.Create;
    try
      JSONObj.AddPair('backupId', AManifest.BackupId);
      JSONObj.AddPair('createdTime', DateTimeToStr(AManifest.CreatedTime));
      JSONObj.AddPair('description', AManifest.Description);
      JSONObj.AddPair('totalItems', TJSONNumber.Create(AManifest.TotalItems));
      JSONObj.AddPair('totalSize', TJSONNumber.Create(AManifest.TotalSize));
      JSONObj.AddPair('backupPath', AManifest.BackupPath);
      
      ItemsArray := TJSONObject.Create;
      for I := 0 to Length(AManifest.Items) - 1 do
      begin
        ItemObj := TJSONObject.Create;
        ItemObj.AddPair('itemType', TJSONNumber.Create(Ord(AManifest.Items[I].ItemType)));
        ItemObj.AddPair('sourcePath', AManifest.Items[I].SourcePath);
        ItemObj.AddPair('backupPath', AManifest.Items[I].BackupPath);
        ItemObj.AddPair('size', TJSONNumber.Create(AManifest.Items[I].Size));
        ItemObj.AddPair('checksum', AManifest.Items[I].Checksum);
        ItemObj.AddPair('timestamp', DateTimeToStr(AManifest.Items[I].Timestamp));
        
        ItemsArray.AddPair('item' + IntToStr(I), ItemObj);
      end;
      JSONObj.AddPair('items', ItemsArray);
      
      TFile.WriteAllText(AFilePath, JSONObj.ToString, TEncoding.UTF8);
      Result := True;
      
    finally
      JSONObj.Free;
    end;
  except
    Result := False;
  end;
end;

function TBackupManager.LoadManifest(const AFilePath: string): TBackupManifest;
var
  JSONStr: string;
  JSONObj, ItemsObj, ItemObj: TJSONObject;
  I: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  
  try
    if not TFile.Exists(AFilePath) then
      Exit;
    
    JSONStr := TFile.ReadAllText(AFilePath, TEncoding.UTF8);
    JSONObj := TJSONObject.ParseJSONValue(JSONStr) as TJSONObject;
    
    try
      Result.BackupId := JSONObj.GetValue('backupId').Value;
      Result.CreatedTime := StrToDateTime(JSONObj.GetValue('createdTime').Value);
      Result.Description := JSONObj.GetValue('description').Value;
      Result.TotalItems := (JSONObj.GetValue('totalItems') as TJSONNumber).AsInt;
      Result.TotalSize := (JSONObj.GetValue('totalSize') as TJSONNumber).AsInt64;
      Result.BackupPath := JSONObj.GetValue('backupPath').Value;
      
      ItemsObj := JSONObj.GetValue('items') as TJSONObject;
      SetLength(Result.Items, Result.TotalItems);
      
      for I := 0 to Result.TotalItems - 1 do
      begin
        ItemObj := ItemsObj.GetValue('item' + IntToStr(I)) as TJSONObject;
        
        Result.Items[I].ItemType := TBackupItemType((ItemObj.GetValue('itemType') as TJSONNumber).AsInt);
        Result.Items[I].SourcePath := ItemObj.GetValue('sourcePath').Value;
        Result.Items[I].BackupPath := ItemObj.GetValue('backupPath').Value;
        Result.Items[I].Size := (ItemObj.GetValue('size') as TJSONNumber).AsInt64;
        Result.Items[I].Checksum := ItemObj.GetValue('checksum').Value;
        Result.Items[I].Timestamp := StrToDateTime(ItemObj.GetValue('timestamp').Value);
      end;
      
    finally
      JSONObj.Free;
    end;
  except
    FillChar(Result, SizeOf(Result), 0);
  end;
end;

function TBackupManager.VerifyBackup(const ABackupId: string): Boolean;
var
  ManifestPath: string;
  Manifest: TBackupManifest;
  I: Integer;
  ActualChecksum: string;
begin
  Result := False;
  
  try
    ManifestPath := TPath.Combine(TPath.Combine(FOptions.BackupLocation, ABackupId), 'manifest.json');
    Manifest := LoadManifest(ManifestPath);
    
    if Length(Manifest.BackupId) = 0 then
      Exit;
    
    Result := True;
    
    for I := 0 to Length(Manifest.Items) - 1 do
    begin
      if not TFile.Exists(Manifest.Items[I].BackupPath) then
      begin
        Result := False;
        Break;
      end;
      
      if Length(Manifest.Items[I].Checksum) > 0 then
      begin
        ActualChecksum := CalculateChecksum(Manifest.Items[I].BackupPath);
        if not SameText(ActualChecksum, Manifest.Items[I].Checksum) then
        begin
          Result := False;
          Break;
        end;
      end;
    end;
    
  except
    Result := False;
  end;
end;

function TBackupManager.CleanupOldBackups: Integer;
var
  BackupDirs: TArray<string>;
  I: Integer;
  DirName: string;
  DirDate: TDateTime;
  CutoffDate: TDateTime;
begin
  Result := 0;
  
  try
    if not TDirectory.Exists(FOptions.BackupLocation) then
      Exit;
    
    BackupDirs := TDirectory.GetDirectories(FOptions.BackupLocation);
    CutoffDate := Now - FOptions.RetentionDays;
    
    for I := 0 to Length(BackupDirs) - 1 do
    begin
      DirName := ExtractFileName(BackupDirs[I]);
      
      // 尝试从目录名解析日期
      try
        if Length(DirName) >= 8 then
        begin
          var DateStr := Copy(DirName, 1, 8);
          DirDate := StrToDate(Copy(DateStr, 1, 4) + '-' + Copy(DateStr, 5, 2) + '-' + Copy(DateStr, 7, 2));
          
          if DirDate < CutoffDate then
          begin
            TDirectory.Delete(BackupDirs[I], True);
            Inc(Result);
          end;
        end;
      except
        // 忽略日期解析错误
      end;
    end;
    
  except
    // 忽略清理错误
  end;
end;

procedure TBackupManager.SetOptions(const AOptions: TBackupOptions);
begin
  FOptions := AOptions;
end;

function TBackupManager.GetOptions: TBackupOptions;
begin
  Result := FOptions;
end;

end.