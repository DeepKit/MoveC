unit uIconManager;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShellAPI,
  System.SysUtils, System.Classes, System.IOUtils,
  Vcl.Graphics, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ImgList,
  Vcl.Imaging.pngimage, Vcl.Buttons;

type
  TIconManager = class
  private
    FImageList: TImageList;
    FAssetsPath: string;
    procedure CreateSystemIcons;
    procedure LoadIconFromFile(const AFileName: string; AIndex: Integer);
    function CreateColoredIcon(AColor: TColor; ASize: Integer = 32): TBitmap;
    function CreateIconWithText(const AText: string; AColor: TColor; ASize: Integer = 32): TBitmap;
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure LoadButtonIcons(AButton: TBitBtn; AIconIndex: Integer);
    procedure ApplyIconToButton(AButton: TBitBtn; AIconIndex: Integer);
    
    property ImageList: TImageList read FImageList;
    
    // 图标索引常量
    const
      ICON_RECYCLE_BIN = 0;
      ICON_CLEAN_TEMP = 1;
      ICON_CLEAN_BACKUP = 2;
      ICON_CLEAN_UPDATE = 3;
      ICON_SMART_CLEAN = 4;
      ICON_SMART_MIGRATION = 5;
      ICON_EXECUTE = 6;
      ICON_ANALYZE = 7;
      ICON_CALCULATE = 8;
      ICON_EXIT = 9;
      ICON_BROWSE = 10;
      ICON_UP = 11;
      ICON_DIAGNOSE = 12;
      ICON_ROLLBACK = 13;
      ICON_FILE_MANAGER = 14;
  end;

var
  IconManager: TIconManager;

implementation

constructor TIconManager.Create;
begin
  inherited Create;

  FAssetsPath := ExtractFilePath(ParamStr(0)) + 'assets\icons\';

  // 创建ImageList
  FImageList := TImageList.Create(nil);
  FImageList.Width := 32;
  FImageList.Height := 32;
  FImageList.ColorDepth := cd24Bit;

  // 确保assets目录存在
  if not TDirectory.Exists(FAssetsPath) then
    TDirectory.CreateDirectory(FAssetsPath);

  // 创建系统图标
  CreateSystemIcons;

  // 调试信息
  OutputDebugString(PChar('IconManager: Created ' + IntToStr(FImageList.Count) + ' icons'));
end;

destructor TIconManager.Destroy;
begin
  FImageList.Free;
  inherited Destroy;
end;

procedure TIconManager.CreateSystemIcons;
var
  Icon: TIcon;
  Bitmap: TBitmap;
begin
  // 创建各种功能的图标 - 使用简单的字母和符号

  // 0. 回收站图标 - 绿色
  Bitmap := CreateIconWithText('R', $4CAF50);
  FImageList.Add(Bitmap, nil);
  Bitmap.Free;

  // 1. 清理临时文件 - 蓝色
  Bitmap := CreateIconWithText('T', $2196F3);
  FImageList.Add(Bitmap, nil);
  Bitmap.Free;

  // 2. 清理备份 - 紫色
  Bitmap := CreateIconWithText('B', $9C27B0);
  FImageList.Add(Bitmap, nil);
  Bitmap.Free;

  // 3. 清理更新缓存 - 橙色
  Bitmap := CreateIconWithText('U', $FF9800);
  FImageList.Add(Bitmap, nil);
  Bitmap.Free;

  // 4. 智能清理 - 青色
  Bitmap := CreateIconWithText('S', $009688);
  FImageList.Add(Bitmap, nil);
  Bitmap.Free;

  // 5. 智能迁移 - 青蓝色
  Bitmap := CreateIconWithText('M', $00BCD4);
  FImageList.Add(Bitmap, nil);
  Bitmap.Free;

  // 6. 执行迁移 - 绿色
  Bitmap := CreateIconWithText('E', $4CAF50);
  FImageList.Add(Bitmap, nil);
  Bitmap.Free;

  // 7. 分析目录 - 蓝色
  Bitmap := CreateIconWithText('A', $2196F3);
  FImageList.Add(Bitmap, nil);
  Bitmap.Free;

  // 8. 计算大小 - 橙色
  Bitmap := CreateIconWithText('C', $FF9800);
  FImageList.Add(Bitmap, nil);
  Bitmap.Free;

  // 9. 退出 - 红色
  Bitmap := CreateIconWithText('X', $F44336);
  FImageList.Add(Bitmap, nil);
  Bitmap.Free;

  // 10. 浏览 - 灰色
  Bitmap := CreateIconWithText('F', $607D8B);
  FImageList.Add(Bitmap, nil);
  Bitmap.Free;

  // 11. 上级 - 棕色
  Bitmap := CreateIconWithText('^', $795548);
  FImageList.Add(Bitmap, nil);
  Bitmap.Free;
  
  // 12. 一键诊断 - 蓝色
  Bitmap := CreateIconWithText('D', $3F51B5);
  FImageList.Add(Bitmap, nil);
  Bitmap.Free;
  
  // 13. 回退 - 深橙色
  Bitmap := CreateIconWithText('←', $FF5722);  // 左箭头符号
  FImageList.Add(Bitmap, nil);
  Bitmap.Free;
  
  // 14. 高级文件管理器 - 橙色
  Bitmap := CreateIconWithText('FM', $FF9800);  // File Manager缩写
  FImageList.Add(Bitmap, nil);
  Bitmap.Free;
end;

function TIconManager.CreateIconWithText(const AText: string; AColor: TColor; ASize: Integer): TBitmap;
var
  Rect: TRect;
begin
  Result := TBitmap.Create;
  Result.Width := ASize;
  Result.Height := ASize;
  Result.PixelFormat := pf24bit;

  // 绘制白色背景
  Result.Canvas.Brush.Style := bsSolid;
  Result.Canvas.Brush.Color := clWhite;
  Result.Canvas.FillRect(TRect.Create(0, 0, ASize, ASize));

  // 绘制彩色圆形
  Result.Canvas.Pen.Style := psSolid;
  Result.Canvas.Pen.Color := AColor;
  Result.Canvas.Pen.Width := 2;
  Result.Canvas.Brush.Color := AColor;
  Result.Canvas.Ellipse(2, 2, ASize-2, ASize-2);

  // 绘制黑色边框
  Result.Canvas.Pen.Color := clBlack;
  Result.Canvas.Pen.Width := 1;
  Result.Canvas.Brush.Style := bsClear;
  Result.Canvas.Rectangle(0, 0, ASize, ASize);

  // 绘制文字
  Result.Canvas.Brush.Style := bsClear;
  Result.Canvas.Font.Name := 'Arial';
  Result.Canvas.Font.Size := ASize div 2;
  Result.Canvas.Font.Color := clWhite;
  Result.Canvas.Font.Style := [fsBold];

  Rect := TRect.Create(0, 0, ASize, ASize);
  DrawText(Result.Canvas.Handle, PChar(AText), -1, Rect,
           DT_CENTER or DT_VCENTER or DT_SINGLELINE);
end;

function TIconManager.CreateColoredIcon(AColor: TColor; ASize: Integer): TBitmap;
begin
  Result := TBitmap.Create;
  Result.Width := ASize;
  Result.Height := ASize;
  Result.PixelFormat := pf32bit;
  
  Result.Canvas.Brush.Color := AColor;
  Result.Canvas.FillRect(Rect(0, 0, ASize, ASize));
  
  // 添加边框
  Result.Canvas.Pen.Color := clGray;
  Result.Canvas.Pen.Width := 1;
  Result.Canvas.Rectangle(0, 0, ASize, ASize);
end;

procedure TIconManager.LoadIconFromFile(const AFileName: string; AIndex: Integer);
var
  PNG: TPngImage;
  Bitmap: TBitmap;
  FullPath: string;
begin
  FullPath := FAssetsPath + AFileName;
  
  if TFile.Exists(FullPath) then
  begin
    PNG := TPngImage.Create;
    try
      PNG.LoadFromFile(FullPath);
      
      Bitmap := TBitmap.Create;
      try
        Bitmap.Assign(PNG);
        if AIndex < FImageList.Count then
          FImageList.Replace(AIndex, Bitmap, nil)
        else
          FImageList.Add(Bitmap, nil);
      finally
        Bitmap.Free;
      end;
    finally
      PNG.Free;
    end;
  end;
end;

procedure TIconManager.LoadButtonIcons(AButton: TBitBtn; AIconIndex: Integer);
begin
  ApplyIconToButton(AButton, AIconIndex);
end;

procedure TIconManager.ApplyIconToButton(AButton: TBitBtn; AIconIndex: Integer);
var
  Bitmap: TBitmap;
  IconText: string;
  IconColor: TColor;
begin
  // 直接创建图标，不使用ImageList
  case AIconIndex of
    ICON_RECYCLE_BIN: begin IconText := 'R'; IconColor := $4CAF50; end;
    ICON_CLEAN_TEMP: begin IconText := 'T'; IconColor := $2196F3; end;
    ICON_CLEAN_BACKUP: begin IconText := 'B'; IconColor := $9C27B0; end;
    ICON_CLEAN_UPDATE: begin IconText := 'U'; IconColor := $FF9800; end;
    ICON_SMART_CLEAN: begin IconText := 'S'; IconColor := $009688; end;
    ICON_SMART_MIGRATION: begin IconText := 'M'; IconColor := $00BCD4; end;
    ICON_EXECUTE: begin IconText := 'E'; IconColor := $4CAF50; end;
    ICON_ANALYZE: begin IconText := 'A'; IconColor := $2196F3; end;
    ICON_CALCULATE: begin IconText := 'C'; IconColor := $FF9800; end;
    ICON_EXIT: begin IconText := 'X'; IconColor := $F44336; end;
    ICON_BROWSE: begin IconText := 'F'; IconColor := $607D8B; end;
    ICON_UP: begin IconText := '^'; IconColor := $795548; end;
    ICON_DIAGNOSE: begin IconText := 'D'; IconColor := $3F51B5; end;
    ICON_ROLLBACK: begin IconText := '←'; IconColor := $FF5722; end;
  else
    Exit;
  end;

  Bitmap := CreateIconWithText(IconText, IconColor, 32);
  try
    if (Bitmap.Width > 0) and (Bitmap.Height > 0) then
    begin
      // 设置tbitbtn的图标
      AButton.Glyph.Assign(Bitmap);
      AButton.Layout := blGlyphLeft;
      AButton.Spacing := 4;
      AButton.Margin := -1;  // 使用-1让delphi自动居中

      // 调整按钮样式
      AButton.Height := 46;  // 增加10像素
    end;
  finally
    Bitmap.Free;
  end;
end;

initialization
  IconManager := TIconManager.Create;

finalization
  IconManager.Free;

end.
