{ ****************************************************************************** }
{ }
{ DelphiSoup Demo Application }
{ }
{ Demonstrates the use of DelphiSoup HTML/XML parser }
{ }
{ ****************************************************************************** }

program DelphiSoupDemo;

{$APPTYPE CONSOLE}

{$R *.res}


uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  DelphiSoup.Types in '..\src\DelphiSoup.Types.pas',
  DelphiSoup.Entities in '..\src\DelphiSoup.Entities.pas',
  DelphiSoup.Element in '..\src\DelphiSoup.Element.pas',
  DelphiSoup.Parser in '..\src\DelphiSoup.Parser.pas',
  DelphiSoup.TreeBuilder in '..\src\DelphiSoup.TreeBuilder.pas',
  DelphiSoup.Strainer in '..\src\DelphiSoup.Strainer.pas',
  DelphiSoup in '..\src\DelphiSoup.pas';

const
  SampleHTML =
    '<!DOCTYPE html>' + sLineBreak +
    '<html lang="en">' + sLineBreak +
    '<head>' + sLineBreak +
    '    <meta charset="UTF-8">' + sLineBreak +
    '    <title>DelphiSoup Demo</title>' + sLineBreak +
    '</head>' + sLineBreak +
    '<body>' + sLineBreak +
    '    <h1>Welcome to DelphiSoup</h1>' + sLineBreak +
    '    <div id="content" class="main-content">' + sLineBreak +
    '        <p class="intro">This is an introduction paragraph.</p>' + sLineBreak +
    '        <p class="body">This is the body paragraph with <strong>bold text</strong>.</p>' + sLineBreak +
    '        <ul class="list">' + sLineBreak +
    '            <li>Item 1</li>' + sLineBreak +
    '            <li>Item 2</li>' + sLineBreak +
    '            <li>Item 3</li>' + sLineBreak +
    '        </ul>' + sLineBreak +
    '    </div>' + sLineBreak +
    '    <div id="sidebar">' + sLineBreak +
    '        <a href="https://example.com" class="link">Example Link</a>' + sLineBreak +
    '        <a href="https://delphi.dev" class="link">Delphi Link</a>' + sLineBreak +
    '    </div>' + sLineBreak +
    '    <!-- This is a comment -->' + sLineBreak +
    '    <footer>' + sLineBreak +
    '        <p>Copyright 2026</p>' + sLineBreak +
    '    </footer>' + sLineBreak +
    '</body>' + sLineBreak +
    '</html>';

procedure Demo1_BasicParsing;
var
  Soup: TBeautifulSoup;
  Title: ITag;
begin
  WriteLn('=== Demo 1: Basic HTML Parsing ===');
  WriteLn;

  Soup := ParseHTML(SampleHTML);
  try
    WriteLn('Texto de la página:');
    WriteLn(Soup.GetTextContent(#13#10, True));
    // Find the title
    Title := Soup.Find('title');
    if Title <> nil then
      WriteLn('Page Title: ', Title.Text);

    WriteLn;
  finally
    Soup.Free;
  end;
end;

procedure Demo2_FindElements;
var
  Soup: TBeautifulSoup;
  Tag: ITag;
  Paragraphs: TList<ITag>;
  Links: TList<ITag>;
begin
  WriteLn('=== Demo 2: Finding Elements ===');
  WriteLn;

  Soup := ParseHTML(SampleHTML);
  try
    // Find single element
    Tag := Soup.Find('h1');
    if Tag <> nil then
      WriteLn('H1: ', Tag.Text);

    // Find all paragraphs
    WriteLn;
    WriteLn('All paragraphs:');
    Paragraphs := Soup.FindAll('p');
    try
      for Tag in Paragraphs do
        WriteLn('  - ', Tag.Text);
    finally
      Paragraphs.Free;
    end;

    // Find all links
    WriteLn;
    WriteLn('All links:');
    Links := Soup.FindAll('a');
    try
      for Tag in Links do
        WriteLn('  - ', Tag.Text, ' -> ', Tag.GetAttr('href'));
    finally
      Links.Free;
    end;

    WriteLn;
  finally
    Soup.Free;
  end;
end;

procedure Demo3_FindByAttribute;
var
  Soup: TBeautifulSoup;
  Tag: ITag;
  Items: TList<ITag>;
  Content: ITag;
begin
  WriteLn('=== Demo 3: Finding by Attribute ===');
  WriteLn;

  Soup := ParseHTML(SampleHTML);
  try
    // Find by ID using CSS selector (simpler alternative to array of const)
    Content := Soup.SelectOne('#content');
    if Content <> nil then
      WriteLn('Found div#content with class: ', Content.GetAttr('class'));

    // Find by class using CSS selector
    Tag := Soup.SelectOne('.intro');
    if Tag <> nil then
      WriteLn('Intro paragraph: ', Tag.Text);

    // Find all list items
    WriteLn;
    WriteLn('List items:');
    Items := Soup.FindAll('li');
    try
      for Tag in Items do
        WriteLn('  - ', Tag.Text);
    finally
      Items.Free;
    end;

    WriteLn;
  finally
    Soup.Free;
  end;
end;

procedure Demo4_Navigation;
var
  Soup: TBeautifulSoup;
  Content, Sibling, Parent: ITag;
  Child: IPageElement;
  ChildTag: ITag;
  I: Integer;
begin
  WriteLn('=== Demo 4: Tree Navigation ===');
  WriteLn;

  Soup := ParseHTML(SampleHTML);
  try
    // Find a div and navigate using CSS selector
    Content := Soup.SelectOne('#content');
    if Content <> nil then
    begin
      WriteLn('Found: div#content');

      // Get children
      WriteLn('Children:');
      for I := 0 to Content.Contents.Count - 1 do
      begin
        Child := Content.Contents[I];
        if Supports(Child, ITag, ChildTag) then
          WriteLn('  - <', ChildTag.TagName, '>');
      end;

      // Find next sibling
      Sibling := Content.FindNextSibling('div');
      if Sibling <> nil then
        WriteLn('Next sibling div: #', Sibling.GetAttr('id'));

      // Find parent
      Parent := Content.FindParent('body');
      if Parent <> nil then
        WriteLn('Parent is: <', Parent.TagName, '>');
    end;

    WriteLn;
  finally
    Soup.Free;
  end;
end;

procedure Demo5_CSSSelectors;
var
  Soup: TBeautifulSoup;
  Tag: ITag;
  Tags: TList<ITag>;
begin
  WriteLn('=== Demo 5: CSS Selectors ===');
  WriteLn;

  Soup := ParseHTML(SampleHTML);
  try
    // Select by class
    Tags := Soup.Select('.link');
    try
      WriteLn('Elements with class "link":');
      for Tag in Tags do
        WriteLn('  - ', Tag.Text);
    finally
      Tags.Free;
    end;

    // Select by ID
    Tag := Soup.SelectOne('#sidebar');
    if Tag <> nil then
      WriteLn('Found #sidebar');

    // Combined selector
    Tags := Soup.Select('div p');
    try
      WriteLn;
      WriteLn('Paragraphs inside divs:');
      for Tag in Tags do
        WriteLn('  - ', Tag.Text);
    finally
      Tags.Free;
    end;

    WriteLn;
  finally
    Soup.Free;
  end;
end;

procedure Demo6_ModifyingContent;
var
  Soup: TBeautifulSoup;
  Tag: ITag;
  NewTag: TTag;
  NewString: TNavigableString;
begin
  WriteLn('=== Demo 6: Modifying Content ===');
  WriteLn;

  Soup := ParseHTML('<html><body><p>Original text</p></body></html>');
  try
    WriteLn('Before modification:');
    WriteLn(Soup.Prettify);

    // Find the paragraph
    Tag := Soup.Find('p');
    if Tag <> nil then
    begin
      // Clear and add new content
      Tag.Clear;
      NewString := TNavigableString.Create('Modified text!');
      Tag.Append(NewString);

      // Change an attribute
      Tag.SetAttr('class', 'modified');
    end;

    // Create a new tag and append
    NewTag := Soup.NewTag('span');
    NewTag.SetAttr('class', 'highlight');
    NewTag.Append(TNavigableString.Create('New span element'));

    Tag := Soup.Find('body');
    if Tag <> nil then
      Tag.Append(NewTag);

    WriteLn('After modification:');
    WriteLn(Soup.Prettify);
  finally

    Soup.Free;
  end;
end;

procedure Demo7_PrettyPrint;
var
  Soup: TBeautifulSoup;
begin
  WriteLn('=== Demo 7: Pretty Print Output ===');
  WriteLn;

  Soup := ParseHTML('<div><p>Hello</p><p><span>World</span></p></div>');
  try
    WriteLn('Raw output:');
    WriteLn(Soup.Decode(False));
    WriteLn;

    WriteLn('Pretty print:');
    WriteLn(Soup.Prettify);
  finally
    Soup.Free;
  end;
end;

procedure Demo8_XMLParsing;
var
  Soup: TBeautifulSoup;
  Item: ITag;
  Items: TList<ITag>;
  TitleTag, AuthorTag: ITag;
const
  SampleXML =
    '<?xml version="1.0"?>' + sLineBreak +
    '<catalog>' + sLineBreak +
    '  <book id="1">' + sLineBreak +
    '    <title>Delphi Programming</title>' + sLineBreak +
    '    <author>John Doe</author>' + sLineBreak +
    '  </book>' + sLineBreak +
    '  <book id="2">' + sLineBreak +
    '    <title>Advanced Delphi</title>' + sLineBreak +
    '    <author>Jane Smith</author>' + sLineBreak +
    '  </book>' + sLineBreak +
    '</catalog>';
begin
  WriteLn('=== Demo 8: XML Parsing ===');
  WriteLn;

  Soup := ParseXML(SampleXML);
  try
    WriteLn('Books in catalog:');
    Items := Soup.FindAll('book');
    try
      for Item in Items do
      begin
        WriteLn('  Book ID: ', Item.GetAttr('id'));
        TitleTag := Item.Find('title');
        if TitleTag <> nil then
          WriteLn('    Title: ', TitleTag.Text);
        AuthorTag := Item.Find('author');
        if AuthorTag <> nil then
          WriteLn('    Author: ', AuthorTag.Text);
      end;
    finally
      Items.Free;
    end;

    WriteLn;
  finally
    Soup.Free;
  end;
end;

begin
  try
    WriteLn('*******************************************');
    WriteLn('*      DelphiSoup Demo Application        *');
    WriteLn('*  A Delphi port of Python BeautifulSoup  *');
    WriteLn('*******************************************');
    WriteLn;

    Demo1_BasicParsing;
    Demo2_FindElements;
    Demo3_FindByAttribute;
    Demo4_Navigation;
    Demo5_CSSSelectors;
    Demo6_ModifyingContent;
    Demo7_PrettyPrint;
    Demo8_XMLParsing;

    WriteLn('=== All demos completed! ===');
    WriteLn;
    WriteLn('Press Enter to exit...');
    ReadLn;
  except
    on E: Exception do
    begin
      WriteLn('Error: ', E.ClassName, ': ', E.Message);
      ReadLn;
    end;
  end;

end.
