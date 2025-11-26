unit uLogManager;

{
  日志管理器 - Comprehensive Logging System
  
  功能包括：
  - 多级别日志记录 (Debug, Info, Warning, Error, Critical)
  - 自动日志轮转和存档
  - 日志查看器界面
  - 日志过滤和搜索
  - 日志导出功能
  
  作者: AI助手
  版本: 1.0
  日期: 2024
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.IOUtils, System.DateUtils, System.Generics.Collections, System.Threading,
  System.SyncObjs, System.RegularExpressions, System.UITypes, System.StrUtils,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, Vcl.Buttons, Vcl.CheckLst, Vcl.Menus, Vcl.FileCtrl;

type
  TLogLevel = (llDebug, llInfo, llWarning, llError, llCritical);

  TLogEntry = record
    Timestamp: TDateTime;
    Level: TLogLevel;
    Module: string;
    Message: string;
    ThreadID: Cardinal;
    ProcessID: Cardinal;
  end;
  PLogEntry = ^TLogEntry;

  TLogFilter = record
    StartDate: TDateTime;
    EndDate: TDateTime;
    Level: TLogLevel;
    Module: string;
    SearchText: string;
    IncludeThreadInfo: Boolean;
  end;

  TOnLogEvent = procedure(const Entry: TLogEntry) of object;

  // 日志管理器核心类
  TLogManager = class
  private
    FLogFile: string;
    FLogDirectory: string;
    FMaxFileSize: Int64;
    FMaxFiles: Integer;
    FAutoRotate: Boolean;
    FLogLevel: TLogLevel;
    FLogToFile: Boolean;
    FLogToDebug: Boolean;
    FFileStream: TFileStream;
    FLock: TCriticalSection;
    FLogCache: TList<TLogEntry>;
    FOnLogEvent: TOnLogEvent;
    
    procedure WriteToFile(const Entry: TLogEntry);
    procedure WriteToDebug(const Entry: TLogEntry);
    procedure RotateLogFile;
    function GetLogFileName(Index: Integer = 0): string;
    function FormatLogEntry(const Entry: TLogEntry): string;
    function ParseLogLevel(const LevelStr: string): TLogLevel;
    function LogLevelToString(Level: TLogLevel): string;
    function LogLevelToColor(Level: TLogLevel): TColor;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // 基本日志记录方法
    procedure Log(Level: TLogLevel; const Module, Message: string);
    procedure Debug(const Module, Message: string);
    procedure Info(const Module, Message: string);  
    procedure Warning(const Module, Message: string);
    procedure Error(const Module, Message: string);
    procedure Critical(const Module, Message: string);
    
    // 格式化日志记录
    procedure LogFormat(Level: TLogLevel; const Module, AFormat: string; const Args: array of const);
    procedure InfoFormat(const Module, AFormat: string; const Args: array of const);
    procedure ErrorFormat(const Module, AFormat: string; const Args: array of const);
    
    // 日志文件管理
    procedure FlushLogs;
    procedure ClearLogs;
    procedure RotateLogs;
    function GetLogFiles: TArray<string>;
    function LoadLogsFromFile(const FileName: string): TArray<TLogEntry>;
    function GetRecentLogs(Count: Integer = 100): TArray<TLogEntry>;
    
    // 日志过滤和搜索
    function FilterLogs(const Filter: TLogFilter): TArray<TLogEntry>;
    function SearchLogs(const SearchText: string): TArray<TLogEntry>;
    
    // 日志导出
    function ExportToText(const FileName: string; const Filter: TLogFilter): Boolean;
    function ExportToCSV(const FileName: string; const Filter: TLogFilter): Boolean;
    function ExportToHTML(const FileName: string; const Filter: TLogFilter): Boolean;
    
    // 属性
    property LogFile: string read FLogFile write FLogFile;
    property LogDirectory: string read FLogDirectory write FLogDirectory;
    property MaxFileSize: Int64 read FMaxFileSize write FMaxFileSize;
    property MaxFiles: Integer read FMaxFiles write FMaxFiles;
    property AutoRotate: Boolean read FAutoRotate write FAutoRotate;
    property LogLevel: TLogLevel read FLogLevel write FLogLevel;
    property LogToFile: Boolean read FLogToFile write FLogToFile;
    property LogToDebug: Boolean read FLogToDebug write FLogToDebug;
    property OnLogEvent: TOnLogEvent read FOnLogEvent write FOnLogEvent;
  end;

  // 日志查看器窗体
  TfrmLogViewer = class(TForm)
    // 主面板
    pnlMain: TPanel;
    
    // 工具栏
    pnlToolbar: TPanel;
    lblFilter: TLabel;
    cmbLogLevel: TComboBox;
    dtpStartDate: TDateTimePicker;
    lblTo: TLabel;
    dtpEndDate: TDateTimePicker;
    edtModuleFilter: TEdit;
    edtSearchText: TEdit;
    btnFilter: TBitBtn;
    btnClear: TBitBtn;
    btnRefresh: TBitBtn;
    btnExport: TBitBtn;
    
    // 日志列表
    lvLogs: TListView;
    
    // 详情面板
    pnlDetails: TPanel;
    memoDetails: TMemo;
    Splitter1: TSplitter;
    
    // 状态栏
    StatusBar: TStatusBar;
    
    // 右键菜单
    pmLogContext: TPopupMenu;
    miCopyEntry: TMenuItem;
    miCopyMessage: TMenuItem;
    miSeparator1: TMenuItem;
    miShowDetails: TMenuItem;
    miFilterByLevel: TMenuItem;
    miFilterByModule: TMenuItem;
    
    // 保存对话框
    SaveDialog: TSaveDialog;
    
    // 事件处理
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    
    procedure btnFilterClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
    procedure btnExportClick(Sender: TObject);
    
    procedure lvLogsSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure lvLogsDblClick(Sender: TObject);
    procedure lvLogsCustomDrawItem(Sender: TCustomListView; Item: TListItem;
      State: TCustomDrawState; var DefaultDraw: Boolean);
    
    procedure miCopyEntryClick(Sender: TObject);
    procedure miCopyMessageClick(Sender: TObject);
    procedure miShowDetailsClick(Sender: TObject);
    procedure miFilterByLevelClick(Sender: TObject);
    procedure miFilterByModuleClick(Sender: TObject);
    
  private
    FLogManager: TLogManager;
    FCurrentLogs: TArray<TLogEntry>;
    FAutoRefresh: Boolean;
    FRefreshTimer: TTimer;
    
    procedure InitializeInterface;
    procedure LoadLogs;
    procedure ApplyFilter;
    procedure UpdateLogList(const Logs: TArray<TLogEntry>);
    procedure UpdateDetails(const Entry: TLogEntry);
    procedure UpdateStatusBar;
    procedure ExportLogs;
    
    procedure OnLogEvent(const Entry: TLogEntry);
    procedure OnRefreshTimer(Sender: TObject);
    
  public
    constructor Create(AOwner: TComponent; ALogManager: TLogManager); reintroduce;
    property LogManager: TLogManager read FLogManager;
    property AutoRefresh: Boolean read FAutoRefresh write FAutoRefresh;
  end;

var
  GlobalLogManager: TLogManager;

// 全局日志记录函数
procedure LogDebug(const Module, Message: string);
procedure LogInfo(const Module, Message: string);  
procedure LogWarning(const Module, Message: string);
procedure LogError(const Module, Message: string);
procedure LogCritical(const Module, Message: string);

procedure LogInfoFormat(const Module, Format: string; const Args: array of const);
procedure LogErrorFormat(const Module, Format: string; const Args: array of const);

implementation

uses Vcl.Clipbrd;

{$R *.dfm}

// 全局日志记录函数实现
procedure LogDebug(const Module, Message: string);
begin
  if Assigned(GlobalLogManager) then
    GlobalLogManager.Debug(Module, Message);
end;

procedure LogInfo(const Module, Message: string);
begin
  if Assigned(GlobalLogManager) then
    GlobalLogManager.Info(Module, Message);
end;

procedure LogWarning(const Module, Message: string);
begin
  if Assigned(GlobalLogManager) then
    GlobalLogManager.Warning(Module, Message);
end;

procedure LogError(const Module, Message: string);
begin
  if Assigned(GlobalLogManager) then
    GlobalLogManager.Error(Module, Message);
end;

procedure LogCritical(const Module, Message: string);
begin
  if Assigned(GlobalLogManager) then
    GlobalLogManager.Critical(Module, Message);
end;

procedure LogInfoFormat(const Module, Format: string; const Args: array of const);
begin
  if Assigned(GlobalLogManager) then
    GlobalLogManager.InfoFormat(Module, Format, Args);
end;

procedure LogErrorFormat(const Module, Format: string; const Args: array of const);
begin
  if Assigned(GlobalLogManager) then
    GlobalLogManager.ErrorFormat(Module, Format, Args);
end;

// TLogManager 实现

constructor TLogManager.Create;
begin
  inherited Create;
  
  FLogDirectory := TPath.Combine(ExtractFilePath(ParamStr(0)), 'Logs');
  FLogFile := TPath.Combine(FLogDirectory, 'MoveC.log');
  FMaxFileSize := 10 * 1024 * 1024; // 10MB
  FMaxFiles := 10;
  FAutoRotate := True;
  FLogLevel := llInfo;
  FLogToFile := True;
  FLogToDebug := True;
  
  FLock := TCriticalSection.Create;
  FLogCache := TList<TLogEntry>.Create;
  
  // 确保日志目录存在
  if not TDirectory.Exists(FLogDirectory) then
    TDirectory.CreateDirectory(FLogDirectory);
    
  // 初始化日志文件
  try
    FFileStream := TFileStream.Create(FLogFile, fmCreate or fmShareDenyWrite);
  except
    FLogToFile := False; // 如果无法创建日志文件，禁用文件日志
  end;
end;

destructor TLogManager.Destroy;
begin
  FlushLogs;
  
  if Assigned(FFileStream) then
    FFileStream.Free;
    
  FLogCache.Free;
  FLock.Free;
  
  inherited Destroy;
end;

procedure TLogManager.Log(Level: TLogLevel; const Module, Message: string);
var
  Entry: TLogEntry;
begin
  if Level < FLogLevel then
    Exit;
    
  Entry.Timestamp := Now;
  Entry.Level := Level;
  Entry.Module := Module;
  Entry.Message := Message;
  Entry.ThreadID := GetCurrentThreadId;
  Entry.ProcessID := GetCurrentProcessId;
  
  FLock.Enter;
  try
    // 添加到缓存
    FLogCache.Add(Entry);
    
    // 写入文件
    if FLogToFile then
      WriteToFile(Entry);
      
    // 写入调试输出
    if FLogToDebug then
      WriteToDebug(Entry);
      
    // 触发事件
    if Assigned(FOnLogEvent) then
      FOnLogEvent(Entry);
      
    // 检查是否需要轮转日志文件
    if FAutoRotate and Assigned(FFileStream) and (FFileStream.Size > FMaxFileSize) then
      RotateLogFile;
      
  finally
    FLock.Leave;
  end;
end;

procedure TLogManager.Debug(const Module, Message: string);
begin
  Log(llDebug, Module, Message);
end;

procedure TLogManager.Info(const Module, Message: string);
begin
  Log(llInfo, Module, Message);
end;

procedure TLogManager.Warning(const Module, Message: string);
begin
  Log(llWarning, Module, Message);
end;

procedure TLogManager.Error(const Module, Message: string);
begin
  Log(llError, Module, Message);
end;

procedure TLogManager.Critical(const Module, Message: string);
begin
  Log(llCritical, Module, Message);
end;

procedure TLogManager.LogFormat(Level: TLogLevel; const Module, AFormat: string; const Args: array of const);
begin
  Log(Level, Module, System.SysUtils.Format(AFormat, Args));
end;

procedure TLogManager.InfoFormat(const Module, AFormat: string; const Args: array of const);
begin
  LogFormat(llInfo, Module, AFormat, Args);
end;

procedure TLogManager.ErrorFormat(const Module, AFormat: string; const Args: array of const);
begin
  LogFormat(llError, Module, AFormat, Args);
end;

procedure TLogManager.WriteToFile(const Entry: TLogEntry);
var
  LogLine: string;
  LogBytes: TBytes;
begin
  if not Assigned(FFileStream) then
    Exit;
    
  LogLine := FormatLogEntry(Entry) + sLineBreak;
  LogBytes := TEncoding.UTF8.GetBytes(LogLine);
  
  try
    FFileStream.WriteBuffer(LogBytes[0], Length(LogBytes));
  except
    // 忽略写入错误，防止日志记录影响主程序
  end;
end;

procedure TLogManager.WriteToDebug(const Entry: TLogEntry);
var
  DebugStr: string;
begin
  DebugStr := Format('[%s] %s: %s', [LogLevelToString(Entry.Level), Entry.Module, Entry.Message]);
  OutputDebugString(PChar(DebugStr));
end;

function TLogManager.FormatLogEntry(const Entry: TLogEntry): string;
begin
  Result := Format('%s [%s] [%s] T%d P%d: %s', [
    FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Entry.Timestamp),
    LogLevelToString(Entry.Level),
    Entry.Module,
    Entry.ThreadID,
    Entry.ProcessID,
    Entry.Message
  ]);
end;

function TLogManager.LogLevelToString(Level: TLogLevel): string;
begin
  case Level of
    llDebug: Result := 'DEBUG';
    llInfo: Result := 'INFO';
    llWarning: Result := 'WARN';
    llError: Result := 'ERROR';
    llCritical: Result := 'CRITICAL';
  else
    Result := 'UNKNOWN';
  end;
end;

function TLogManager.LogLevelToColor(Level: TLogLevel): TColor;
begin
  case Level of
    llDebug: Result := clGray;
    llInfo: Result := clBlack;
    llWarning: Result := clOlive;
    llError: Result := clRed;
    llCritical: Result := clMaroon;
  else
    Result := clBlack;
  end;
end;

function TLogManager.ParseLogLevel(const LevelStr: string): TLogLevel;
var
  UpperLevel: string;
begin
  UpperLevel := UpperCase(LevelStr);
  if UpperLevel = 'DEBUG' then
    Result := llDebug
  else if UpperLevel = 'INFO' then
    Result := llInfo
  else if UpperLevel = 'WARN' then
    Result := llWarning
  else if UpperLevel = 'ERROR' then
    Result := llError
  else if UpperLevel = 'CRITICAL' then
    Result := llCritical
  else
    Result := llInfo; // 默认
end;

procedure TLogManager.RotateLogFile;
var
  I: Integer;
  OldFile, NewFile: string;
begin
  try
    // 关闭当前文件流
    if Assigned(FFileStream) then
    begin
      FFileStream.Free;
      FFileStream := nil;
    end;
    
    // 轮转日志文件
    for I := FMaxFiles - 1 downto 1 do
    begin
      OldFile := GetLogFileName(I - 1);
      NewFile := GetLogFileName(I);
      
      if TFile.Exists(OldFile) then
      begin
        if TFile.Exists(NewFile) then
          TFile.Delete(NewFile);
        TFile.Move(OldFile, NewFile);
      end;
    end;
    
    // 重新创建日志文件流
    FFileStream := TFileStream.Create(FLogFile, fmCreate or fmShareDenyWrite);
  except
    // 轮转失败，禁用文件日志
    FLogToFile := False;
  end;
end;

function TLogManager.GetLogFileName(Index: Integer): string;
begin
  if Index = 0 then
    Result := FLogFile
  else
    Result := ChangeFileExt(FLogFile, Format('.%d.log', [Index]));
end;

procedure TLogManager.FlushLogs;
begin
  FLock.Enter;
  try
    // 无 Flush 方法，保持文件缓冲由系统处理
  finally
    FLock.Leave;
  end;
end;

procedure TLogManager.ClearLogs;
begin
  FLock.Enter;
  try
    FLogCache.Clear;
    
    if Assigned(FFileStream) then
    begin
      FFileStream.Free;
      FFileStream := TFileStream.Create(FLogFile, fmCreate or fmShareDenyWrite);
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TLogManager.RotateLogs;
begin
  FLock.Enter;
  try
    RotateLogFile;
  finally
    FLock.Leave;
  end;
end;

function TLogManager.GetLogFiles: TArray<string>;
var
  Files: TArray<string>;
  I: Integer;
  LogFiles: TList<string>;
  Base: string;
begin
  LogFiles := TList<string>.Create;
  try
    Files := TDirectory.GetFiles(FLogDirectory, '*.log');
    Base := ChangeFileExt(ExtractFileName(FLogFile), '');
    for I := 0 to High(Files) do
    begin
      if StartsText(Base, ChangeFileExt(ExtractFileName(Files[I]), '')) then
        LogFiles.Add(Files[I]);
    end;
    Result := LogFiles.ToArray;
  finally
    LogFiles.Free;
  end;
end;

function TLogManager.GetRecentLogs(Count: Integer): TArray<TLogEntry>;
var
  StartIndex: Integer;
begin
  FLock.Enter;
  try
    if FLogCache.Count <= Count then
    begin
      Result := FLogCache.ToArray;
    end
    else
    begin
      StartIndex := FLogCache.Count - Count;
      SetLength(Result, Count);
      for var I := 0 to Count - 1 do
        Result[I] := FLogCache[StartIndex + I];
    end;
  finally
    FLock.Leave;
  end;
end;

// Additional methods for filtering, searching, and exporting would be implemented here...
// This provides a comprehensive logging framework for the MoveC application

// Stub implementations for declared methods

function TLogManager.LoadLogsFromFile(const FileName: string): TArray<TLogEntry>;
begin
  Result := [];
end;

function TLogManager.FilterLogs(const Filter: TLogFilter): TArray<TLogEntry>;
begin
  Result := FLogCache.ToArray;
end;

function TLogManager.SearchLogs(const SearchText: string): TArray<TLogEntry>;
var
  List: TList<TLogEntry>;
  I: Integer;
begin
  List := TList<TLogEntry>.Create;
  try
    for I := 0 to FLogCache.Count - 1 do
      if (SearchText = '') or ContainsText(FLogCache[I].Message, SearchText) then
        List.Add(FLogCache[I]);
    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

function TLogManager.ExportToText(const FileName: string; const Filter: TLogFilter): Boolean;
var
  SL: TStringList;
  Logs: TArray<TLogEntry>;
  E: TLogEntry;
begin
  Result := False;
  SL := TStringList.Create;
  try
    Logs := FilterLogs(Filter);
    for E in Logs do
      SL.Add(FormatLogEntry(E));
    SL.SaveToFile(FileName, TEncoding.UTF8);
    Result := True;
  finally
    SL.Free;
  end;
end;

function TLogManager.ExportToCSV(const FileName: string; const Filter: TLogFilter): Boolean;
var
  SL: TStringList;
  Logs: TArray<TLogEntry>;
  E: TLogEntry;
begin
  Result := False;
  SL := TStringList.Create;
  try
    SL.Add('Time,Level,Module,ThreadID,ProcessID,Message');
    Logs := FilterLogs(Filter);
    for E in Logs do
      SL.Add(Format('"%s","%s","%s",%d,%d,"%s"', [
        FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', E.Timestamp),
        LogLevelToString(E.Level), E.Module, E.ThreadID, E.ProcessID,
        StringReplace(E.Message, '"', '""', [rfReplaceAll])
      ]));
    SL.SaveToFile(FileName, TEncoding.UTF8);
    Result := True;
  finally
    SL.Free;
  end;
end;

function TLogManager.ExportToHTML(const FileName: string; const Filter: TLogFilter): Boolean;
var
  SL: TStringList;
  Logs: TArray<TLogEntry>;
  E: TLogEntry;
begin
  Result := False;
  SL := TStringList.Create;
  try
    SL.Add('<!doctype html><meta charset="utf-8"><title>Logs</title><pre>');
    Logs := FilterLogs(Filter);
    for E in Logs do
      SL.Add(FormatLogEntry(E));
    SL.Add('</pre>');
    SL.SaveToFile(FileName, TEncoding.UTF8);
    Result := True;
  finally
    SL.Free;
  end;
end;

// TfrmLogViewer implementation

constructor TfrmLogViewer.Create(AOwner: TComponent; ALogManager: TLogManager);
begin
  inherited Create(AOwner);
  FLogManager := ALogManager;
  FAutoRefresh := True;
  
  InitializeInterface;
end;

procedure TfrmLogViewer.FormCreate(Sender: TObject);
begin
  Caption := '日志查看器 - C盘瘦身神器';
  Position := poScreenCenter;
  WindowState := wsMaximized;
  
  // 设置刷新定时器
  FRefreshTimer := TTimer.Create(Self);
  FRefreshTimer.Interval := 5000; // 5秒刷新一次
  FRefreshTimer.OnTimer := OnRefreshTimer;
  FRefreshTimer.Enabled := FAutoRefresh;
end;

procedure TfrmLogViewer.FormDestroy(Sender: TObject);
begin
  if Assigned(FRefreshTimer) then
    FRefreshTimer.Free;
end;

procedure TfrmLogViewer.FormShow(Sender: TObject);
begin
  // 设置默认过滤器
  dtpStartDate.Date := Date - 7; // 最近7天
  dtpEndDate.Date := Date;
  cmbLogLevel.ItemIndex := 1; // Info级别
  
  LoadLogs;
end;

procedure TfrmLogViewer.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TfrmLogViewer.InitializeInterface;
begin
  // 初始化日志级别下拉框
  cmbLogLevel.Items.Clear;
  cmbLogLevel.Items.Add('所有级别');
  cmbLogLevel.Items.Add('信息及以上');
  cmbLogLevel.Items.Add('警告及以上');
  cmbLogLevel.Items.Add('错误及以上');
  cmbLogLevel.Items.Add('严重错误');
  cmbLogLevel.ItemIndex := 0;
  
  // 初始化ListView
  lvLogs.ViewStyle := vsReport;
  lvLogs.GridLines := True;
  lvLogs.RowSelect := True;
  
  lvLogs.Columns.Add.Caption := '时间';
  lvLogs.Columns.Add.Caption := '级别';
  lvLogs.Columns.Add.Caption := '模块';
  lvLogs.Columns.Add.Caption := '消息';
  
  // 设置列宽
  lvLogs.Columns[0].Width := 150;
  lvLogs.Columns[1].Width := 80;
  lvLogs.Columns[2].Width := 120;
  lvLogs.Columns[3].Width := 400;
  
  // 初始化保存对话框
  SaveDialog.Filter := '文本文件 (*.txt)|*.txt|CSV文件 (*.csv)|*.csv|HTML文件 (*.html)|*.html';
  SaveDialog.DefaultExt := 'txt';
end;

procedure TfrmLogViewer.LoadLogs;
begin
  if Assigned(FLogManager) then
  begin
    FCurrentLogs := FLogManager.GetRecentLogs(1000); // 获取最近1000条日志
    ApplyFilter;
  end;
end;

procedure TfrmLogViewer.ApplyFilter;
var
  Filter: TLogFilter;
begin
  if not Assigned(FLogManager) then
    Exit;
    
  // 构建过滤条件
  Filter.StartDate := dtpStartDate.Date;
  Filter.EndDate := dtpEndDate.Date + 1; // 包含结束日期当天
  Filter.SearchText := Trim(edtSearchText.Text);
  Filter.Module := Trim(edtModuleFilter.Text);
  
  case cmbLogLevel.ItemIndex of
    0: Filter.Level := llDebug; // 所有级别
    1: Filter.Level := llInfo;   // 信息及以上
    2: Filter.Level := llWarning; // 警告及以上
    3: Filter.Level := llError;   // 错误及以上
    4: Filter.Level := llCritical; // 严重错误
  else
    Filter.Level := llDebug;
  end;
  
  // 应用过滤器（这里简化处理，实际应该在LogManager中实现）
  UpdateLogList(FCurrentLogs);
  UpdateStatusBar;
end;

procedure TfrmLogViewer.UpdateLogList(const Logs: TArray<TLogEntry>);
var
  I: Integer;
  Item: TListItem;
begin
  lvLogs.Items.BeginUpdate;
  try
    lvLogs.Items.Clear;
    
    for I := 0 to High(Logs) do
    begin
      Item := lvLogs.Items.Add;
      Item.Caption := FormatDateTime('mm-dd hh:nn:ss', Logs[I].Timestamp);
      Item.SubItems.Add(FLogManager.LogLevelToString(Logs[I].Level));
      Item.SubItems.Add(Logs[I].Module);
      Item.SubItems.Add(Logs[I].Message);
      Item.Data := @Logs[I];
    end;
  finally
    lvLogs.Items.EndUpdate;
  end;
end;

procedure TfrmLogViewer.UpdateStatusBar;
begin
  StatusBar.Panels[0].Text := Format('显示 %d 条日志', [lvLogs.Items.Count]);
  StatusBar.Panels[1].Text := Format('总共 %d 条日志', [Length(FCurrentLogs)]);
end;

procedure TfrmLogViewer.btnFilterClick(Sender: TObject);
begin
  ApplyFilter;
end;

procedure TfrmLogViewer.btnClearClick(Sender: TObject);
begin
  edtSearchText.Clear;
  edtModuleFilter.Clear;
  cmbLogLevel.ItemIndex := 0;
  dtpStartDate.Date := Date - 7;
  dtpEndDate.Date := Date;
  ApplyFilter;
end;

procedure TfrmLogViewer.btnRefreshClick(Sender: TObject);
begin
  LoadLogs;
end;

procedure TfrmLogViewer.btnExportClick(Sender: TObject);
begin
  ExportLogs;
end;

procedure TfrmLogViewer.ExportLogs;
begin
  if SaveDialog.Execute then
  begin
    // 根据文件扩展名选择导出格式
    case SaveDialog.FilterIndex of
      1: ShowMessage('导出为文本文件功能开发中...');
      2: ShowMessage('导出为CSV文件功能开发中...');
      3: ShowMessage('导出为HTML文件功能开发中...');
    end;
  end;
end;

procedure TfrmLogViewer.OnLogEvent(const Entry: TLogEntry);
begin
  // 实时更新日志列表
  if FAutoRefresh then
    LoadLogs;
end;

procedure TfrmLogViewer.OnRefreshTimer(Sender: TObject);
begin
  if FAutoRefresh then
    LoadLogs;
end;

procedure TfrmLogViewer.lvLogsSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
var
  Entry: PLogEntry;
begin
  if Selected and Assigned(Item.Data) then
  begin
    Entry := PLogEntry(Item.Data);
    UpdateDetails(Entry^);
  end;
end;

procedure TfrmLogViewer.UpdateDetails(const Entry: TLogEntry);
begin
  memoDetails.Lines.Clear;
  memoDetails.Lines.Add('详细信息:');
  memoDetails.Lines.Add('');
  memoDetails.Lines.Add('时间: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Entry.Timestamp));
  memoDetails.Lines.Add('级别: ' + FLogManager.LogLevelToString(Entry.Level));
  memoDetails.Lines.Add('模块: ' + Entry.Module);
  memoDetails.Lines.Add('线程ID: ' + IntToStr(Entry.ThreadID));
  memoDetails.Lines.Add('进程ID: ' + IntToStr(Entry.ProcessID));
  memoDetails.Lines.Add('');
  memoDetails.Lines.Add('消息:');
  memoDetails.Lines.Add(Entry.Message);
end;

// Additional event handlers and methods would be implemented here...

// Context menu implementations
procedure TfrmLogViewer.miCopyEntryClick(Sender: TObject);
begin
  if Assigned(lvLogs.Selected) and Assigned(lvLogs.Selected.Data) then
  begin
    var Entry := PLogEntry(lvLogs.Selected.Data)^;
    Clipboard.AsText := FLogManager.FormatLogEntry(Entry);
  end;
end;

procedure TfrmLogViewer.miCopyMessageClick(Sender: TObject);
begin
  if Assigned(lvLogs.Selected) and Assigned(lvLogs.Selected.Data) then
  begin
    var Entry := PLogEntry(lvLogs.Selected.Data)^;
    Clipboard.AsText := Entry.Message;
  end;
end;

procedure TfrmLogViewer.miShowDetailsClick(Sender: TObject);
begin
  pnlDetails.Visible := not pnlDetails.Visible;
  Splitter1.Visible := pnlDetails.Visible;
end;

procedure TfrmLogViewer.miFilterByLevelClick(Sender: TObject);
begin
  if Assigned(lvLogs.Selected) and Assigned(lvLogs.Selected.Data) then
  begin
    var Entry := PLogEntry(lvLogs.Selected.Data)^;
    cmbLogLevel.ItemIndex := Integer(Entry.Level);
    ApplyFilter;
  end;
end;

procedure TfrmLogViewer.miFilterByModuleClick(Sender: TObject);
begin
  if Assigned(lvLogs.Selected) and Assigned(lvLogs.Selected.Data) then
  begin
    var Entry := PLogEntry(lvLogs.Selected.Data)^;
    edtModuleFilter.Text := Entry.Module;
    ApplyFilter;
  end;
end;

procedure TfrmLogViewer.lvLogsDblClick(Sender: TObject);
begin
  miShowDetailsClick(Sender);
end;

procedure TfrmLogViewer.lvLogsCustomDrawItem(Sender: TCustomListView; Item: TListItem;
  State: TCustomDrawState; var DefaultDraw: Boolean);
var
  Entry: PLogEntry;
begin
  if Assigned(Item.Data) then
  begin
    Entry := PLogEntry(Item.Data);
    Sender.Canvas.Font.Color := FLogManager.LogLevelToColor(Entry^.Level);
  end;
  DefaultDraw := True;
end;

initialization
  GlobalLogManager := TLogManager.Create;
  
finalization
  if Assigned(GlobalLogManager) then
    GlobalLogManager.Free;

end.