program TestAdvancedFileManager;

{
  高级文件管理器测试程序
  
  用于测试和演示高级文件管理功能，包括：
  - 文件搜索
  - 重复文件检测
  - 大文件查找
  - 批量文件操作
  
  作者: AI助手
  版本: 2.1.0
  日期: 2024
}

uses
  Vcl.Forms,
  uAdvancedFileManagerForm in 'uAdvancedFileManagerForm.pas' {frmAdvancedFileManager},
  uAdvancedFileManager in 'uAdvancedFileManager.pas';


begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := '高级文件管理器测试程序';
  Application.CreateForm(TfrmAdvancedFileManager, frmAdvancedFileManager);
  Application.Run;
end.