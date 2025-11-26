unit uDiskAnalyzer;

{
  C盘空间分析器 - 核心功能模块
  
  专注功能：
  - 分析C盘目录空间占用
  - 识别大文件夹和大文件
  - 提供迁移和清理建议  
  - 计算可节省的空间
  
  作者: AI助手
  版本: 1.0.0
  日期: 2024
}

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections,
  System.Math, System.Threading, Winapi.Windows;

type
  // 目录分析信息
  TDirectoryInfo = record
    Path: string;              // 目录路径
    Name: string;              // 目录名称
    Size: Int64;               // 目录大小(字节)
    FileCount: Integer;        // 文件数量
    SubDirCount: Integer;      // 子目录数量
    IsSystemDir: Boolean;      // 是否系统目录
    CanMigrate: Boolean;       // 是否可迁移
    CanClean: Boolean;         // 是否可清理
    MigrateReason: string;     // 迁移建议原因
    CleanReason: string;       // 清理建议原因
  end;

  // 大文件信息
  TLargeFileInfo = record
    Path: string;              // 文件路径
    Name: string;              // 文件名
    Size: Int64;               // 文件大小
    Extension: string;         // 文件扩展名
    LastModified: TDateTime;   // 最后修改时间
    CanDelete: Boolean;        // 是否可删除
    DeleteReason: string;      // 删除建议原因
  end;

  // 清理建议类型
  TCleanupSuggestionType = (
    cstMigrateUserFolders,     // 迁移用户文件夹
    cstCleanTempFiles,         // 清理临时文件
    cstCleanDownloads,         // 清理下载文件夹
    cstCleanRecycleBin,        // 清理回收站
    cstCleanCache,             // 清理缓存文件
    cstCleanLogs,              // 清理日志文件
    cstCleanLargeFiles         // 清理大文件
  );

  // 清理建议
  TCleanupSuggestion = record
    SuggestionType: TCleanupSuggestionType;
    Title: string;             // 建议标题
    Description: string;       // 详细描述
    Path: string;              // 相关路径
    EstimatedSpace: Int64;     // 预计节省空间
    Risk: Integer;             // 风险等级 (0=无风险, 5=高风险)
    Priority: Integer;         // 优先级 (1=最高, 5=最低)
  end;

  // 分析进度回调
  TAnalysisProgressCallback = procedure(const Message: string; Progress: Integer) of object;

  // C盘空间分析器
  TCDriveAnalyzer = class
  private
    FAnalyzing: Boolean;
    FOnProgress: TAnalysisProgressCallback;
    FDirectories: TArray<TDirectoryInfo>;
    FLargeFiles: TArray<TLargeFileInfo>;
    FSuggestions: TArray<TCleanupSuggestion>;
    FTotalScanned: Int64;
    FTotalFiles: Integer;
    FTotalDirectories: Integer;
    
    // 私有方法
    function IsSystemDirectory(const APath: string): Boolean;
    function CanDirectoryBeMigrated(const APath: string): Boolean;
    function CanDirectoryBeCleaned(const APath: string): Boolean;
    function GetMigrationReason(const APath: string): string;
    function GetCleanupReason(const APath: string): string;
    procedure ScanDirectory(const APath: string; var DirInfo: TDirectoryInfo);
    procedure FindLargeFiles(const APath: string; MinSize: Int64);
    procedure GenerateCleanupSuggestions;
    procedure UpdateProgress(const Message: string; Progress: Integer);
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // 属性
    property Analyzing: Boolean read FAnalyzing;
    property OnProgress: TAnalysisProgressCallback read FOnProgress write FOnProgress;
    
    // 分析方法
    function StartAnalysis: Boolean;
    procedure StopAnalysis;
    
    // 结果获取
    function GetTopDirectoriesBySize(Count: Integer): TArray<TDirectoryInfo>;
    function GetMigratableDirectories: TArray<TDirectoryInfo>;
    function GetCleanableDirectories: TArray<TDirectoryInfo>;
    function GetLargeFiles(MinSizeMB: Integer = 100): TArray<TLargeFileInfo>;
    function GetCleanupSuggestions: TArray<TCleanupSuggestion>;
    
    // 统计信息
    function GetTotalScannedSize: Int64;
    function GetTotalFiles: Integer;
    function GetTotalDirectories: Integer;
    function GetEstimatedSavings: Int64;
    
    // 工具方法
    function FormatBytes(Bytes: Int64): string;
    function GetDirectoryByPath(const APath: string): TDirectoryInfo;
  end;

implementation

uses
  System.StrUtils;

{ TCDriveAnalyzer }

constructor TCDriveAnalyzer.Create;
begin
  inherited Create;
  FAnalyzing := False;
  FTotalScanned := 0;
  FTotalFiles := 0;
  FTotalDirectories := 0;
end;

destructor TCDriveAnalyzer.Destroy;
begin
  if FAnalyzing then
    StopAnalysis;
  inherited Destroy;
end;

function TCDriveAnalyzer.StartAnalysis: Boolean;
var
  CDrive: string;
  RootDirs: TArray<string>;
  I: Integer;
  DirInfo: TDirectoryInfo;
  Progress: Integer;
begin
  Result := False;
  
  if FAnalyzing then
    Exit;
    
  FAnalyzing := True;
  FTotalScanned := 0;
  FTotalFiles := 0;
  FTotalDirectories := 0;
  
  SetLength(FDirectories, 0);
  SetLength(FLargeFiles, 0);
  SetLength(FSuggestions, 0);
  
  try
    UpdateProgress('开始分析C盘空间占用...', 0);
    
    CDrive := 'C:\';
    if not TDirectory.Exists(CDrive) then
    begin
      UpdateProgress('C盘不存在或无法访问', 100);
      Exit;
    end;
    
    // 获取C盘根目录下的所有文件夹
    try
      RootDirs := TDirectory.GetDirectories(CDrive);
    except
      on E: Exception do
      begin
        UpdateProgress('无法读取C盘目录: ' + E.Message, 100);
        Exit;
      end;
    end;
    
    UpdateProgress(Format('发现 %d 个根目录，开始详细分析...', [Length(RootDirs)]), 10);
    
    // 分析每个根目录
    for I := 0 to High(RootDirs) do
    begin
      if not FAnalyzing then
        Break;
        
      Progress := 10 + (I * 70) div Length(RootDirs);
      UpdateProgress(Format('正在分析: %s', [RootDirs[I]]), Progress);
      
      try
        FillChar(DirInfo, SizeOf(DirInfo), 0);
        ScanDirectory(RootDirs[I], DirInfo);
        
        if DirInfo.Size > 0 then
        begin
          SetLength(FDirectories, Length(FDirectories) + 1);
          FDirectories[High(FDirectories)] := DirInfo;
        end;
      except
        on E: Exception do
        begin
          UpdateProgress(Format('分析 %s 时出错: %s', [RootDirs[I], E.Message]), Progress);
          Continue;
        end;
      end;
    end;
    
    if FAnalyzing then
    begin
      UpdateProgress('正在查找大文件...', 80);
      FindLargeFiles(CDrive, 100 * 1024 * 1024); // 查找大于100MB的文件
      
      UpdateProgress('正在生成清理建议...', 90);
      GenerateCleanupSuggestions;
      
      UpdateProgress('分析完成', 100);
      Result := True;
    end;
    
  finally
    FAnalyzing := False;
  end;
end;

procedure TCDriveAnalyzer.StopAnalysis;
begin
  FAnalyzing := False;
end;

function TCDriveAnalyzer.IsSystemDirectory(const APath: string): Boolean;
var
  UpperPath: string;
begin
  UpperPath := UpperCase(APath);
  
  Result := 
    (Pos('C:\WINDOWS', UpperPath) = 1) or
    (Pos('C:\PROGRAM FILES', UpperPath) = 1) or
    (Pos('C:\PROGRAM FILES (X86)', UpperPath) = 1) or
    (Pos('C:\SYSTEM VOLUME INFORMATION', UpperPath) = 1) or
    (Pos('C:\BOOT', UpperPath) = 1) or
    (Pos('C:\EFI', UpperPath) = 1) or
    (Pos('C:\RECOVERY', UpperPath) = 1);
end;

function TCDriveAnalyzer.CanDirectoryBeMigrated(const APath: string): Boolean;
var
  UpperPath: string;
begin
  UpperPath := UpperCase(APath);
  
  // 系统目录不能迁移
  if IsSystemDirectory(APath) then
  begin
    Result := False;
    Exit;
  end;
  
  // 可以迁移的用户目录
  Result := 
    (Pos('C:\USERS\', UpperPath) = 1) and not
    (Pos('\APPDATA\', UpperPath) > 0) and not
    (Pos('\NTUSER', UpperPath) > 0);
end;

function TCDriveAnalyzer.CanDirectoryBeCleaned(const APath: string): Boolean;
var
  UpperPath: string;
begin
  UpperPath := UpperCase(APath);
  
  // 可以清理的目录类型
  Result := 
    (Pos('\TEMP', UpperPath) > 0) or
    (Pos('\TMP', UpperPath) > 0) or
    (Pos('\CACHE', UpperPath) > 0) or
    (Pos('\LOG', UpperPath) > 0) or
    (Pos('C:\$RECYCLE.BIN', UpperPath) = 1) or
    (Pos('C:\WINDOWS\SOFTWAREDISTRIBUTION\DOWNLOAD', UpperPath) = 1);
end;

function TCDriveAnalyzer.GetMigrationReason(const APath: string): string;
var
  UpperPath: string;
begin
  UpperPath := UpperCase(APath);
  
  if Pos('C:\USERS\', UpperPath) = 1 then
  begin
    if Pos('\DOCUMENTS', UpperPath) > 0 then
      Result := '文档文件夹，通常包含大量用户文件，迁移后可节省大量空间'
    else if Pos('\DOWNLOADS', UpperPath) > 0 then
      Result := '下载文件夹，通常包含大量下载文件，迁移后可节省空间'
    else if Pos('\DESKTOP', UpperPath) > 0 then
      Result := '桌面文件夹，可能包含大量文件，可考虑迁移'
    else if Pos('\PICTURES', UpperPath) > 0 then
      Result := '图片文件夹，通常占用较大空间，建议迁移'
    else if Pos('\VIDEOS', UpperPath) > 0 then
      Result := '视频文件夹，视频文件通常很大，强烈建议迁移'
    else if Pos('\MUSIC', UpperPath) > 0 then
      Result := '音乐文件夹，音频文件占用空间，可考虑迁移'
    else
      Result := '用户数据文件夹，可安全迁移到其他盘符';
  end
  else
    Result := '';
end;

function TCDriveAnalyzer.GetCleanupReason(const APath: string): string;
var
  UpperPath: string;
begin
  UpperPath := UpperCase(APath);
  
  if Pos('\TEMP', UpperPath) > 0 then
    Result := '临时文件夹，可安全清理以释放空间'
  else if Pos('\CACHE', UpperPath) > 0 then
    Result := '缓存文件夹，清理后程序会自动重建缓存'
  else if Pos('\LOG', UpperPath) > 0 then
    Result := '日志文件夹，旧日志可以安全删除'
  else if Pos('C:\$RECYCLE.BIN', UpperPath) = 1 then
    Result := '回收站，清空后可立即释放空间'
  else if Pos('SOFTWAREDISTRIBUTION\DOWNLOAD', UpperPath) > 0 then
    Result := 'Windows更新缓存，清理后可节省大量空间'
  else
    Result := '可清理的系统文件';
end;

procedure TCDriveAnalyzer.ScanDirectory(const APath: string; var DirInfo: TDirectoryInfo);
var
  Files: TArray<string>;
  SubDirs: TArray<string>;
  I: Integer;
  FileSize: Int64;
  SubDirInfo: TDirectoryInfo;
begin
  DirInfo.Path := APath;
  DirInfo.Name := TPath.GetFileName(APath);
  DirInfo.Size := 0;
  DirInfo.FileCount := 0;
  DirInfo.SubDirCount := 0;
  DirInfo.IsSystemDir := IsSystemDirectory(APath);
  DirInfo.CanMigrate := CanDirectoryBeMigrated(APath);
  DirInfo.CanClean := CanDirectoryBeCleaned(APath);
  DirInfo.MigrateReason := GetMigrationReason(APath);
  DirInfo.CleanReason := GetCleanupReason(APath);
  
  try
    // 计算文件大小
    Files := TDirectory.GetFiles(APath);
    DirInfo.FileCount := Length(Files);
    Inc(FTotalFiles, Length(Files));
    
    for I := 0 to High(Files) do
    begin
      try
        FileSize := TFile.GetSize(Files[I]);
        Inc(DirInfo.Size, FileSize);
        Inc(FTotalScanned, FileSize);
      except
        // 忽略无法访问的文件
      end;
    end;
    
    // 递归计算子目录大小
    SubDirs := TDirectory.GetDirectories(APath);
    DirInfo.SubDirCount := Length(SubDirs);
    Inc(FTotalDirectories, Length(SubDirs));
    
    for I := 0 to High(SubDirs) do
    begin
      if not FAnalyzing then
        Break;
        
      try
        FillChar(SubDirInfo, SizeOf(SubDirInfo), 0);
        ScanDirectory(SubDirs[I], SubDirInfo);
        Inc(DirInfo.Size, SubDirInfo.Size);
        Inc(DirInfo.FileCount, SubDirInfo.FileCount);
        Inc(DirInfo.SubDirCount, SubDirInfo.SubDirCount);
      except
        // 忽略无法访问的子目录
      end;
    end;
    
  except
    on E: Exception do
    begin
      // 记录错误但继续处理
    end;
  end;
end;

procedure TCDriveAnalyzer.FindLargeFiles(const APath: string; MinSize: Int64);
var
  Files: TArray<string>;
  Dirs: TArray<string>;
  I: Integer;
  FileSize: Int64;
  FileInfo: TLargeFileInfo;
begin
  try
    // 查找当前目录的大文件
    Files := TDirectory.GetFiles(APath);
    for I := 0 to High(Files) do
    begin
      if not FAnalyzing then
        Break;
        
      try
        FileSize := TFile.GetSize(Files[I]);
        if FileSize >= MinSize then
        begin
          FileInfo.Path := Files[I];
          FileInfo.Name := TPath.GetFileName(Files[I]);
          FileInfo.Size := FileSize;
          FileInfo.Extension := UpperCase(TPath.GetExtension(Files[I]));
          FileInfo.LastModified := TFile.GetLastWriteTime(Files[I]);
          
          // 判断是否可删除
          FileInfo.CanDelete := not IsSystemDirectory(TPath.GetDirectoryName(Files[I]));
          
          if FileInfo.CanDelete then
          begin
            if (FileInfo.Extension = '.TMP') or (FileInfo.Extension = '.LOG') then
              FileInfo.DeleteReason := '临时文件或日志文件，可安全删除'
            else if (FileInfo.Extension = '.ISO') or (FileInfo.Extension = '.IMG') then
              FileInfo.DeleteReason := '镜像文件，确认不需要后可删除'
            else if (FileInfo.Extension = '.ZIP') or (FileInfo.Extension = '.RAR') then
              FileInfo.DeleteReason := '压缩文件，确认内容已解压后可删除'
            else
              FileInfo.DeleteReason := '大文件，请确认是否需要后删除';
          end
          else
            FileInfo.DeleteReason := '系统文件，不建议删除';
          
          SetLength(FLargeFiles, Length(FLargeFiles) + 1);
          FLargeFiles[High(FLargeFiles)] := FileInfo;
        end;
      except
        // 忽略无法访问的文件
      end;
    end;
    
    // 递归查找子目录
    Dirs := TDirectory.GetDirectories(APath);
    for I := 0 to High(Dirs) do
    begin
      if not FAnalyzing then
        Break;
        
      if not IsSystemDirectory(Dirs[I]) then
      begin
        try
          FindLargeFiles(Dirs[I], MinSize);
        except
          // 忽略无法访问的子目录
        end;
      end;
    end;
    
  except
    // 忽略权限错误
  end;
end;

procedure TCDriveAnalyzer.GenerateCleanupSuggestions;
var
  I: Integer;
  Suggestion: TCleanupSuggestion;
  TotalMigratable, TotalCleanable: Int64;
begin
  SetLength(FSuggestions, 0);
  TotalMigratable := 0;
  TotalCleanable := 0;
  
  // 生成迁移建议
  for I := 0 to High(FDirectories) do
  begin
    if FDirectories[I].CanMigrate and (FDirectories[I].Size > 100 * 1024 * 1024) then // 大于100MB
    begin
      Inc(TotalMigratable, FDirectories[I].Size);
      
      Suggestion.SuggestionType := cstMigrateUserFolders;
      Suggestion.Title := Format('迁移 %s', [FDirectories[I].Name]);
      Suggestion.Description := FDirectories[I].MigrateReason;
      Suggestion.Path := FDirectories[I].Path;
      Suggestion.EstimatedSpace := FDirectories[I].Size;
      Suggestion.Risk := 1; // 低风险
      Suggestion.Priority := 2; // 高优先级
      
      SetLength(FSuggestions, Length(FSuggestions) + 1);
      FSuggestions[High(FSuggestions)] := Suggestion;
    end;
  end;
  
  // 生成清理建议
  for I := 0 to High(FDirectories) do
  begin
    if FDirectories[I].CanClean and (FDirectories[I].Size > 10 * 1024 * 1024) then // 大于10MB
    begin
      Inc(TotalCleanable, FDirectories[I].Size);
      
      if Pos('TEMP', UpperCase(FDirectories[I].Path)) > 0 then
        Suggestion.SuggestionType := cstCleanTempFiles
      else if Pos('CACHE', UpperCase(FDirectories[I].Path)) > 0 then
        Suggestion.SuggestionType := cstCleanCache
      else if Pos('RECYCLE', UpperCase(FDirectories[I].Path)) > 0 then
        Suggestion.SuggestionType := cstCleanRecycleBin
      else
        Suggestion.SuggestionType := cstCleanLogs;
        
      Suggestion.Title := Format('清理 %s', [FDirectories[I].Name]);
      Suggestion.Description := FDirectories[I].CleanReason;
      Suggestion.Path := FDirectories[I].Path;
      Suggestion.EstimatedSpace := FDirectories[I].Size;
      Suggestion.Risk := 0; // 无风险
      Suggestion.Priority := 1; // 最高优先级
      
      SetLength(FSuggestions, Length(FSuggestions) + 1);
      FSuggestions[High(FSuggestions)] := Suggestion;
    end;
  end;
  
  // 生成大文件清理建议
  for I := 0 to High(FLargeFiles) do
  begin
    if FLargeFiles[I].CanDelete then
    begin
      Suggestion.SuggestionType := cstCleanLargeFiles;
      Suggestion.Title := Format('删除大文件 %s', [FLargeFiles[I].Name]);
      Suggestion.Description := FLargeFiles[I].DeleteReason;
      Suggestion.Path := FLargeFiles[I].Path;
      Suggestion.EstimatedSpace := FLargeFiles[I].Size;
      Suggestion.Risk := 3; // 中等风险
      Suggestion.Priority := 4; // 较低优先级
      
      SetLength(FSuggestions, Length(FSuggestions) + 1);
      FSuggestions[High(FSuggestions)] := Suggestion;
    end;
  end;
end;

procedure TCDriveAnalyzer.UpdateProgress(const Message: string; Progress: Integer);
begin
  if Assigned(FOnProgress) then
    FOnProgress(Message, Progress);
end;

function TCDriveAnalyzer.GetTopDirectoriesBySize(Count: Integer): TArray<TDirectoryInfo>;
var
  I, J: Integer;
  Temp: TDirectoryInfo;
  ResultCount: Integer;
begin
  // 复制数组并排序
  Result := Copy(FDirectories, 0, Length(FDirectories));
  
  // 简单冒泡排序（按大小降序）
  for I := 0 to High(Result) - 1 do
  begin
    for J := I + 1 to High(Result) do
    begin
      if Result[I].Size < Result[J].Size then
      begin
        Temp := Result[I];
        Result[I] := Result[J];
        Result[J] := Temp;
      end;
    end;
  end;
  
  // 截取指定数量
  ResultCount := Min(Count, Length(Result));
  SetLength(Result, ResultCount);
end;

function TCDriveAnalyzer.GetMigratableDirectories: TArray<TDirectoryInfo>;
var
  I, Count: Integer;
begin
  Count := 0;
  for I := 0 to High(FDirectories) do
  begin
    if FDirectories[I].CanMigrate then
      Inc(Count);
  end;
  
  SetLength(Result, Count);
  Count := 0;
  for I := 0 to High(FDirectories) do
  begin
    if FDirectories[I].CanMigrate then
    begin
      Result[Count] := FDirectories[I];
      Inc(Count);
    end;
  end;
end;

function TCDriveAnalyzer.GetCleanableDirectories: TArray<TDirectoryInfo>;
var
  I, Count: Integer;
begin
  Count := 0;
  for I := 0 to High(FDirectories) do
  begin
    if FDirectories[I].CanClean then
      Inc(Count);
  end;
  
  SetLength(Result, Count);
  Count := 0;
  for I := 0 to High(FDirectories) do
  begin
    if FDirectories[I].CanClean then
    begin
      Result[Count] := FDirectories[I];
      Inc(Count);
    end;
  end;
end;

function TCDriveAnalyzer.GetLargeFiles(MinSizeMB: Integer): TArray<TLargeFileInfo>;
var
  I, Count: Integer;
  MinBytes: Int64;
begin
  MinBytes := Int64(MinSizeMB) * 1024 * 1024;
  Count := 0;
  
  for I := 0 to High(FLargeFiles) do
  begin
    if FLargeFiles[I].Size >= MinBytes then
      Inc(Count);
  end;
  
  SetLength(Result, Count);
  Count := 0;
  for I := 0 to High(FLargeFiles) do
  begin
    if FLargeFiles[I].Size >= MinBytes then
    begin
      Result[Count] := FLargeFiles[I];
      Inc(Count);
    end;
  end;
end;

function TCDriveAnalyzer.GetCleanupSuggestions: TArray<TCleanupSuggestion>;
begin
  Result := Copy(FSuggestions, 0, Length(FSuggestions));
end;

function TCDriveAnalyzer.GetTotalScannedSize: Int64;
begin
  Result := FTotalScanned;
end;

function TCDriveAnalyzer.GetTotalFiles: Integer;
begin
  Result := FTotalFiles;
end;

function TCDriveAnalyzer.GetTotalDirectories: Integer;
begin
  Result := FTotalDirectories;
end;

function TCDriveAnalyzer.GetEstimatedSavings: Int64;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to High(FSuggestions) do
  begin
    Inc(Result, FSuggestions[I].EstimatedSpace);
  end;
end;

function TCDriveAnalyzer.FormatBytes(Bytes: Int64): string;
const
  KB = 1024;
  MB = KB * 1024;
  GB = MB * 1024;
  TB = GB * Int64(1024);
begin
  if Bytes < KB then
    Result := Format('%d B', [Bytes])
  else if Bytes < MB then
    Result := Format('%.1f KB', [Bytes / KB])
  else if Bytes < GB then
    Result := Format('%.1f MB', [Bytes / MB])
  else if Bytes < TB then
    Result := Format('%.2f GB', [Bytes / GB])
  else
    Result := Format('%.2f TB', [Bytes / TB]);
end;

function TCDriveAnalyzer.GetDirectoryByPath(const APath: string): TDirectoryInfo;
var
  I: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  
  for I := 0 to High(FDirectories) do
  begin
    if SameText(FDirectories[I].Path, APath) then
    begin
      Result := FDirectories[I];
      Break;
    end;
  end;
end;

end.