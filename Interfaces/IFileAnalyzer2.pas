unit IFileAnalyzer2;

interface

uses
  System.SysUtils, System.Classes, DataTypes;

type
  // 文件分析器接口
  IFileAnalyzer = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    function AnalyzeFile(const AFilePath: string): TFileAnalysisResult;
    function AnalyzeDirectory(const ADirPath: string): TArray<TFileAnalysisResult>;
    function CheckDependencies(const AFilePath: string): TArray<string>;
    function EvaluateSymlinkFeasibility(const AFilePath: string): TSymlinkFeasibility;
  end;

implementation

end.
