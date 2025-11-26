unit uAdvancedFileManager;

{
  高级文件管理模块 - Phase 2.1
  
  功能包括：
  - 智能文件搜索和过滤
  - 批量文件操作
  - 文件关联分析
  - 重复文件检测
  - 大文件识别
  - 文件分类和标记
  
  作者: AI助手
  版本: 2.1.0
  日期: 2024
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.IOUtils,
  System.Threading, System.RegularExpressions, System.Math,
  System.Generics.Defaults,
  Vcl.Forms, Vcl.ComCtrls, Vcl.Controls,
  Winapi.Windows;

type
  // 文件信息扩展记录
  TAdvancedFileInfo = record
    FullPath: string;
    FileName: string;
    FileSize: Int64;
    CreationTime: TDateTime;
    LastWriteTime: TDateTime;
    LastAccessTime: TDateTime;
    Attributes: Integer;
    Extension: string;
    FileType: string;
    MD5Hash: string;
    Category: string;
    Tags: TArray<string>;
    IsSystemFile: Boolean;
    IsHidden: Boolean;
    IsReadOnly: Boolean;
  end;

  // 搜索条件
  TFileSearchCriteria = record
    SearchPath: string;
    NamePattern: string;
    UseRegex: Boolean;
    MinSize: Int64;
    MaxSize: Int64;
    DateFrom: TDateTime;
    DateTo: TDateTime;
    Extensions: TArray<string>;
    IncludeSubdirs: Boolean;
    IncludeHidden: Boolean;
    IncludeSystem: Boolean;
    Categories: TArray<string>;
  end;

  // 批量操作类型
  TBatchOperationType = (
    botNone,
    botCopy,
    botMove,
    botDelete,
    botRename,
    botChangeAttributes,
    botCompress,
    botExtract
  );

  // 批量操作参数
  TBatchOperationParams = record
    OperationType: TBatchOperationType;
    TargetPath: string;
    NewNamePattern: string;
    NewAttributes: Integer;
    CompressionLevel: Integer;
    OverwriteExisting: Boolean;
  end;

  // 重复文件组
  TDuplicateFileGroup = record
    MD5Hash: string;
    TotalSize: Int64;
    FileCount: Integer;
    Files: TArray<TAdvancedFileInfo>;
  end;

  // 进度回调
  TProgressCallback = procedure(const Message: string; Progress: Integer; Cancel: Boolean) of object;

  // 高级文件管理器类
  TAdvancedFileManager = class
  private
    FFiles: TList<TAdvancedFileInfo>;
    FDuplicateGroups: TList<TDuplicateFileGroup>;
    FCancelRequested: Boolean;
    FOnProgress: TProgressCallback;
    
    function GetFileCategory(const FileExt: string): string;
    function CalculateMD5Hash(const FileName: string): string;
    function MatchesSearchCriteria(const FileInfo: TAdvancedFileInfo; 
      const Criteria: TFileSearchCriteria): Boolean;
    procedure UpdateProgress(const Message: string; Progress: Integer);
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // 属性
    property OnProgress: TProgressCallback read FOnProgress write FOnProgress;
    
    // 文件搜索
    function SearchFiles(const Criteria: TFileSearchCriteria): TArray<TAdvancedFileInfo>;
    function QuickSearch(const SearchPath: string; const Pattern: string): TArray<TAdvancedFileInfo>;
    
    // 文件分析
    function AnalyzeDirectory(const DirPath: string): Boolean;
    function FindDuplicateFiles(const SearchPath: string): TArray<TDuplicateFileGroup>;
    function FindLargeFiles(const SearchPath: string; MinSize: Int64): TArray<TAdvancedFileInfo>;
    
    // 批量操作
    function BatchOperation(const Files: TArray<string>; 
      const Params: TBatchOperationParams): Boolean;
    
    // 文件分类
    function CategorizeFiles(const Files: TArray<TAdvancedFileInfo>): TDictionary<string, TArray<TAdvancedFileInfo>>;
    
    // 工具方法
    procedure CancelOperation;
    procedure ClearCache;
    function GetFileInfo(const FilePath: string): TAdvancedFileInfo;
    function FormatFileSize(Size: Int64): string;
    function GetFileTypeDescription(const Extension: string): string;
    
  end;

implementation

uses
  System.Hash, System.StrUtils, System.DateUtils, System.Zip;

{ TAdvancedFileManager }

constructor TAdvancedFileManager.Create;
begin
  inherited Create;
  FFiles := TList<TAdvancedFileInfo>.Create;
  FDuplicateGroups := TList<TDuplicateFileGroup>.Create;
  FCancelRequested := False;
end;

destructor TAdvancedFileManager.Destroy;
begin
  FFiles.Free;
  FDuplicateGroups.Free;
  inherited Destroy;
end;


procedure TAdvancedFileManager.UpdateProgress(const Message: string; Progress: Integer);
begin
  if Assigned(FOnProgress) then
    FOnProgress(Message, Progress, FCancelRequested);
end;

function TAdvancedFileManager.GetFileCategory(const FileExt: string): string;
var
  Ext: string;
begin
  Ext := LowerCase(FileExt);
  
  // 图像文件
  if TRegEx.IsMatch(Ext, '\.(jpg|jpeg|png|gif|bmp|tiff|svg|webp|ico)$') then
    Result := '图像文件'
  // 视频文件
  else if TRegEx.IsMatch(Ext, '\.(mp4|avi|mov|wmv|flv|mkv|webm|m4v)$') then
    Result := '视频文件'
  // 音频文件
  else if TRegEx.IsMatch(Ext, '\.(mp3|wav|flac|aac|ogg|wma|m4a)$') then
    Result := '音频文件'
  // 文档文件
  else if TRegEx.IsMatch(Ext, '\.(doc|docx|pdf|txt|rtf|xls|xlsx|ppt|pptx)$') then
    Result := '文档文件'
  // 压缩文件
  else if TRegEx.IsMatch(Ext, '\.(zip|rar|7z|tar|gz|bz2)$') then
    Result := '压缩文件'
  // 可执行文件
  else if TRegEx.IsMatch(Ext, '\.(exe|msi|bat|cmd|com|scr)$') then
    Result := '可执行文件'
  // 代码文件
  else if TRegEx.IsMatch(Ext, '\.(pas|cpp|c|h|js|html|css|php|py|java|cs)$') then
    Result := '代码文件'
  else
    Result := '其他文件';
end;

function TAdvancedFileManager.CalculateMD5Hash(const FileName: string): string;
var
  FileStream: TFileStream;
  Hash: THashMD5;
  Buffer: TBytes;
  BytesRead: Integer;
const
  BUFFER_SIZE = 8192;
begin
  Result := '';
  try
    if not TFile.Exists(FileName) then Exit;
    
    FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
    try
      Hash := THashMD5.Create;
      SetLength(Buffer, BUFFER_SIZE);
      
      while FileStream.Position < FileStream.Size do
      begin
        BytesRead := FileStream.Read(Buffer[0], BUFFER_SIZE);
        if BytesRead > 0 then
          Hash.Update(Buffer[0], BytesRead);
      end;
      
      Result := Hash.HashAsString;
    finally
      FileStream.Free;
    end;
  except
    // 忽略无法访问的文件
    Result := '';
  end;
end;

function TAdvancedFileManager.GetFileInfo(const FilePath: string): TAdvancedFileInfo;
var
  FileAttribs: TFileAttributes;
  AttrInt: Integer;
begin
  ZeroMemory(@Result, SizeOf(Result));
  
  if not TFile.Exists(FilePath) then Exit;
  
  Result.FullPath := FilePath;
  Result.FileName := TPath.GetFileName(FilePath);
  Result.Extension := TPath.GetExtension(FilePath);
  
  try
    Result.FileSize := TFile.GetSize(FilePath);
    Result.CreationTime := TFile.GetCreationTime(FilePath);
    Result.LastWriteTime := TFile.GetLastWriteTime(FilePath);
    Result.LastAccessTime := TFile.GetLastAccessTime(FilePath);
    
    {$IFDEF MSWINDOWS}
    FileAttribs := TFile.GetAttributes(FilePath);
    AttrInt := 0;
    if TFileAttribute.faHidden in FileAttribs then AttrInt := AttrInt or faHidden;
    if TFileAttribute.faReadOnly in FileAttribs then AttrInt := AttrInt or faReadOnly;
    if TFileAttribute.faSystem in FileAttribs then AttrInt := AttrInt or faSysFile;
    Result.Attributes := AttrInt;
    Result.IsHidden := TFileAttribute.faHidden in FileAttribs;
    Result.IsReadOnly := TFileAttribute.faReadOnly in FileAttribs;
    Result.IsSystemFile := TFileAttribute.faSystem in FileAttribs;
    {$ELSE}
    Result.Attributes := 0;
    Result.IsHidden := False;
    Result.IsReadOnly := False;
    Result.IsSystemFile := False;
    {$ENDIF}
    
    Result.Category := GetFileCategory(Result.Extension);
    Result.FileType := GetFileTypeDescription(Result.Extension);
    
  except
    // 忽略获取信息失败的文件
  end;
end;

function TAdvancedFileManager.MatchesSearchCriteria(const FileInfo: TAdvancedFileInfo;
  const Criteria: TFileSearchCriteria): Boolean;
var
  NameMatch: Boolean;
  SizeMatch: Boolean;
  DateMatch: Boolean;
  ExtMatch: Boolean;
  CategoryMatch: Boolean;
  I: Integer;
begin
  Result := False;
  
  // 文件名匹配
  if Criteria.UseRegex then
    NameMatch := TRegEx.IsMatch(FileInfo.FileName, Criteria.NamePattern, [roIgnoreCase])
  else
    NameMatch := (Criteria.NamePattern = '') or 
                 ContainsText(FileInfo.FileName, Criteria.NamePattern);
  
  if not NameMatch then Exit;
  
  // 大小匹配
  SizeMatch := (Criteria.MinSize <= 0) or (FileInfo.FileSize >= Criteria.MinSize);
  if SizeMatch and (Criteria.MaxSize > 0) then
    SizeMatch := FileInfo.FileSize <= Criteria.MaxSize;
  
  if not SizeMatch then Exit;
  
  // 日期匹配
  DateMatch := True;
  if Criteria.DateFrom > 0 then
    DateMatch := FileInfo.LastWriteTime >= Criteria.DateFrom;
  if DateMatch and (Criteria.DateTo > 0) then
    DateMatch := FileInfo.LastWriteTime <= Criteria.DateTo;
  
  if not DateMatch then Exit;
  
  // 扩展名匹配
  ExtMatch := (Length(Criteria.Extensions) = 0);
  if not ExtMatch then
  begin
    for I := 0 to High(Criteria.Extensions) do
    begin
      if SameText(FileInfo.Extension, Criteria.Extensions[I]) then
      begin
        ExtMatch := True;
        Break;
      end;
    end;
  end;
  
  if not ExtMatch then Exit;
  
  // 分类匹配
  CategoryMatch := (Length(Criteria.Categories) = 0);
  if not CategoryMatch then
  begin
    for I := 0 to High(Criteria.Categories) do
    begin
      if SameText(FileInfo.Category, Criteria.Categories[I]) then
      begin
        CategoryMatch := True;
        Break;
      end;
    end;
  end;
  
  if not CategoryMatch then Exit;
  
  // 隐藏文件和系统文件检查
  if not Criteria.IncludeHidden and FileInfo.IsHidden then Exit;
  if not Criteria.IncludeSystem and FileInfo.IsSystemFile then Exit;
  
  Result := True;
end;

function TAdvancedFileManager.SearchFiles(const Criteria: TFileSearchCriteria): TArray<TAdvancedFileInfo>;
var
  Files: TArray<string>;
  ResultList: TList<TAdvancedFileInfo>;
  FileInfo: TAdvancedFileInfo;
  I: Integer;
  SearchOption: TSearchOption;
begin
  ResultList := TList<TAdvancedFileInfo>.Create;
  try
    FCancelRequested := False;
    UpdateProgress('开始搜索文件...', 0);
    
    // 设置搜索选项
    if Criteria.IncludeSubdirs then
      SearchOption := TSearchOption.soAllDirectories
    else
      SearchOption := TSearchOption.soTopDirectoryOnly;
    
    // 获取文件列表
    try
      Files := TDirectory.GetFiles(Criteria.SearchPath, '*', SearchOption);
      UpdateProgress(Format('找到 %d 个文件，正在分析...', [Length(Files)]), 10);
      
      for I := 0 to High(Files) do
      begin
        if FCancelRequested then Break;
        
        FileInfo := GetFileInfo(Files[I]);
        if MatchesSearchCriteria(FileInfo, Criteria) then
          ResultList.Add(FileInfo);
        
        if (I mod 100 = 0) then
          UpdateProgress(Format('已分析 %d/%d 个文件', [I + 1, Length(Files)]), 
                        10 + Round((I * 80) / Length(Files)));
      end;
      
    except
      on E: Exception do
        UpdateProgress('搜索失败: ' + E.Message, -1);
    end;
    
    Result := ResultList.ToArray;
    UpdateProgress(Format('搜索完成，找到 %d 个匹配文件', [Length(Result)]), 100);
    
  finally
    ResultList.Free;
  end;
end;

function TAdvancedFileManager.QuickSearch(const SearchPath: string; 
  const Pattern: string): TArray<TAdvancedFileInfo>;
var
  Criteria: TFileSearchCriteria;
begin
  // 设置快速搜索条件
  ZeroMemory(@Criteria, SizeOf(Criteria));
  Criteria.SearchPath := SearchPath;
  Criteria.NamePattern := Pattern;
  Criteria.UseRegex := False;
  Criteria.IncludeSubdirs := True;
  Criteria.IncludeHidden := False;
  Criteria.IncludeSystem := False;
  
  Result := SearchFiles(Criteria);
end;

function TAdvancedFileManager.FindDuplicateFiles(const SearchPath: string): TArray<TDuplicateFileGroup>;
var
  Files: TArray<string>;
  HashDict: TDictionary<string, TList<TAdvancedFileInfo>>;
  FileInfo: TAdvancedFileInfo;
  HashList: TList<TAdvancedFileInfo>;
  Group: TDuplicateFileGroup;
  ResultList: TList<TDuplicateFileGroup>;
  Hash: string;
  I, J: Integer;
begin
  ResultList := TList<TDuplicateFileGroup>.Create;
  HashDict := TDictionary<string, TList<TAdvancedFileInfo>>.Create;
  try
    FCancelRequested := False;
    UpdateProgress('开始扫描重复文件...', 0);
    
    Files := TDirectory.GetFiles(SearchPath, '*', TSearchOption.soAllDirectories);
    UpdateProgress(Format('找到 %d 个文件，正在计算哈希值...', [Length(Files)]), 5);
    
    // 计算所有文件的MD5哈希值
    for I := 0 to High(Files) do
    begin
      if FCancelRequested then Break;
      
      FileInfo := GetFileInfo(Files[I]);
      if FileInfo.FileSize > 0 then // 跳过空文件
      begin
        Hash := CalculateMD5Hash(Files[I]);
        if Hash <> '' then
        begin
          FileInfo.MD5Hash := Hash;
          
          if not HashDict.TryGetValue(Hash, HashList) then
          begin
            HashList := TList<TAdvancedFileInfo>.Create;
            HashDict.Add(Hash, HashList);
          end;
          HashList.Add(FileInfo);
        end;
      end;
      
      if (I mod 50 = 0) then
        UpdateProgress(Format('已处理 %d/%d 个文件', [I + 1, Length(Files)]), 
                      5 + Round((I * 85) / Length(Files)));
    end;
    
    UpdateProgress('正在分析重复文件组...', 90);
    
    // 找出重复文件组
    for Hash in HashDict.Keys do
    begin
      HashList := HashDict[Hash];
      if HashList.Count > 1 then
      begin
        Group.MD5Hash := Hash;
        Group.FileCount := HashList.Count;
        Group.TotalSize := 0;
        SetLength(Group.Files, HashList.Count);
        
        for J := 0 to HashList.Count - 1 do
        begin
          Group.Files[J] := HashList[J];
          Group.TotalSize := Group.TotalSize + HashList[J].FileSize;
        end;
        
        ResultList.Add(Group);
      end;
    end;
    
    Result := ResultList.ToArray;
    UpdateProgress(Format('重复文件扫描完成，找到 %d 组重复文件', [Length(Result)]), 100);
    
  finally
    // 清理字典中的列表
    for HashList in HashDict.Values do
      HashList.Free;
    HashDict.Free;
    ResultList.Free;
  end;
end;

function TAdvancedFileManager.FindLargeFiles(const SearchPath: string; MinSize: Int64): TArray<TAdvancedFileInfo>;
var
  Files: TArray<string>;
  FileInfo: TAdvancedFileInfo;
  ResultList: TList<TAdvancedFileInfo>;
  I: Integer;
begin
  ResultList := TList<TAdvancedFileInfo>.Create;
  try
    FCancelRequested := False;
    UpdateProgress('开始搜索大文件...', 0);
    
    Files := TDirectory.GetFiles(SearchPath, '*', TSearchOption.soAllDirectories);
    UpdateProgress(Format('找到 %d 个文件，正在分析大小...', [Length(Files)]), 10);
    
    for I := 0 to High(Files) do
    begin
      if FCancelRequested then Break;
      
      FileInfo := GetFileInfo(Files[I]);
      if FileInfo.FileSize >= MinSize then
        ResultList.Add(FileInfo);
      
      if (I mod 100 = 0) then
        UpdateProgress(Format('已分析 %d/%d 个文件', [I + 1, Length(Files)]), 
                      10 + Round((I * 80) / Length(Files)));
    end;
    
    // 按大小排序（从大到小）
    ResultList.Sort(TComparer<TAdvancedFileInfo>.Construct(
      function(const Left, Right: TAdvancedFileInfo): Integer
      begin
        Result := CompareValue(Right.FileSize, Left.FileSize);
      end));
    
    Result := ResultList.ToArray;
    UpdateProgress(Format('大文件搜索完成，找到 %d 个大文件', [Length(Result)]), 100);
    
  finally
    ResultList.Free;
  end;
end;

function TAdvancedFileManager.CategorizeFiles(const Files: TArray<TAdvancedFileInfo>): TDictionary<string, TArray<TAdvancedFileInfo>>;
var
  CategoryDict: TDictionary<string, TList<TAdvancedFileInfo>>;
  CategoryList: TList<TAdvancedFileInfo>;
  FileInfo: TAdvancedFileInfo;
  Category: string;
  I: Integer;
begin
  Result := TDictionary<string, TArray<TAdvancedFileInfo>>.Create;
  CategoryDict := TDictionary<string, TList<TAdvancedFileInfo>>.Create;
  try
    UpdateProgress('开始文件分类...', 0);
    
    for I := 0 to High(Files) do
    begin
      FileInfo := Files[I];
      Category := FileInfo.Category;
      
      if not CategoryDict.TryGetValue(Category, CategoryList) then
      begin
        CategoryList := TList<TAdvancedFileInfo>.Create;
        CategoryDict.Add(Category, CategoryList);
      end;
      CategoryList.Add(FileInfo);
      
      if (I mod 100 = 0) then
        UpdateProgress(Format('已分类 %d/%d 个文件', [I + 1, Length(Files)]), 
                      Round((I * 100) / Length(Files)));
    end;
    
    // 转换为结果格式
    for Category in CategoryDict.Keys do
    begin
      CategoryList := CategoryDict[Category];
      Result.Add(Category, CategoryList.ToArray);
    end;
    
    UpdateProgress('文件分类完成', 100);
    
  finally
    for CategoryList in CategoryDict.Values do
      CategoryList.Free;
    CategoryDict.Free;
  end;
end;

function TAdvancedFileManager.BatchOperation(const Files: TArray<string>; 
  const Params: TBatchOperationParams): Boolean;
var
  I: Integer;
  SourceFile, TargetFile: string;
  Success: Integer;
begin
  Result := False;
  Success := 0;
  FCancelRequested := False;
  
  UpdateProgress(Format('开始批量操作，共 %d 个文件', [Length(Files)]), 0);
  
  try
    for I := 0 to High(Files) do
    begin
      if FCancelRequested then Break;
      
      SourceFile := Files[I];
      
      case Params.OperationType of
        botCopy:
        begin
          TargetFile := TPath.Combine(Params.TargetPath, TPath.GetFileName(SourceFile));
          try
            TFile.Copy(SourceFile, TargetFile, Params.OverwriteExisting);
            Inc(Success);
          except
            // 忽略复制失败的文件
          end;
        end;
        
        botMove:
        begin
          TargetFile := TPath.Combine(Params.TargetPath, TPath.GetFileName(SourceFile));
          try
            TFile.Move(SourceFile, TargetFile);
            Inc(Success);
          except
            // 忽略移动失败的文件
          end;
        end;
        
        botDelete:
        begin
          try
            TFile.Delete(SourceFile);
            Inc(Success);
          except
            // 忽略删除失败的文件
          end;
        end;
        
        // 其他操作类型的实现...
      end;
      
      UpdateProgress(Format('已处理 %d/%d 个文件', [I + 1, Length(Files)]), 
                    Round(((I + 1) * 100) / Length(Files)));
    end;
    
    UpdateProgress(Format('批量操作完成，成功处理 %d/%d 个文件', [Success, Length(Files)]), 100);
    Result := Success > 0;
    
  except
    on E: Exception do
    begin
      UpdateProgress('批量操作失败: ' + E.Message, -1);
      Result := False;
    end;
  end;
end;

procedure TAdvancedFileManager.CancelOperation;
begin
  FCancelRequested := True;
end;

procedure TAdvancedFileManager.ClearCache;
begin
  FFiles.Clear;
  FDuplicateGroups.Clear;
end;

function TAdvancedFileManager.FormatFileSize(Size: Int64): string;
const
  Units: array[0..4] of string = ('B', 'KB', 'MB', 'GB', 'TB');
var
  UnitIndex: Integer;
  SizeValue: Double;
begin
  UnitIndex := 0;
  SizeValue := Size;
  
  while (SizeValue >= 1024) and (UnitIndex < High(Units)) do
  begin
    SizeValue := SizeValue / 1024;
    Inc(UnitIndex);
  end;
  
  if UnitIndex = 0 then
    Result := Format('%d %s', [Round(SizeValue), Units[UnitIndex]])
  else
    Result := Format('%.2f %s', [SizeValue, Units[UnitIndex]]);
end;

function TAdvancedFileManager.GetFileTypeDescription(const Extension: string): string;
var
  Ext: string;
begin
  Ext := LowerCase(Extension);
  
  case IndexStr(Ext, ['.txt', '.doc', '.docx', '.pdf', '.rtf']) of
    0: Result := '文本文档';
    1, 2: Result := 'Word文档';
    3: Result := 'PDF文档';
    4: Result := 'RTF文档';
  else
    if Ext <> '' then
      Result := UpperCase(Copy(Ext, 2, MaxInt)) + '文件'
    else
      Result := '未知文件类型';
  end;
end;

function TAdvancedFileManager.AnalyzeDirectory(const DirPath: string): Boolean;
var
  Files: TArray<string>;
  FileInfo: TAdvancedFileInfo;
  I: Integer;
begin
  Result := False;
  FCancelRequested := False;
  FFiles.Clear;
  
  try
    UpdateProgress('开始分析目录...', 0);
    
    Files := TDirectory.GetFiles(DirPath, '*', TSearchOption.soAllDirectories);
    UpdateProgress(Format('找到 %d 个文件，正在分析...', [Length(Files)]), 5);
    
    for I := 0 to High(Files) do
    begin
      if FCancelRequested then Break;
      
      FileInfo := GetFileInfo(Files[I]);
      FFiles.Add(FileInfo);
      
      if (I mod 100 = 0) then
        UpdateProgress(Format('已分析 %d/%d 个文件', [I + 1, Length(Files)]), 
                      5 + Round((I * 90) / Length(Files)));
    end;
    
    UpdateProgress('目录分析完成', 100);
    Result := not FCancelRequested;
    
  except
    on E: Exception do
    begin
      UpdateProgress('目录分析失败: ' + E.Message, -1);
      Result := False;
    end;
  end;
end;

end.