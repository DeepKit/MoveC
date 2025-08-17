unit DuplicateFileDetector;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections,
  System.Hash, System.Threading, System.DateUtils,
  Winapi.Windows, DataTypes;

type
  // 重复文件信息
  TDuplicateFileInfo = record
    FilePath: string;
    FileSize: Int64;
    MD5Hash: string;
    CreationTime: TDateTime;
    LastWriteTime: TDateTime;
    IsSelected: Boolean;
    CanDelete: Boolean;
    DeleteReason: string; // 为什么建议删除这个文件
  end;

  // 重复文件组
  TDuplicateGroup = record
    Hash: string;
    TotalSize: Int64;
    FileCount: Integer;
    Files: TArray<TDuplicateFileInfo>;
    PotentialSavings: Int64; // 可节省的空间
  end;

  // 检测选项
  TDetectionOptions = record
    MinFileSize: Int64;        // 最小文件大小（字节）
    MaxFileSize: Int64;        // 最大文件大小（字节）
    IncludeHiddenFiles: Boolean;
    IncludeSystemFiles: Boolean;
    FileExtensions: TArray<string>; // 要检测的文件扩展名，空表示所有
    ExcludePaths: TArray<string>;   // 排除的路径
    UseQuickScan: Boolean;     // 快速扫描（只比较大小和部分哈希）
  end;

  // 进度回调
  TProgressCallback = procedure(const CurrentFile: string; Progress: Integer; const Status: string) of object;
  TResultCallback = procedure(const Groups: TArray<TDuplicateGroup>; TotalDuplicates: Integer; TotalSavings: Int64) of object;

  // 重复文件检测器
  TDuplicateFileDetector = class
  private
    FOptions: TDetectionOptions;
    FIsScanning: Boolean;
    FCancelled: Boolean;
    FOnProgress: TProgressCallback;
    FOnResult: TResultCallback;
    FSmartEvaluator: TSmartFileEvaluator;  // 智能评估器

    // 内部数据结构
    FSizeGroups: TDictionary<Int64, TList<string>>; // 按大小分组
    FHashGroups: TDictionary<string, TList<TDuplicateFileInfo>>; // 按哈希分组
    
    // 内部方法
    function ShouldIncludeFile(const FilePath: string; const FileInfo: TSearchRec): Boolean;
    function CalculateFileMD5(const FilePath: string): string;
    function CalculateQuickHash(const FilePath: string): string;
    function IsPathExcluded(const FilePath: string): Boolean;
    function GetFileDeletePriority(const FileInfo: TDuplicateFileInfo): Integer;
    function GenerateDeleteReason(const FileInfo: TDuplicateFileInfo; const Group: TArray<TDuplicateFileInfo>): string;
    procedure ScanDirectory(const DirPath: string; var ProcessedFiles: Integer; TotalFiles: Integer);
    procedure ProcessSizeGroups;
    procedure BuildDuplicateGroups(out Groups: TArray<TDuplicateGroup>);
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // 主要方法
    procedure StartScan(const RootPaths: TArray<string>; const Options: TDetectionOptions);
    procedure CancelScan;
    function IsScanning: Boolean;
    
    // 删除操作
    function DeleteSelectedFiles(const Groups: TArray<TDuplicateGroup>; MoveToRecycleBin: Boolean): Boolean;
    function GetRecommendedDeletions(const Groups: TArray<TDuplicateGroup>): TArray<TDuplicateGroup>;

    // 智能决策功能
    function MakeSmartDecisions(const Groups: TArray<TDuplicateGroup>): TArray<TDuplicateGroup>;
    function GetOneClickCleanupPlan(const Groups: TArray<TDuplicateGroup>): TArray<TDuplicateGroup>;
    procedure SetDecisionMode(Mode: TDecisionMode);
    
    // 事件
    property OnProgress: TProgressCallback read FOnProgress write FOnProgress;
    property OnResult: TResultCallback read FOnResult write FOnResult;
  end;

  // 辅助函数
  function FormatFileSize(Size: Int64): string;
  function GetDefaultDetectionOptions: TDetectionOptions;

implementation

uses
  System.StrUtils, System.Math, SmartFileEvaluator;

{ TDuplicateFileDetector }

constructor TDuplicateFileDetector.Create;
begin
  inherited Create;
  FSizeGroups := TDictionary<Int64, TList<string>>.Create;
  FHashGroups := TDictionary<string, TList<TDuplicateFileInfo>>.Create;
  FSmartEvaluator := TSmartFileEvaluator.Create;
  FIsScanning := False;
  FCancelled := False;
end;

destructor TDuplicateFileDetector.Destroy;
var
  List: TList<string>;
  HashList: TList<TDuplicateFileInfo>;
begin
  // 清理大小分组
  for List in FSizeGroups.Values do
    List.Free;
  FSizeGroups.Free;

  // 清理哈希分组
  for HashList in FHashGroups.Values do
    HashList.Free;
  FHashGroups.Free;

  // 清理智能评估器
  FSmartEvaluator.Free;

  inherited Destroy;
end;

procedure TDuplicateFileDetector.StartScan(const RootPaths: TArray<string>; const Options: TDetectionOptions);
begin
  if FIsScanning then
    Exit;
    
  FOptions := Options;
  FIsScanning := True;
  FCancelled := False;
  
  // 清理之前的结果
  for var List in FSizeGroups.Values do
    List.Free;
  FSizeGroups.Clear;
  
  for var HashList in FHashGroups.Values do
    HashList.Free;
  FHashGroups.Clear;
  
  // 在后台线程中执行扫描
  TTask.Run(
    procedure
    var
      TotalFiles, ProcessedFiles: Integer;
      Groups: TArray<TDuplicateGroup>;
      TotalDuplicates: Integer;
      TotalSavings: Int64;
    begin
      try
        if Assigned(FOnProgress) then
          FOnProgress('正在统计文件数量...', 0, '准备扫描');
          
        // 第一阶段：按文件大小分组
        TotalFiles := 0;
        ProcessedFiles := 0;
        
        for var RootPath in RootPaths do
        begin
          if FCancelled then Break;
          ScanDirectory(RootPath, ProcessedFiles, TotalFiles);
        end;
        
        if FCancelled then
        begin
          FIsScanning := False;
          Exit;
        end;
        
        if Assigned(FOnProgress) then
          FOnProgress('正在计算文件哈希...', 50, '分析重复文件');
          
        // 第二阶段：处理大小相同的文件组
        ProcessSizeGroups;
        
        if FCancelled then
        begin
          FIsScanning := False;
          Exit;
        end;
        
        if Assigned(FOnProgress) then
          FOnProgress('正在生成结果...', 90, '完成分析');
          
        // 第三阶段：构建最终结果
        BuildDuplicateGroups(Groups);
        
        // 计算统计信息
        TotalDuplicates := 0;
        TotalSavings := 0;
        for var Group in Groups do
        begin
          Inc(TotalDuplicates, Group.FileCount);
          Inc(TotalSavings, Group.PotentialSavings);
        end;
        
        FIsScanning := False;
        
        if Assigned(FOnProgress) then
          FOnProgress('扫描完成', 100, Format('找到 %d 组重复文件，可节省 %s', 
            [Length(Groups), FormatFileSize(TotalSavings)]));
            
        if Assigned(FOnResult) then
          FOnResult(Groups, TotalDuplicates, TotalSavings);
          
      except
        on E: Exception do
        begin
          FIsScanning := False;
          if Assigned(FOnProgress) then
            FOnProgress('扫描出错: ' + E.Message, 0, '错误');
        end;
      end;
    end);
end;

procedure TDuplicateFileDetector.CancelScan;
begin
  FCancelled := True;
end;

function TDuplicateFileDetector.IsScanning: Boolean;
begin
  Result := FIsScanning;
end;

function TDuplicateFileDetector.ShouldIncludeFile(const FilePath: string; const FileInfo: TSearchRec): Boolean;
var
  FileSize: Int64;
  Ext: string;
begin
  Result := False;
  
  // 检查是否是文件
  if (FileInfo.Attr and faDirectory) <> 0 then
    Exit;
    
  // 检查文件大小
  FileSize := FileInfo.Size;
  if (FileSize < FOptions.MinFileSize) or 
     ((FOptions.MaxFileSize > 0) and (FileSize > FOptions.MaxFileSize)) then
    Exit;
    
  // 检查隐藏文件
  if not FOptions.IncludeHiddenFiles and ((FileInfo.Attr and faHidden) <> 0) then
    Exit;
    
  // 检查系统文件
  if not FOptions.IncludeSystemFiles and ((FileInfo.Attr and faSystem) <> 0) then
    Exit;
    
  // 检查文件扩展名
  if Length(FOptions.FileExtensions) > 0 then
  begin
    Ext := LowerCase(ExtractFileExt(FilePath));
    if Ext <> '' then
      Ext := Copy(Ext, 2); // 去掉点号
      
    var Found := False;
    for var AllowedExt in FOptions.FileExtensions do
    begin
      if SameText(Ext, AllowedExt) then
      begin
        Found := True;
        Break;
      end;
    end;
    
    if not Found then
      Exit;
  end;
  
  // 检查排除路径
  if IsPathExcluded(FilePath) then
    Exit;
    
  Result := True;
end;

function TDuplicateFileDetector.IsPathExcluded(const FilePath: string): Boolean;
begin
  Result := False;
  for var ExcludePath in FOptions.ExcludePaths do
  begin
    if StartsText(ExcludePath, FilePath) then
    begin
      Result := True;
      Break;
    end;
  end;
end;

function TDuplicateFileDetector.CalculateFileMD5(const FilePath: string): string;
var
  FileStream: TFileStream;
  HashMD5: THashMD5;
begin
  Result := '';
  try
    FileStream := TFileStream.Create(FilePath, fmOpenRead or fmShareDenyNone);
    try
      HashMD5 := THashMD5.Create;
      Result := HashMD5.GetHashString(FileStream);
    finally
      FileStream.Free;
    end;
  except
    // 如果无法读取文件，返回空字符串
    Result := '';
  end;
end;

function TDuplicateFileDetector.CalculateQuickHash(const FilePath: string): string;
var
  FileStream: TFileStream;
  Buffer: TBytes;
  HashMD5: THashMD5;
  ReadSize: Integer;
begin
  Result := '';
  try
    FileStream := TFileStream.Create(FilePath, fmOpenRead or fmShareDenyNone);
    try
      // 快速哈希：读取文件开头、中间和结尾各4KB
      HashMD5 := THashMD5.Create;
      SetLength(Buffer, 4096);
      
      // 读取开头
      ReadSize := FileStream.Read(Buffer, Length(Buffer));
      if ReadSize > 0 then
        HashMD5.Update(Buffer, ReadSize);
        
      // 读取中间
      if FileStream.Size > 8192 then
      begin
        FileStream.Seek(FileStream.Size div 2, soBeginning);
        ReadSize := FileStream.Read(Buffer, Length(Buffer));
        if ReadSize > 0 then
          HashMD5.Update(Buffer, ReadSize);
      end;
      
      // 读取结尾
      if FileStream.Size > 4096 then
      begin
        FileStream.Seek(-4096, soEnd);
        ReadSize := FileStream.Read(Buffer, Length(Buffer));
        if ReadSize > 0 then
          HashMD5.Update(Buffer, ReadSize);
      end;
      
      Result := HashMD5.HashAsString;
    finally
      FileStream.Free;
    end;
  except
    Result := '';
  end;
end;

// 辅助函数实现
function FormatFileSize(Size: Int64): string;
begin
  if Size < 1024 then
    Result := Format('%d B', [Size])
  else if Size < 1024 * 1024 then
    Result := Format('%.1f KB', [Size / 1024])
  else if Size < 1024 * 1024 * 1024 then
    Result := Format('%.1f MB', [Size / (1024 * 1024)])
  else
    Result := Format('%.2f GB', [Size / (1024 * 1024 * 1024)]);
end;

procedure TDuplicateFileDetector.ScanDirectory(const DirPath: string; var ProcessedFiles: Integer; TotalFiles: Integer);
var
  SearchRec: TSearchRec;
  FilePath: string;
  FileSize: Int64;
  SizeList: TList<string>;
begin
  if FCancelled then Exit;

  try
    if FindFirst(IncludeTrailingPathDelimiter(DirPath) + '*', faAnyFile, SearchRec) = 0 then
    begin
      repeat
        if FCancelled then Break;

        if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
        begin
          FilePath := IncludeTrailingPathDelimiter(DirPath) + SearchRec.Name;

          if (SearchRec.Attr and faDirectory) <> 0 then
          begin
            // 递归扫描子目录
            ScanDirectory(FilePath, ProcessedFiles, TotalFiles);
          end
          else if ShouldIncludeFile(FilePath, SearchRec) then
          begin
            FileSize := SearchRec.Size;

            // 按文件大小分组
            if not FSizeGroups.TryGetValue(FileSize, SizeList) then
            begin
              SizeList := TList<string>.Create;
              FSizeGroups.Add(FileSize, SizeList);
            end;
            SizeList.Add(FilePath);

            Inc(ProcessedFiles);
            if Assigned(FOnProgress) and (ProcessedFiles mod 100 = 0) then
            begin
              var Progress := 0;
              if TotalFiles > 0 then
                Progress := Min(45, (ProcessedFiles * 45) div TotalFiles);
              FOnProgress(ExtractFileName(FilePath), Progress,
                Format('已扫描 %d 个文件', [ProcessedFiles]));
            end;
          end;
        end;
      until FindNext(SearchRec) <> 0;
      FindClose(SearchRec);
    end;
  except
    on E: Exception do
    begin
      if Assigned(FOnProgress) then
        FOnProgress('扫描目录出错: ' + DirPath, 0, E.Message);
    end;
  end;
end;

procedure TDuplicateFileDetector.ProcessSizeGroups;
var
  FileSize: Int64;
  FileList: TList<string>;
  FilePath: string;
  Hash: string;
  FileInfo: TDuplicateFileInfo;
  HashList: TList<TDuplicateFileInfo>;
  ProcessedGroups: Integer;
  TotalGroups: Integer;
begin
  ProcessedGroups := 0;
  TotalGroups := 0;

  // 计算需要处理的组数（只处理有多个文件的组）
  for FileList in FSizeGroups.Values do
  begin
    if FileList.Count > 1 then
      Inc(TotalGroups);
  end;

  for FileSize in FSizeGroups.Keys do
  begin
    if FCancelled then Break;

    FileList := FSizeGroups[FileSize];
    if FileList.Count > 1 then // 只处理有重复的大小组
    begin
      for FilePath in FileList do
      begin
        if FCancelled then Break;

        // 计算文件哈希
        if FOptions.UseQuickScan then
          Hash := CalculateQuickHash(FilePath)
        else
          Hash := CalculateFileMD5(FilePath);

        if Hash <> '' then
        begin
          // 创建文件信息
          FileInfo.FilePath := FilePath;
          FileInfo.FileSize := FileSize;
          FileInfo.MD5Hash := Hash;
          FileInfo.CreationTime := TFile.GetCreationTime(FilePath);
          FileInfo.LastWriteTime := TFile.GetLastWriteTime(FilePath);
          FileInfo.IsSelected := False;
          FileInfo.CanDelete := True;

          // 按哈希分组
          if not FHashGroups.TryGetValue(Hash, HashList) then
          begin
            HashList := TList<TDuplicateFileInfo>.Create;
            FHashGroups.Add(Hash, HashList);
          end;
          HashList.Add(FileInfo);
        end;
      end;

      Inc(ProcessedGroups);
      if Assigned(FOnProgress) then
      begin
        var Progress := 50 + ((ProcessedGroups * 40) div TotalGroups);
        FOnProgress(Format('处理大小组 %d/%d', [ProcessedGroups, TotalGroups]),
          Progress, '计算文件哈希');
      end;
    end;
  end;
end;

procedure TDuplicateFileDetector.BuildDuplicateGroups(out Groups: TArray<TDuplicateGroup>);
var
  GroupList: TList<TDuplicateGroup>;
  Hash: string;
  FileList: TList<TDuplicateFileInfo>;
  Group: TDuplicateGroup;
  Files: TArray<TDuplicateFileInfo>;
  i: Integer;
begin
  GroupList := TList<TDuplicateGroup>.Create;
  try
    for Hash in FHashGroups.Keys do
    begin
      FileList := FHashGroups[Hash];
      if FileList.Count > 1 then // 只包含真正重复的文件组
      begin
        Group.Hash := Hash;
        Group.FileCount := FileList.Count;
        Group.TotalSize := FileList[0].FileSize * FileList.Count;
        Group.PotentialSavings := FileList[0].FileSize * (FileList.Count - 1);

        // 复制文件列表并设置删除建议
        SetLength(Files, FileList.Count);
        for i := 0 to FileList.Count - 1 do
        begin
          Files[i] := FileList[i];
          Files[i].DeleteReason := GenerateDeleteReason(Files[i], Files);
        end;
        Group.Files := Files;

        GroupList.Add(Group);
      end;
    end;

    Groups := GroupList.ToArray;
  finally
    GroupList.Free;
  end;
end;

function TDuplicateFileDetector.GetFileDeletePriority(const FileInfo: TDuplicateFileInfo): Integer;
var
  FileName: string;
  FilePath: string;
begin
  Result := 0;
  FileName := LowerCase(ExtractFileName(FileInfo.FilePath));
  FilePath := LowerCase(FileInfo.FilePath);

  // 优先删除的文件类型（分数越高越优先删除）
  if ContainsText(FileName, 'copy') or ContainsText(FileName, '副本') then
    Inc(Result, 50);
  if ContainsText(FileName, 'backup') or ContainsText(FileName, '备份') then
    Inc(Result, 40);
  if ContainsText(FileName, 'temp') or ContainsText(FileName, '临时') then
    Inc(Result, 60);
  if ContainsText(FilePath, '\temp\') or ContainsText(FilePath, '\tmp\') then
    Inc(Result, 30);
  if ContainsText(FilePath, '\downloads\') or ContainsText(FilePath, '\下载\') then
    Inc(Result, 20);
  if ContainsText(FilePath, '\desktop\') or ContainsText(FilePath, '\桌面\') then
    Inc(Result, 10);

  // 根据文件时间调整优先级（较新的文件优先保留）
  var DaysSinceModified := DaysBetween(Now, FileInfo.LastWriteTime);
  if DaysSinceModified > 365 then
    Inc(Result, 15)
  else if DaysSinceModified > 30 then
    Inc(Result, 5);
end;

function TDuplicateFileDetector.GenerateDeleteReason(const FileInfo: TDuplicateFileInfo;
  const Group: TArray<TDuplicateFileInfo>): string;
var
  Priority: Integer;
  MaxPriority: Integer;
  KeepFile: TDuplicateFileInfo;
begin
  Priority := GetFileDeletePriority(FileInfo);
  MaxPriority := 0;

  // 找到优先级最低的文件（应该保留的文件）
  for var File in Group do
  begin
    var FilePriority := GetFileDeletePriority(File);
    if FilePriority < MaxPriority then
    begin
      MaxPriority := FilePriority;
      KeepFile := File;
    end;
  end;

  if Priority > MaxPriority then
  begin
    Result := '建议删除：';
    if ContainsText(LowerCase(FileInfo.FilePath), 'copy') then
      Result := Result + '文件名包含"copy"'
    else if ContainsText(LowerCase(FileInfo.FilePath), 'backup') then
      Result := Result + '疑似备份文件'
    else if ContainsText(LowerCase(FileInfo.FilePath), 'temp') then
      Result := Result + '疑似临时文件'
    else
      Result := Result + '较旧或位置不重要';
  end
  else
    Result := '建议保留：原始文件或重要位置';
end;

function TDuplicateFileDetector.DeleteSelectedFiles(const Groups: TArray<TDuplicateGroup>;
  MoveToRecycleBin: Boolean): Boolean;
var
  DeletedCount: Integer;
  TotalSelected: Integer;
  ErrorCount: Integer;
begin
  Result := True;
  DeletedCount := 0;
  ErrorCount := 0;
  TotalSelected := 0;

  // 计算选中的文件数
  for var Group in Groups do
    for var FileInfo in Group.Files do
      if FileInfo.IsSelected then
        Inc(TotalSelected);

  if TotalSelected = 0 then
  begin
    Result := False;
    Exit;
  end;

  for var Group in Groups do
  begin
    for var FileInfo in Group.Files do
    begin
      if FileInfo.IsSelected then
      begin
        try
          if MoveToRecycleBin then
          begin
            // 移动到回收站
            var Op: TSHFileOpStruct;
            var FromBuf: array[0..MAX_PATH] of Char;
            StrPCopy(FromBuf, FileInfo.FilePath + #0#0);

            FillChar(Op, SizeOf(Op), 0);
            Op.wFunc := FO_DELETE;
            Op.pFrom := @FromBuf[0];
            Op.fFlags := FOF_ALLOWUNDO or FOF_NOCONFIRMATION or FOF_SILENT;

            if SHFileOperation(Op) = 0 then
              Inc(DeletedCount)
            else
              Inc(ErrorCount);
          end
          else
          begin
            // 永久删除
            if DeleteFile(FileInfo.FilePath) then
              Inc(DeletedCount)
            else
              Inc(ErrorCount);
          end;

          if Assigned(FOnProgress) then
          begin
            var Progress := (DeletedCount + ErrorCount) * 100 div TotalSelected;
            FOnProgress(ExtractFileName(FileInfo.FilePath), Progress,
              Format('已删除 %d/%d 个文件', [DeletedCount, TotalSelected]));
          end;

        except
          Inc(ErrorCount);
        end;
      end;
    end;
  end;

  if Assigned(FOnProgress) then
  begin
    if ErrorCount = 0 then
      FOnProgress('删除完成', 100, Format('成功删除 %d 个重复文件', [DeletedCount]))
    else
      FOnProgress('删除完成', 100, Format('删除 %d 个文件，%d 个失败', [DeletedCount, ErrorCount]));
  end;

  Result := ErrorCount = 0;
end;

function TDuplicateFileDetector.GetRecommendedDeletions(const Groups: TArray<TDuplicateGroup>): TArray<TDuplicateGroup>;
var
  RecommendedGroups: TList<TDuplicateGroup>;
  Group: TDuplicateGroup;
  i: Integer;
begin
  RecommendedGroups := TList<TDuplicateGroup>.Create;
  try
    for var OrigGroup in Groups do
    begin
      Group := OrigGroup;

      // 为每个组设置推荐删除的文件
      for i := 0 to Length(Group.Files) - 1 do
      begin
        var Priority := GetFileDeletePriority(Group.Files[i]);
        Group.Files[i].IsSelected := Priority > 10; // 优先级大于10的建议删除
      end;

      RecommendedGroups.Add(Group);
    end;

    Result := RecommendedGroups.ToArray;
  finally
    RecommendedGroups.Free;
  end;
end;

function TDuplicateFileDetector.MakeSmartDecisions(const Groups: TArray<TDuplicateGroup>): TArray<TDuplicateGroup>;
var
  i, j: Integer;
  SmartGroups: TArray<TDuplicateGroup>;
  FilePaths: TArray<string>;
  KeepFile: string;
  Score: TFileImportanceScore;
begin
  SetLength(SmartGroups, Length(Groups));

  for i := 0 to Length(Groups) - 1 do
  begin
    SmartGroups[i] := Groups[i];

    // 准备文件路径数组
    SetLength(FilePaths, Length(Groups[i].Files));
    for j := 0 to Length(Groups[i].Files) - 1 do
      FilePaths[j] := Groups[i].Files[j].FilePath;

    // 使用智能评估器找到最佳保留文件
    KeepFile := FSmartEvaluator.GetRecommendedKeepFile(FilePaths);

    // 设置删除建议
    for j := 0 to Length(SmartGroups[i].Files) - 1 do
    begin
      if SmartGroups[i].Files[j].FilePath = KeepFile then
      begin
        SmartGroups[i].Files[j].IsSelected := False;
        SmartGroups[i].Files[j].DeleteReason := '智能推荐保留：最重要的文件';
      end
      else
      begin
        Score := FSmartEvaluator.EvaluateFile(SmartGroups[i].Files[j].FilePath);
        SmartGroups[i].Files[j].IsSelected := Score.RecommendDelete;
        SmartGroups[i].Files[j].DeleteReason := Score.Reason;
      end;
    end;
  end;

  Result := SmartGroups;
end;

function TDuplicateFileDetector.GetOneClickCleanupPlan(const Groups: TArray<TDuplicateGroup>): TArray<TDuplicateGroup>;
var
  CleanupGroups: TArray<TDuplicateGroup>;
  i, j: Integer;
  SafeToDelete: Boolean;
begin
  CleanupGroups := MakeSmartDecisions(Groups);

  // 进一步过滤，只保留高信心度的删除决策
  for i := 0 to Length(CleanupGroups) - 1 do
  begin
    for j := 0 to Length(CleanupGroups[i].Files) - 1 do
    begin
      if CleanupGroups[i].Files[j].IsSelected then
      begin
        SafeToDelete := FSmartEvaluator.IsSafeToDelete(CleanupGroups[i].Files[j].FilePath);
        CleanupGroups[i].Files[j].IsSelected := SafeToDelete;

        if not SafeToDelete then
          CleanupGroups[i].Files[j].DeleteReason := '安全检查未通过，建议手动确认';
      end;
    end;
  end;

  Result := CleanupGroups;
end;

procedure TDuplicateFileDetector.SetDecisionMode(Mode: TDecisionMode);
begin
  FSmartEvaluator.SetDecisionMode(Mode);
end;

function GetDefaultDetectionOptions: TDetectionOptions;
begin
  Result.MinFileSize := 1024; // 1KB
  Result.MaxFileSize := 0;    // 无限制
  Result.IncludeHiddenFiles := False;
  Result.IncludeSystemFiles := False;
  Result.FileExtensions := []; // 所有文件类型
  Result.ExcludePaths := ['C:\Windows', 'C:\Program Files', 'C:\Program Files (x86)'];
  Result.UseQuickScan := False;
end;

end.
