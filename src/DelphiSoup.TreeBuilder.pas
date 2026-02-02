{******************************************************************************}
{                                                                              }
{                              DelphiSoup Library                              }
{                                                                              }
{                          Tree Builder Module                                 }
{                                                                              }
{******************************************************************************}

unit DelphiSoup.TreeBuilder;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  DelphiSoup.Types, DelphiSoup.Element, DelphiSoup.Parser;

type
  /// <summary>
  /// Base class for tree builders that construct the document tree
  /// </summary>
  TTreeBuilder = class
  private
    FSoup: TObject;  // Reference to parent soup object (avoids circular dependency)
    FIsXML: Boolean;
    FEmptyElementTags: TArray<string>;
    FPreserveWhitespaceTags: TArray<string>;
    FCDataListAttributes: TDictionary<string, TArray<string>>;
  protected
    procedure InitializeEmptyElements; virtual;
    procedure InitializePreserveWhitespaceTags; virtual;
    procedure InitializeCDataListAttributes; virtual;
  public
    constructor Create(AIsXML: Boolean = False);
    destructor Destroy; override;
    
    procedure Reset; virtual;
    
    /// <summary>
    /// Check if a tag can be an empty element
    /// </summary>
    function CanBeEmptyElement(const AName: string): Boolean; virtual;
    
    /// <summary>
    /// Check if whitespace should be preserved in this tag
    /// </summary>
    function ShouldPreserveWhitespace(const AName: string): Boolean;
    
    /// <summary>
    /// Set up any necessary substitutions for a tag
    /// </summary>
    procedure SetUpSubstitutions(Tag: TTag); virtual;
    
    /// <summary>
    /// Replace CDATA list attribute values (like class="foo bar")
    /// </summary>
    function ReplaceCDataListAttributeValues(const TagName: string;
      Attrs: TDictionary<string, string>): TDictionary<string, string>;
    
    property IsXML: Boolean read FIsXML write FIsXML;
    property EmptyElementTags: TArray<string> read FEmptyElementTags;
    property PreserveWhitespaceTags: TArray<string> read FPreserveWhitespaceTags;
    property Soup: TObject read FSoup write FSoup;
  end;

  /// <summary>
  /// Tree builder for HTML documents
  /// </summary>
  THTMLTreeBuilder = class(TTreeBuilder)
  private
    // Implicit tag closing rules
    FBlockTagNames: TArray<string>;
    FNestedTagRules: TDictionary<string, TArray<string>>;
  protected
    procedure InitializeEmptyElements; override;
    procedure InitializePreserveWhitespaceTags; override;
    procedure InitializeCDataListAttributes; override;
    procedure InitializeNestedTagRules;
  public
    constructor Create;
    destructor Destroy; override;
    
    /// <summary>
    /// Get tags that should be implicitly closed when this tag opens
    /// </summary>
    function GetTagsToClose(const OpeningTagName: string): TArray<string>;
    
    /// <summary>
    /// Check if opening a tag should close the current tag
    /// </summary>
    function ShouldClosePreviousTag(const CurrentTag, OpeningTag: string): Boolean;
  end;

  /// <summary>
  /// Tree builder for XML documents
  /// </summary>
  TXMLTreeBuilder = class(TTreeBuilder)
  protected
    procedure InitializeEmptyElements; override;
    procedure InitializePreserveWhitespaceTags; override;
  public
    constructor Create;
    
    function CanBeEmptyElement(const AName: string): Boolean; override;
  end;

implementation

uses
  System.StrUtils;

{ TTreeBuilder }

constructor TTreeBuilder.Create(AIsXML: Boolean);
begin
  inherited Create;
  FIsXML := AIsXML;
  FSoup := nil;
  FCDataListAttributes := TDictionary<string, TArray<string>>.Create;
  
  InitializeEmptyElements;
  InitializePreserveWhitespaceTags;
  InitializeCDataListAttributes;
end;

destructor TTreeBuilder.Destroy;
begin
  FCDataListAttributes.Free;
  inherited;
end;

procedure TTreeBuilder.Reset;
begin
  // Override in subclasses if needed
end;

procedure TTreeBuilder.InitializeEmptyElements;
begin
  SetLength(FEmptyElementTags, 0);
end;

procedure TTreeBuilder.InitializePreserveWhitespaceTags;
begin
  SetLength(FPreserveWhitespaceTags, 0);
end;

procedure TTreeBuilder.InitializeCDataListAttributes;
begin
  // Override in subclasses
end;

function TTreeBuilder.CanBeEmptyElement(const AName: string): Boolean;
var
  Tag: string;
  LowerName: string;
begin
  LowerName := LowerCase(AName);
  for Tag in FEmptyElementTags do
    if Tag = LowerName then
      Exit(True);
  Result := False;
end;

function TTreeBuilder.ShouldPreserveWhitespace(const AName: string): Boolean;
var
  Tag: string;
  LowerName: string;
begin
  LowerName := LowerCase(AName);
  for Tag in FPreserveWhitespaceTags do
    if Tag = LowerName then
      Exit(True);
  Result := False;
end;

procedure TTreeBuilder.SetUpSubstitutions(Tag: TTag);
begin
  // Override in subclasses for things like charset substitution in meta tags
end;

function TTreeBuilder.ReplaceCDataListAttributeValues(const TagName: string;
  Attrs: TDictionary<string, string>): TDictionary<string, string>;
var
  Key, Value: string;
  ListAttrs: TArray<string>;
  ListAttr: string;
begin
  Result := TDictionary<string, string>.Create;
  
  for Key in Attrs.Keys do
    Result.Add(Key, Attrs[Key]);
    
  // Check if this tag has CDATA list attributes
  if FCDataListAttributes.TryGetValue(LowerCase(TagName), ListAttrs) then
  begin
    for ListAttr in ListAttrs do
    begin
      if Result.TryGetValue(ListAttr, Value) then
      begin
        // The attribute value is already a string; in Python this would be a list
        // We'll keep it as a string for simplicity
        Result[ListAttr] := Value;
      end;
    end;
  end;
end;

{ THTMLTreeBuilder }

constructor THTMLTreeBuilder.Create;
begin
  inherited Create(False);  // Not XML
  InitializeNestedTagRules;
end;

destructor THTMLTreeBuilder.Destroy;
begin
  FNestedTagRules.Free;
  inherited;
end;

procedure THTMLTreeBuilder.InitializeEmptyElements;
begin
  FEmptyElementTags := TArray<string>.Create(
    'area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input',
    'keygen', 'link', 'menuitem', 'meta', 'param', 'source', 'track', 'wbr',
    // Obsolete elements
    'basefont', 'bgsound', 'command', 'frame', 'image', 'isindex', 'nextid', 'spacer'
  );
end;

procedure THTMLTreeBuilder.InitializePreserveWhitespaceTags;
begin
  FPreserveWhitespaceTags := TArray<string>.Create(
    'pre', 'textarea', 'listing', 'script', 'style'
  );
end;

procedure THTMLTreeBuilder.InitializeCDataListAttributes;
begin
  // Attributes that contain space-separated lists
  FCDataListAttributes.Add('*', TArray<string>.Create('class', 'accesskey', 'dropzone'));
  FCDataListAttributes.Add('a', TArray<string>.Create('rel', 'rev'));
  FCDataListAttributes.Add('link', TArray<string>.Create('rel', 'rev'));
  FCDataListAttributes.Add('td', TArray<string>.Create('headers'));
  FCDataListAttributes.Add('th', TArray<string>.Create('headers'));
  FCDataListAttributes.Add('form', TArray<string>.Create('accept-charset'));
  FCDataListAttributes.Add('object', TArray<string>.Create('archive'));
  FCDataListAttributes.Add('area', TArray<string>.Create('rel'));
  FCDataListAttributes.Add('input', TArray<string>.Create('accept'));
  FCDataListAttributes.Add('output', TArray<string>.Create('for'));
end;

procedure THTMLTreeBuilder.InitializeNestedTagRules;
begin
  FNestedTagRules := TDictionary<string, TArray<string>>.Create;
  
  // When opening these tags, close any open tags in the list
  FNestedTagRules.Add('p', TArray<string>.Create(
    'p'
  ));
  
  FNestedTagRules.Add('li', TArray<string>.Create('li'));
  FNestedTagRules.Add('dt', TArray<string>.Create('dt', 'dd'));
  FNestedTagRules.Add('dd', TArray<string>.Create('dt', 'dd'));
  FNestedTagRules.Add('rp', TArray<string>.Create('rp', 'rt'));
  FNestedTagRules.Add('rt', TArray<string>.Create('rp', 'rt'));
  FNestedTagRules.Add('optgroup', TArray<string>.Create('optgroup'));
  FNestedTagRules.Add('option', TArray<string>.Create('option', 'optgroup'));
  FNestedTagRules.Add('thead', TArray<string>.Create('tbody', 'tfoot'));
  FNestedTagRules.Add('tbody', TArray<string>.Create('tbody', 'tfoot'));
  FNestedTagRules.Add('tfoot', TArray<string>.Create('tbody'));
  FNestedTagRules.Add('tr', TArray<string>.Create('tr'));
  FNestedTagRules.Add('td', TArray<string>.Create('td', 'th'));
  FNestedTagRules.Add('th', TArray<string>.Create('td', 'th'));
  
  FBlockTagNames := TArray<string>.Create(
    'address', 'article', 'aside', 'blockquote', 'canvas', 'dd', 'div',
    'dl', 'dt', 'fieldset', 'figcaption', 'figure', 'footer', 'form',
    'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'header', 'hgroup', 'hr', 'li',
    'main', 'nav', 'noscript', 'ol', 'output', 'p', 'pre', 'section',
    'table', 'tfoot', 'ul', 'video'
  );
end;

function THTMLTreeBuilder.GetTagsToClose(const OpeningTagName: string): TArray<string>;
begin
  if not FNestedTagRules.TryGetValue(LowerCase(OpeningTagName), Result) then
    SetLength(Result, 0);
end;

function THTMLTreeBuilder.ShouldClosePreviousTag(const CurrentTag, 
  OpeningTag: string): Boolean;
var
  TagsToClose: TArray<string>;
  Tag: string;
  LowerCurrentTag: string;
begin
  TagsToClose := GetTagsToClose(OpeningTag);
  LowerCurrentTag := LowerCase(CurrentTag);
  
  for Tag in TagsToClose do
    if Tag = LowerCurrentTag then
      Exit(True);
      
  Result := False;
end;

{ TXMLTreeBuilder }

constructor TXMLTreeBuilder.Create;
begin
  inherited Create(True);  // Is XML
end;

procedure TXMLTreeBuilder.InitializeEmptyElements;
begin
  // XML has no predefined empty elements
  SetLength(FEmptyElementTags, 0);
end;

procedure TXMLTreeBuilder.InitializePreserveWhitespaceTags;
begin
  // XML preserves whitespace by default in no specific tags
  SetLength(FPreserveWhitespaceTags, 0);
end;

function TXMLTreeBuilder.CanBeEmptyElement(const AName: string): Boolean;
begin
  // In XML, any element can be self-closing
  Result := True;
end;

end.
