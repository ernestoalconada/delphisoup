{******************************************************************************}
{                                                                              }
{                              DelphiSoup Library                              }
{                                                                              }
{                       HTML Entity Substitution Module                        }
{                                                                              }
{******************************************************************************}

unit DelphiSoup.Entities;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  DelphiSoup.Types;

type
  /// <summary>
  /// Handles HTML/XML entity substitution
  /// </summary>
  TEntitySubstitution = class
  private
    class var FHTMLEntities: TDictionary<Char, string>;
    class var FXMLEntities: TDictionary<Char, string>;
    class constructor Create;
    class destructor Destroy;
  public
    /// <summary>
    /// Substitute special characters with HTML entities
    /// </summary>
    class function SubstituteHTML(const S: string): string;
    
    /// <summary>
    /// Substitute special characters with XML entities (minimal)
    /// </summary>
    class function SubstituteXML(const S: string): string;
    
    /// <summary>
    /// Quote an attribute value, choosing appropriate quote style
    /// </summary>
    class function QuotedAttributeValue(const Value: string): string;
    
    /// <summary>
    /// Apply formatting based on formatter type
    /// </summary>
    class function ApplyFormatter(const S: string; Formatter: TFormatterType): string;
  end;

  /// <summary>
  /// HTML-aware entity substitution that respects script/style tags
  /// </summary>
  THTMLAwareEntitySubstitution = class(TEntitySubstitution)
  private
    class var FCDataContainingTags: TArray<string>;
    class var FPreformattedTags: TArray<string>;
    class constructor Create;
  public
    class property CDataContainingTags: TArray<string> read FCDataContainingTags;
    class property PreformattedTags: TArray<string> read FPreformattedTags;
    
    /// <summary>
    /// Check if a tag contains CDATA (script, style)
    /// </summary>
    class function IsCDataContainingTag(const TagName: string): Boolean;
    
    /// <summary>
    /// Check if a tag is preformatted (pre)
    /// </summary>
    class function IsPreformattedTag(const TagName: string): Boolean;
    
    /// <summary>
    /// Substitute HTML entities, but skip content of script/style tags
    /// </summary>
    class function SubstituteIfAppropriate(const ParentTagName, S: string): string;
  end;

implementation

{ TEntitySubstitution }

class constructor TEntitySubstitution.Create;
begin
  FHTMLEntities := TDictionary<Char, string>.Create;
  FXMLEntities := TDictionary<Char, string>.Create;
  
  // XML entities (minimal set)
  FXMLEntities.Add('&', '&amp;');
  FXMLEntities.Add('<', '&lt;');
  FXMLEntities.Add('>', '&gt;');
  
  // HTML entities (extended set)
  FHTMLEntities.Add('&', '&amp;');
  FHTMLEntities.Add('<', '&lt;');
  FHTMLEntities.Add('>', '&gt;');
  FHTMLEntities.Add('"', '&quot;');
  FHTMLEntities.Add('''', '&#x27;');
  FHTMLEntities.Add(#160, '&nbsp;');
  FHTMLEntities.Add(#169, '&copy;');
  FHTMLEntities.Add(#174, '&reg;');
  FHTMLEntities.Add(#8212, '&mdash;');
  FHTMLEntities.Add(#8211, '&ndash;');
  FHTMLEntities.Add(#8220, '&ldquo;');
  FHTMLEntities.Add(#8221, '&rdquo;');
  FHTMLEntities.Add(#8216, '&lsquo;');
  FHTMLEntities.Add(#8217, '&rsquo;');
  FHTMLEntities.Add(#8230, '&hellip;');
  FHTMLEntities.Add(#8364, '&euro;');
  FHTMLEntities.Add(#163, '&pound;');
  FHTMLEntities.Add(#165, '&yen;');
  FHTMLEntities.Add(#162, '&cent;');
end;

class destructor TEntitySubstitution.Destroy;
begin
  FHTMLEntities.Free;
  FXMLEntities.Free;
end;

class function TEntitySubstitution.SubstituteHTML(const S: string): string;
var
  Builder: TStringBuilder;
  C: Char;
  Entity: string;
begin
  Builder := TStringBuilder.Create(Length(S));
  try
    for C in S do
    begin
      if FHTMLEntities.TryGetValue(C, Entity) then
        Builder.Append(Entity)
      else if Ord(C) > 127 then
        // High Unicode characters as numeric entity
        Builder.Append('&#').Append(Ord(C)).Append(';')
      else
        Builder.Append(C);
    end;
    Result := Builder.ToString;
  finally
    Builder.Free;
  end;
end;

class function TEntitySubstitution.SubstituteXML(const S: string): string;
var
  Builder: TStringBuilder;
  C: Char;
  Entity: string;
begin
  Builder := TStringBuilder.Create(Length(S));
  try
    for C in S do
    begin
      if FXMLEntities.TryGetValue(C, Entity) then
        Builder.Append(Entity)
      else
        Builder.Append(C);
    end;
    Result := Builder.ToString;
  finally
    Builder.Free;
  end;
end;

class function TEntitySubstitution.QuotedAttributeValue(const Value: string): string;
begin
  // Choose quote style based on content
  if Pos('"', Value) = 0 then
    Result := '"' + Value + '"'
  else if Pos('''', Value) = 0 then
    Result := '''' + Value + ''''
  else
    // Has both types of quotes, escape double quotes
    Result := '"' + StringReplace(Value, '"', '&quot;', [rfReplaceAll]) + '"';
end;

class function TEntitySubstitution.ApplyFormatter(const S: string; 
  Formatter: TFormatterType): string;
begin
  case Formatter of
    ftNone:
      Result := S;
    ftMinimal:
      Result := SubstituteXML(S);
    ftHTML:
      Result := SubstituteHTML(S);
  else
    Result := S;
  end;
end;

{ THTMLAwareEntitySubstitution }

class constructor THTMLAwareEntitySubstitution.Create;
begin
  FCDataContainingTags := TArray<string>.Create('script', 'style');
  FPreformattedTags := TArray<string>.Create('pre', 'listing', 'textarea');
end;

class function THTMLAwareEntitySubstitution.IsCDataContainingTag(
  const TagName: string): Boolean;
var
  Tag: string;
  LowerName: string;
begin
  LowerName := LowerCase(TagName);
  for Tag in FCDataContainingTags do
    if Tag = LowerName then
      Exit(True);
  Result := False;
end;

class function THTMLAwareEntitySubstitution.IsPreformattedTag(
  const TagName: string): Boolean;
var
  Tag: string;
  LowerName: string;
begin
  LowerName := LowerCase(TagName);
  for Tag in FPreformattedTags do
    if Tag = LowerName then
      Exit(True);
  Result := False;
end;

class function THTMLAwareEntitySubstitution.SubstituteIfAppropriate(
  const ParentTagName, S: string): string;
begin
  // Don't substitute content inside script or style tags
  if IsCDataContainingTag(ParentTagName) then
    Result := S
  else
    Result := SubstituteHTML(S);
end;

end.
