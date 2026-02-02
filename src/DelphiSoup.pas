{******************************************************************************}
{                                                                              }
{                              DelphiSoup Library                              }
{                                                                              }
{            A Delphi port of Python's BeautifulSoup HTML/XML parser           }
{                                                                              }
{                        Copyright (c) 2026                                    }
{                                                                              }
{******************************************************************************}

unit DelphiSoup;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  DelphiSoup.Types, DelphiSoup.Element, DelphiSoup.Entities, 
  DelphiSoup.Parser, DelphiSoup.TreeBuilder, DelphiSoup.Strainer;

type
  /// <summary>
  /// Main BeautifulSoup class - the entry point for HTML/XML parsing
  /// </summary>
  TBeautifulSoup = class(TTag)
  public const
    ROOT_TAG_NAME = '[document]';
    VERSION = '1.0.0';
  private
    FBuilder: TTreeBuilder;
    FParseOnly: TSoupStrainer;
    FOriginalEncoding: TEncoding;
    FCurrentData: TStringBuilder;
    FCurrentTag: TTag;
    FTagStack: TStack<TTag>;
    FPreserveWhitespaceTagStack: TStack<TTag>;
    FMostRecentElement: IPageElement;
    
    procedure DoFeed(const Markup: string);
    procedure EndData(ContainerClass: TClass = nil);
    procedure ObjectWasParsed(Element: IPageElement; AParent: TTag = nil);
    procedure PopToTag(const AName: string; InclusivePop: Boolean = True);
  public
    /// <summary>
    /// Create a BeautifulSoup parser from markup string
    /// </summary>
    constructor Create(const Markup: string; 
      Features: TTreeBuilderFeatures = []); overload;
      
    /// <summary>
    /// Create a BeautifulSoup parser from a stream
    /// </summary>
    constructor CreateFromStream(Stream: TStream; 
      Features: TTreeBuilderFeatures = []); overload;
      
    /// <summary>
    /// Create a BeautifulSoup parser from a file
    /// </summary>
    constructor CreateFromFile(const FileName: string; 
      Features: TTreeBuilderFeatures = []); overload;
      
    destructor Destroy; override;
    
    /// <summary>
    /// Reset the parser to initial state
    /// </summary>
    procedure Reset;
    
    // Parser callbacks (used internally)
    procedure HandleStartTag(const AName: string; 
      Attrs: TDictionary<string, string>; SelfClosing: Boolean);
    procedure HandleEndTag(const AName: string);
    procedure HandleData(const Data: string);
    procedure HandleComment(const Data: string);
    procedure HandleDoctype(const Data: string);
    procedure HandleCData(const Data: string);
    
    // Factory methods
    function NewTag(const AName: string; 
      Attrs: TDictionary<string, string> = nil): TTag;
    function NewString(const S: string): TNavigableString;
    
    // Tree manipulation
    procedure PushTag(ATag: TTag);
    function PopTag: TTag;
    
    // Override decode to handle document output
    function Decode(PrettyPrint: Boolean = False; 
      Formatter: TFormatterType = ftMinimal): string; override;
    
    property Builder: TTreeBuilder read FBuilder;
    property OriginalEncoding: TEncoding read FOriginalEncoding;
  end;

/// <summary>
/// Convenience function to parse HTML
/// </summary>
function ParseHTML(const Markup: string): TBeautifulSoup;

/// <summary>
/// Convenience function to parse XML
/// </summary>
function ParseXML(const Markup: string): TBeautifulSoup;

/// <summary>
/// Parse HTML from a file
/// </summary>
function ParseHTMLFile(const FileName: string): TBeautifulSoup;

/// <summary>
/// Parse XML from a file
/// </summary>
function ParseXMLFile(const FileName: string): TBeautifulSoup;

implementation

{ Helper functions }

function ParseHTML(const Markup: string): TBeautifulSoup;
begin
  Result := TBeautifulSoup.Create(Markup, [tbfHTML]);
end;

function ParseXML(const Markup: string): TBeautifulSoup;
begin
  Result := TBeautifulSoup.Create(Markup, [tbfXML]);
end;

function ParseHTMLFile(const FileName: string): TBeautifulSoup;
begin
  Result := TBeautifulSoup.CreateFromFile(FileName, [tbfHTML]);
end;

function ParseXMLFile(const FileName: string): TBeautifulSoup;
begin
  Result := TBeautifulSoup.CreateFromFile(FileName, [tbfXML]);
end;

{ TBeautifulSoup }

constructor TBeautifulSoup.Create(const Markup: string; 
  Features: TTreeBuilderFeatures);
begin
  // Initialize as the root tag
  inherited Create(ROOT_TAG_NAME, nil, tbfXML in Features);
  
  FHidden := True;  // Root tag is hidden
  FOriginalEncoding := TEncoding.UTF8;
  
  // Create the appropriate tree builder
  if tbfXML in Features then
    FBuilder := TXMLTreeBuilder.Create
  else
    FBuilder := THTMLTreeBuilder.Create;
    
  FBuilder.Soup := Self;
  
  FParseOnly := nil;
  FCurrentData := TStringBuilder.Create;
  FTagStack := TStack<TTag>.Create;
  FPreserveWhitespaceTagStack := TStack<TTag>.Create;
  FMostRecentElement := nil;
  
  Reset;
  
  // Parse the markup
  if Markup <> '' then
    DoFeed(Markup);
end;

constructor TBeautifulSoup.CreateFromStream(Stream: TStream; 
  Features: TTreeBuilderFeatures);
var
  Reader: TStreamReader;
  Markup: string;
begin
  Reader := TStreamReader.Create(Stream, TEncoding.UTF8, True);
  try
    Markup := Reader.ReadToEnd;
  finally
    Reader.Free;
  end;
  
  Create(Markup, Features);
end;

constructor TBeautifulSoup.CreateFromFile(const FileName: string; 
  Features: TTreeBuilderFeatures);
var
  FileStream: TFileStream;
begin
  FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    CreateFromStream(FileStream, Features);
  finally
    FileStream.Free;
  end;
end;

destructor TBeautifulSoup.Destroy;
begin
  FPreserveWhitespaceTagStack.Free;
  FTagStack.Free;
  FCurrentData.Free;
  FParseOnly.Free;
  FBuilder.Free;
  inherited;
end;

procedure TBeautifulSoup.Reset;
begin
  // Re-initialize as root tag
  FTagName := ROOT_TAG_NAME;
  FHidden := True;
  FContents.Clear;
  
  FBuilder.Reset;
  FCurrentData.Clear;
  FCurrentTag := nil;
  
  FTagStack.Clear;
  FPreserveWhitespaceTagStack.Clear;
  FMostRecentElement := nil;
  
  PushTag(Self);
end;

procedure TBeautifulSoup.DoFeed(const Markup: string);
var
  Parser: THTMLParser;
begin
  Parser := THTMLParser.Create(Markup, FBuilder.IsXML);
  try
    Parser.OnStartTag := HandleStartTag;
    Parser.OnEndTag := HandleEndTag;
    Parser.OnText := HandleData;
    Parser.OnComment := HandleComment;
    Parser.OnDoctype := HandleDoctype;
    Parser.OnCData := HandleCData;
    
    Parser.Parse;
    
    // Close out any remaining data
    EndData;
    
    // Close all remaining open tags
    while FCurrentTag.TagName <> ROOT_TAG_NAME do
      PopTag;
  finally
    Parser.Free;
  end;
end;

procedure TBeautifulSoup.HandleStartTag(const AName: string;
  Attrs: TDictionary<string, string>; SelfClosing: Boolean);
var
  Tag: TTag;
  ProcessedAttrs: TDictionary<string, string>;
  HTMLBuilder: THTMLTreeBuilder;
begin
  EndData;
  
  // Check for parse_only filter
  if (FParseOnly <> nil) and (FTagStack.Count <= 1) then
  begin
    // Skip if doesn't match filter
    // (simplified - full implementation would check strainer)
  end;
  
  // Handle HTML implicit tag closing
  if FBuilder is THTMLTreeBuilder then
  begin
    HTMLBuilder := FBuilder as THTMLTreeBuilder;
    while (FCurrentTag <> nil) and (FCurrentTag.TagName <> ROOT_TAG_NAME) and
          HTMLBuilder.ShouldClosePreviousTag(FCurrentTag.TagName, AName) do
    begin
      PopTag;
    end;
  end;
  
  // Process attributes
  if Attrs <> nil then
    ProcessedAttrs := FBuilder.ReplaceCDataListAttributeValues(AName, Attrs)
  else
    ProcessedAttrs := nil;
  
  try
    Tag := TTag.Create(AName, ProcessedAttrs, FBuilder.IsXML);
    Tag.CanBeEmptyElement := FBuilder.CanBeEmptyElement(AName);
  finally
    if ProcessedAttrs <> nil then
      ProcessedAttrs.Free;
  end;
  
  // Set up element links
  if FMostRecentElement <> nil then
    FMostRecentElement.NextElement := Tag;
  FMostRecentElement := Tag;
  
  // Apply any substitutions (like charset in meta tags)
  FBuilder.SetUpSubstitutions(Tag);
  
  PushTag(Tag);
  
  // Handle self-closing tags
  if SelfClosing or FBuilder.CanBeEmptyElement(AName) then
    PopTag;
end;

procedure TBeautifulSoup.HandleEndTag(const AName: string);
begin
  EndData;
  PopToTag(AName);
end;

procedure TBeautifulSoup.HandleData(const Data: string);
begin
  FCurrentData.Append(Data);
end;

procedure TBeautifulSoup.HandleComment(const Data: string);
var
  Comment: TComment;
begin
  EndData;
  
  Comment := TComment.Create(Data);
  ObjectWasParsed(Comment);
end;

procedure TBeautifulSoup.HandleDoctype(const Data: string);
var
  Doctype: TDoctype;
begin
  EndData;
  
  Doctype := TDoctype.Create(Data);
  ObjectWasParsed(Doctype);
end;

procedure TBeautifulSoup.HandleCData(const Data: string);
var
  CData: TCData;
begin
  EndData;
  
  CData := TCData.Create(Data);
  ObjectWasParsed(CData);
end;

procedure TBeautifulSoup.EndData(ContainerClass: TClass);
var
  CurrentData: string;
  Strippable: Boolean;
  C: Char;
  NavString: TNavigableString;
begin
  if FCurrentData.Length = 0 then
    Exit;
    
  CurrentData := FCurrentData.ToString;
  FCurrentData.Clear;
  
  // Handle whitespace collapsing when not in a preserve-whitespace tag
  if FPreserveWhitespaceTagStack.Count = 0 then
  begin
    Strippable := True;
    for C in CurrentData do
    begin
      if not CharInSet(C, [' ', #9, #10, #12, #13]) then
      begin
        Strippable := False;
        Break;
      end;
    end;
    
    if Strippable then
    begin
      if Pos(#10, CurrentData) > 0 then
        CurrentData := #10
      else
        CurrentData := ' ';
    end;
  end;
  
  // Apply parse_only filter if present
  if (FParseOnly <> nil) and (FTagStack.Count <= 1) then
  begin
    // Skip if doesn't match filter
    // (simplified implementation)
  end;
  
  // Create the NavigableString
  if ContainerClass <> nil then
  begin
    NavString := ContainerClass.NewInstance as TNavigableString;
    NavString.Create(CurrentData);
  end
  else
    NavString := TNavigableString.Create(CurrentData);
    
  ObjectWasParsed(NavString);
end;

procedure TBeautifulSoup.ObjectWasParsed(Element: IPageElement; AParent: TTag);
begin
  if AParent = nil then
    AParent := FCurrentTag;
    
  Element.Setup(AParent, FMostRecentElement);
  
  if FMostRecentElement <> nil then
    FMostRecentElement.NextElement := Element;
    
  FMostRecentElement := Element;
  AParent.Contents.Add(Element);
end;

procedure TBeautifulSoup.PopToTag(const AName: string; InclusivePop: Boolean);
var
  MostRecentlyPopped: TTag;
  I: Integer;
  T: TTag;
begin
  if AName = ROOT_TAG_NAME then
    Exit;
    
  MostRecentlyPopped := nil;
  
  // Find the tag in the stack and pop to it
  for I := FTagStack.Count - 1 downto 1 do
  begin
    T := FTagStack.Peek;
    
    if SameText(T.TagName, AName) then
    begin
      if InclusivePop then
        MostRecentlyPopped := PopTag;
      Break;
    end;
    
    MostRecentlyPopped := PopTag;
  end;
end;

procedure TBeautifulSoup.PushTag(ATag: TTag);
begin
  if FCurrentTag <> nil then
  begin
    // Don't add to contents here - that's done in ObjectWasParsed
    if ATag <> Self then
      ObjectWasParsed(ATag);
  end;
  
  FTagStack.Push(ATag);
  FCurrentTag := ATag;
  
  if FBuilder.ShouldPreserveWhitespace(ATag.TagName) then
    FPreserveWhitespaceTagStack.Push(ATag);
end;

function TBeautifulSoup.PopTag: TTag;
begin
  Result := FTagStack.Pop;
  
  if (FPreserveWhitespaceTagStack.Count > 0) and 
     (FPreserveWhitespaceTagStack.Peek = Result) then
    FPreserveWhitespaceTagStack.Pop;
    
  if FTagStack.Count > 0 then
    FCurrentTag := FTagStack.Peek
  else
    FCurrentTag := nil;
end;

function TBeautifulSoup.NewTag(const AName: string;
  Attrs: TDictionary<string, string>): TTag;
begin
  Result := TTag.Create(AName, Attrs, FBuilder.IsXML);
  Result.CanBeEmptyElement := FBuilder.CanBeEmptyElement(AName);
end;

function TBeautifulSoup.NewString(const S: string): TNavigableString;
begin
  Result := TNavigableString.Create(S);
  Result.Setup(nil, nil);
end;

function TBeautifulSoup.Decode(PrettyPrint: Boolean; 
  Formatter: TFormatterType): string;
var
  Prefix: string;
begin
  // Add XML declaration if this is an XML document
  if FBuilder.IsXML then
    Prefix := '<?xml version="1.0" encoding="utf-8"?>'#10
  else
    Prefix := '';
    
  if PrettyPrint then
    Result := Prefix + DecodeContents(0, Formatter)
  else
    Result := Prefix + DecodeContents(-1, Formatter);
end;

end.
