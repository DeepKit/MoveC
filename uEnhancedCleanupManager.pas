unit uEnhancedCleanupManager;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShellAPI, Winapi.ShlObj,
  System.SysUtils, System.Classes, System.IOUtils, System.Variants,
  System.Generics.Collections, System.Math, System.Win.Registry,
  System.JSON, Vcl.Forms, Vcl.Dialogs, uCleanupManager;

type
  // 清理项目类型
  TCleanupItemType = (
    ciRecycleBin,
    ciTempFiles,
    ciBrowserCache,
    ciWindowsUpdate,
    ciSystemLogs,
    ciPrefetch,
    ciRegistryJunk,
    ciCustomPath
  );
  
  // 清理项目状态
  TCleanupItemStatus = (
    csPending,      // 待清理
    csPreviewing,   // 预览中
    csCleaning,     // 清理中
    csCompleted,    // 已完成
    csFailed,       // 失败
    csSkipped       // 跳过
  );
  
  // 清理项目信息
  TCleanupItem = record
    ItemType: TCleanupItemType;
    ItemName: string;
    ItemPath: string;
    ItemSize: Int64;
    FileCount: Integer;
    Status: TCleanupItemStatus;
    IsSafe: Boolean;
    RiskLevel: Integer;    // 0-10，0最安全，10最危险
    Description: string;
    LastModified: TDateTime;
  end;
  
  // 清理预览结果
  TCleanupPreview = record
    TotalItems: Integer;
    TotalSize: Int64;
    TotalFiles: Integer;
    SafeItems: Integer;
    RiskyItems: Integer;
    Items: TArray<TCleanupItem>;
    EstimatedTime: Integer; // 预计清理时间（秒）
  end;
  
  // 清理历史记录
  TCleanupHistory = record
    Timestamp: TDateTime;
    CleanupType: string;
    ItemsCleaned: Integer;
    FilesDeleted: Integer;
    SpaceFreed: Int64;
    Duration: Integer; // 清理耗时（秒）
    Success: Boolean;
    ErrorMessage: string;
  end;
  
  // 安全级别
  TSafetyLevel = (
    slConservative,  // 保守模式 - 只清理最安全的项目
    slStandard,      // 标准模式 - 清理常见安全项目
    slAggressive     // 激进模式 - 清理更多项目但有风险
  );
  
  // 增强的清理进度回调
  TEnhancedProgressCallback = procedure(const AMessage: string; AProgress: Integer; 
    const ACurrentItem: string) of object;
  
  // 清理确认回调
  TCleanupConfirmCallback = function(const AItem: TCleanupItem): Boolean of object;
  
  // 增强的清理管理器
  TEnhancedCleanupManager = class(TCleanupManager)
  private
    FSafetyLevel: TSafetyLevel;
    FPreviewCallback: TEnhancedProgressCallback;
    FConfirmCallback: TCleanupConfirmCallback;
    FCleanupHistory: TList<TCleanupHistory>;
    FMaxHistoryCount: Integer;
    
    // 预览相关方法
    function PreviewRecycleBin: TArray<TCleanupItem>;
    function PreviewTempFiles: TArray<TCleanupItem>;
    function PreviewBrowserCache: TArray<TCleanupItem>;
    function PreviewWindowsUpdate: TArray<TCleanupItem>;
    function PreviewSystemLogs: TArray<TCleanupItem>;
    function PreviewPrefetchFiles: TArray<TCleanupItem>;
    function PreviewCustomPath(const APath: string): TArray<TCleanupItem>;
    
    // 安全检查增强
    function IsSafeToDeleteEnhanced(const APath: string; var ARiskLevel: Integer): Boolean;
    function CheckFileAge(const APath: string): Boolean;
    function CheckFileUsage(const APath: string): Boolean;
    function CheckSystemProtection(const APath: string): Boolean;
    
    // 历史记录管理
    procedure AddCleanupHistory(const AHistory: TCleanupHistory);
    procedure SaveCleanupHistory;
    procedure LoadCleanupHistory;
    function GetHistoryFilePath: string;
    
    // 清理执行增强
    function CleanItemEnhanced(var AItem: TCleanupItem): Boolean;
    procedure UpdateProgressEnhanced(const AMessage: string; AProgress: Integer; 
      const ACurrentItem: string);
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // 预览功能
    function PreviewCleanup(const AItemTypes: TArray<TCleanupItemType>): TCleanupPreview;
    function PreviewAllCleanup: TCleanupPreview;
    
    // 增强的清理方法
    function PerformEnhancedCleanup(const APreview: TCleanupPreview): TCleanupResult;
    function CleanItemByType(const AItemType: TCleanupItemType): TCleanupResult;
    
    // 安全控制
    property SafetyLevel: TSafetyLevel read FSafetyLevel write FSafetyLevel;
    function SetSafetyLevel(const ALevel: TSafetyLevel): Boolean;
    
    // 历史记录
    function GetCleanupHistory: TArray<TCleanupHistory>;
    procedure ClearCleanupHistory;
    property MaxHistoryCount: Integer read FMaxHistoryCount write FMaxHistoryCount;
    
    // 统计信息
    function GetTotalCleanedSpace: Int64;
    function GetCleanupStatistics: TJSONObject;
    
    // 回调设置
    property OnPreviewProgress: TEnhancedProgressCallback read FPreviewCallback write FPreviewCallback;
    property OnCleanupConfirm: TCleanupConfirmCallback read FConfirmCallback write FConfirmCallback;
  end;

// 全局函数
function CleanupItemTypeToString(const AType: TCleanupItemType): string;
function SafetyLevelToString(const ALevel: TSafetyLevel): string;
function GetDefaultSafetyLevel: TSafetyLevel;
function FormatFileSize(const ASize: Int64): string;
procedure ComputeDirectoryStats(const APath: string; var AFileCount: Integer; var ATotalSize: Int64);

implementation

uses
  System.StrUtils, System.DateUtils, System.JSON.Types;

{ 全局函数 }

function CleanupItemTypeToString(const AType: TCleanupItemType): string;
begin
  case AType of
    ciRecycleBin: Result := '回收站';
    ciTempFiles: Result := '临时文件';
    ciBrowserCache: Result := '浏览器缓存';
    ciWindowsUpdate: Result := 'Windows更新缓存';
    ciSystemLogs: Result := '系统日志';
    ciPrefetch: Result := '预取文件';
    ciRegistryJunk: Result := '注册表垃圾';
    ciCustomPath: Result := '自定义路径';
  else
    Result := '未知类型';
  end;
end;

function SafetyLevelToString(const ALevel: TSafetyLevel): string;
begin
  case ALevel of
    slConservative: Result := '保守模式';
    slStandard: Result := '标准模式';
    slAggressive: Result := '激进模式';
  else
    Result := '未知级别';
  end;
end;

function GetDefaultSafetyLevel: TSafetyLevel;
begin
  Result := slStandard;
end;

function FormatFileSize(const ASize: Int64): string;
begin
  if ASize < 1024 then
    Result := Format('%d 字节', [ASize])
  else if ASize < 1024 * 1024 then
    Result := Format('%.1f KB', [ASize / 1024.0])
  else if ASize < 1024 * 1024 * 1024 then
    Result := Format('%.1f MB', [ASize / (1024.0 * 1024.0)])
  else
    Result := Format('%.2f GB', [ASize / (1024.0 * 1024.0 * 1024.0)]);
end;

procedure ComputeDirectoryStats(const APath: string; var AFileCount: Integer; var ATotalSize: Int64);
var
  Files: TArray<string>;
  Dirs: TArray<string>;
  I: Integer;
begin
  try
    // 统计文件
    Files := TDirectory.GetFiles(APath);
    for I := 0 to High(Files) do
    begin
      try
        Inc(AFileCount);
        ATotalSize := ATotalSize + TFile.GetSize(Files[I]);
      except
        // 忽略无法访问的文件
      end;
    end;

    // 递归统计子目录
    Dirs := TDirectory.GetDirectories(APath);
    for I := 0 to High(Dirs) do
    begin
      try
        ComputeDirectoryStats(Dirs[I], AFileCount, ATotalSize);
      except
        // 忽略无法访问的目录
      end;
    end;
  except
    // 忽略访问权限错误
  end;
end;

{ TEnhancedCleanupManager }

constructor TEnhancedCleanupManager.Create;
begin
  inherited Create;
  FSafetyLevel := GetDefaultSafetyLevel;
  FCleanupHistory := TList<TCleanupHistory>.Create;
  FMaxHistoryCount := 100;
  LoadCleanupHistory;
end;

destructor TEnhancedCleanupManager.Destroy;
begin
  SaveCleanupHistory;
  FreeAndNil(FCleanupHistory);
  inherited Destroy;
end;

function TEnhancedCleanupManager.PreviewCleanup(const AItemTypes: TArray<TCleanupItemType>): TCleanupPreview;
var
  AllItems: TList<TCleanupItem>;
  ItemType: TCleanupItemType;
  Items: TArray<TCleanupItem>;
  TotalSize, StartTime: Int64;
  I: Integer;
begin
  AllItems := TList<TCleanupItem>.Create;
  StartTime := TDateTime.Now;
  
  try
    UpdateProgressEnhanced('开始预览清理项目...', 0, '');
    
    // 预览各种类型的清理项目
    for ItemType in AItemTypes do
    begin
      UpdateProgressEnhanced('预览 ' + CleanupItemTypeToString(ItemType) + '...', 
        Trunc(AllItems.Count * 100.0 / Length(AItemTypes)), '');
      
      case ItemType of
        ciRecycleBin: Items := PreviewRecycleBin;
        ciTempFiles: Items := PreviewTempFiles;
        ciBrowserCache: Items := PreviewBrowserCache;
        ciWindowsUpdate: Items := PreviewWindowsUpdate;
        ciSystemLogs: Items := PreviewSystemLogs;
        ciPrefetch: Items := PreviewPrefetchFiles;
        ciCustomPath: Items := []; // 需要额外参数
      else
        Items := [];
      end;
      
      // 根据安全级别过滤项目
      for I := 0 to High(Items) do
      begin
        case FSafetyLevel of
          slConservative: 
            if Items[I].IsSafe and (Items[I].RiskLevel <= 2) then
              AllItems.Add(Items[I]);
          slStandard: 
            if Items[I].IsSafe and (Items[I].RiskLevel <= 5) then
              AllItems.Add(Items[I]);
          slAggressive: 
            AllItems.Add(Items[I]); // 包含所有项目
        end;
      end;
    end;
    
    // 计算统计信息
    TotalSize := 0;
    Result.TotalItems := AllItems.Count;
    Result.SafeItems := 0;
    Result.RiskyItems := 0;
    Result.TotalFiles := 0;
    
    for I := 0 to AllItems.Count - 1 do
    begin
      Inc(TotalSize, AllItems[I].ItemSize);
      Inc(Result.TotalFiles, AllItems[I].FileCount);
      if AllItems[I].IsSafe then
        Inc(Result.SafeItems)
      else
        Inc(Result.RiskyItems);
    end;
    
    Result.TotalSize := TotalSize;
    Result.Items := AllItems.ToArray;
    Result.EstimatedTime := Trunc(TotalSize / (100 * 1024 * 1024)); // 假设每秒100MB
    
    UpdateProgressEnhanced('预览完成', 100, Format('找到 %d 个清理项目，可释放 %s 空间', 
      [Result.TotalItems, FormatFileSize(TotalSize)]));
      
  finally
    AllItems.Free;
  end;
end;

function TEnhancedCleanupManager.PreviewAllCleanup: TCleanupPreview;
begin
  Result := PreviewCleanup([
    TCleanupItemType.ciRecycleBin,
    TCleanupItemType.ciTempFiles,
    TCleanupItemType.ciBrowserCache,
    TCleanupItemType.ciWindowsUpdate,
    TCleanupItemType.ciSystemLogs,
    TCleanupItemType.ciPrefetch
  ]);
end;

function TEnhancedCleanupManager.PreviewRecycleBin: TArray<TCleanupItem>;
var
  Item: TCleanupItem;
  RecyclePath: string;
begin
  SetLength(Result, 0);
  
  RecyclePath := GetRecycleBinPath;
  if not TDirectory.Exists(RecyclePath) then Exit;
  
  Item.ItemType := ciRecycleBin;
  Item.ItemName := '回收站';
  Item.ItemPath := RecyclePath;
  Item.Status := csPending;
  Item.IsSafe := True;
  Item.RiskLevel := 0;
  Item.Description := '清空回收站中的所有文件';
  Item.LastModified := Now;
  
  // 计算回收站大小和文件数量
  try
    ComputeDirectoryStats(RecyclePath, Item.FileCount, Item.ItemSize);
  except
    Item.FileCount := 0;
    Item.ItemSize := 0;
  end;
  
  SetLength(Result, 1);
  Result[0] := Item;
end;

function TEnhancedCleanupManager.PreviewTempFiles: TArray<TCleanupItem>;
var
  Item: TCleanupItem;
  TempPaths: TArray<string>;
  TempPath: string;
  Items: TList<TCleanupItem>;
begin
  Items := TList<TCleanupItem>.Create;
  try
    TempPaths := GetSystemTempPaths;
    
    for TempPath in TempPaths do
    begin
      if TDirectory.Exists(TempPath) then
      begin
        Item.ItemType := ciTempFiles;
        Item.ItemName := '临时文件 - ' + ExtractFileName(TempPath);
        Item.ItemPath := TempPath;
        Item.Status := csPending;
        Item.IsSafe := IsSafeToDeleteEnhanced(TempPath, Item.RiskLevel);
        Item.Description := '清理系统临时文件';
        Item.LastModified := Now;
        
        try
          ComputeDirectoryStats(TempPath, Item.FileCount, Item.ItemSize);
        except
          Item.FileCount := 0;
          Item.ItemSize := 0;
        end;
        
        Items.Add(Item);
      end;
    end;
    
    Result := Items.ToArray;
  finally
    Items.Free;
  end;
end;

function TEnhancedCleanupManager.PreviewBrowserCache: TArray<TCleanupItem>;
var
  Item: TCleanupItem;
  CachePaths: TArray<string>;
  CachePath: string;
  Items: TList<TCleanupItem>;
begin
  Items := TList<TCleanupItem>.Create;
  try
    CachePaths := GetBrowserCachePaths;
    
    for CachePath in CachePaths do
    begin
      if TDirectory.Exists(CachePath) then
      begin
        Item.ItemType := ciBrowserCache;
        Item.ItemName := '浏览器缓存 - ' + ExtractFileName(ExtractFileDir(CachePath));
        Item.ItemPath := CachePath;
        Item.Status := csPending;
        Item.IsSafe := IsSafeToDeleteEnhanced(CachePath, Item.RiskLevel);
        Item.Description := '清理浏览器缓存文件';
        Item.LastModified := Now;
        
        try
          ComputeDirectoryStats(CachePath, Item.FileCount, Item.ItemSize);
        except
          Item.FileCount := 0;
          Item.ItemSize := 0;
        end;
        
        Items.Add(Item);
      end;
    end;
    
    Result := Items.ToArray;
  finally
    Items.Free;
  end;
end;

function TEnhancedCleanupManager.PreviewWindowsUpdate: TArray<TCleanupItem>;
var
  Item: TCleanupItem;
  UpdatePath: string;
begin
  SetLength(Result, 0);
  
  UpdatePath := GetWindowsUpdatePath;
  if not TDirectory.Exists(UpdatePath) then Exit;
  
  Item.ItemType := ciWindowsUpdate;
  Item.ItemName := 'Windows更新缓存';
  Item.ItemPath := UpdatePath;
  Item.Status := csPending;
  Item.IsSafe := True; // 更新缓存通常是安全的
  Item.RiskLevel := 1;
  Item.Description := '清理Windows更新下载的缓存文件';
  Item.LastModified := Now;
  
  try
    ComputeDirectoryStats(UpdatePath, Item.FileCount, Item.ItemSize);
  except
    Item.FileCount := 0;
    Item.ItemSize := 0;
  end;
  
  SetLength(Result, 1);
  Result[0] := Item;
end;

function TEnhancedCleanupManager.PreviewSystemLogs: TArray<TCleanupItem>;
var
  Item: TCleanupItem;
  LogPaths: TArray<string>;
  LogPath: string;
  Items: TList<TCleanupItem>;
begin
  Items := TList<TCleanupItem>.Create;
  try
    // 系统日志路径
    SetLength(LogPaths, 3);
    LogPaths[0] := 'C:\Windows\Logs';
    LogPaths[1] := 'C:\Windows\Debug';
    LogPaths[2] := 'C:\ProgramData\Microsoft\Windows\WER\ReportArchive';
    
    for LogPath in LogPaths do
    begin
      if TDirectory.Exists(LogPath) then
      begin
        Item.ItemType := ciSystemLogs;
        Item.ItemName := '系统日志 - ' + ExtractFileName(LogPath);
        Item.ItemPath := LogPath;
        Item.Status := csPending;
        Item.IsSafe := IsSafeToDeleteEnhanced(LogPath, Item.RiskLevel);
        Item.Description := '清理系统日志文件';
        Item.LastModified := Now;
        
        try
          ComputeDirectoryStats(LogPath, Item.FileCount, Item.ItemSize);
        except
          Item.FileCount := 0;
          Item.ItemSize := 0;
        end;
        
        Items.Add(Item);
      end;
    end;
    
    Result := Items.ToArray;
  finally
    Items.Free;
  end;
end;

function TEnhancedCleanupManager.PreviewPrefetchFiles: TArray<TCleanupItem>;
var
  Item: TCleanupItem;
  PrefetchPath: string;
begin
  SetLength(Result, 0);
  
  PrefetchPath := 'C:\Windows\Prefetch';
  if not TDirectory.Exists(PrefetchPath) then Exit;
  
  Item.ItemType := ciPrefetch;
  Item.ItemName := '预取文件';
  Item.ItemPath := PrefetchPath;
  Item.Status := csPending;
  Item.IsSafe := True;
  Item.RiskLevel := 1;
  Item.Description := '清理系统预取文件，系统会自动重建';
  Item.LastModified := Now;
  
  try
    ComputeDirectoryStats(PrefetchPath, Item.FileCount, Item.ItemSize);
  except
    Item.FileCount := 0;
    Item.ItemSize := 0;
  end;
  
  SetLength(Result, 1);
  Result[0] := Item;
end;

function TEnhancedCleanupManager.PerformEnhancedCleanup(const APreview: TCleanupPreview): TCleanupResult;
var
  I: Integer;
  Item: TCleanupItem;
  History: TCleanupHistory;
  StartTime: TDateTime;
begin
  Result.Success := True;
  Result.FilesDeleted := 0;
  Result.SpaceFreed := 0;
  Result.ErrorMessage := '';
  Result.Details := TStringList.Create;
  
  StartTime := Now;
  History.Timestamp := StartTime;
  History.CleanupType := '增强清理';
  History.ItemsCleaned := 0;
  History.FilesDeleted := 0;
  History.SpaceFreed := 0;
  History.Success := True;
  History.ErrorMessage := '';
  
  try
    UpdateProgressEnhanced('开始增强清理...', 0, '');
    
    for I := 0 to High(APreview.Items) do
    begin
      Item := APreview.Items[I];
      
      // 检查是否取消
      if IsCancelled then
      begin
        Result.Success := False;
        Result.ErrorMessage := '用户取消操作';
        History.Success := False;
        History.ErrorMessage := '用户取消操作';
        Break;
      end;
      
      // 确认清理
      if Assigned(FConfirmCallback) then
      begin
        if not FConfirmCallback(Item) then
        begin
          Result.Details.Add('跳过: ' + Item.ItemName);
          Continue;
        end;
      end;
      
      // 执行清理
      UpdateProgressEnhanced('清理 ' + Item.ItemName + '...', 
        Trunc(I * 100.0 / Length(APreview.Items)), Item.ItemName);
      
      Item.Status := csCleaning;
      
      if CleanItemEnhanced(Item) then
      begin
        Inc(Result.FilesDeleted, Item.FileCount);
        Inc(Result.SpaceFreed, Item.ItemSize);
        Inc(History.FilesDeleted, Item.FileCount);
        Inc(History.SpaceFreed, Item.ItemSize);
        Inc(History.ItemsCleaned);
        Result.Details.Add('成功: ' + Item.ItemName + ' - ' + 
          FormatFileSize(Item.ItemSize) + ', ' + IntToStr(Item.FileCount) + ' 个文件');
        Item.Status := csCompleted;
      end
      else
      begin
        Result.Details.Add('失败: ' + Item.ItemName);
        Item.Status := csFailed;
      end;
    end;
    
    History.Duration := Trunc(SecondsBetween(Now, StartTime));
    AddCleanupHistory(History);
    
    UpdateProgressEnhanced('清理完成', 100, Format('已清理 %d 个项目，释放 %s 空间', 
      [History.ItemsCleaned, FormatFileSize(History.SpaceFreed)]));
      
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.ErrorMessage := E.Message;
      History.Success := False;
      History.ErrorMessage := E.Message;
    end;
  end;
end;

function TEnhancedCleanupManager.CleanItemEnhanced(var AItem: TCleanupItem): Boolean;
begin
  Result := False;
  
  try
    case AItem.ItemType of
      ciRecycleBin: Result := EmptyRecycleBinInternal.Success;
      ciTempFiles: Result := CleanTempFilesInternal.Success;
      ciBrowserCache: Result := CleanBrowserCacheInternal.Success;
      ciWindowsUpdate: Result := CleanWindowsUpdateCacheInternal.Success;
      ciSystemLogs: Result := CleanSystemLogsInternal.Success;
      ciPrefetch: Result := CleanPrefetchFilesInternal.Success;
    else
      Result := False;
    end;
  except
    Result := False;
  end;
end;

function TEnhancedCleanupManager.IsSafeToDeleteEnhanced(const APath: string; var ARiskLevel: Integer): Boolean;
begin
  ARiskLevel := 0;
  Result := True;
  
  // 基础安全检查
  if not IsSafeToDelete(APath) then
  begin
    Result := False;
    ARiskLevel := 10;
    Exit;
  end;
  
  // 增强安全检查
  if not CheckFileAge(APath) then
    Inc(ARiskLevel, 2);
    
  if not CheckFileUsage(APath) then
    Inc(ARiskLevel, 3);
    
  if not CheckSystemProtection(APath) then
  begin
    Result := False;
    ARiskLevel := 8;
  end;
  
  // 路径风险评级
  if ContainsText(APath, 'System32') or ContainsText(APath, 'SysWOW64') then
  begin
    Result := False;
    ARiskLevel := 10;
  end
  else if ContainsText(APath, 'Program Files') then
    Inc(ARiskLevel, 5)
  else if ContainsText(APath, 'Windows') then
    Inc(ARiskLevel, 3)
  else if ContainsText(APath, 'Temp') or ContainsText(APath, 'Cache') then
    Inc(ARiskLevel, 0); // 最安全
end;

function TEnhancedCleanupManager.CheckFileAge(const APath: string): Boolean;
var
  Files: TArray<string>;
  FileAge: TDateTime;
  I: Integer;
begin
  Result := True;
  
  try
    Files := TDirectory.GetFiles(APath, '*', TSearchOption.soTopDirectoryOnly);
    for I := 0 to Min(9, High(Files)) do // 只检查前10个文件
    begin
      FileAge := TFile.GetLastWriteTime(Files[I]);
      if DaysBetween(Now, FileAge) < 7 then // 7天内的文件认为不安全
      begin
        Result := False;
        Break;
      end;
    end;
  except
    Result := False;
  end;
end;

function TEnhancedCleanupManager.CheckFileUsage(const APath: string): Boolean;
var
  Handle: THandle;
begin
  // 简单的文件占用检查
  Result := True;
  
  try
    Handle := CreateFile(PChar(APath), GENERIC_READ, FILE_SHARE_READ, 
      nil, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, 0);
    if Handle = INVALID_HANDLE_VALUE then
      Result := False
    else
      CloseHandle(Handle);
  except
    Result := False;
  end;
end;

function TEnhancedCleanupManager.CheckSystemProtection(const APath: string): Boolean;
begin
  // 检查系统文件保护
  Result := not (ContainsText(APath, 'System32') or 
                ContainsText(APath, 'DriverStore') or
                ContainsText(APath, 'WinSxS') or
                ContainsText(APath, 'assembly'));
end;

procedure TEnhancedCleanupManager.UpdateProgressEnhanced(const AMessage: string; 
  AProgress: Integer; const ACurrentItem: string);
begin
  if Assigned(FPreviewCallback) then
    FPreviewCallback(AMessage, AProgress, ACurrentItem);
    
  // 调用基类的进度更新
  UpdateProgress(AMessage, AProgress);
end;

procedure TEnhancedCleanupManager.AddCleanupHistory(const AHistory: TCleanupHistory);
begin
  FCleanupHistory.Add(AHistory);
  
  // 限制历史记录数量
  while FCleanupHistory.Count > FMaxHistoryCount do
    FCleanupHistory.Delete(0);
    
  SaveCleanupHistory;
end;

function TEnhancedCleanupManager.GetHistoryFilePath: string;
begin
  Result := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), 'CleanupHistory.json');
end;

procedure TEnhancedCleanupManager.SaveCleanupHistory;
var
  JSON: TJSONObject;
  HistArray: TJSONArray;
  History: TCleanupHistory;
  I: Integer;
begin
  try
    JSON := TJSONObject.Create;
    try
      HistArray := TJSONArray.Create;
      for I := 0 to FCleanupHistory.Count - 1 do
      begin
        History := FCleanupHistory[I];
        HistArray.AddElement(TJSONObject.Create
          .AddPair('timestamp', DateTimeToStr(History.Timestamp))
          .AddPair('cleanupType', History.CleanupType)
          .AddPair('itemsCleaned', History.ItemsCleaned)
          .AddPair('filesDeleted', History.FilesDeleted)
          .AddPair('spaceFreed', History.SpaceFreed)
          .AddPair('duration', History.Duration)
          .AddPair('success', History.Success)
          .AddPair('errorMessage', History.ErrorMessage));
      end;
      JSON.AddPair('history', HistArray);
      
      TFile.WriteAllText(GetHistoryFilePath, JSON.Format);
    finally
      JSON.Free;
    end;
  except
    // 忽略保存错误
  end;
end;

procedure TEnhancedCleanupManager.LoadCleanupHistory;
var
  JSON: TJSONObject;
  HistArray: TJSONArray;
  HistoryItem: TJSONObject;
  History: TCleanupHistory;
  I: Integer;
begin
  FCleanupHistory.Clear;
  
  if not TFile.Exists(GetHistoryFilePath) then Exit;
  
  try
    JSON := TJSONObject.Parse(TFile.ReadAllText(GetHistoryFilePath)) as TJSONObject;
    try
      HistArray := JSON.GetValue('history') as TJSONArray;
      for I := 0 to HistArray.Count - 1 do
      begin
        HistoryItem := HistArray.Items[I] as TJSONObject;
        History.Timestamp := StrToDateTime(HistoryItem.GetValue('timestamp').Value);
        History.CleanupType := HistoryItem.GetValue('cleanupType').Value;
        History.ItemsCleaned := StrToIntDef(HistoryItem.GetValue('itemsCleaned').Value, 0);
        History.FilesDeleted := StrToIntDef(HistoryItem.GetValue('filesDeleted').Value, 0);
        History.SpaceFreed := StrToInt64Def(HistoryItem.GetValue('spaceFreed').Value, 0);
        History.Duration := StrToIntDef(HistoryItem.GetValue('duration').Value, 0);
        History.Success := StrToBoolDef(HistoryItem.GetValue('success').Value, True);
        History.ErrorMessage := HistoryItem.GetValue('errorMessage').Value;
        
        FCleanupHistory.Add(History);
      end;
    finally
      JSON.Free;
    end;
  except
    // 忽略加载错误
  end;
end;

function TEnhancedCleanupManager.GetCleanupHistory: TArray<TCleanupHistory>;
begin
  Result := FCleanupHistory.ToArray;
end;

procedure TEnhancedCleanupManager.ClearCleanupHistory;
begin
  FCleanupHistory.Clear;
  if TFile.Exists(GetHistoryFilePath) then
    TFile.Delete(GetHistoryFilePath);
end;

function TEnhancedCleanupManager.GetTotalCleanedSpace: Int64;
var
  History: TCleanupHistory;
  Total: Int64;
  I: Integer;
begin
  Total := 0;
  for I := 0 to FCleanupHistory.Count - 1 do
  begin
    History := FCleanupHistory[I];
    if History.Success then
      Inc(Total, History.SpaceFreed);
  end;
  Result := Total;
end;

function TEnhancedCleanupManager.GetCleanupStatistics: TJSONObject;
var
  TotalCleaned, TotalFiles, TotalItems: Int64;
  SuccessfulCleanups, FailedCleanups: Integer;
  History: TCleanupHistory;
  I: Integer;
begin
  TotalCleaned := 0;
  TotalFiles := 0;
  TotalItems := 0;
  SuccessfulCleanups := 0;
  FailedCleanups := 0;
  
  for I := 0 to FCleanupHistory.Count - 1 do
  begin
    History := FCleanupHistory[I];
    if History.Success then
    begin
      Inc(SuccessfulCleanups);
      Inc(TotalCleaned, History.SpaceFreed);
      Inc(TotalFiles, History.FilesDeleted);
      Inc(TotalItems, History.ItemsCleaned);
    end
    else
    begin
      Inc(FailedCleanups);
    end;
  end;
  
  Result := TJSONObject.Create
    .AddPair('totalCleanups', FCleanupHistory.Count)
    .AddPair('successfulCleanups', SuccessfulCleanups)
    .AddPair('failedCleanups', FailedCleanups)
    .AddPair('totalSpaceFreed', TotalCleaned)
    .AddPair('totalFilesDeleted', TotalFiles)
    .AddPair('totalItemsCleaned', TotalItems)
    .AddPair('safetyLevel', SafetyLevelToString(FSafetyLevel))
    .AddPair('lastCleanup', DateTimeToStr(Now));
end;

function TEnhancedCleanupManager.SetSafetyLevel(const ALevel: TSafetyLevel): Boolean;
begin
  FSafetyLevel := ALevel;
  Result := True;
end;

function TEnhancedCleanupManager.CleanItemByType(const AItemType: TCleanupItemType): TCleanupResult;
var
  Preview: TCleanupPreview;
  ItemTypes: TArray<TCleanupItemType>;
begin
  SetLength(ItemTypes, 1);
  ItemTypes[0] := AItemType;
  
  Preview := PreviewCleanup(ItemTypes);
  try
    Result := PerformEnhancedCleanup(Preview);
  finally
    // 清理预览资源
  end;
end;

end.
