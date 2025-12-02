unit uScanCache;

{
  扫描结果缓存 - Scan Result Cache
  
  功能：
  - 缓存目录扫描结果
  - 基于目录修改时间判断缓存有效性
  - 支持缓存过期和自动清理
  - 持久化存储到磁盘
  - 内存+磁盘两级缓存
  
  作者: MoveC Team
  版本: 1.0
  日期: 2025-12-02
}

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.IniFiles,
  System.DateUtils, System.Generics.Collections, System.Hash,
  Winapi.Windows;

type
  // 目录扫描缓存条目
  TDirCacheEntry = record
    Path: string;               // 目录路径
    TotalSize: Int64;           // 总大小
    FileCount: Integer;         // 文件数
    DirCount: Integer;          // 子目录数
    LastModified: TDateTime;    // 目录最后修改时间
    ScanTime: TDateTime;        // 扫描时间
    PathHash: string;           // 路径哈希（用作键）
    IsValid: Boolean;           // 是否有效
  end;
  
  // 文件信息缓存
  TFileCacheEntry = record
    FilePath: string;
    FileSize: Int64;
    ModifiedTime: TDateTime;
    FileHash: string;           // 可选的文件哈希
    Extension: string;
  end;

  TScanCache = class
  private
    FCacheDir: string;
    FMemoryCache: TDictionary<string, TDirCacheEntry>;
    FCacheExpireMinutes: Integer;
    FMaxMemoryCacheSize: Integer;
    FEnabled: Boolean;
    FHitCount: Int64;
    FMissCount: Int64;
    
    function GetCacheDir: string;
    function GetPathHash(const APath: string): string;
    function GetDirModifiedTime(const APath: string): TDateTime;
    function LoadFromDisk(const APathHash: string): TDirCacheEntry;
    procedure SaveToDisk(const Entry: TDirCacheEntry);
    procedure CleanupOldCache;
    procedure TrimMemoryCache;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // 缓存操作
    function TryGetCache(const APath: string; out Entry: TDirCacheEntry): Boolean;
    procedure SetCache(const APath: string; TotalSize: Int64; 
      FileCount, DirCount: Integer);
    procedure InvalidateCache(const APath: string);
    procedure InvalidateAll;
    
    // 检查缓存有效性
    function IsCacheValid(const APath: string): Boolean;
    
    // 统计信息
    function GetHitRate: Double;
    procedure ResetStats;
    
    // 配置
    property Enabled: Boolean read FEnabled write FEnabled;
    property CacheExpireMinutes: Integer read FCacheExpireMinutes write FCacheExpireMinutes;
    property MaxMemoryCacheSize: Integer read FMaxMemoryCacheSize write FMaxMemoryCacheSize;
    property HitCount: Int64 read FHitCount;
    property MissCount: Int64 read FMissCount;
  end;
  
  // 全局单例
  function ScanCache: TScanCache;

implementation

uses
  uLogManager;

var
  _ScanCache: TScanCache = nil;

function ScanCache: TScanCache;
begin
  if _ScanCache = nil then
    _ScanCache := TScanCache.Create;
  Result := _ScanCache;
end;

{ TScanCache }

constructor TScanCache.Create;
begin
  inherited Create;
  FMemoryCache := TDictionary<string, TDirCacheEntry>.Create;
  FCacheDir := GetCacheDir;
  FCacheExpireMinutes := 30;  // 默认30分钟过期
  FMaxMemoryCacheSize := 1000;  // 最多缓存1000个目录
  FEnabled := True;
  FHitCount := 0;
  FMissCount := 0;
  
  // 确保缓存目录存在
  if not TDirectory.Exists(FCacheDir) then
    TDirectory.CreateDirectory(FCacheDir);
end;

destructor TScanCache.Destroy;
begin
  FMemoryCache.Free;
  inherited;
end;

function TScanCache.GetCacheDir: string;
begin
  Result := TPath.Combine(ExtractFilePath(ParamStr(0)), 'ScanCache');
end;

function TScanCache.GetPathHash(const APath: string): string;
begin
  // 使用MD5生成路径哈希作为缓存键
  Result := THashMD5.GetHashString(LowerCase(APath));
end;

function TScanCache.GetDirModifiedTime(const APath: string): TDateTime;
var
  SearchRec: TSearchRec;
  LatestTime: TDateTime;
  Files: TArray<string>;
  I: Integer;
begin
  Result := 0;
  LatestTime := 0;
  
  if not TDirectory.Exists(APath) then Exit;
  
  // 获取目录本身的修改时间
  if FindFirst(APath, faDirectory, SearchRec) = 0 then
  begin
    try
      Result := SearchRec.TimeStamp;
    finally
      FindClose(SearchRec);
    end;
  end;
  
  // 检查直接子项的修改时间（不递归，性能考虑）
  try
    if FindFirst(TPath.Combine(APath, '*'), faAnyFile, SearchRec) = 0 then
    begin
      try
        repeat
          if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
          begin
            if SearchRec.TimeStamp > LatestTime then
              LatestTime := SearchRec.TimeStamp;
          end;
        until FindNext(SearchRec) <> 0;
      finally
        FindClose(SearchRec);
      end;
    end;
  except
    // 忽略访问错误
  end;
  
  if LatestTime > Result then
    Result := LatestTime;
end;

function TScanCache.LoadFromDisk(const APathHash: string): TDirCacheEntry;
var
  CacheFile: string;
  IniFile: TIniFile;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.IsValid := False;
  
  CacheFile := TPath.Combine(FCacheDir, APathHash + '.cache');
  if not TFile.Exists(CacheFile) then Exit;
  
  try
    IniFile := TIniFile.Create(CacheFile);
    try
      Result.Path := IniFile.ReadString('Cache', 'Path', '');
      Result.TotalSize := IniFile.ReadInt64('Cache', 'TotalSize', 0);
      Result.FileCount := IniFile.ReadInteger('Cache', 'FileCount', 0);
      Result.DirCount := IniFile.ReadInteger('Cache', 'DirCount', 0);
      Result.LastModified := IniFile.ReadDateTime('Cache', 'LastModified', 0);
      Result.ScanTime := IniFile.ReadDateTime('Cache', 'ScanTime', 0);
      Result.PathHash := APathHash;
      Result.IsValid := Result.Path <> '';
    finally
      IniFile.Free;
    end;
  except
    Result.IsValid := False;
  end;
end;

procedure TScanCache.SaveToDisk(const Entry: TDirCacheEntry);
var
  CacheFile: string;
  IniFile: TIniFile;
begin
  if not FEnabled then Exit;
  
  CacheFile := TPath.Combine(FCacheDir, Entry.PathHash + '.cache');
  
  try
    IniFile := TIniFile.Create(CacheFile);
    try
      IniFile.WriteString('Cache', 'Path', Entry.Path);
      IniFile.WriteInt64('Cache', 'TotalSize', Entry.TotalSize);
      IniFile.WriteInteger('Cache', 'FileCount', Entry.FileCount);
      IniFile.WriteInteger('Cache', 'DirCount', Entry.DirCount);
      IniFile.WriteDateTime('Cache', 'LastModified', Entry.LastModified);
      IniFile.WriteDateTime('Cache', 'ScanTime', Entry.ScanTime);
      IniFile.UpdateFile;
    finally
      IniFile.Free;
    end;
  except
    on E: Exception do
      LogWarning('ScanCache', '保存缓存失败: ' + E.Message);
  end;
end;

procedure TScanCache.CleanupOldCache;
var
  Files: TArray<string>;
  FileName: string;
  FileAge: TDateTime;
begin
  if not TDirectory.Exists(FCacheDir) then Exit;
  
  try
    Files := TDirectory.GetFiles(FCacheDir, '*.cache');
    for FileName in Files do
    begin
      FileAge := TFile.GetLastWriteTime(FileName);
      // 删除超过7天的缓存
      if DaysBetween(Now, FileAge) > 7 then
        TFile.Delete(FileName);
    end;
  except
    // 忽略清理错误
  end;
end;

procedure TScanCache.TrimMemoryCache;
var
  KeysToRemove: TList<string>;
  Pair: TPair<string, TDirCacheEntry>;
  Entry: TDirCacheEntry;
begin
  if FMemoryCache.Count <= FMaxMemoryCacheSize then Exit;
  
  KeysToRemove := TList<string>.Create;
  try
    // 删除过期的条目
    for Pair in FMemoryCache do
    begin
      Entry := Pair.Value;
      if MinutesBetween(Now, Entry.ScanTime) > FCacheExpireMinutes then
        KeysToRemove.Add(Pair.Key);
    end;
    
    for var Key in KeysToRemove do
      FMemoryCache.Remove(Key);
    
    // 如果还是太多，删除最旧的一半
    if FMemoryCache.Count > FMaxMemoryCacheSize then
    begin
      KeysToRemove.Clear;
      var Count := 0;
      for Pair in FMemoryCache do
      begin
        KeysToRemove.Add(Pair.Key);
        Inc(Count);
        if Count >= FMemoryCache.Count div 2 then Break;
      end;
      
      for var Key in KeysToRemove do
        FMemoryCache.Remove(Key);
    end;
  finally
    KeysToRemove.Free;
  end;
end;

function TScanCache.TryGetCache(const APath: string; out Entry: TDirCacheEntry): Boolean;
var
  PathHash: string;
  CurrentModTime: TDateTime;
begin
  Result := False;
  FillChar(Entry, SizeOf(Entry), 0);
  
  if not FEnabled then
  begin
    Inc(FMissCount);
    Exit;
  end;
  
  if not TDirectory.Exists(APath) then
  begin
    Inc(FMissCount);
    Exit;
  end;
  
  PathHash := GetPathHash(APath);
  
  // 先查内存缓存
  if FMemoryCache.TryGetValue(PathHash, Entry) then
  begin
    // 检查是否过期
    if MinutesBetween(Now, Entry.ScanTime) > FCacheExpireMinutes then
    begin
      FMemoryCache.Remove(PathHash);
      Inc(FMissCount);
      Exit;
    end;
    
    // 检查目录是否被修改
    CurrentModTime := GetDirModifiedTime(APath);
    if CurrentModTime > Entry.LastModified then
    begin
      FMemoryCache.Remove(PathHash);
      Inc(FMissCount);
      Exit;
    end;
    
    Inc(FHitCount);
    Result := True;
    Exit;
  end;
  
  // 查磁盘缓存
  Entry := LoadFromDisk(PathHash);
  if Entry.IsValid then
  begin
    // 检查是否过期
    if MinutesBetween(Now, Entry.ScanTime) > FCacheExpireMinutes then
    begin
      Inc(FMissCount);
      Exit;
    end;
    
    // 检查目录是否被修改
    CurrentModTime := GetDirModifiedTime(APath);
    if CurrentModTime > Entry.LastModified then
    begin
      Inc(FMissCount);
      Exit;
    end;
    
    // 加入内存缓存
    TrimMemoryCache;
    FMemoryCache.AddOrSetValue(PathHash, Entry);
    
    Inc(FHitCount);
    Result := True;
    Exit;
  end;
  
  Inc(FMissCount);
end;

procedure TScanCache.SetCache(const APath: string; TotalSize: Int64;
  FileCount, DirCount: Integer);
var
  Entry: TDirCacheEntry;
begin
  if not FEnabled then Exit;
  if not TDirectory.Exists(APath) then Exit;
  
  Entry.Path := APath;
  Entry.TotalSize := TotalSize;
  Entry.FileCount := FileCount;
  Entry.DirCount := DirCount;
  Entry.LastModified := GetDirModifiedTime(APath);
  Entry.ScanTime := Now;
  Entry.PathHash := GetPathHash(APath);
  Entry.IsValid := True;
  
  // 存入内存缓存
  TrimMemoryCache;
  FMemoryCache.AddOrSetValue(Entry.PathHash, Entry);
  
  // 存入磁盘缓存
  SaveToDisk(Entry);
end;

procedure TScanCache.InvalidateCache(const APath: string);
var
  PathHash: string;
  CacheFile: string;
begin
  PathHash := GetPathHash(APath);
  
  // 从内存移除
  FMemoryCache.Remove(PathHash);
  
  // 从磁盘移除
  CacheFile := TPath.Combine(FCacheDir, PathHash + '.cache');
  if TFile.Exists(CacheFile) then
    TFile.Delete(CacheFile);
end;

procedure TScanCache.InvalidateAll;
var
  Files: TArray<string>;
  FileName: string;
begin
  // 清空内存缓存
  FMemoryCache.Clear;
  
  // 清空磁盘缓存
  if TDirectory.Exists(FCacheDir) then
  begin
    try
      Files := TDirectory.GetFiles(FCacheDir, '*.cache');
      for FileName in Files do
        TFile.Delete(FileName);
    except
      // 忽略错误
    end;
  end;
  
  ResetStats;
end;

function TScanCache.IsCacheValid(const APath: string): Boolean;
var
  Entry: TDirCacheEntry;
begin
  Result := TryGetCache(APath, Entry);
  // 不计入统计（这是检查调用）
  if Result then Dec(FHitCount) else Dec(FMissCount);
end;

function TScanCache.GetHitRate: Double;
var
  Total: Int64;
begin
  Total := FHitCount + FMissCount;
  if Total = 0 then
    Result := 0
  else
    Result := FHitCount / Total * 100;
end;

procedure TScanCache.ResetStats;
begin
  FHitCount := 0;
  FMissCount := 0;
end;

initialization

finalization
  if _ScanCache <> nil then
  begin
    _ScanCache.Free;
    _ScanCache := nil;
  end;

end.
