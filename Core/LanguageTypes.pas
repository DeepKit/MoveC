unit LanguageTypes;

interface

type
  // 支持的语言类型 (16种语言)
  TLanguageCode = (
    lcChineseSimplified,  // 简体中文
    lcChineseTraditional, // 繁体中文
    lcEnglish,            // 英语
    lcJapanese,           // 日语
    lcKorean,             // 韩语
    lcGerman,             // 德语
    lcFrench,             // 法语
    lcSpanish,            // 西班牙语
    lcItalian,            // 意大利语
    lcRussian,            // 俄语
    lcPortuguese,         // 葡萄牙语
    lcDutch,              // 荷兰语
    lcSwedish,            // 瑞典语
    lcNorwegian,          // 挪威语
    lcDanish,             // 丹麦语
    lcFinnish             // 芬兰语
  );
  
  // 语言信息
  TLanguageInfo = record
    Code: TLanguageCode;
    Name: string;
    NativeName: string;
    FileName: string;
  end;

implementation

end.
