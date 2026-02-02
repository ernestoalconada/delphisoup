{******************************************************************************}
{                                                                              }
{                              DelphiSoup Library                              }
{                                                                              }
{                           Element Classes Module                             }
{                                                                              }
{******************************************************************************}

unit DelphiSoup.Element;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.Generics.Defaults,
  DelphiSoup.Types, DelphiSoup.Entities;

type
  // Forward declarations
  TPageElement = class;
  TNavigableString = class;
  TTag = class;

  /// <summary>
  /// Base class for all page elements (tags and text)
  /// </summary>
  TPageElement = class(TNonRefCountedInterfacedObject, IPageElement)
  private
    FParent: Pointer;  // Weak reference to avoid circular refs
    FNextElement: IPageElement;
    FPreviousElement: Pointer;  // Weak reference
    FNextSibling: IPageElement;
    FPreviousSibling: Pointer;  // Weak reference
  protected
    // IPageElement implementation
    function GetParent: ITag;
    function GetNextElement: IPageElement;
    function GetPreviousElement: IPageElement;
    function GetNextSibling: IPageElement;
    function GetPreviousSibling: IPageElement;
    function GetName: string; virtual;
    
    procedure SetParent(const Value: ITag);
    procedure SetNextElement(const Value: IPageElement);
    procedure SetPreviousElement(const Value: IPageElement);
    procedure SetNextSibling(const Value: IPageElement);
    procedure SetPreviousSibling(const Value: IPageElement);
    
    function GetLastDescendant(AcceptSelf: Boolean = True): IPageElement; virtual;
  public
    constructor Create;
    destructor Destroy; override;
    
    /// <summary>
    /// Set up initial relations between elements
    /// </summary>
    procedure Setup(const AParent: ITag; const APreviousElement: IPageElement); virtual;
    
    /// <summary>
    /// Remove this element from the tree
    /// </summary>
    function Extract: IPageElement; virtual;
    
    /// <summary>
    /// Replace this element with another
    /// </summary>
    function ReplaceWith(const NewElement: IPageElement): IPageElement;
    
    /// <summary>
    /// Insert an element before this one
    /// </summary>
    procedure InsertBefore(const Predecessor: IPageElement);
    
    /// <summary>
    /// Insert an element after this one
    /// </summary>
    procedure InsertAfter(const Successor: IPageElement);
    
    /// <summary>
    /// Decode element to string representation
    /// </summary>
    function Decode(PrettyPrint: Boolean = False; 
      Formatter: TFormatterType = ftMinimal): string; virtual; abstract;
    
    // Navigation - find next/previous elements
    function FindNext(const AName: string = ''): IPageElement;
    function FindAllNext(const AName: string = ''; ALimit: Integer = 0): TList<IPageElement>;
    function FindPrevious(const AName: string = ''): IPageElement;
    function FindAllPrevious(const AName: string = ''; ALimit: Integer = 0): TList<IPageElement>;
    function FindParentTag(const AName: string = ''): ITag;
    function FindParentTags(const AName: string = ''; ALimit: Integer = 0): TList<ITag>;
    
    // Properties
    property Parent: ITag read GetParent write SetParent;
    property NextElement: IPageElement read GetNextElement write SetNextElement;
    property PreviousElement: IPageElement read GetPreviousElement write SetPreviousElement;
    property NextSibling: IPageElement read GetNextSibling write SetNextSibling;
    property PreviousSibling: IPageElement read GetPreviousSibling write SetPreviousSibling;
    property Name: string read GetName;
  end;

  /// <summary>
  /// Text content within the document
  /// </summary>
  TNavigableString = class(TPageElement, INavigableString)
  private
    FValue: string;
  protected
    function GetValue: string;
    procedure SetValue(const AValue: string);
    function GetName: string; override;
  public
    constructor Create(const AValue: string);
    
    /// <summary>
    /// Format string for output
    /// </summary>
    function OutputReady(Formatter: TFormatterType = ftMinimal): string; virtual;
    
    function Decode(PrettyPrint: Boolean = False; 
      Formatter: TFormatterType = ftMinimal): string; override;
    
    property Value: string read GetValue write SetValue;
  end;

  /// <summary>
  /// Preformatted string that bypasses formatting rules
  /// </summary>
  TPreformattedString = class(TNavigableString)
  protected
    FPrefix: string;
    FSuffix: string;
  public
    function OutputReady(Formatter: TFormatterType = ftMinimal): string; override;
  end;

  /// <summary>
  /// CDATA section: <![CDATA[...]]>
  /// </summary>
  TCData = class(TPreformattedString)
  public
    constructor Create(const AValue: string);
  end;

  /// <summary>
  /// HTML/XML comment: <!-- ... -->
  /// </summary>
  TComment = class(TPreformattedString)
  public
    constructor Create(const AValue: string);
  end;

  /// <summary>
  /// Processing instruction: <?...?>
  /// </summary>
  TProcessingInstruction = class(TPreformattedString)
  public
    constructor Create(const AValue: string);
  end;

  /// <summary>
  /// Declaration: <!...!>
  /// </summary>
  TDeclaration = class(TPreformattedString)
  public
    constructor Create(const AValue: string);
  end;

  /// <summary>
  /// DOCTYPE declaration
  /// </summary>
  TDoctype = class(TPreformattedString)
  public
    constructor Create(const AValue: string);
    class function ForNameAndIds(const AName, APubId, ASystemId: string): TDoctype;
  end;

  /// <summary>
  /// HTML/XML tag element
  /// </summary>
  TTag = class(TPageElement, ITag)
  protected
    FTagName: string;
    FNamespace: string;
    FPrefix: string;
    FAttrs: TDictionary<string, string>;
    FContents: TList<IPageElement>;
    FHidden: Boolean;
    FCanBeEmptyElement: Boolean;
    FIsXML: Boolean;
  protected
    // ITag implementation
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
    function GetName: string; override;
    
    procedure SetTagName(const Value: string);
    procedure SetNamespace(const Value: string);
    procedure SetPrefix(const Value: string);
    procedure SetHidden(const Value: Boolean);
    procedure SetCanBeEmptyElement(const Value: Boolean);
    
    function GetLastDescendant(AcceptSelf: Boolean = True): IPageElement; override;
    function ShouldPrettyPrint(IndentLevel: Integer): Boolean;
  public
    constructor Create(const AName: string; AAttrs: TDictionary<string, string> = nil;
      AIsXML: Boolean = False);
    destructor Destroy; override;
    
    // Search methods - by name
    function Find(const AName: string; const AAttrs: array of const): ITag; overload;
    function Find(const AName: string = ''): ITag; overload;
    function FindAll(const AName: string; const AAttrs: array of const; 
      ALimit: Integer = 0): TList<ITag>; overload;
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
    
    // Get all descendants
    function GetDescendants: TList<IPageElement>;
    function GetDescendantTags: TList<ITag>;
    
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
    
    // Text extraction
    function GetTextContent(const Separator: string = ''; Strip: Boolean = False): string;
    function GetStrings(Strip: Boolean = False): TList<string>;
    
    // Output
    function Decode(PrettyPrint: Boolean = False; 
      Formatter: TFormatterType = ftMinimal): string; override;
    function DecodeWithIndent(IndentLevel: Integer; 
      Formatter: TFormatterType = ftMinimal): string;
    function Prettify(Formatter: TFormatterType = ftMinimal): string;
    function DecodeContents(IndentLevel: Integer = -1; 
      Formatter: TFormatterType = ftMinimal): string;
    
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
    property IsXML: Boolean read FIsXML write FIsXML;
  end;

implementation

uses
  System.StrUtils;

// Forward declaration of helper procedure
procedure FindAllMatchingSelector(ParentTag: TTag; const TagName, ClassName, IdName: string;
  Results: TList<ITag>); forward;

// Helper procedure for CSS selector matching
procedure FindAllMatchingSelector(ParentTag: TTag; const TagName, ClassName, IdName: string;
  Results: TList<ITag>);
var
  Descendants: TList<ITag>;
  Tag: ITag;
  ClassAttr: string;
  ClassMatch, IdMatch, NameMatch: Boolean;
begin
  Descendants := ParentTag.GetDescendantTags;
  try
    for Tag in Descendants do
    begin
      // Check tag name
      if TagName <> '' then
        NameMatch := SameText(Tag.TagName, TagName)
      else
        NameMatch := True;
        
      // Check class
      if ClassName <> '' then
      begin
        ClassAttr := Tag.GetAttr('class', '');
        ClassMatch := Pos(ClassName, ClassAttr) > 0;
      end
      else
        ClassMatch := True;
        
      // Check id
      if IdName <> '' then
        IdMatch := SameText(Tag.GetAttr('id', ''), IdName)
      else
        IdMatch := True;
        
      if NameMatch and ClassMatch and IdMatch then
        Results.Add(Tag);
    end;
  finally
    Descendants.Free;
  end;
end;

{ TPageElement }


constructor TPageElement.Create;
begin
  inherited Create;
  FParent := nil;
  FNextElement := nil;
  FPreviousElement := nil;
  FNextSibling := nil;
  FPreviousSibling := nil;
end;

destructor TPageElement.Destroy;
begin
  // Clear references
  FNextElement := nil;
  FNextSibling := nil;
  inherited;
end;

function TPageElement.GetParent: ITag;
begin
  if FParent <> nil then
    Result := ITag(FParent)
  else
    Result := nil;
end;

function TPageElement.GetNextElement: IPageElement;
begin
  Result := FNextElement;
end;

function TPageElement.GetPreviousElement: IPageElement;
begin
  if FPreviousElement <> nil then
    Result := IPageElement(FPreviousElement)
  else
    Result := nil;
end;

function TPageElement.GetNextSibling: IPageElement;
begin
  Result := FNextSibling;
end;

function TPageElement.GetPreviousSibling: IPageElement;
begin
  if FPreviousSibling <> nil then
    Result := IPageElement(FPreviousSibling)
  else
    Result := nil;
end;

function TPageElement.GetName: string;
begin
  Result := '';
end;

procedure TPageElement.SetParent(const Value: ITag);
begin
  if Value <> nil then
    FParent := Pointer(Value)
  else
    FParent := nil;
end;

procedure TPageElement.SetNextElement(const Value: IPageElement);
begin
  FNextElement := Value;
end;

procedure TPageElement.SetPreviousElement(const Value: IPageElement);
begin
  if Value <> nil then
    FPreviousElement := Pointer(Value)
  else
    FPreviousElement := nil;
end;

procedure TPageElement.SetNextSibling(const Value: IPageElement);
begin
  FNextSibling := Value;
end;

procedure TPageElement.SetPreviousSibling(const Value: IPageElement);
begin
  if Value <> nil then
    FPreviousSibling := Pointer(Value)
  else
    FPreviousSibling := nil;
end;

procedure TPageElement.Setup(const AParent: ITag; const APreviousElement: IPageElement);
begin
  SetParent(AParent);
  SetPreviousElement(APreviousElement);
  
  if APreviousElement <> nil then
    APreviousElement.NextElement := Self;
    
  FNextElement := nil;
  FNextSibling := nil;
  SetPreviousSibling(nil);
  
  if (AParent <> nil) and (AParent.Contents.Count > 0) then
  begin
    SetPreviousSibling(AParent.Contents[AParent.Contents.Count - 1]);
    if PreviousSibling <> nil then
      PreviousSibling.NextSibling := Self;
  end;
end;

function TPageElement.GetLastDescendant(AcceptSelf: Boolean): IPageElement;
begin
  Result := Self;
end;

function TPageElement.Extract: IPageElement;
var
  LastChild, NextElem: IPageElement;
  ParentTag: ITag;
  Idx: Integer;
begin
  ParentTag := GetParent;
  if ParentTag <> nil then
  begin
    Idx := ParentTag.Index(Self);
    if Idx >= 0 then
      ParentTag.Contents.Delete(Idx);
  end;
  
  // Find elements that would be adjacent without this element
  LastChild := GetLastDescendant;
  NextElem := LastChild.NextElement;
  
  // Reconnect adjacent elements
  if PreviousElement <> nil then
    PreviousElement.NextElement := NextElem;
  if NextElem <> nil then
    NextElem.PreviousElement := PreviousElement;
    
  SetPreviousElement(nil);
  LastChild.NextElement := nil;
  SetParent(nil);
  
  // Handle siblings
  if PreviousSibling <> nil then
    PreviousSibling.NextSibling := NextSibling;
  if NextSibling <> nil then
    NextSibling.PreviousSibling := PreviousSibling;
    
  SetPreviousSibling(nil);
  FNextSibling := nil;
  
  Result := Self;
end;

function TPageElement.ReplaceWith(const NewElement: IPageElement): IPageElement;
var
  OldParent: ITag;
  MyIndex: Integer;
begin
  if NewElement = IPageElement(Self) then
    Exit(Self);
    
  OldParent := GetParent;
  if OldParent = nil then
    raise Exception.Create('Cannot replace element with no parent');
    
  MyIndex := OldParent.Index(Self);
  Extract;
  OldParent.Insert(MyIndex, NewElement);
  Result := Self;
end;

procedure TPageElement.InsertBefore(const Predecessor: IPageElement);
var
  ParentTag: ITag;
  Idx: Integer;
begin
  ParentTag := GetParent;
  if ParentTag = nil then
    raise Exception.Create('Element has no parent, cannot insert before');
    
  if Predecessor = IPageElement(Self) then
    raise Exception.Create('Cannot insert element before itself');
    
  Idx := ParentTag.Index(Self);
  ParentTag.Insert(Idx, Predecessor);
end;

procedure TPageElement.InsertAfter(const Successor: IPageElement);
var
  ParentTag: ITag;
  Idx: Integer;
begin
  ParentTag := GetParent;
  if ParentTag = nil then
    raise Exception.Create('Element has no parent, cannot insert after');
    
  if Successor = IPageElement(Self) then
    raise Exception.Create('Cannot insert element after itself');
    
  Idx := ParentTag.Index(Self);
  ParentTag.Insert(Idx + 1, Successor);
end;

function TPageElement.FindNext(const AName: string): IPageElement;
var
  Elem: IPageElement;
  Tag: ITag;
begin
  Result := nil;
  Elem := NextElement;
  while Elem <> nil do
  begin
    if AName = '' then
      Exit(Elem);
      
    if Supports(Elem, ITag, Tag) and SameText(Tag.TagName, AName) then
      Exit(Elem);
      
    Elem := Elem.NextElement;
  end;
end;

function TPageElement.FindAllNext(const AName: string; ALimit: Integer): TList<IPageElement>;
var
  Elem: IPageElement;
  Tag: ITag;
begin
  Result := TList<IPageElement>.Create;
  Elem := NextElement;
  while Elem <> nil do
  begin
    if AName = '' then
      Result.Add(Elem)
    else if Supports(Elem, ITag, Tag) and SameText(Tag.TagName, AName) then
      Result.Add(Elem);
      
    if (ALimit > 0) and (Result.Count >= ALimit) then
      Break;
      
    Elem := Elem.NextElement;
  end;
end;

function TPageElement.FindPrevious(const AName: string): IPageElement;
var
  Elem: IPageElement;
  Tag: ITag;
begin
  Result := nil;
  Elem := PreviousElement;
  while Elem <> nil do
  begin
    if AName = '' then
      Exit(Elem);
      
    if Supports(Elem, ITag, Tag) and SameText(Tag.TagName, AName) then
      Exit(Elem);
      
    Elem := Elem.PreviousElement;
  end;
end;

function TPageElement.FindAllPrevious(const AName: string; ALimit: Integer): TList<IPageElement>;
var
  Elem: IPageElement;
  Tag: ITag;
begin
  Result := TList<IPageElement>.Create;
  Elem := PreviousElement;
  while Elem <> nil do
  begin
    if AName = '' then
      Result.Add(Elem)
    else if Supports(Elem, ITag, Tag) and SameText(Tag.TagName, AName) then
      Result.Add(Elem);
      
    if (ALimit > 0) and (Result.Count >= ALimit) then
      Break;
      
    Elem := Elem.PreviousElement;
  end;
end;

function TPageElement.FindParentTag(const AName: string): ITag;
var
  P: ITag;
begin
  Result := nil;
  P := GetParent;
  while P <> nil do
  begin
    if (AName = '') or SameText(P.TagName, AName) then
      Exit(P);
    P := P.Parent;
  end;
end;

function TPageElement.FindParentTags(const AName: string; ALimit: Integer): TList<ITag>;
var
  P: ITag;
begin
  Result := TList<ITag>.Create;
  P := GetParent;
  while P <> nil do
  begin
    if (AName = '') or SameText(P.TagName, AName) then
      Result.Add(P);
      
    if (ALimit > 0) and (Result.Count >= ALimit) then
      Break;
      
    P := P.Parent;
  end;
end;

{ TNavigableString }

constructor TNavigableString.Create(const AValue: string);
begin
  inherited Create;
  FValue := AValue;
end;

function TNavigableString.GetValue: string;
begin
  Result := FValue;
end;

procedure TNavigableString.SetValue(const AValue: string);
begin
  FValue := AValue;
end;

function TNavigableString.GetName: string;
begin
  Result := '';  // NavigableStrings don't have a name
end;

function TNavigableString.OutputReady(Formatter: TFormatterType): string;
var
  ParentTag: ITag;
  ParentName: string;
begin
  ParentTag := GetParent;
  if ParentTag <> nil then
    ParentName := ParentTag.TagName
  else
    ParentName := '';
    
  case Formatter of
    ftNone:
      Result := FValue;
    ftMinimal:
      Result := THTMLAwareEntitySubstitution.SubstituteIfAppropriate(ParentName, FValue);
    ftHTML:
      Result := THTMLAwareEntitySubstitution.SubstituteIfAppropriate(ParentName, FValue);
  else
    Result := FValue;
  end;
end;

function TNavigableString.Decode(PrettyPrint: Boolean; Formatter: TFormatterType): string;
begin
  Result := OutputReady(Formatter);
end;

{ TPreformattedString }

function TPreformattedString.OutputReady(Formatter: TFormatterType): string;
begin
  // Call formatter for side effects, but return raw value
  TEntitySubstitution.ApplyFormatter(FValue, Formatter);
  Result := FPrefix + FValue + FSuffix;
end;

{ TCData }

constructor TCData.Create(const AValue: string);
begin
  inherited Create(AValue);
  FPrefix := '<![CDATA[';
  FSuffix := ']]>';
end;

{ TComment }

constructor TComment.Create(const AValue: string);
begin
  inherited Create(AValue);
  FPrefix := '<!--';
  FSuffix := '-->';
end;

{ TProcessingInstruction }

constructor TProcessingInstruction.Create(const AValue: string);
begin
  inherited Create(AValue);
  FPrefix := '<?';
  FSuffix := '?>';
end;

{ TDeclaration }

constructor TDeclaration.Create(const AValue: string);
begin
  inherited Create(AValue);
  FPrefix := '<!';
  FSuffix := '>';
end;

{ TDoctype }

constructor TDoctype.Create(const AValue: string);
begin
  inherited Create(AValue);
  FPrefix := '<!DOCTYPE ';
  FSuffix := '>'#10;
end;

class function TDoctype.ForNameAndIds(const AName, APubId, ASystemId: string): TDoctype;
var
  DoctypeValue: string;
begin
  DoctypeValue := AName;
  if DoctypeValue = '' then
    DoctypeValue := 'html';
    
  if APubId <> '' then
  begin
    DoctypeValue := DoctypeValue + ' PUBLIC "' + APubId + '"';
    if ASystemId <> '' then
      DoctypeValue := DoctypeValue + ' "' + ASystemId + '"';
  end
  else if ASystemId <> '' then
    DoctypeValue := DoctypeValue + ' SYSTEM "' + ASystemId + '"';
    
  Result := TDoctype.Create(DoctypeValue);
end;

{ TTag }

constructor TTag.Create(const AName: string; AAttrs: TDictionary<string, string>;
  AIsXML: Boolean);
var
  Key: string;
begin
  inherited Create;
  
  if AName = '' then
    raise EArgumentException.Create('Tag name cannot be empty');
    
  FTagName := AName;
  FNamespace := '';
  FPrefix := '';
  FHidden := False;
  FIsXML := AIsXML;
  FCanBeEmptyElement := THTMLEmptyElements.IsEmptyElement(AName);
  
  FAttrs := TDictionary<string, string>.Create;
  if AAttrs <> nil then
    for Key in AAttrs.Keys do
      FAttrs.Add(Key, AAttrs[Key]);
      
  FContents := TList<IPageElement>.Create;
end;

destructor TTag.Destroy;
var
  I: Integer;
  Child: IPageElement;
  Obj: TObject;
begin
  // Free all child elements (non-reference-counted)
  if FContents <> nil then
  begin
    for I := FContents.Count - 1 downto 0 do
    begin
      Child := FContents[I];
      FContents[I] := nil;
      // Get the underlying object and free it
      if Child <> nil then
      begin
        Obj := Child as TObject;
        Child := nil;  // Clear interface reference first
        Obj.Free;
      end;
    end;
    FContents.Free;
  end;
  FAttrs.Free;
  inherited;
end;

function TTag.GetAttrs: TDictionary<string, string>;
begin
  Result := FAttrs;
end;

function TTag.GetContents: TList<IPageElement>;
begin
  Result := FContents;
end;

function TTag.GetTagName: string;
begin
  Result := FTagName;
end;

function TTag.GetNamespace: string;
begin
  Result := FNamespace;
end;

function TTag.GetPrefix: string;
begin
  Result := FPrefix;
end;

function TTag.GetHidden: Boolean;
begin
  Result := FHidden;
end;

function TTag.GetCanBeEmptyElement: Boolean;
begin
  Result := FCanBeEmptyElement;
end;

function TTag.GetIsEmptyElement: Boolean;
begin
  Result := (FContents.Count = 0) and FCanBeEmptyElement;
end;

function TTag.GetName: string;
begin
  Result := FTagName;
end;

procedure TTag.SetTagName(const Value: string);
begin
  FTagName := Value;
end;

procedure TTag.SetNamespace(const Value: string);
begin
  FNamespace := Value;
end;

procedure TTag.SetPrefix(const Value: string);
begin
  FPrefix := Value;
end;

procedure TTag.SetHidden(const Value: Boolean);
begin
  FHidden := Value;
end;

procedure TTag.SetCanBeEmptyElement(const Value: Boolean);
begin
  FCanBeEmptyElement := Value;
end;

function TTag.GetLastDescendant(AcceptSelf: Boolean): IPageElement;
var
  LastChild: IPageElement;
  LastTag: ITag;
begin
  Result := Self;
  while (Result is TTag) and (TTag(Result).FContents.Count > 0) do
  begin
    LastChild := TTag(Result).FContents[TTag(Result).FContents.Count - 1];
    Result := LastChild;
  end;
  
  if (not AcceptSelf) and (Result = IPageElement(Self)) then
    Result := nil;
end;

function TTag.GetText: string;
begin
  Result := GetTextContent('', False);
end;

function TTag.GetString: INavigableString;
var
  Child: IPageElement;
begin
  Result := nil;
  
  if FContents.Count <> 1 then
    Exit;
    
  Child := FContents[0];
  if Supports(Child, INavigableString, Result) then
    Exit
  else if Supports(Child, ITag) then
    Result := (Child as ITag).StringValue;
end;

function TTag.GetTextContent(const Separator: string; Strip: Boolean): string;
var
  Strings: TList<string>;
  S: string;
begin
  Strings := GetStrings(Strip);
  try
    Result := '';
    for S in Strings do
    begin
      if Result <> '' then
        Result := Result + Separator;
      Result := Result + S;
    end;
  finally
    Strings.Free;
  end;
end;

function TTag.GetStrings(Strip: Boolean): TList<string>;
var
  Descendants: TList<IPageElement>;
  Elem: IPageElement;
  NavStr: INavigableString;
  S: string;
begin
  Result := TList<string>.Create;
  Descendants := GetDescendants;
  try
    for Elem in Descendants do
    begin
      if Supports(Elem, INavigableString, NavStr) and not (TObject(Elem) is TPreformattedString) then
      begin
        S := NavStr.Value;
        if Strip then
          S := Trim(S);
        if S <> '' then
          Result.Add(S);
      end;
    end;
  finally
    Descendants.Free;
  end;
end;

function TTag.GetDescendants: TList<IPageElement>;

  procedure CollectDescendants(ATag: ITag; AResult: TList<IPageElement>);
  var
    I: Integer;
    Elem: IPageElement;
    ChildTag: ITag;
  begin
    for I := 0 to ATag.Contents.Count - 1 do
    begin
      Elem := ATag.Contents[I];
      AResult.Add(Elem);
      if Supports(Elem, ITag, ChildTag) then
        CollectDescendants(ChildTag, AResult);
    end;
  end;

begin
  Result := TList<IPageElement>.Create;
  CollectDescendants(Self, Result);
end;

function TTag.GetDescendantTags: TList<ITag>;
var
  Descendants: TList<IPageElement>;
  Elem: IPageElement;
  Tag: ITag;
begin
  Result := TList<ITag>.Create;
  Descendants := GetDescendants;
  try
    for Elem in Descendants do
      if Supports(Elem, ITag, Tag) then
        Result.Add(Tag);
  finally
    Descendants.Free;
  end;
end;

function TTag.Find(const AName: string): ITag;
begin
  Result := Find(AName, []);
end;

function TTag.Find(const AName: string; const AAttrs: array of const): ITag;
var
  Results: TList<ITag>;
begin
  Results := FindAll(AName, AAttrs, 1);
  try
    if Results.Count > 0 then
      Result := Results[0]
    else
      Result := nil;
  finally
    Results.Free;
  end;
end;

function TTag.FindAll(const AName: string; ALimit: Integer): TList<ITag>;
begin
  Result := FindAll(AName, [], ALimit);
end;

function TTag.FindAll(const AName: string; const AAttrs: array of const; 
  ALimit: Integer): TList<ITag>;
var
  Descendants: TList<IPageElement>;
  Elem: IPageElement;
  Tag: ITag;
  MatchName, MatchAttrs: Boolean;
  I: Integer;
  AttrKey, AttrValue, TagAttrValue: string;
begin
  Result := TList<ITag>.Create;
  Descendants := GetDescendants;
  try
    for Elem in Descendants do
    begin
      if not Supports(Elem, ITag, Tag) then
        Continue;
        
      // Check name match
      if AName <> '' then
        MatchName := SameText(Tag.TagName, AName)
      else
        MatchName := True;
        
      if not MatchName then
        Continue;
        
      // Check attribute matches
      MatchAttrs := True;
      I := 0;
      while I < Length(AAttrs) - 1 do
      begin
        // Get key
        case AAttrs[I].VType of
          vtString: AttrKey := string(AAttrs[I].VString^);
          vtAnsiString: AttrKey := string(AnsiString(AAttrs[I].VAnsiString));
          vtUnicodeString: AttrKey := string(AAttrs[I].VUnicodeString);
        else
          AttrKey := '';
        end;
        
        // Get value
        case AAttrs[I + 1].VType of
          vtString: AttrValue := string(AAttrs[I + 1].VString^);
          vtAnsiString: AttrValue := string(AnsiString(AAttrs[I + 1].VAnsiString));
          vtUnicodeString: AttrValue := string(AAttrs[I + 1].VUnicodeString);
        else
          AttrValue := '';
        end;
        
        TagAttrValue := Tag.GetAttr(AttrKey, '');
        if not SameText(TagAttrValue, AttrValue) then
        begin
          MatchAttrs := False;
          Break;
        end;
        
        Inc(I, 2);
      end;
      
      if MatchName and MatchAttrs then
      begin
        Result.Add(Tag);
        if (ALimit > 0) and (Result.Count >= ALimit) then
          Break;
      end;
    end;
  finally
    Descendants.Free;
  end;
end;

function TTag.Select(const Selector: string): TList<ITag>;
var
  Parts: TArray<string>;
  CurrentResults, NewResults: TList<ITag>;
  Part, TagName, ClassName, IdName: string;
  Tag: ITag;
  I: Integer;
  ClassMatch, IdMatch: Boolean;
begin
  // Simple CSS selector implementation
  // Supports: tag, .class, #id, tag.class, tag#id
  Result := TList<ITag>.Create;
  
  Parts := Selector.Split([' ']);
  
  CurrentResults := TList<ITag>.Create;
  CurrentResults.Add(Self);
  
  try
    for Part in Parts do
    begin
      if Part = '' then
        Continue;
        
      NewResults := TList<ITag>.Create;
      
      // Parse selector part
      TagName := '';
      ClassName := '';
      IdName := '';
      
      I := 1;
      // Get tag name (everything before . or #)
      while (I <= Length(Part)) and (Part[I] <> '.') and (Part[I] <> '#') do
      begin
        TagName := TagName + Part[I];
        Inc(I);
      end;
      
      // Get class or id
      while I <= Length(Part) do
      begin
        if Part[I] = '.' then
        begin
          Inc(I);
          ClassName := '';
          while (I <= Length(Part)) and (Part[I] <> '.') and (Part[I] <> '#') do
          begin
            ClassName := ClassName + Part[I];
            Inc(I);
          end;
        end
        else if Part[I] = '#' then
        begin
          Inc(I);
          IdName := '';
          while (I <= Length(Part)) and (Part[I] <> '.') and (Part[I] <> '#') do
          begin
            IdName := IdName + Part[I];
            Inc(I);
          end;
        end
        else
          Inc(I);
      end;
      
      // Search in current results
      for Tag in CurrentResults do
      begin
        FindAllMatchingSelector(Tag as TTag, TagName, ClassName, IdName, NewResults);
      end;
      
      CurrentResults.Free;
      CurrentResults := NewResults;
    end;
    
    // Copy results
    for Tag in CurrentResults do
      Result.Add(Tag);
  finally
    CurrentResults.Free;
  end;
end;

function TTag.SelectOne(const Selector: string): ITag;
var
  Results: TList<ITag>;
begin
  Results := Select(Selector);
  try
    if Results.Count > 0 then
      Result := Results[0]
    else
      Result := nil;
  finally
    Results.Free;
  end;
end;

function TTag.FindNextSibling(const AName: string): ITag;
var
  Sibling: IPageElement;
begin
  Result := nil;
  Sibling := NextSibling;
  while Sibling <> nil do
  begin
    if Supports(Sibling, ITag, Result) then
    begin
      if (AName = '') or SameText(Result.TagName, AName) then
        Exit;
    end;
    Sibling := Sibling.NextSibling;
  end;
  Result := nil;
end;

function TTag.FindNextSiblings(const AName: string; ALimit: Integer): TList<ITag>;
var
  Sibling: IPageElement;
  Tag: ITag;
begin
  Result := TList<ITag>.Create;
  Sibling := NextSibling;
  while Sibling <> nil do
  begin
    if Supports(Sibling, ITag, Tag) then
    begin
      if (AName = '') or SameText(Tag.TagName, AName) then
      begin
        Result.Add(Tag);
        if (ALimit > 0) and (Result.Count >= ALimit) then
          Break;
      end;
    end;
    Sibling := Sibling.NextSibling;
  end;
end;

function TTag.FindPreviousSibling(const AName: string): ITag;
var
  Sibling: IPageElement;
begin
  Result := nil;
  Sibling := PreviousSibling;
  while Sibling <> nil do
  begin
    if Supports(Sibling, ITag, Result) then
    begin
      if (AName = '') or SameText(Result.TagName, AName) then
        Exit;
    end;
    Sibling := Sibling.PreviousSibling;
  end;
  Result := nil;
end;

function TTag.FindPreviousSiblings(const AName: string; ALimit: Integer): TList<ITag>;
var
  Sibling: IPageElement;
  Tag: ITag;
begin
  Result := TList<ITag>.Create;
  Sibling := PreviousSibling;
  while Sibling <> nil do
  begin
    if Supports(Sibling, ITag, Tag) then
    begin
      if (AName = '') or SameText(Tag.TagName, AName) then
      begin
        Result.Add(Tag);
        if (ALimit > 0) and (Result.Count >= ALimit) then
          Break;
      end;
    end;
    Sibling := Sibling.PreviousSibling;
  end;
end;

function TTag.FindParent(const AName: string): ITag;
begin
  Result := FindParentTag(AName);
end;

function TTag.FindParents(const AName: string; ALimit: Integer): TList<ITag>;
begin
  Result := FindParentTags(AName, ALimit);
end;

procedure TTag.Append(const AElement: IPageElement);
begin
  Insert(FContents.Count, AElement);
end;

procedure TTag.Insert(APosition: Integer; const AElement: IPageElement);
var
  PrevChild, NextChild: IPageElement;
  LastDescendant, NextElem: IPageElement;
  ParentSibling: IPageElement;
  P: ITag;
begin
  if AElement = IPageElement(Self) then
    raise Exception.Create('Cannot insert a tag into itself');
    
  // Clamp position
  if APosition < 0 then
    APosition := 0;
  if APosition > FContents.Count then
    APosition := FContents.Count;
    
  // Extract if already has a parent
  if AElement.Parent <> nil then
    AElement.Extract;
    
  AElement.Parent := Self;
  
  // Set up sibling and element links
  if APosition = 0 then
  begin
    AElement.PreviousSibling := nil;
    AElement.PreviousElement := Self;
  end
  else
  begin
    PrevChild := FContents[APosition - 1];
    AElement.PreviousSibling := PrevChild;
    PrevChild.NextSibling := AElement;
    
    // Get last descendant of previous child
    if Supports(PrevChild, ITag) then
      LastDescendant := (PrevChild as TTag).GetLastDescendant(True)
    else
      LastDescendant := PrevChild;
    AElement.PreviousElement := LastDescendant;
  end;
  
  if AElement.PreviousElement <> nil then
    AElement.PreviousElement.NextElement := AElement;
    
  // Last descendant of new element
  if Supports(AElement, ITag) then
    LastDescendant := (AElement as TTag).GetLastDescendant(True)
  else
    LastDescendant := AElement;
    
  if APosition >= FContents.Count then
  begin
    AElement.NextSibling := nil;
    
    // Find next element after this tag's subtree
    P := Self;
    ParentSibling := nil;
    while (ParentSibling = nil) and (P <> nil) do
    begin
      ParentSibling := P.NextSibling;
      P := P.Parent;
    end;
    
    if ParentSibling <> nil then
      LastDescendant.NextElement := ParentSibling
    else
      LastDescendant.NextElement := nil;
  end
  else
  begin
    NextChild := FContents[APosition];
    AElement.NextSibling := NextChild;
    NextChild.PreviousSibling := AElement;
    LastDescendant.NextElement := NextChild;
  end;
  
  if LastDescendant.NextElement <> nil then
    LastDescendant.NextElement.PreviousElement := LastDescendant;
    
  FContents.Insert(APosition, AElement);
end;

procedure TTag.Clear(ADecompose: Boolean);
var
  I: Integer;
  Elem: IPageElement;
  Tag: ITag;
begin
  for I := FContents.Count - 1 downto 0 do
  begin
    Elem := FContents[I];
    if ADecompose then
    begin
      if Supports(Elem, ITag, Tag) then
        Tag.Decompose
      else
        Elem.Extract;
    end
    else
      Elem.Extract;
  end;
end;

procedure TTag.Decompose;
var
  Elem: IPageElement;
  I: Integer;
begin
  Extract;
  
  // Clear all descendants
  for I := FContents.Count - 1 downto 0 do
  begin
    Elem := FContents[I];
    if Supports(Elem, ITag) then
      (Elem as ITag).Decompose;
  end;
  
  FContents.Clear;
  FAttrs.Clear;
end;

function TTag.Index(const AElement: IPageElement): Integer;
var
  I: Integer;
begin
  for I := 0 to FContents.Count - 1 do
    if FContents[I] = AElement then
      Exit(I);
  Result := -1;
end;

function TTag.GetAttr(const AKey: string; const ADefault: string): string;
begin
  if not FAttrs.TryGetValue(LowerCase(AKey), Result) then
    Result := ADefault;
end;

procedure TTag.SetAttr(const AKey, AValue: string);
begin
  FAttrs.AddOrSetValue(LowerCase(AKey), AValue);
end;

function TTag.HasAttr(const AKey: string): Boolean;
begin
  Result := FAttrs.ContainsKey(LowerCase(AKey));
end;

procedure TTag.DeleteAttr(const AKey: string);
begin
  FAttrs.Remove(LowerCase(AKey));
end;

function TTag.ShouldPrettyPrint(IndentLevel: Integer): Boolean;
begin
  Result := (IndentLevel >= 0) and 
    (not THTMLAwareEntitySubstitution.IsPreformattedTag(FTagName) or FIsXML);
end;

function TTag.Decode(PrettyPrint: Boolean; Formatter: TFormatterType): string;
begin
  if PrettyPrint then
    Result := DecodeWithIndent(0, Formatter)
  else
    Result := DecodeWithIndent(-1, Formatter);
end;

    function TTag.DecodeWithIndent(IndentLevel: Integer; Formatter: TFormatterType): string;
    var
      Builder: TStringBuilder;
      AttrKey, AttrValue, AttrStr: string;
      FullPrefix, CloseTag, IndentSpace, Space, Contents: string;
      DoPrettyPrint: Boolean;
      AttrPairs: TArray<TPair<string, string>>;
      TempPair: TPair<string, string>;
      I, J: Integer;
    begin
      if FHidden then
      begin
        Result := DecodeContents(IndentLevel, Formatter);
        Exit;
      end;
      
      Builder := TStringBuilder.Create;
      try
        // Build attribute string
        AttrStr := '';
        if FAttrs.Count > 0 then
        begin
          SetLength(AttrPairs, FAttrs.Count);
          I := 0;
          for AttrKey in FAttrs.Keys do
          begin
            AttrPairs[I].Key := AttrKey;
            AttrPairs[I].Value := FAttrs[AttrKey];
            Inc(I);
          end;
          
          // Simple bubble sort for consistent output (usually small number of attributes)
          for I := 0 to High(AttrPairs) - 1 do
            for J := I + 1 to High(AttrPairs) do
              if CompareText(AttrPairs[I].Key, AttrPairs[J].Key) > 0 then
              begin
                TempPair := AttrPairs[I];
                AttrPairs[I] := AttrPairs[J];
                AttrPairs[J] := TempPair;
              end;
          
          for I := 0 to Length(AttrPairs) - 1 do
          begin
            AttrKey := AttrPairs[I].Key;
            AttrValue := AttrPairs[I].Value;
            
            AttrValue := TEntitySubstitution.ApplyFormatter(AttrValue, Formatter);
            AttrStr := AttrStr + ' ' + AttrKey + '=' + 
              TEntitySubstitution.QuotedAttributeValue(AttrValue);
          end;
        end;
        
        // Build prefix (namespace prefix)
        if FPrefix <> '' then
          FullPrefix := FPrefix + ':'
        else
          FullPrefix := '';
          
        DoPrettyPrint := ShouldPrettyPrint(IndentLevel);
        
        if IndentLevel >= 0 then
          IndentSpace := StringOfChar(' ', IndentLevel * 2)
        else
          IndentSpace := '';
          
        if DoPrettyPrint then
          Space := IndentSpace
        else
          Space := '';
          
        // Get contents
        if IndentLevel >= 0 then
          Contents := DecodeContents(IndentLevel + 1, Formatter)
        else
          Contents := DecodeContents(-1, Formatter);
          
        // Build close tag
        if IsEmptyElement then
          CloseTag := ''
        else
          CloseTag := '</' + FullPrefix + FTagName + '>';
          
        // Build output
        if IndentLevel >= 0 then
          Builder.Append(IndentSpace);
          
        if IsEmptyElement then
        begin
          if FIsXML then
            Builder.Append('<').Append(FullPrefix).Append(FTagName).Append(AttrStr).Append('/>')
          else
            Builder.Append('<').Append(FullPrefix).Append(FTagName).Append(AttrStr).Append('>');
        end
        else
        begin
          Builder.Append('<').Append(FullPrefix).Append(FTagName).Append(AttrStr).Append('>');
          
          if DoPrettyPrint then
            Builder.AppendLine;
            
          Builder.Append(Contents);
          
          if DoPrettyPrint and (Contents <> '') and not Contents.EndsWith(#10) then
            Builder.AppendLine;
            
          if DoPrettyPrint and (CloseTag <> '') then
            Builder.Append(IndentSpace);
            
          Builder.Append(CloseTag);
        end;
        
        if (IndentLevel >= 0) and (NextSibling <> nil) then
          Builder.AppendLine;
          
        Result := Builder.ToString;
      finally
        Builder.Free;
      end;
    end;

function TTag.Prettify(Formatter: TFormatterType): string;
begin
  Result := Decode(True, Formatter);
end;

function TTag.DecodeContents(IndentLevel: Integer; Formatter: TFormatterType): string;
var
  Builder: TStringBuilder;
  Elem: IPageElement;
  ElemTag: TTag;
  NavStr: INavigableString;
  S: string;
  DoPrettyPrint: Boolean;
begin
  Builder := TStringBuilder.Create;
  try
    DoPrettyPrint := ShouldPrettyPrint(IndentLevel);
    
    for Elem in FContents do
    begin
      if Supports(Elem, ITag) then
      begin
        ElemTag := Elem as TTag;
        Builder.Append(ElemTag.DecodeWithIndent(IndentLevel, Formatter));
      end
      else if Supports(Elem, INavigableString, NavStr) and not (TObject(Elem) is TPreformattedString) then
      begin
        S := NavStr.OutputReady(Formatter);
        if DoPrettyPrint and (Trim(S) = '') then
          Continue; // Skip whitespace-only strings in pretty print
        if DoPrettyPrint and (IndentLevel >= 0) then
          Builder.Append(StringOfChar(' ', IndentLevel * 2));
        Builder.Append(S);
        if DoPrettyPrint then
          Builder.AppendLine;
      end;
    end;
    
    Result := Builder.ToString;
  finally
    Builder.Free;
  end;
end;

end.







