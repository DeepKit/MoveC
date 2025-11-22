unit uDuplicateFileDetector;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.IOUtils, System.Generics.Collections, System.Math, System.Diagnostics,
  System.JSON, System.DateUtils, uFileHasher, uFileOperations;

type
  // 重复文件信息
  TDuplicateFileInfo = record
    FilePath: string;
    FileSize: Int64;
    LastWriteTime: TDateTime;
    IsSelected: Boolean;
    DeleteReason: string;
  end;
  
  // 重复文件组类型
  TDuplicateGroup = record
    Files: TArray<TDuplicateFileInfo>;
    FileCount: Integer;
    PotentialSavings: Int64;
  end;

  // 检测选项
  TDetectionOptions = record
    IncludeHiddenFiles: Boolean;
    IncludeSystemFiles: Boolean;
    MinFileSize: Int64;
    MaxFileSize: Int64;
    HashAlgorithm: string;
    ParallelProcessing: Boolean;
    MaxThreads: Integer;
  end;

  // 进度回调
  TProgressEvent = procedure(const CurrentFile: string; Progress: Integer; const Status: string) of object;
  TResultEvent = procedure(const Groups: TArray<TDuplicateGroup>; TotalDuplicates: Integer; TotalSavings: Int64) of object;

type
  TDuplicateFileDetector = class
  private
    FIsScanning: Boolean;
    FOnProgress: TProgressEvent;
    FOnResult: TResultEvent;
    
    // 内部方法
    function ScanDirectory(const RootPath: string; const Options: TDetectionOptions): TArray<TDuplicateFileInfo>;
    function GroupFilesBySize(const Files: TArray<TDuplicateFileInfo>): TDictionary<Int64, TArray<TDuplicateFileInfo>>;
    function CalculateFileHashes(const Groups: TDictionary<Int64, TArray<TDuplicateFileInfo>>; const Options: TDetectionOptions): TDictionary<string, TArray<TDuplicateFileInfo>>;
    function CreateDuplicateGroups(const HashGroups: TDictionary<string, TArray<TDuplicateFileInfo>>): TArray<TDuplicateGroup>;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // 公共方法
    procedure StartScan(const RootPaths: TArray<string>; const Options: TDetectionOptions);
    procedure CancelScan;
    function IsScanning: Boolean;
    
    // 智能推荐
    function GetRecommendedDeletions(const Groups: TArray<TDuplicateGroup>): TArray<TDuplicateGroup>;
    
    // 清理执行
    function DeleteSelectedFiles(var Groups: TArray<TDuplicateGroup>; MoveToRecycleBin: Boolean): Boolean;
    
    // 事件
    property OnProgress: TProgressEvent read FOnProgress write FOnProgress;
    property OnResult: TResultEvent read FOnResult write FOnResult;
  end;
  
  // 全局函数
  function GetDefaultDetectionOptions: TDetectionOptions;

implementation

{ TDuplicateFileDetector }

constructor TDuplicateFileDetector.Create;
begin
  inherited Create;
  FIsScanning := False;
end;

destructor TDuplicateFileDetector.Destroy;
begin
  inherited Destroy;
end;

function TDuplicateFileDetector.IsScanning: Boolean;
begin
  Result := FIsScanning;
end;

procedure TDuplicateFileDetector.CancelScan;
begin
  if FIsScanning then
  begin
    FIsScanning := False;
  end;
end;

procedure TDuplicateFileDetector.StartScan(const RootPaths: TArray<string>; const Options: TDetectionOptions);
var
  AllFiles: TArray<TDuplicateFileInfo>;
  SizeGroups: TDictionary<Int64, TArray<TDuplicateFileInfo>>;
  HashGroups: TDictionary<string, TArray<TDuplicateFileInfo>>;
  DuplicateGroups: TArray<TDuplicateGroup>;
  TotalDuplicates: Integer;
  TotalSavings: Int64;
  Stopwatch: TStopwatch;
  I: Integer;
begin
  if FIsScanning then Exit;
  
  FIsScanning := True;
  try
    Stopwatch := TStopwatch.StartNew;
    
    if Assigned(FOnProgress) then
      FOnProgress('', 0, '正在扫描文件...');
    
    // 1. 扫描所有文件
    AllFiles := [];
    for I := 0 to High(RootPaths) do
    begin
      var PathFiles := ScanDirectory(RootPaths[I], Options);
      AllFiles := AllFiles + PathFiles;
    end;
    
    if Assigned(FOnProgress) then
      FOnProgress('', 25, Format('已找到 %d 个文件，正在按大小分组...', [Length(AllFiles)]));
    
    // 2. 按文件大小分组
    SizeGroups := GroupFilesBySize(AllFiles);
    
    if Assigned(FOnProgress) then
      FOnProgress('', 50, '正在计算文件哈希值...');
    
    // 3. 计算哈希值并分组
    HashGroups := CalculateFileHashes(SizeGroups, Options);
    
    if Assigned(FOnProgress) then
      FOnProgress('', 75, '正在生成重复文件组...');
    
    // 4. 创建重复文件组
    DuplicateGroups := CreateDuplicateGroups(HashGroups);
    
    // 5. 计算统计信息
    TotalDuplicates := 0;
    TotalSavings := 0;
    for I := 0 to High(DuplicateGroups) do
    begin
      Inc(TotalDuplicates, DuplicateGroups[I].FileCount - 1); // 减1是因为保留一个文件
      Inc(TotalSavings, DuplicateGroups[I].PotentialSavings);
    end;
    
    Stopwatch.Stop;
    
    if Assigned(FOnProgress) then
      FOnProgress('', 100, Format('扫描完成，耗时 %d 秒', [Trunc(Stopwatch.Elapsed.TotalSeconds)]));
    
    if Assigned(FOnResult) then
      FOnResult(DuplicateGroups, TotalDuplicates, TotalSavings);
      
  except
    on E: Exception do
    begin
      if Assigned(FOnProgress) then
        FOnProgress('', -1, '扫描出错: ' + E.Message);
    end;
  end;
  FIsScanning := False;
end;

function TDuplicateFileDetector.ScanDirectory(const RootPath: string; const Options: TDetectionOptions): TArray<TDuplicateFileInfo>;
var
  FileList: TList<TDuplicateFileInfo>;
  SearchOption: TSearchOption;
  Files: TArray<string>;
  I: Integer;
begin
  FileList := TList<TDuplicateFileInfo>.Create;
  try
    SearchOption := TSearchOption.soAllDirectories;
    
    Files := TDirectory.GetFiles(RootPath, '*.*', SearchOption);
    for I := 0 to High(Files) do
    begin
      var FilePath := Files[I];
      var FileInfo: TDuplicateFileInfo;
      
      // 检查文件大小
      var Size := TFile.GetSize(FilePath);
      if (Size < Options.MinFileSize) or (Size > Options.MaxFileSize) then
        Continue;
        
      // 检查是否为系统文件或隐藏文件
      var Attrs := TFile.GetAttributes(FilePath);
      if not Options.IncludeSystemFiles and (TFileAttribute.faSystem in Attrs) then
        Continue;
      if not Options.IncludeHiddenFiles and (TFileAttribute.faHidden in Attrs) then
        Continue;
      
      FileInfo.FilePath := FilePath;
      FileInfo.FileSize := Size;
      FileInfo.LastWriteTime := TFile.GetLastWriteTime(FilePath);
      FileInfo.IsSelected := False;
      FileInfo.DeleteReason := '';
      
      FileList.Add(FileInfo);
    end;
    
    Result := FileList.ToArray;
  finally
    FileList.Free;
  end;
end;

function TDuplicateFileDetector.GroupFilesBySize(const Files: TArray<TDuplicateFileInfo>): TDictionary<Int64, TArray<TDuplicateFileInfo>>;
var
  SizeGroups: TDictionary<Int64, TList<TDuplicateFileInfo>>;
  I: Integer;
  Size: Int64;
  FileList: TList<TDuplicateFileInfo>;
  Pair: TPair<Int64, TList<TDuplicateFileInfo>>;
begin
  SizeGroups := TDictionary<Int64, TList<TDuplicateFileInfo>>.Create;
  try
    // 按文件大小分组
    for I := 0 to High(Files) do
    begin
      Size := Files[I].FileSize;
      if not SizeGroups.ContainsKey(Size) then
        SizeGroups.Add(Size, TList<TDuplicateFileInfo>.Create);
      SizeGroups[Size].Add(Files[I]);
    end;
    
    // 只保留有多个文件的组
    Result := TDictionary<Int64, TArray<TDuplicateFileInfo>>.Create;
    for Pair in SizeGroups do
    begin
      if Pair.Value.Count > 1 then
        Result.Add(Pair.Key, Pair.Value.ToArray);
      Pair.Value.Free;
    end;
    
    SizeGroups.Free;
  except
    SizeGroups.Free;
    raise;
  end;
end;

function TDuplicateFileDetector.CalculateFileHashes(const Groups: TDictionary<Int64, TArray<TDuplicateFileInfo>>; const Options: TDetectionOptions): TDictionary<string, TArray<TDuplicateFileInfo>>;
var
  HashGroups: TDictionary<string, TList<TDuplicateFileInfo>>;
  Pair: TPair<Int64, TArray<TDuplicateFileInfo>>;
  FileGroup: TArray<TDuplicateFileInfo>;
  I: Integer;
  FilePath: string;
  FileHash: string;
  Pair2: TPair<string, TList<TDuplicateFileInfo>>;
begin
  HashGroups := TDictionary<string, TList<TDuplicateFileInfo>>.Create;
  try
    // 对每个大小组计算哈希值
    for Pair in Groups do
    begin
      FileGroup := Pair.Value;
      for I := 0 to High(FileGroup) do
      begin
        FilePath := FileGroup[I].FilePath;
        FileHash := uFileHasher.TFileHasher.ComputeSHA256(FilePath);
        
        if not HashGroups.ContainsKey(FileHash) then
          HashGroups.Add(FileHash, TList<TDuplicateFileInfo>.Create);
        HashGroups[FileHash].Add(FileGroup[I]);
      end;
    end;
    
    // 只保留有多个文件的组
    Result := TDictionary<string, TArray<TDuplicateFileInfo>>.Create;
    for Pair2 in HashGroups do
    begin
      if Pair2.Value.Count > 1 then
        Result.Add(Pair2.Key, Pair2.Value.ToArray);
      Pair2.Value.Free;
    end;
    
    HashGroups.Free;
  except
    HashGroups.Free;
    raise;
  end;
end;

function TDuplicateFileDetector.CreateDuplicateGroups(const HashGroups: TDictionary<string, TArray<TDuplicateFileInfo>>): TArray<TDuplicateGroup>;
var
  Pair: TPair<string, TArray<TDuplicateFileInfo>>;
  FileGroup: TArray<TDuplicateFileInfo>;
  Group: TDuplicateGroup;
  I, J: Integer;
  TotalSize: Int64;
  GroupsList: TList<TDuplicateGroup>;
begin
  GroupsList := TList<TDuplicateGroup>.Create;
  try
    for Pair in HashGroups do
    begin
      FileGroup := Pair.Value;
      if Length(FileGroup) > 1 then
      begin
        Group.FileCount := Length(FileGroup);
        Group.Files := FileGroup;
        
        // 计算潜在节省空间（保留最大的文件，删除其他）
        TotalSize := 0;
        var MaxSize := 0;
        for I := 0 to High(FileGroup) do
        begin
          TotalSize := TotalSize + FileGroup[I].FileSize;
          if FileGroup[I].FileSize > MaxSize then
            MaxSize := FileGroup[I].FileSize;
        end;
        Group.PotentialSavings := TotalSize - MaxSize;
        
        GroupsList.Add(Group);
      end;
    end;
    
    Result := GroupsList.ToArray;
  finally
    GroupsList.Free;
  end;
end;

function TDuplicateFileDetector.GetRecommendedDeletions(const Groups: TArray<TDuplicateGroup>): TArray<TDuplicateGroup>;
var
  I, J: Integer;
  Group, ResultGroup: TDuplicateGroup;
  FileList: TList<TDuplicateFileInfo>;
  ResultList: TList<TDuplicateGroup>;
  NewestIndex: Integer;
begin
  ResultList := TList<TDuplicateGroup>.Create;
  try
    for I := 0 to High(Groups) do
    begin
      Group := Groups[I];
      FileList := TList<TDuplicateFileInfo>.Create;
      
      // 保留最新的文件，标记其他为待删除
      NewestIndex := 0;
      for J := 1 to High(Group.Files) do
      begin
        if Group.Files[J].LastWriteTime > Group.Files[NewestIndex].LastWriteTime then
          NewestIndex := J;
      end;
      
      // 添加除最新文件外的所有文件
      for J := 0 to High(Group.Files) do
      begin
        if J <> NewestIndex then
        begin
          var FileInfo := Group.Files[J];
          FileInfo.IsSelected := True;
          FileInfo.DeleteReason := '重复文件（保留最新版本）';
          FileList.Add(FileInfo);
        end;
      end;
      
      if FileList.Count > 0 then
      begin
        ResultGroup.FileCount := FileList.Count;
        ResultGroup.Files := FileList.ToArray;
        ResultGroup.PotentialSavings := Group.PotentialSavings;
        ResultList.Add(ResultGroup);
      end;
      
      FileList.Free;
    end;
    
    Result := ResultList.ToArray;
  finally
    ResultList.Free;
  end;
end;

function TDuplicateFileDetector.DeleteSelectedFiles(var Groups: TArray<TDuplicateGroup>; MoveToRecycleBin: Boolean): Boolean;
var
  I, J: Integer;
  Group: TDuplicateGroup;
begin
  Result := True;
  try
    for I := 0 to High(Groups) do
    begin
      Group := Groups[I];
      for J := 0 to High(Group.Files) do
      begin
        if Group.Files[J].IsSelected then
        begin
          if MoveToRecycleBin then
            uFileOperations.DeleteFileToRecycleBin(Group.Files[J].FilePath)
          else
            TFile.Delete(Group.Files[J].FilePath);
        end;
      end;
    end;
  except
    Result := False;
  end;
end;

function GetDefaultDetectionOptions: TDetectionOptions;
begin
  Result.IncludeHiddenFiles := False;
  Result.IncludeSystemFiles := False;
  Result.MinFileSize := 1024; // 1KB
  Result.MaxFileSize := 1024 * 1024 * 1024; // 1GB
  Result.HashAlgorithm := 'SHA256';
  Result.ParallelProcessing := True;
  Result.MaxThreads := 4;
end;

end.
