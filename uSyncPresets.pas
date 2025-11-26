unit uSyncPresets;

interface

uses
  System.SysUtils, System.Classes, System.JSON, uSyncDatabase;

type
  TSyncPresetManager = class
  private
    FDatabase: TSyncDatabase;
  public
    constructor Create(ADatabase: TSyncDatabase);
    destructor Destroy; override;
    
    // 初始化系统预设
    procedure InitializeSystemPresets;
    
    // 获取预设的过滤规则JSON
    function GetDevelopmentCodeFilter: string;
    function GetDocumentBackupFilter: string;
    function GetFullSyncFilter: string;
    function GetMediaFilesFilter: string;
    function GetProjectFilesFilter: string;
  end;

implementation

{ TSyncPresetManager }

constructor TSyncPresetManager.Create(ADatabase: TSyncDatabase);
begin
  inherited Create;
  FDatabase := ADatabase;
end;

destructor TSyncPresetManager.Destroy;
begin
  inherited Destroy;
end;

procedure TSyncPresetManager.InitializeSystemPresets;
var
  Preset: TSyncPreset;
  PresetID: Integer;
begin
  if not FDatabase.IsConnected then
    Exit;
  
  // 开发代码同步预设
  Preset.Name := '开发代码同步';
  Preset.Description := '适用于Delphi、Python、Node.js等开发项目的源代码同步';
  Preset.FilterRules := GetDevelopmentCodeFilter;
  Preset.ConflictStrategy := csNewerPriority;
  Preset.IsSystem := True;
  PresetID := FDatabase.CreatePreset(Preset);
  
  // 文档备份预设
  Preset.Name := '文档备份';
  Preset.Description := '文档、表格、演示文稿等办公文件的备份同步';
  Preset.FilterRules := GetDocumentBackupFilter;
  Preset.ConflictStrategy := csNewerPriority;
  Preset.IsSystem := True;
  PresetID := FDatabase.CreatePreset(Preset);
  
  // 全量同步预设
  Preset.Name := '全量同步';
  Preset.Description := '同步所有文件类型，排除临时文件和系统文件';
  Preset.FilterRules := GetFullSyncFilter;
  Preset.ConflictStrategy := csAskUser;
  Preset.IsSystem := True;
  PresetID := FDatabase.CreatePreset(Preset);
  
  // 媒体文件预设
  Preset.Name := '媒体文件同步';
  Preset.Description := '图片、音频、视频等媒体文件的同步';
  Preset.FilterRules := GetMediaFilesFilter;
  Preset.ConflictStrategy := csSourcePriority;
  Preset.IsSystem := True;
  PresetID := FDatabase.CreatePreset(Preset);
  
  // 项目文件预设
  Preset.Name := '项目文件同步';
  Preset.Description := '项目相关文件，包括源代码、配置文件、文档等';
  Preset.FilterRules := GetProjectFilesFilter;
  Preset.ConflictStrategy := csNewerPriority;
  Preset.IsSystem := True;
  PresetID := FDatabase.CreatePreset(Preset);
end;

function TSyncPresetManager.GetDevelopmentCodeFilter: string;
var
  JSONObject: TJSONObject;
  IncludeArray, ExcludeArray: TJSONArray;
begin
  JSONObject := TJSONObject.Create;
  try
    // 包含的文件类型
    IncludeArray := TJSONArray.Create;
    IncludeArray.Add('*.pas');
    IncludeArray.Add('*.dfm');
    IncludeArray.Add('*.dpr');
    IncludeArray.Add('*.dpk');
    IncludeArray.Add('*.py');
    IncludeArray.Add('*.js');
    IncludeArray.Add('*.ts');
    IncludeArray.Add('*.jsx');
    IncludeArray.Add('*.tsx');
    IncludeArray.Add('*.html');
    IncludeArray.Add('*.css');
    IncludeArray.Add('*.scss');
    IncludeArray.Add('*.less');
    IncludeArray.Add('*.json');
    IncludeArray.Add('*.xml');
    IncludeArray.Add('*.yaml');
    IncludeArray.Add('*.yml');
    IncludeArray.Add('*.md');
    IncludeArray.Add('*.txt');
    IncludeArray.Add('*.sql');
    IncludeArray.Add('*.sh');
    IncludeArray.Add('*.bat');
    IncludeArray.Add('*.cmd');
    IncludeArray.Add('*.ps1');
    IncludeArray.Add('*.config');
    IncludeArray.Add('*.ini');
    IncludeArray.Add('*.properties');
    IncludeArray.Add('*.gitignore');
    IncludeArray.Add('*.dockerfile');
    IncludeArray.Add('Dockerfile');
    IncludeArray.Add('Makefile');
    IncludeArray.Add('*.cmake');
    IncludeArray.Add('CMakeLists.txt');
    JSONObject.AddPair('include_extensions', IncludeArray);
    
    // 排除的文件类型
    ExcludeArray := TJSONArray.Create;
    ExcludeArray.Add('*.exe');
    ExcludeArray.Add('*.dll');
    ExcludeArray.Add('*.obj');
    ExcludeArray.Add('*.dcu');
    ExcludeArray.Add('*.dcu');
    ExcludeArray.Add('*.bpl');
    ExcludeArray.Add('*.dcp');
    ExcludeArray.Add('*.bpl');
    ExcludeArray.Add('*.dcp');
    ExcludeArray.Add('*.~*');
    ExcludeArray.Add('*.bak');
    ExcludeArray.Add('*.tmp');
    ExcludeArray.Add('*.temp');
    ExcludeArray.Add('*.log');
    ExcludeArray.Add('*.cache');
    ExcludeArray.Add('*.swp');
    ExcludeArray.Add('*.swo');
    ExcludeArray.Add('*.pyc');
    ExcludeArray.Add('*.pyo');
    ExcludeArray.Add('*.pyd');
    ExcludeArray.Add('*.node_modules');
    ExcludeArray.Add('*.npm');
    ExcludeArray.Add('*.pnpm');
    ExcludeArray.Add('*.yarn');
    JSONObject.AddPair('exclude_extensions', ExcludeArray);
    
    // 排除的目录
    ExcludeArray := TJSONArray.Create;
    ExcludeArray.Add('__pycache__');
    ExcludeArray.Add('node_modules');
    ExcludeArray.Add('.git');
    ExcludeArray.Add('.svn');
    ExcludeArray.Add('.hg');
    ExcludeArray.Add('.bzr');
    ExcludeArray.Add('.idea');
    ExcludeArray.Add('.vs');
    ExcludeArray.Add('.vscode');
    ExcludeArray.Add('bin');
    ExcludeArray.Add('Debug');
    ExcludeArray.Add('Release');
    ExcludeArray.Add('Win32');
    ExcludeArray.Add('Win64');
    ExcludeArray.Add('Android');
    ExcludeArray.Add('iOS');
    ExcludeArray.Add('Linux64');
    ExcludeArray.Add('macOS64');
    ExcludeArray.Add('output');
    ExcludeArray.Add('build');
    ExcludeArray.Add('dist');
    ExcludeArray.Add('coverage');
    ExcludeArray.Add('test-results');
    ExcludeArray.Add('.pytest_cache');
    ExcludeArray.Add('.coverage');
    ExcludeArray.Add('htmlcov');
    ExcludeArray.Add('site-packages');
    JSONObject.AddPair('exclude_directories', ExcludeArray);
    
    // 最大文件大小 (100MB)
    JSONObject.AddPair('max_file_size', TJSONNumber.Create(104857600));
    
    // 其他设置
    JSONObject.AddPair('include_hidden_files', TJSONBool.Create(False));
    JSONObject.AddPair('follow_symlinks', TJSONBool.Create(False));
    JSONObject.AddPair('preserve_timestamps', TJSONBool.Create(True));
    
    Result := JSONObject.ToString;
  finally
    JSONObject.Free;
  end;
end;

function TSyncPresetManager.GetDocumentBackupFilter: string;
var
  JSONObject: TJSONObject;
  IncludeArray, ExcludeArray: TJSONArray;
begin
  JSONObject := TJSONObject.Create;
  try
    // 包含的文件类型
    IncludeArray := TJSONArray.Create;
    IncludeArray.Add('*.doc');
    IncludeArray.Add('*.docx');
    IncludeArray.Add('*.xls');
    IncludeArray.Add('*.xlsx');
    IncludeArray.Add('*.ppt');
    IncludeArray.Add('*.pptx');
    IncludeArray.Add('*.pdf');
    IncludeArray.Add('*.rtf');
    IncludeArray.Add('*.odt');
    IncludeArray.Add('*.ods');
    IncludeArray.Add('*.odp');
    IncludeArray.Add('*.txt');
    IncludeArray.Add('*.md');
    IncludeArray.Add('*.csv');
    IncludeArray.Add('*.xml');
    IncludeArray.Add('*.json');
    IncludeArray.Add('*.yaml');
    IncludeArray.Add('*.yml');
    IncludeArray.Add('*.eml');
    IncludeArray.Add('*.msg');
    IncludeArray.Add('*.pst');
    IncludeArray.Add('*.ost');
    IncludeArray.Add('*.mbox');
    IncludeArray.Add('*.mht');
    IncludeArray.Add('*.mhtml');
    IncludeArray.Add('*.htm');
    IncludeArray.Add('*.html');
    JSONObject.AddPair('include_extensions', IncludeArray);
    
    // 排除的文件类型
    ExcludeArray := TJSONArray.Create;
    ExcludeArray.Add('*.tmp');
    ExcludeArray.Add('*.temp');
    ExcludeArray.Add('*.~*');
    ExcludeArray.Add('*.bak');
    ExcludeArray.Add('*.lock');
    ExcludeArray.Add('*.part');
    JSONObject.AddPair('exclude_extensions', ExcludeArray);
    
    // 排除的目录
    ExcludeArray := TJSONArray.Create;
    ExcludeArray.Add('.git');
    ExcludeArray.Add('.svn');
    ExcludeArray.Add('.hg');
    ExcludeArray.Add('temp');
    ExcludeArray.Add('tmp');
    ExcludeArray.Add('cache');
    ExcludeArray.Add('.cache');
    ExcludeArray.Add('recycle.bin');
    ExcludeArray.Add('$Recycle.Bin');
    JSONObject.AddPair('exclude_directories', ExcludeArray);
    
    // 最大文件大小 (500MB)
    JSONObject.AddPair('max_file_size', TJSONNumber.Create(524288000));
    
    // 其他设置
    JSONObject.AddPair('include_hidden_files', TJSONBool.Create(False));
    JSONObject.AddPair('follow_symlinks', TJSONBool.Create(False));
    JSONObject.AddPair('preserve_timestamps', TJSONBool.Create(True));
    
    Result := JSONObject.ToString;
  finally
    JSONObject.Free;
  end;
end;

function TSyncPresetManager.GetFullSyncFilter: string;
var
  JSONObject: TJSONObject;
  ExcludeArray: TJSONArray;
begin
  JSONObject := TJSONObject.Create;
  try
    // 不指定包含扩展名，表示包含所有文件
    
    // 排除的文件类型
    ExcludeArray := TJSONArray.Create;
    ExcludeArray.Add('*.tmp');
    ExcludeArray.Add('*.temp');
    ExcludeArray.Add('*.~*');
    ExcludeArray.Add('*.bak');
    ExcludeArray.Add('*.old');
    ExcludeArray.Add('*.lock');
    ExcludeArray.Add('*.part');
    ExcludeArray.Add('*.crdownload');
    ExcludeArray.Add('*.download');
    ExcludeArray.Add('*.partial');
    ExcludeArray.Add('*.filepart');
    ExcludeArray.Add('*.swp');
    ExcludeArray.Add('*.swo');
    ExcludeArray.Add('*.DS_Store');
    ExcludeArray.Add('*.Thumbs.db');
    ExcludeArray.Add('*.desktop.ini');
    ExcludeArray.Add('*.folder.htt');
    JSONObject.AddPair('exclude_extensions', ExcludeArray);
    
    // 排除的目录
    ExcludeArray := TJSONArray.Create;
    ExcludeArray.Add('.git');
    ExcludeArray.Add('.svn');
    ExcludeArray.Add('.hg');
    ExcludeArray.Add('.bzr');
    ExcludeArray.Add('node_modules');
    ExcludeArray.Add('__pycache__');
    ExcludeArray.Add('temp');
    ExcludeArray.Add('tmp');
    ExcludeArray.Add('cache');
    ExcludeArray.Add('.cache');
    ExcludeArray.Add('.temp');
    ExcludeArray.Add('.tmp');
    ExcludeArray.Add('recycle.bin');
    ExcludeArray.Add('$Recycle.Bin');
    ExcludeArray.Add('System Volume Information');
    ExcludeArray.Add('$RECYCLE.BIN');
    ExcludeArray.Add('RECYCLER');
    ExcludeArray.Add('.Spotlight-V100');
    ExcludeArray.Add('.Trashes');
    ExcludeArray.Add('.fseventsd');
    ExcludeArray.Add('.DocumentRevisions-V100');
    ExcludeArray.Add('.PKInstallSandboxManager');
    ExcludeArray.Add('.PKInstallSandboxManager-SystemSoftware');
    JSONObject.AddPair('exclude_directories', ExcludeArray);
    
    // 最大文件大小 (1GB)
    JSONObject.AddPair('max_file_size', TJSONNumber.Create(1073741824));
    
    // 其他设置
    JSONObject.AddPair('include_hidden_files', TJSONBool.Create(False));
    JSONObject.AddPair('follow_symlinks', TJSONBool.Create(False));
    JSONObject.AddPair('preserve_timestamps', TJSONBool.Create(True));
    
    Result := JSONObject.ToString;
  finally
    JSONObject.Free;
  end;
end;

function TSyncPresetManager.GetMediaFilesFilter: string;
var
  JSONObject: TJSONObject;
  IncludeArray, ExcludeArray: TJSONArray;
begin
  JSONObject := TJSONObject.Create;
  try
    // 包含的文件类型
    IncludeArray := TJSONArray.Create;
    // 图片
    IncludeArray.Add('*.jpg');
    IncludeArray.Add('*.jpeg');
    IncludeArray.Add('*.png');
    IncludeArray.Add('*.gif');
    IncludeArray.Add('*.bmp');
    IncludeArray.Add('*.tiff');
    IncludeArray.Add('*.tif');
    IncludeArray.Add('*.webp');
    IncludeArray.Add('*.svg');
    IncludeArray.Add('*.ico');
    IncludeArray.Add('*.psd');
    IncludeArray.Add('*.raw');
    IncludeArray.Add('*.cr2');
    IncludeArray.Add('*.nef');
    IncludeArray.Add('*.arw');
    // 音频
    IncludeArray.Add('*.mp3');
    IncludeArray.Add('*.wav');
    IncludeArray.Add('*.flac');
    IncludeArray.Add('*.aac');
    IncludeArray.Add('*.ogg');
    IncludeArray.Add('*.wma');
    IncludeArray.Add('*.m4a');
    IncludeArray.Add('*.opus');
    IncludeArray.Add('*.aiff');
    IncludeArray.Add('*.au');
    // 视频
    IncludeArray.Add('*.mp4');
    IncludeArray.Add('*.avi');
    IncludeArray.Add('*.mkv');
    IncludeArray.Add('*.mov');
    IncludeArray.Add('*.wmv');
    IncludeArray.Add('*.flv');
    IncludeArray.Add('*.webm');
    IncludeArray.Add('*.m4v');
    IncludeArray.Add('*.3gp');
    IncludeArray.Add('*.mpeg');
    IncludeArray.Add('*.mpg');
    IncludeArray.Add('*.ts');
    IncludeArray.Add('*.mts');
    IncludeArray.Add('*.m2ts');
    JSONObject.AddPair('include_extensions', IncludeArray);
    
    // 排除的文件类型
    ExcludeArray := TJSONArray.Create;
    ExcludeArray.Add('*.tmp');
    ExcludeArray.Add('*.temp');
    ExcludeArray.Add('*.~*');
    ExcludeArray.Add('*.bak');
    ExcludeArray.Add('*.partial');
    ExcludeArray.Add('*.part');
    JSONObject.AddPair('exclude_extensions', ExcludeArray);
    
    // 排除的目录
    ExcludeArray := TJSONArray.Create;
    ExcludeArray.Add('.git');
    ExcludeArray.Add('.svn');
    ExcludeArray.Add('.hg');
    ExcludeArray.Add('temp');
    ExcludeArray.Add('tmp');
    ExcludeArray.Add('cache');
    ExcludeArray.Add('.cache');
    ExcludeArray.Add('recycle.bin');
    ExcludeArray.Add('$Recycle.Bin');
    ExcludeArray.Add('.thumbnails');
    ExcludeArray.Add('Thumbnails');
    JSONObject.AddPair('exclude_directories', ExcludeArray);
    
    // 最大文件大小 (5GB)
    JSONObject.AddPair('max_file_size', TJSONNumber.Create(5368709120));
    
    // 其他设置
    JSONObject.AddPair('include_hidden_files', TJSONBool.Create(False));
    JSONObject.AddPair('follow_symlinks', TJSONBool.Create(False));
    JSONObject.AddPair('preserve_timestamps', TJSONBool.Create(True));
    
    Result := JSONObject.ToString;
  finally
    JSONObject.Free;
  end;
end;

function TSyncPresetManager.GetProjectFilesFilter: string;
var
  JSONObject: TJSONObject;
  IncludeArray, ExcludeArray: TJSONArray;
begin
  JSONObject := TJSONObject.Create;
  try
    // 包含的文件类型
    IncludeArray := TJSONArray.Create;
    // 源代码文件
    IncludeArray.Add('*.pas');
    IncludeArray.Add('*.dfm');
    IncludeArray.Add('*.dpr');
    IncludeArray.Add('*.dpk');
    IncludeArray.Add('*.py');
    IncludeArray.Add('*.js');
    IncludeArray.Add('*.ts');
    IncludeArray.Add('*.jsx');
    IncludeArray.Add('*.tsx');
    IncludeArray.Add('*.java');
    IncludeArray.Add('*.cpp');
    IncludeArray.Add('*.c');
    IncludeArray.Add('*.h');
    IncludeArray.Add('*.hpp');
    IncludeArray.Add('*.cs');
    IncludeArray.Add('*.vb');
    IncludeArray.Add('*.php');
    IncludeArray.Add('*.rb');
    IncludeArray.Add('*.go');
    IncludeArray.Add('*.rs');
    IncludeArray.Add('*.swift');
    IncludeArray.Add('*.kt');
    IncludeArray.Add('*.scala');
    // 配置文件
    IncludeArray.Add('*.json');
    IncludeArray.Add('*.xml');
    IncludeArray.Add('*.yaml');
    IncludeArray.Add('*.yml');
    IncludeArray.Add('*.ini');
    IncludeArray.Add('*.config');
    IncludeArray.Add('*.properties');
    IncludeArray.Add('*.toml');
    IncludeArray.Add('*.env');
    // 文档文件
    IncludeArray.Add('*.md');
    IncludeArray.Add('*.txt');
    IncludeArray.Add('*.rst');
    IncludeArray.Add('*.adoc');
    IncludeArray.Add('*.doc');
    IncludeArray.Add('*.docx');
    IncludeArray.Add('*.pdf');
    // 构建文件
    IncludeArray.Add('Makefile');
    IncludeArray.Add('*.mk');
    IncludeArray.Add('CMakeLists.txt');
    IncludeArray.Add('*.cmake');
    IncludeArray.Add('*.sh');
    IncludeArray.Add('*.bat');
    IncludeArray.Add('*.cmd');
    IncludeArray.Add('*.ps1');
    IncludeArray.Add('Dockerfile');
    IncludeArray.Add('docker-compose.yml');
    IncludeArray.Add('docker-compose.yaml');
    IncludeArray.Add('*.dockerfile');
    // 版本控制
    IncludeArray.Add('.gitignore');
    IncludeArray.Add('.gitattributes');
    IncludeArray.Add('.gitmodules');
    IncludeArray.Add('.hgignore');
    IncludeArray.Add('.svnignore');
    JSONObject.AddPair('include_extensions', IncludeArray);
    
    // 排除的文件类型
    ExcludeArray := TJSONArray.Create;
    ExcludeArray.Add('*.exe');
    ExcludeArray.Add('*.dll');
    ExcludeArray.Add('*.obj');
    ExcludeArray.Add('*.o');
    ExcludeArray.Add('*.so');
    ExcludeArray.Add('*.dylib');
    ExcludeArray.Add('*.a');
    ExcludeArray.Add('*.lib');
    ExcludeArray.Add('*.dcu');
    ExcludeArray.Add('*.bpl');
    ExcludeArray.Add('*.dcp');
    ExcludeArray.Add('*.pyc');
    ExcludeArray.Add('*.pyo');
    ExcludeArray.Add('*.pyd');
    ExcludeArray.Add('*.class');
    ExcludeArray.Add('*.jar');
    ExcludeArray.Add('*.war');
    ExcludeArray.Add('*.ear');
    ExcludeArray.Add('*.~*');
    ExcludeArray.Add('*.bak');
    ExcludeArray.Add('*.tmp');
    ExcludeArray.Add('*.temp');
    ExcludeArray.Add('*.log');
    ExcludeArray.Add('*.cache');
    ExcludeArray.Add('*.swp');
    ExcludeArray.Add('*.swo');
    ExcludeArray.Add('*.pid');
    ExcludeArray.Add('*.seed');
    ExcludeArray.Add('*.pid.lock');
    JSONObject.AddPair('exclude_extensions', ExcludeArray);
    
    // 排除的目录
    ExcludeArray := TJSONArray.Create;
    ExcludeArray.Add('__pycache__');
    ExcludeArray.Add('node_modules');
    ExcludeArray.Add('.git');
    ExcludeArray.Add('.svn');
    ExcludeArray.Add('.hg');
    ExcludeArray.Add('.bzr');
    ExcludeArray.Add('.idea');
    ExcludeArray.Add('.vs');
    ExcludeArray.Add('.vscode');
    ExcludeArray.Add('.eclipse');
    ExcludeArray.Add('.netbeans');
    ExcludeArray.Add('bin');
    ExcludeArray.Add('obj');
    ExcludeArray.Add('Debug');
    ExcludeArray.Add('Release');
    ExcludeArray.Add('build');
    ExcludeArray.Add('dist');
    ExcludeArray.Add('out');
    ExcludeArray.Add('target');
    ExcludeArray.Add('cmake-build-*');
    ExcludeArray.Add('.gradle');
    ExcludeArray.Add('.maven');
    ExcludeArray.Add('.npm');
    ExcludeArray.Add('.pnpm');
    ExcludeArray.Add('.yarn');
    ExcludeArray.Add('coverage');
    ExcludeArray.Add('.coverage');
    ExcludeArray.Add('htmlcov');
    ExcludeArray.Add('test-results');
    ExcludeArray.Add('.pytest_cache');
    ExcludeArray.Add('site-packages');
    ExcludeArray.Add('.tox');
    ExcludeArray.Add('.venv');
    ExcludeArray.Add('venv');
    ExcludeArray.Add('env');
    ExcludeArray.Add('packages');
    ExcludeArray.Add('.packages');
    JSONObject.AddPair('exclude_directories', ExcludeArray);
    
    // 最大文件大小 (200MB)
    JSONObject.AddPair('max_file_size', TJSONNumber.Create(209715200));
    
    // 其他设置
    JSONObject.AddPair('include_hidden_files', TJSONBool.Create(False));
    JSONObject.AddPair('follow_symlinks', TJSONBool.Create(False));
    JSONObject.AddPair('preserve_timestamps', TJSONBool.Create(True));
    
    Result := JSONObject.ToString;
  finally
    JSONObject.Free;
  end;
end;

end.
