{******************************************************************************}
{                                                                              }
{                              DelphiSoup Library                              }
{                                                                              }
{                          HTML/XML Tokenizer Module                           }
{                                                                              }
{******************************************************************************}

unit DelphiSoup.Parser;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.Character,
  DelphiSoup.Types;

type
  // Event types for parser callbacks
  TStartTagEvent = procedure(const AName: string; 
    Attrs: TDictionary<string, string>; SelfClosing: Boolean) of object;
  TStringEvent = procedure(const Data: string) of object;

  /// <summary>
  /// HTML/XML tokenizer that converts markup into tokens
  /// </summary>
  THTMLTokenizer = class
  private
    FMarkup: string;
    FPosition: Integer;
    FLength: Integer;
    FIsXML: Boolean;
    
    function Peek(Offset: Integer = 0): Char;
    function Read: Char;
    procedure Skip(Count: Integer = 1);
    function IsEOF: Boolean;
    function MatchString(const S: string; CaseSensitive: Boolean = False): Boolean;
    procedure SkipWhitespace;
    
    function ReadUntil(const Terminators: array of string): string;
    function ReadWhile(const Chars: TSysCharSet): string;
    function ReadAttributeName: string;
    function ReadAttributeValue: string;
    function ParseAttributes: TDictionary<string, string>;
    function ParseStartTag: TToken;
    function ParseEndTag: TToken;
    function ParseComment: TToken;
    function ParseDoctype: TToken;
    function ParseCData: TToken;
    function ParseProcessingInstruction: TToken;
    function ParseText: TToken;
  public
    constructor Create(const AMarkup: string; AIsXML: Boolean = False);
    
    /// <summary>
    /// Get the next token from the markup
    /// </summary>
    function GetNextToken: TToken;
    
    /// <summary>
    /// Check if there are more tokens to read
    /// </summary>
    function HasMoreTokens: Boolean;
    
    /// <summary>
    /// Current position in the markup
    /// </summary>
    property Position: Integer read FPosition;
    property IsXML: Boolean read FIsXML write FIsXML;
  end;

  /// <summary>
  /// Simple HTML parser that uses the tokenizer
  /// </summary>
  THTMLParser = class
  private
    FTokenizer: THTMLTokenizer;
    FOnStartTag: TStartTagEvent;
    FOnEndTag: TStringEvent;
    FOnText: TStringEvent;
    FOnComment: TStringEvent;
    FOnDoctype: TStringEvent;
    FOnCData: TStringEvent;
  public
    constructor Create(const AMarkup: string; AIsXML: Boolean = False);
    destructor Destroy; override;
    
    /// <summary>
    /// Parse the markup and fire events
    /// </summary>
    procedure Parse;
    
    // Events
    property OnStartTag: TStartTagEvent read FOnStartTag write FOnStartTag;
    property OnEndTag: TStringEvent read FOnEndTag write FOnEndTag;
    property OnText: TStringEvent read FOnText write FOnText;
    property OnComment: TStringEvent read FOnComment write FOnComment;
    property OnDoctype: TStringEvent read FOnDoctype write FOnDoctype;
    property OnCData: TStringEvent read FOnCData write FOnCData;
  end;

implementation

{ THTMLTokenizer }

constructor THTMLTokenizer.Create(const AMarkup: string; AIsXML: Boolean);
begin
  inherited Create;
  FMarkup := AMarkup;
  FPosition := 1;  // Delphi strings are 1-indexed
  FLength := Length(FMarkup);
  FIsXML := AIsXML;
end;

function THTMLTokenizer.Peek(Offset: Integer): Char;
var
  Idx: Integer;
begin
  Idx := FPosition + Offset;
  if (Idx >= 1) and (Idx <= FLength) then
    Result := FMarkup[Idx]
  else
    Result := #0;
end;

function THTMLTokenizer.Read: Char;
begin
  if FPosition <= FLength then
  begin
    Result := FMarkup[FPosition];
    Inc(FPosition);
  end
  else
    Result := #0;
end;

procedure THTMLTokenizer.Skip(Count: Integer);
begin
  Inc(FPosition, Count);
  if FPosition > FLength + 1 then
    FPosition := FLength + 1;
end;

function THTMLTokenizer.IsEOF: Boolean;
begin
  Result := FPosition > FLength;
end;

function THTMLTokenizer.MatchString(const S: string; CaseSensitive: Boolean): Boolean;
var
  I: Integer;
  C1, C2: Char;
begin
  if FPosition + Length(S) - 1 > FLength then
    Exit(False);
    
  for I := 1 to Length(S) do
  begin
    C1 := FMarkup[FPosition + I - 1];
    C2 := S[I];
    
    if not CaseSensitive then
    begin
      C1 := UpCase(C1);
      C2 := UpCase(C2);
    end;
    
    if C1 <> C2 then
      Exit(False);
  end;
  
  Result := True;
end;

procedure THTMLTokenizer.SkipWhitespace;
begin
  while (FPosition <= FLength) and FMarkup[FPosition].IsWhiteSpace do
    Inc(FPosition);
end;

function THTMLTokenizer.ReadUntil(const Terminators: array of string): string;
var
  StartPos: Integer;
  Found: Boolean;
  T: string;
begin
  StartPos := FPosition;
  
  while FPosition <= FLength do
  begin
    Found := False;
    for T in Terminators do
    begin
      if MatchString(T) then
      begin
        Found := True;
        Break;
      end;
    end;
    
    if Found then
      Break;
      
    Inc(FPosition);
  end;
  
  Result := Copy(FMarkup, StartPos, FPosition - StartPos);
end;

function THTMLTokenizer.ReadWhile(const Chars: TSysCharSet): string;
var
  StartPos: Integer;
begin
  StartPos := FPosition;
  
  while (FPosition <= FLength) and CharInSet(FMarkup[FPosition], Chars) do
    Inc(FPosition);
    
  Result := Copy(FMarkup, StartPos, FPosition - StartPos);
end;

function THTMLTokenizer.ReadAttributeName: string;
const
  NameChars = ['a'..'z', 'A'..'Z', '0'..'9', '-', '_', ':', '.'];
begin
  Result := ReadWhile(NameChars);
end;

function THTMLTokenizer.ReadAttributeValue: string;
var
  Quote: Char;
  StartPos: Integer;
begin
  SkipWhitespace;
  
  if Peek = '=' then
  begin
    Skip; // Skip '='
    SkipWhitespace;
    
    if (Peek = '"') or (Peek = '''') then
    begin
      Quote := Read;
      StartPos := FPosition;
      
      while (FPosition <= FLength) and (FMarkup[FPosition] <> Quote) do
        Inc(FPosition);
        
      Result := Copy(FMarkup, StartPos, FPosition - StartPos);
      Skip; // Skip closing quote
    end
    else
    begin
      // Unquoted attribute value
      Result := ReadWhile(['a'..'z', 'A'..'Z', '0'..'9', '-', '_', '.', '/', ':', '#']);
    end;
  end
  else
    Result := ''; // Attribute without value (e.g., "disabled")
end;

function THTMLTokenizer.ParseAttributes: TDictionary<string, string>;
var
  AttrName, AttrValue: string;
begin
  Result := TDictionary<string, string>.Create;
  
  try
    while True do
    begin
      SkipWhitespace;
      
      // Check for end of tag
      if (Peek = '>') or (Peek = '/') or IsEOF then
        Break;
        
      AttrName := ReadAttributeName;
      if AttrName = '' then
        Break;
        
      AttrValue := ReadAttributeValue;
      
      // Store with lowercase key for case-insensitive lookup
      Result.AddOrSetValue(LowerCase(AttrName), AttrValue);
    end;
  except
    Result.Free;
    raise;
  end;
end;

function THTMLTokenizer.ParseStartTag: TToken;
var
  TagName: string;
  Attrs: TDictionary<string, string>;
  SelfClosing: Boolean;
begin
  // Skip '<'
  Skip;
  
  // Read tag name
  TagName := ReadWhile(['a'..'z', 'A'..'Z', '0'..'9', ':', '-']);
  
  // Read attributes
  Attrs := ParseAttributes;
  
  // Check for self-closing
  SkipWhitespace;
  SelfClosing := (Peek = '/');
  if SelfClosing then
    Skip;
    
  // Skip '>'
  if Peek = '>' then
    Skip;
    
  // Check if this is an HTML empty element
  if not SelfClosing and not FIsXML then
    SelfClosing := THTMLEmptyElements.IsEmptyElement(TagName);
    
  Result := TToken.CreateStartTag(LowerCase(TagName), Attrs, SelfClosing);
end;

function THTMLTokenizer.ParseEndTag: TToken;
var
  TagName: string;
begin
  // Skip '</'
  Skip(2);
  
  // Read tag name
  TagName := ReadWhile(['a'..'z', 'A'..'Z', '0'..'9', ':', '-']);
  
  // Skip whitespace and '>'
  SkipWhitespace;
  if Peek = '>' then
    Skip;
    
  Result := TToken.CreateEndTag(LowerCase(TagName));
end;

function THTMLTokenizer.ParseComment: TToken;
var
  Content: string;
begin
  // Skip '<!--'
  Skip(4);
  
  Content := ReadUntil(['-->']);
  
  // Skip '-->'
  if MatchString('-->') then
    Skip(3);
    
  Result := TToken.CreateComment(Content);
end;

function THTMLTokenizer.ParseDoctype: TToken;
var
  Content: string;
begin
  // Skip '<!DOCTYPE' or '<!doctype'
  Skip(9);
  
  SkipWhitespace;
  
  Content := ReadUntil(['>']);
  
  // Skip '>'
  if Peek = '>' then
    Skip;
    
  Result := TToken.CreateDoctype(Trim(Content));
end;

function THTMLTokenizer.ParseCData: TToken;
var
  Content: string;
begin
  // Skip '<![CDATA['
  Skip(9);
  
  Content := ReadUntil([']]>']);
  
  // Skip ']]>'
  if MatchString(']]>') then
    Skip(3);
    
  Result := TToken.CreateCData(Content);
end;

function THTMLTokenizer.ParseProcessingInstruction: TToken;
var
  Content: string;
begin
  // Skip '<?'
  Skip(2);
  
  Content := ReadUntil(['?>']);
  
  // Skip '?>'
  if MatchString('?>') then
    Skip(2);
    
  Result.TokenType := ttProcessingInstruction;
  Result.Name := '';
  Result.Attrs := nil;
  Result.Data := Content;
  Result.SelfClosing := False;
end;

function THTMLTokenizer.ParseText: TToken;
var
  Content: string;
begin
  Content := ReadUntil(['<']);
  Result := TToken.CreateText(Content);
end;

function THTMLTokenizer.GetNextToken: TToken;
begin
  if IsEOF then
  begin
    Result := TToken.CreateEOF;
    Exit;
  end;
  
  if Peek = '<' then
  begin
    // Check for comment
    if MatchString('<!--') then
      Result := ParseComment
    // Check for DOCTYPE
    else if MatchString('<!DOCTYPE', False) then
      Result := ParseDoctype
    // Check for CDATA
    else if MatchString('<![CDATA[', True) then
      Result := ParseCData
    // Check for processing instruction
    else if MatchString('<?') then
      Result := ParseProcessingInstruction
    // Check for end tag
    else if Peek(1) = '/' then
      Result := ParseEndTag
    // Check for start tag (must start with letter)
    else if Peek(1).IsLetter then
      Result := ParseStartTag
    else
    begin
      // Not a valid tag, treat '<' as text
      Skip;
      Result := TToken.CreateText('<');
    end;
  end
  else
    Result := ParseText;
end;

function THTMLTokenizer.HasMoreTokens: Boolean;
begin
  Result := not IsEOF;
end;

{ THTMLParser }

constructor THTMLParser.Create(const AMarkup: string; AIsXML: Boolean);
begin
  inherited Create;
  FTokenizer := THTMLTokenizer.Create(AMarkup, AIsXML);
end;

destructor THTMLParser.Destroy;
begin
  FTokenizer.Free;
  inherited;
end;

procedure THTMLParser.Parse;
var
  Token: TToken;
begin
  while FTokenizer.HasMoreTokens do
  begin
    Token := FTokenizer.GetNextToken;
    
    case Token.TokenType of
      ttStartTag:
        if Assigned(FOnStartTag) then
          FOnStartTag(Token.Name, Token.Attrs, Token.SelfClosing);
          
      ttEndTag:
        if Assigned(FOnEndTag) then
          FOnEndTag(Token.Name);
          
      ttText:
        if Assigned(FOnText) then
          FOnText(Token.Data);
          
      ttComment:
        if Assigned(FOnComment) then
          FOnComment(Token.Data);
          
      ttDoctype:
        if Assigned(FOnDoctype) then
          FOnDoctype(Token.Data);
          
      ttCData:
        if Assigned(FOnCData) then
          FOnCData(Token.Data);
          
      ttEOF:
        Break;
    end;
    
    // Free attribute dictionary if created
    if Token.Attrs <> nil then
      Token.Attrs.Free;
  end;
end;

end.
