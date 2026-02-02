{******************************************************************************}
{                                                                              }
{                              DelphiSoup Library                              }
{                                                                              }
{                           Search Strainer Module                             }
{                                                                              }
{******************************************************************************}

unit DelphiSoup.Strainer;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.RegularExpressions,
  DelphiSoup.Types, DelphiSoup.Element;

type
  /// <summary>
  /// Encapsulates search criteria for matching markup elements
  /// </summary>
  TSoupStrainer = class
  private
    FName: TMatchValue;
    FAttrs: TDictionary<string, TMatchValue>;
    FText: TMatchValue;
    
    function MatchesTag(Tag: TTag): Boolean;
    function MatchesString(NavStr: TNavigableString): Boolean;
    function MatchesAttributes(Tag: TTag): Boolean;
  public
    constructor Create(const AName: string = ''; const AText: string = ''); overload;
    constructor Create(const AName: string; AAttrs: TDictionary<string, string>; 
      const AText: string = ''); overload;
    constructor CreateWithRegex(const ANamePattern: string); overload;
    destructor Destroy; override;
    
    /// <summary>
    /// Add an attribute match condition
    /// </summary>
    procedure AddAttrMatch(const AKey, AValue: string);
    procedure AddAttrMatchRegex(const AKey, APattern: string);
    
    /// <summary>
    /// Search for a tag that matches the criteria
    /// </summary>
    function SearchTag(Tag: TTag): Boolean;
    
    /// <summary>
    /// Search for an element that matches the criteria
    /// </summary>
    function Search(Element: IPageElement): IPageElement;
    
    property NameMatch: TMatchValue read FName;
    property TextMatch: TMatchValue read FText;
  end;

  /// <summary>
  /// A list that keeps track of the strainer that created it
  /// </summary>
  TResultSet = class(TList<IPageElement>)
  private
    FSource: TSoupStrainer;
  public
    constructor Create(ASource: TSoupStrainer); overload;
    destructor Destroy; override;
    
    property Source: TSoupStrainer read FSource;
  end;
  
  /// <summary>
  /// Result set specifically for tags
  /// </summary>
  TTagResultSet = class(TList<ITag>)
  private
    FSource: TSoupStrainer;
  public
    constructor Create(ASource: TSoupStrainer); overload;
    destructor Destroy; override;
    
    property Source: TSoupStrainer read FSource;
  end;

implementation

uses
  System.StrUtils;

{ TSoupStrainer }

constructor TSoupStrainer.Create(const AName: string; const AText: string);
begin
  inherited Create;
  FAttrs := TDictionary<string, TMatchValue>.Create;
  
  if AName <> '' then
    FName := TMatchValue.FromString(AName)
  else
    FName := TMatchValue.Empty;
    
  if AText <> '' then
    FText := TMatchValue.FromString(AText)
  else
    FText := TMatchValue.Empty;
end;

constructor TSoupStrainer.Create(const AName: string; 
  AAttrs: TDictionary<string, string>; const AText: string);
var
  Key: string;
begin
  inherited Create;
  FAttrs := TDictionary<string, TMatchValue>.Create;
  
  if AName <> '' then
    FName := TMatchValue.FromString(AName)
  else
    FName := TMatchValue.Empty;
    
  if AAttrs <> nil then
  begin
    for Key in AAttrs.Keys do
      FAttrs.Add(LowerCase(Key), TMatchValue.FromString(AAttrs[Key]));
  end;
  
  if AText <> '' then
    FText := TMatchValue.FromString(AText)
  else
    FText := TMatchValue.Empty;
end;

constructor TSoupStrainer.CreateWithRegex(const ANamePattern: string);
begin
  inherited Create;
  FAttrs := TDictionary<string, TMatchValue>.Create;
  FName := TMatchValue.FromRegex(ANamePattern);
  FText := TMatchValue.Empty;
end;

destructor TSoupStrainer.Destroy;
begin
  FAttrs.Free;
  inherited;
end;

procedure TSoupStrainer.AddAttrMatch(const AKey, AValue: string);
begin
  FAttrs.AddOrSetValue(LowerCase(AKey), TMatchValue.FromString(AValue));
end;

procedure TSoupStrainer.AddAttrMatchRegex(const AKey, APattern: string);
begin
  FAttrs.AddOrSetValue(LowerCase(AKey), TMatchValue.FromRegex(APattern));
end;

function TSoupStrainer.MatchesAttributes(Tag: TTag): Boolean;
var
  AttrKey: string;
  AttrMatch: TMatchValue;
  AttrValue: string;
begin
  Result := True;
  
  for AttrKey in FAttrs.Keys do
  begin
    AttrMatch := FAttrs[AttrKey];
    
    // Get the attribute value from the tag
    AttrValue := Tag.GetAttr(AttrKey, '');
    
    // Special handling for 'class' attribute - check if class is in the list
    if (AttrKey = 'class') and (Pos(' ', AttrValue) > 0) then
    begin
      // Multi-valued class attribute
      if AttrMatch.IsString then
      begin
        // Check if the search value is one of the classes
        if Pos(AttrMatch.StringValue, AttrValue) = 0 then
          Exit(False);
      end
      else if not AttrMatch.Matches(AttrValue) then
        Exit(False);
    end
    else
    begin
      if not AttrMatch.Matches(AttrValue) then
        Exit(False);
    end;
  end;
end;

function TSoupStrainer.MatchesTag(Tag: TTag): Boolean;
begin
  Result := False;
  
  // Check name match
  if FName.IsSet then
  begin
    if not FName.Matches(Tag.TagName) then
      Exit;
  end;
  
  // Check attribute matches
  if FAttrs.Count > 0 then
  begin
    if not MatchesAttributes(Tag) then
      Exit;
  end;
  
  // Check text match
  if FText.IsSet then
  begin
    if not FText.Matches(Tag.Text) then
      Exit;
  end;
  
  Result := True;
end;

function TSoupStrainer.MatchesString(NavStr: TNavigableString): Boolean;
begin
  Result := False;
  
  // Only match if we're looking for text and not a specific tag name
  if FName.IsSet then
    Exit;
    
  if FAttrs.Count > 0 then
    Exit;
    
  if FText.IsSet then
    Result := FText.Matches(NavStr.Value)
  else
    Result := True;
end;

function TSoupStrainer.SearchTag(Tag: TTag): Boolean;
begin
  Result := MatchesTag(Tag);
end;

function TSoupStrainer.Search(Element: IPageElement): IPageElement;
var
  Tag: ITag;
  NavStr: INavigableString;
begin
  Result := nil;
  
  if Supports(Element, ITag, Tag) then
  begin
    if MatchesTag(Tag as TTag) then
      Result := Element;
  end
  else if Supports(Element, INavigableString, NavStr) then
  begin
    if MatchesString(NavStr as TNavigableString) then
      Result := Element;
  end;
end;

{ TResultSet }

constructor TResultSet.Create(ASource: TSoupStrainer);
begin
  inherited Create;
  FSource := ASource;
end;

destructor TResultSet.Destroy;
begin
  // Note: We don't own the source strainer
  inherited;
end;

{ TTagResultSet }

constructor TTagResultSet.Create(ASource: TSoupStrainer);
begin
  inherited Create;
  FSource := ASource;
end;

destructor TTagResultSet.Destroy;
begin
  inherited;
end;

end.
