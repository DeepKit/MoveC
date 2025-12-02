unit uCleanupHistory;

{
  清理历史记录管理模块
  
  功能：
  - 保存清理操作历史到JSON文件
  - 加载和查询历史记录
  - 生成清理报告
  
  作者: AI助手
  版本: 1.0
  日期: 2025-12-01
}

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.DateUtils,
  System.JSON, System.Generics.Collections, System.Math, System.StrUtils;

type
  // 清理类型枚举
  TCleanupType = (
    ctRecycleBin,      // 回收站
    ctTempFiles,       // 临时文件
    ctBrowserCache,    // 浏览器缓存
    ctWindowsUpdate,   // Windows更新缓存
    ctSystemLogs,      // 系统日志
    ctPrefetch,        // 预取文件
    ctSmartCleanup     // 智能清理（综合）
  );

  // 单条清理历史记录
  TCleanupHistoryEntry = record
    ID: string;              // 唯一标识（GUID）
    Timestamp: TDateTime;    // 清理时间
    CleanupType: TCleanupType;  // 清理类型
    TypeName: string;        // 类型名称（中文）
    FilesDeleted: Integer;   // 删除文件数
    SpaceFreed: Int64;       // 释放空间（字节）
    Success: Boolean;        // 是否成功
    ErrorMessage: string;    // 错误信息
    Duration: Integer;       // 耗时（毫秒）
    Details: TArray<string>; // 详细信息
    
    function ToJSON: TJSONObject;
    procedure FromJSON(AJson: TJSONObject);
    function GetSpaceFreedStr: string;
    function GetDurationStr: string;
  end;

  // 清理历史管理器
  TCleanupHistoryManager = class
  private
    FHistoryFile: string;
    FHistory: TList<TCleanupHistoryEntry>;
    FMaxEntries: Integer;
    
    procedure LoadFromFile;
    procedure SaveToFile;
    function GetHistoryFilePath: string;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // 添加历史记录
    procedure AddEntry(const AEntry: TCleanupHistoryEntry); overload;
    procedure AddEntry(AType: TCleanupType; AFilesDeleted: Integer; 
      ASpaceFreed: Int64; ASuccess: Boolean; const AErrorMessage: string = '';
      ADuration: Integer = 0; const ADetails: TArray<string> = nil); overload;
    
    // 查询历史记录
    function GetAllEntries: TArray<TCleanupHistoryEntry>;
    function GetEntriesByType(AType: TCleanupType): TArray<TCleanupHistoryEntry>;
    function GetEntriesByDateRange(AStartDate, AEndDate: TDateTime): TArray<TCleanupHistoryEntry>;
    function GetRecentEntries(ACount: Integer = 20): TArray<TCleanupHistoryEntry>;
    
    // 统计信息
    function GetTotalSpaceFreed: Int64;
    function GetTotalFilesDeleted: Integer;
    function GetEntryCount: Integer;
    
    // 清理操作
    procedure ClearHistory;
    procedure PruneOldEntries(AKeepDays: Integer = 30);
    
    // 导出报告
    function ExportToJSON(const AFileName: string): Boolean;
    function ExportToText(const AFileName: string): Boolean;
    function GenerateReportText: string;
    
    // 属性
    property MaxEntries: Integer read FMaxEntries write FMaxEntries;
    property HistoryFile: string read FHistoryFile;
  end;

// 全局函数 - 获取清理类型名称
function CleanupTypeToString(AType: TCleanupType): string;
function StringToCleanupType(const AStr: string): TCleanupType;

// 全局单例
function CleanupHistory: TCleanupHistoryManager;

implementation

var
  GCleanupHistory: TCleanupHistoryManager = nil;

function CleanupHistory: TCleanupHistoryManager;
begin
  if not Assigned(GCleanupHistory) then
    GCleanupHistory := TCleanupHistoryManager.Create;
  Result := GCleanupHistory;
end;

function CleanupTypeToString(AType: TCleanupType): string;
begin
  case AType of
    ctRecycleBin:     Result := '回收站清理';
    ctTempFiles:      Result := '临时文件清理';
    ctBrowserCache:   Result := '浏览器缓存清理';
    ctWindowsUpdate:  Result := 'Windows更新缓存清理';
    ctSystemLogs:     Result := '系统日志清理';
    ctPrefetch:       Result := '预取文件清理';
    ctSmartCleanup:   Result := '智能清理';
  else
    Result := '未知类型';
  end;
end;

function StringToCleanupType(const AStr: string): TCleanupType;
begin
  if AStr = '回收站清理' then Result := ctRecycleBin
  else if AStr = '临时文件清理' then Result := ctTempFiles
  else if AStr = '浏览器缓存清理' then Result := ctBrowserCache
  else if AStr = 'Windows更新缓存清理' then Result := ctWindowsUpdate
  else if AStr = '系统日志清理' then Result := ctSystemLogs
  else if AStr = '预取文件清理' then Result := ctPrefetch
  else if AStr = '智能清理' then Result := ctSmartCleanup
  else Result := ctTempFiles; // 默认
end;

{ TCleanupHistoryEntry }

function TCleanupHistoryEntry.ToJSON: TJSONObject;
var
  DetailsArr: TJSONArray;
  I: Integer;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id', ID);
  Result.AddPair('timestamp', DateToISO8601(Timestamp));
  Result.AddPair('cleanupType', Integer(CleanupType));
  Result.AddPair('typeName', TypeName);
  Result.AddPair('filesDeleted', TJSONNumber.Create(FilesDeleted));
  Result.AddPair('spaceFreed', TJSONNumber.Create(SpaceFreed));
  Result.AddPair('success', TJSONBool.Create(Success));
  Result.AddPair('errorMessage', ErrorMessage);
  Result.AddPair('duration', TJSONNumber.Create(Duration));
  
  DetailsArr := TJSONArray.Create;
  for I := 0 to High(Details) do
    DetailsArr.Add(Details[I]);
  Result.AddPair('details', DetailsArr);
end;

procedure TCleanupHistoryEntry.FromJSON(AJson: TJSONObject);
var
  DetailsArr: TJSONArray;
  I: Integer;
begin
  ID := AJson.GetValue<string>('id', '');
  Timestamp := ISO8601ToDate(AJson.GetValue<string>('timestamp', ''));
  CleanupType := TCleanupType(AJson.GetValue<Integer>('cleanupType', 0));
  TypeName := AJson.GetValue<string>('typeName', '');
  FilesDeleted := AJson.GetValue<Integer>('filesDeleted', 0);
  SpaceFreed := AJson.GetValue<Int64>('spaceFreed', 0);
  Success := AJson.GetValue<Boolean>('success', False);
  ErrorMessage := AJson.GetValue<string>('errorMessage', '');
  Duration := AJson.GetValue<Integer>('duration', 0);
  
  SetLength(Details, 0);
  if AJson.TryGetValue<TJSONArray>('details', DetailsArr) then
  begin
    SetLength(Details, DetailsArr.Count);
    for I := 0 to DetailsArr.Count - 1 do
      Details[I] := DetailsArr.Items[I].Value;
  end;
end;

function TCleanupHistoryEntry.GetSpaceFreedStr: string;
begin
  if SpaceFreed < 1024 then
    Result := Format('%d B', [SpaceFreed])
  else if SpaceFreed < 1024 * 1024 then
    Result := Format('%.2f KB', [SpaceFreed / 1024])
  else if SpaceFreed < 1024 * 1024 * 1024 then
    Result := Format('%.2f MB', [SpaceFreed / (1024 * 1024)])
  else
    Result := Format('%.2f GB', [SpaceFreed / (1024 * 1024 * 1024)]);
end;

function TCleanupHistoryEntry.GetDurationStr: string;
begin
  if Duration < 1000 then
    Result := Format('%d 毫秒', [Duration])
  else if Duration < 60000 then
    Result := Format('%.1f 秒', [Duration / 1000])
  else
    Result := Format('%.1f 分钟', [Duration / 60000]);
end;

{ TCleanupHistoryManager }

constructor TCleanupHistoryManager.Create;
begin
  inherited Create;
  FHistory := TList<TCleanupHistoryEntry>.Create;
  FMaxEntries := 500; // 最多保存500条记录
  FHistoryFile := GetHistoryFilePath;
  LoadFromFile;
end;

destructor TCleanupHistoryManager.Destroy;
begin
  SaveToFile;
  FHistory.Free;
  inherited Destroy;
end;

function TCleanupHistoryManager.GetHistoryFilePath: string;
begin
  Result := TPath.Combine(ExtractFilePath(ParamStr(0)), 'cleanup_history.json');
end;

procedure TCleanupHistoryManager.LoadFromFile;
var
  JsonStr: string;
  JsonArr: TJSONArray;
  JsonObj: TJSONObject;
  I: Integer;
  Entry: TCleanupHistoryEntry;
begin
  FHistory.Clear;
  
  if not TFile.Exists(FHistoryFile) then
    Exit;
    
  try
    JsonStr := TFile.ReadAllText(FHistoryFile, TEncoding.UTF8);
    JsonArr := TJSONObject.ParseJSONValue(JsonStr) as TJSONArray;
    if Assigned(JsonArr) then
    begin
      try
        for I := 0 to JsonArr.Count - 1 do
        begin
          JsonObj := JsonArr.Items[I] as TJSONObject;
          Entry.FromJSON(JsonObj);
          FHistory.Add(Entry);
        end;
      finally
        JsonArr.Free;
      end;
    end;
  except
    // 忽略加载错误，使用空历史
  end;
end;

procedure TCleanupHistoryManager.SaveToFile;
var
  JsonArr: TJSONArray;
  I: Integer;
begin
  JsonArr := TJSONArray.Create;
  try
    for I := 0 to FHistory.Count - 1 do
      JsonArr.AddElement(FHistory[I].ToJSON);
      
    TFile.WriteAllText(FHistoryFile, JsonArr.Format(2), TEncoding.UTF8);
  finally
    JsonArr.Free;
  end;
end;

procedure TCleanupHistoryManager.AddEntry(const AEntry: TCleanupHistoryEntry);
var
  Entry: TCleanupHistoryEntry;
begin
  Entry := AEntry;
  if Entry.ID = '' then
    Entry.ID := TGUID.NewGuid.ToString;
  if Entry.TypeName = '' then
    Entry.TypeName := CleanupTypeToString(Entry.CleanupType);
    
  FHistory.Insert(0, Entry); // 最新的在前面
  
  // 限制历史记录数量
  while FHistory.Count > FMaxEntries do
    FHistory.Delete(FHistory.Count - 1);
    
  SaveToFile;
end;

procedure TCleanupHistoryManager.AddEntry(AType: TCleanupType; AFilesDeleted: Integer;
  ASpaceFreed: Int64; ASuccess: Boolean; const AErrorMessage: string;
  ADuration: Integer; const ADetails: TArray<string>);
var
  Entry: TCleanupHistoryEntry;
begin
  Entry.ID := TGUID.NewGuid.ToString;
  Entry.Timestamp := Now;
  Entry.CleanupType := AType;
  Entry.TypeName := CleanupTypeToString(AType);
  Entry.FilesDeleted := AFilesDeleted;
  Entry.SpaceFreed := ASpaceFreed;
  Entry.Success := ASuccess;
  Entry.ErrorMessage := AErrorMessage;
  Entry.Duration := ADuration;
  Entry.Details := ADetails;
  
  AddEntry(Entry);
end;

function TCleanupHistoryManager.GetAllEntries: TArray<TCleanupHistoryEntry>;
begin
  Result := FHistory.ToArray;
end;

function TCleanupHistoryManager.GetEntriesByType(AType: TCleanupType): TArray<TCleanupHistoryEntry>;
var
  ResultList: TList<TCleanupHistoryEntry>;
  Entry: TCleanupHistoryEntry;
begin
  ResultList := TList<TCleanupHistoryEntry>.Create;
  try
    for Entry in FHistory do
    begin
      if Entry.CleanupType = AType then
        ResultList.Add(Entry);
    end;
    Result := ResultList.ToArray;
  finally
    ResultList.Free;
  end;
end;

function TCleanupHistoryManager.GetEntriesByDateRange(AStartDate, AEndDate: TDateTime): TArray<TCleanupHistoryEntry>;
var
  ResultList: TList<TCleanupHistoryEntry>;
  Entry: TCleanupHistoryEntry;
begin
  ResultList := TList<TCleanupHistoryEntry>.Create;
  try
    for Entry in FHistory do
    begin
      if (Entry.Timestamp >= AStartDate) and (Entry.Timestamp <= AEndDate) then
        ResultList.Add(Entry);
    end;
    Result := ResultList.ToArray;
  finally
    ResultList.Free;
  end;
end;

function TCleanupHistoryManager.GetRecentEntries(ACount: Integer): TArray<TCleanupHistoryEntry>;
var
  I, Count: Integer;
begin
  Count := Min(ACount, FHistory.Count);
  SetLength(Result, Count);
  for I := 0 to Count - 1 do
    Result[I] := FHistory[I];
end;

function TCleanupHistoryManager.GetTotalSpaceFreed: Int64;
var
  Entry: TCleanupHistoryEntry;
begin
  Result := 0;
  for Entry in FHistory do
    Result := Result + Entry.SpaceFreed;
end;

function TCleanupHistoryManager.GetTotalFilesDeleted: Integer;
var
  Entry: TCleanupHistoryEntry;
begin
  Result := 0;
  for Entry in FHistory do
    Result := Result + Entry.FilesDeleted;
end;

function TCleanupHistoryManager.GetEntryCount: Integer;
begin
  Result := FHistory.Count;
end;

procedure TCleanupHistoryManager.ClearHistory;
begin
  FHistory.Clear;
  SaveToFile;
end;

procedure TCleanupHistoryManager.PruneOldEntries(AKeepDays: Integer);
var
  CutoffDate: TDateTime;
  I: Integer;
begin
  CutoffDate := Now - AKeepDays;
  
  for I := FHistory.Count - 1 downto 0 do
  begin
    if FHistory[I].Timestamp < CutoffDate then
      FHistory.Delete(I);
  end;
  
  SaveToFile;
end;

function TCleanupHistoryManager.ExportToJSON(const AFileName: string): Boolean;
var
  JsonArr: TJSONArray;
  I: Integer;
begin
  Result := False;
  JsonArr := TJSONArray.Create;
  try
    for I := 0 to FHistory.Count - 1 do
      JsonArr.AddElement(FHistory[I].ToJSON);
      
    TFile.WriteAllText(AFileName, JsonArr.Format(2), TEncoding.UTF8);
    Result := True;
  finally
    JsonArr.Free;
  end;
end;

function TCleanupHistoryManager.ExportToText(const AFileName: string): Boolean;
begin
  Result := False;
  try
    TFile.WriteAllText(AFileName, GenerateReportText, TEncoding.UTF8);
    Result := True;
  except
  end;
end;

function TCleanupHistoryManager.GenerateReportText: string;
var
  SB: TStringBuilder;
  Entry: TCleanupHistoryEntry;
  I: Integer;
begin
  SB := TStringBuilder.Create;
  try
    SB.AppendLine('========================================');
    SB.AppendLine('        MoveC 清理历史报告');
    SB.AppendLine('========================================');
    SB.AppendLine('');
    SB.AppendLine(Format('生成时间: %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)]));
    SB.AppendLine(Format('总记录数: %d', [FHistory.Count]));
    SB.AppendLine(Format('累计释放空间: %.2f MB', [GetTotalSpaceFreed / (1024 * 1024)]));
    SB.AppendLine(Format('累计删除文件: %d 个', [GetTotalFilesDeleted]));
    SB.AppendLine('');
    SB.AppendLine('----------------------------------------');
    SB.AppendLine('详细记录:');
    SB.AppendLine('----------------------------------------');
    
    for I := 0 to FHistory.Count - 1 do
    begin
      Entry := FHistory[I];
      SB.AppendLine('');
      SB.AppendLine(Format('[%d] %s', [I + 1, FormatDateTime('yyyy-mm-dd hh:nn:ss', Entry.Timestamp)]));
      SB.AppendLine(Format('    类型: %s', [Entry.TypeName]));
      SB.AppendLine(Format('    状态: %s', [IfThen(Entry.Success, '成功', '失败')]));
      SB.AppendLine(Format('    删除文件: %d 个', [Entry.FilesDeleted]));
      SB.AppendLine(Format('    释放空间: %s', [Entry.GetSpaceFreedStr]));
      SB.AppendLine(Format('    耗时: %s', [Entry.GetDurationStr]));
      if Entry.ErrorMessage <> '' then
        SB.AppendLine(Format('    错误: %s', [Entry.ErrorMessage]));
    end;
    
    SB.AppendLine('');
    SB.AppendLine('========================================');
    SB.AppendLine('                报告结束');
    SB.AppendLine('========================================');
    
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

initialization

finalization
  if Assigned(GCleanupHistory) then
    FreeAndNil(GCleanupHistory);

end.
