{******************************************************************************}
{                                                                              }
{                              DelphiSoup Library                              }
{                                                                              }
{            A Delphi port of Python's BeautifulSoup HTML/XML parser           }
{                                                                              }
{                        Copyright (c) 2026                                    }
{                                                                              }
{******************************************************************************}

unit DelphiSoup.Types;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.RegularExpressions;

type
  /// <summary>
  /// Base class that implements IInterface without reference counting.
  /// This allows manual memory management while supporting interfaces.
  /// </summary>
  TNonRefCountedInterfacedObject = class(TObject, IInterface)
  protected
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  end;

  /// <summary>
  /// Formatter types for output generation
  /// </summary>
  TFormatterType = (
    ftNone,      // No formatting, raw output
    ftMinimal,   // Minimal entity substitution (&amp; &lt; &gt;)
    ftHTML       // Full HTML entity substitution
  );

  /// <summary>
  /// Tree builder features/capabilities
  /// </summary>
  TTreeBuilderFeature = (
    tbfHTML,     // HTML parsing mode
    tbfXML,      // XML parsing mode
    tbfFast,     // Optimized for speed
    tbfLenient   // Lenient parsing of malformed markup
  );
  TTreeBuilderFeatures = set of TTreeBuilderFeature;

  /// <summary>
  /// Token types produced by the tokenizer
  /// </summary>
  TTokenType = (
    ttStartTag,
    ttEndTag,
    ttText,
    ttComment,
    ttDoctype,
    ttCData,
    ttProcessingInstruction,
    ttEOF
  );

  /// <summary>
  /// Exception raised when parser rejects markup
  /// </summary>
  EParserRejectedMarkup = class(Exception);

  /// <summary>
  /// Exception raised when a feature is not available
  /// </summary>
  EFeatureNotFound = class(Exception);

  // Forward declarations
  IPageElement = interface;
  ITag = interface;
  INavigableString = interface;

  /// <summary>
  /// Base interface for all page elements
  /// </summary>
  IPageElement = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    // Getters
    function GetParent: ITag;
    function GetNextElement: IPageElement;
    function GetPreviousElement: IPageElement;
    function GetNextSibling: IPageElement;
    function GetPreviousSibling: IPageElement;
    function GetName: string;
    
    // Setters
    procedure SetParent(const Value: ITag);
    procedure SetNextElement(const Value: IPageElement);
    procedure SetPreviousElement(const Value: IPageElement);
    procedure SetNextSibling(const Value: IPageElement);
    procedure SetPreviousSibling(const Value: IPageElement);
    
    // Methods
    procedure Setup(const AParent: ITag; const APreviousElement: IPageElement);
    function Extract: IPageElement;
    function Decode(PrettyPrint: Boolean = False; Formatter: TFormatterType = ftMinimal): string;
    
    // Properties
    property Parent: ITag read GetParent write SetParent;
    property NextElement: IPageElement read GetNextElement write SetNextElement;
    property PreviousElement: IPageElement read GetPreviousElement write SetPreviousElement;
    property NextSibling: IPageElement read GetNextSibling write SetNextSibling;
    property PreviousSibling: IPageElement read GetPreviousSibling write SetPreviousSibling;
    property Name: string read GetName;
  end;

  /// <summary>
  /// Interface for text content elements
  /// </summary>
  INavigableString = interface(IPageElement)
    ['{B2C3D4E5-F6A7-8901-BCDE-F23456789012}']
    function GetValue: string;
    procedure SetValue(const AValue: string);
    function OutputReady(Formatter: TFormatterType = ftMinimal): string;
    
    property Value: string read GetValue write SetValue;
  end;

  /// <summary>
  /// Interface for tag elements
  /// </summary>
  ITag = interface(IPageElement)
    ['{C3D4E5F6-A7B8-9012-CDEF-345678901234}']
    // Getters
    function GetAttrs: TDictionary<string, string>;
    function GetContents: TList<IPageElement>;
    function GetTagName: string;
    function GetNamespace: string;
    function GetPrefix: string;
    function GetHidden: Boolean;
    function GetCanBeEmptyElement: Boolean;
    function GetIsEmptyElement: Boolean;
    function GetText: string;
    function GetString: INavigableString;
    
    // Setters
    procedure SetTagName(const Value: string);
    procedure SetNamespace(const Value: string);
    procedure SetPrefix(const Value: string);
    procedure SetHidden(const Value: Boolean);
    procedure SetCanBeEmptyElement(const Value: Boolean);
    
    // Search methods
    function Find(const AName: string; const AAttrs: array of const): ITag; overload;
    function Find(const AName: string = ''): ITag; overload;
    function FindAll(const AName: string; const AAttrs: array of const; ALimit: Integer = 0): TList<ITag>; overload;
    function FindAll(const AName: string = ''; ALimit: Integer = 0): TList<ITag>; overload;
    
    // CSS selectors
    function Select(const Selector: string): TList<ITag>;
    function SelectOne(const Selector: string): ITag;
    
    // Sibling search
    function FindNextSibling(const AName: string = ''): ITag;
    function FindNextSiblings(const AName: string = ''; ALimit: Integer = 0): TList<ITag>;
    function FindPreviousSibling(const AName: string = ''): ITag;
    function FindPreviousSiblings(const AName: string = ''; ALimit: Integer = 0): TList<ITag>;
    
    // Parent search
    function FindParent(const AName: string = ''): ITag;
    function FindParents(const AName: string = ''; ALimit: Integer = 0): TList<ITag>;
    
    // Content manipulation
    procedure Append(const AElement: IPageElement);
    procedure Insert(APosition: Integer; const AElement: IPageElement);
    procedure Clear(ADecompose: Boolean = False);
    procedure Decompose;
    function Index(const AElement: IPageElement): Integer;
    
    // Attribute access
    function GetAttr(const AKey: string; const ADefault: string = ''): string;
    procedure SetAttr(const AKey, AValue: string);
    function HasAttr(const AKey: string): Boolean;
    procedure DeleteAttr(const AKey: string);
    
    // Output
    function Prettify(Formatter: TFormatterType = ftMinimal): string;
    function DecodeContents(IndentLevel: Integer = -1; Formatter: TFormatterType = ftMinimal): string;
    
    // Properties
    property TagName: string read GetTagName write SetTagName;
    property Namespace: string read GetNamespace write SetNamespace;
    property Prefix: string read GetPrefix write SetPrefix;
    property Attrs: TDictionary<string, string> read GetAttrs;
    property Contents: TList<IPageElement> read GetContents;
    property Hidden: Boolean read GetHidden write SetHidden;
    property CanBeEmptyElement: Boolean read GetCanBeEmptyElement write SetCanBeEmptyElement;
    property IsEmptyElement: Boolean read GetIsEmptyElement;
    property Text: string read GetText;
    property StringValue: INavigableString read GetString;
  end;

  /// <summary>
  /// Token produced by the HTML/XML tokenizer
  /// </summary>
  TToken = record
    TokenType: TTokenType;
    Name: string;
    Attrs: TDictionary<string, string>;
    Data: string;
    SelfClosing: Boolean;
    
    class function CreateStartTag(const AName: string; AAttrs: TDictionary<string, string>;
      ASelfClosing: Boolean = False): TToken; static;
    class function CreateEndTag(const AName: string): TToken; static;
    class function CreateText(const AData: string): TToken; static;
    class function CreateComment(const AData: string): TToken; static;
    class function CreateDoctype(const AData: string): TToken; static;
    class function CreateCData(const AData: string): TToken; static;
    class function CreateEOF: TToken; static;
  end;

  /// <summary>
  /// Match value for flexible searching
  /// </summary>
  TMatchValue = record
  private
    FIsSet: Boolean;
    FIsString: Boolean;
    FIsRegex: Boolean;
    FIsList: Boolean;
    FIsBoolean: Boolean;
    FStringValue: string;
    FRegexValue: TRegEx;
    FListValue: TArray<string>;
    FBoolValue: Boolean;
  public
    class function Empty: TMatchValue; static;
    class function FromString(const AValue: string): TMatchValue; static;
    class function FromRegex(const APattern: string): TMatchValue; static;
    class function FromList(const AValues: TArray<string>): TMatchValue; static;
    class function FromBoolean(AValue: Boolean): TMatchValue; static;
    
    function IsSet: Boolean;
    function Matches(const AValue: string): Boolean;
    
    property IsString: Boolean read FIsString;
    property IsRegex: Boolean read FIsRegex;
    property IsList: Boolean read FIsList;
    property IsBoolean: Boolean read FIsBoolean;
    property StringValue: string read FStringValue;
    property BoolValue: Boolean read FBoolValue;
  end;

  /// <summary>
  /// HTML empty element (void) tags
  /// </summary>
  THTMLEmptyElements = class
  public
    class function IsEmptyElement(const AName: string): Boolean;
    class function GetEmptyElements: TArray<string>;
  end;

  /// <summary>
  /// HTML block-level tags
  /// </summary>
  THTMLBlockElements = class
  public
    class function IsBlockElement(const AName: string): Boolean;
  end;

  /// <summary>
  /// HTML preformatted/whitespace-preserving tags
  /// </summary>
  THTMLPreformattedTags = class
  public
    class function IsPreformatted(const AName: string): Boolean;
  end;

implementation

{ TNonRefCountedInterfacedObject }

function TNonRefCountedInterfacedObject.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    Result := S_OK
  else
    Result := E_NOINTERFACE;
end;

function TNonRefCountedInterfacedObject._AddRef: Integer;
begin
  Result := -1;  // Non-reference counted
end;

function TNonRefCountedInterfacedObject._Release: Integer;
begin
  Result := -1;  // Non-reference counted
end;

{ TToken }

class function TToken.CreateStartTag(const AName: string; 
  AAttrs: TDictionary<string, string>; ASelfClosing: Boolean): TToken;
begin
  Result.TokenType := ttStartTag;
  Result.Name := AName;
  Result.Attrs := AAttrs;
  Result.Data := '';
  Result.SelfClosing := ASelfClosing;
end;

class function TToken.CreateEndTag(const AName: string): TToken;
begin
  Result.TokenType := ttEndTag;
  Result.Name := AName;
  Result.Attrs := nil;
  Result.Data := '';
  Result.SelfClosing := False;
end;

class function TToken.CreateText(const AData: string): TToken;
begin
  Result.TokenType := ttText;
  Result.Name := '';
  Result.Attrs := nil;
  Result.Data := AData;
  Result.SelfClosing := False;
end;

class function TToken.CreateComment(const AData: string): TToken;
begin
  Result.TokenType := ttComment;
  Result.Name := '';
  Result.Attrs := nil;
  Result.Data := AData;
  Result.SelfClosing := False;
end;

class function TToken.CreateDoctype(const AData: string): TToken;
begin
  Result.TokenType := ttDoctype;
  Result.Name := '';
  Result.Attrs := nil;
  Result.Data := AData;
  Result.SelfClosing := False;
end;

class function TToken.CreateCData(const AData: string): TToken;
begin
  Result.TokenType := ttCData;
  Result.Name := '';
  Result.Attrs := nil;
  Result.Data := AData;
  Result.SelfClosing := False;
end;

class function TToken.CreateEOF: TToken;
begin
  Result.TokenType := ttEOF;
  Result.Name := '';
  Result.Attrs := nil;
  Result.Data := '';
  Result.SelfClosing := False;
end;

{ TMatchValue }

class function TMatchValue.Empty: TMatchValue;
begin
  Result.FIsSet := False;
  Result.FIsString := False;
  Result.FIsRegex := False;
  Result.FIsList := False;
  Result.FIsBoolean := False;
  Result.FStringValue := '';
  Result.FBoolValue := False;
  SetLength(Result.FListValue, 0);
end;

class function TMatchValue.FromString(const AValue: string): TMatchValue;
begin
  Result := Empty;
  Result.FIsSet := True;
  Result.FIsString := True;
  Result.FStringValue := AValue;
end;

class function TMatchValue.FromRegex(const APattern: string): TMatchValue;
begin
  Result := Empty;
  Result.FIsSet := True;
  Result.FIsRegex := True;
  Result.FRegexValue := TRegEx.Create(APattern, [roIgnoreCase]);
end;

class function TMatchValue.FromList(const AValues: TArray<string>): TMatchValue;
begin
  Result := Empty;
  Result.FIsSet := True;
  Result.FIsList := True;
  Result.FListValue := AValues;
end;

class function TMatchValue.FromBoolean(AValue: Boolean): TMatchValue;
begin
  Result := Empty;
  Result.FIsSet := True;
  Result.FIsBoolean := True;
  Result.FBoolValue := AValue;
end;

function TMatchValue.IsSet: Boolean;
begin
  Result := FIsSet;
end;

function TMatchValue.Matches(const AValue: string): Boolean;
var
  S: string;
begin
  if not FIsSet then
    Exit(True);  // Not set means match anything
    
  if FIsBoolean then
  begin
    if FBoolValue then
      Result := AValue <> ''  // True matches any non-empty value
    else
      Result := AValue = '';  // False matches empty value
  end
  else if FIsString then
    Result := SameText(AValue, FStringValue)
  else if FIsRegex then
    Result := FRegexValue.IsMatch(AValue)
  else if FIsList then
  begin
    Result := False;
    for S in FListValue do
      if SameText(AValue, S) then
        Exit(True);
  end
  else
    Result := True;
end;

{ THTMLEmptyElements }

class function THTMLEmptyElements.GetEmptyElements: TArray<string>;
begin
  Result := TArray<string>.Create(
    'area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input',
    'link', 'meta', 'param', 'source', 'track', 'wbr',
    // Obsolete but still used
    'command', 'keygen', 'menuitem'
  );
end;

class function THTMLEmptyElements.IsEmptyElement(const AName: string): Boolean;
var
  Element: string;
  LowerName: string;
begin
  LowerName := LowerCase(AName);
  for Element in GetEmptyElements do
    if Element = LowerName then
      Exit(True);
  Result := False;
end;

{ THTMLBlockElements }

class function THTMLBlockElements.IsBlockElement(const AName: string): Boolean;
const
  BlockElements: array[0..35] of string = (
    'address', 'article', 'aside', 'blockquote', 'canvas', 'dd', 'div',
    'dl', 'dt', 'fieldset', 'figcaption', 'figure', 'footer', 'form',
    'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'header', 'hgroup', 'hr', 'li',
    'main', 'nav', 'noscript', 'ol', 'output', 'p', 'pre', 'section',
    'table', 'tfoot', 'ul', 'video'
  );
var
  Element: string;
  LowerName: string;
begin
  LowerName := LowerCase(AName);
  for Element in BlockElements do
    if Element = LowerName then
      Exit(True);
  Result := False;
end;

{ THTMLPreformattedTags }

class function THTMLPreformattedTags.IsPreformatted(const AName: string): Boolean;
const
  PreformattedTags: array[0..2] of string = ('pre', 'textarea', 'listing');
var
  Element: string;
  LowerName: string;
begin
  LowerName := LowerCase(AName);
  for Element in PreformattedTags do
    if Element = LowerName then
      Exit(True);
  Result := False;
end;

end.
