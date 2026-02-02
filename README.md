# DelphiSoup

A Delphi 11 port of Python's [BeautifulSoup](https://www.crummy.com/software/BeautifulSoup/) HTML/XML parsing library.

## Overview

DelphiSoup provides a simple way to navigate, search, and modify HTML and XML documents. It creates a parse tree that allows you to extract data using intuitive methods similar to BeautifulSoup.

## Features

- **HTML/XML Parsing**: Parse both HTML and XML documents with a lenient parser
- **Tree Navigation**: Navigate parent, child, and sibling relationships
- **Search Methods**: Find elements by tag name, attributes, or text content
- **CSS Selectors**: Use CSS selector syntax to find elements (`.class`, `#id`, `tag.class`, etc.)
- **Tree Modification**: Add, remove, or modify elements and their content
- **Pretty Print**: Output formatted, readable HTML/XML
- **Entity Handling**: Proper HTML/XML entity encoding and decoding

## Installation

1. Add the `src` folder to your Delphi project's search path
2. Add `DelphiSoup` to your uses clause

```pascal
uses
  DelphiSoup;
```

## Quick Start

### Basic Parsing

```pascal
var
  Soup: TBeautifulSoup;
  Title: ITag;
begin
  Soup := ParseHTML('<html><head><title>Hello World</title></head></html>');
  try
    Title := Soup.Find('title');
    WriteLn(Title.Text);  // Outputs: Hello World
  finally
    Soup.Free;
  end;
end;
```

### Finding Elements

```pascal
var
  Soup: TBeautifulSoup;
  Links: TList<ITag>;
  Link: ITag;
begin
  Soup := ParseHTML(HTMLContent);
  try
    // Find single element
    Link := Soup.Find('a');

    // Find all elements
    Links := Soup.FindAll('a');
    try
      for Link in Links do
        WriteLn(Link.GetAttr('href'));
    finally
      Links.Free;
    end;
  finally
    Soup.Free;
  end;
end;
```

### Finding by Attributes

```pascal
// Find by ID
Div := Soup.Find('div', ['id', 'content']);

// Find by class
Para := Soup.Find('p', ['class', 'intro']);

// Find all with attribute
Items := Soup.FindAll('input', ['type', 'text']);
```

### CSS Selectors

```pascal
// Select by class
Tags := Soup.Select('.highlight');

// Select by ID
Tag := Soup.SelectOne('#main-content');

// Combined selectors
Tags := Soup.Select('div p.intro');
```

### Tree Navigation

```pascal
var
  Tag, Parent, Sibling: ITag;
  Child: IPageElement;
begin
  Tag := Soup.Find('div');

  // Navigate to parent
  Parent := Tag.FindParent('body');

  // Navigate to siblings
  Sibling := Tag.FindNextSibling;

  // Iterate children
  for Child in Tag.Contents do
  begin
    if Supports(Child, ITag) then
      WriteLn((Child as ITag).TagName);
  end;
end;
```

### Modifying Content

```pascal
var
  Tag: ITag;
  NewTag: TTag;
  NewString: TNavigableString;
begin
  // Change text content
  Tag := Soup.Find('p');
  Tag.Clear;
  Tag.Append(TNavigableString.Create('New text'));

  // Set attributes
  Tag.SetAttr('class', 'modified');

  // Create and append new elements
  NewTag := Soup.NewTag('span');
  NewTag.Append(TNavigableString.Create('New content'));
  Tag.Append(NewTag);
end;
```

### Pretty Print Output

```pascal
// Compact output
WriteLn(Soup.Decode);

// Formatted output
WriteLn(Soup.Prettify);
```

### XML Parsing

```pascal
var
  Soup: TBeautifulSoup;
begin
  Soup := ParseXML(XMLContent);
  try
    // Same API as HTML parsing
    WriteLn(Soup.Find('element').Text);
  finally
    Soup.Free;
  end;
end;
```

## API Reference

### Main Classes

| Class              | Description                                       |
| ------------------ | ------------------------------------------------- |
| `TBeautifulSoup`   | Main parser class, represents the entire document |
| `TTag`             | Represents an HTML/XML tag element                |
| `TNavigableString` | Represents text content                           |
| `TComment`         | Represents an HTML/XML comment                    |
| `TDoctype`         | Represents a DOCTYPE declaration                  |

### TBeautifulSoup Methods

| Method                               | Description                              |
| ------------------------------------ | ---------------------------------------- |
| `Create(Markup, Features)`           | Parse markup string                      |
| `CreateFromFile(FileName, Features)` | Parse from file                          |
| `Find(Name, Attrs)`                  | Find first matching element              |
| `FindAll(Name, Attrs, Limit)`        | Find all matching elements               |
| `Select(Selector)`                   | Find elements using CSS selector         |
| `SelectOne(Selector)`                | Find first element matching CSS selector |
| `NewTag(Name, Attrs)`                | Create a new tag element                 |
| `NewString(Text)`                    | Create a new text element                |
| `Decode(PrettyPrint)`                | Convert document to string               |
| `Prettify`                           | Convert document to formatted string     |

### TTag Methods

| Method                        | Description                   |
| ----------------------------- | ----------------------------- |
| `Find(Name, Attrs)`           | Find descendant element       |
| `FindAll(Name, Attrs, Limit)` | Find all descendant elements  |
| `FindParent(Name)`            | Find ancestor element         |
| `FindNextSibling(Name)`       | Find next sibling element     |
| `FindPreviousSibling(Name)`   | Find previous sibling element |
| `GetAttr(Key, Default)`       | Get attribute value           |
| `SetAttr(Key, Value)`         | Set attribute value           |
| `HasAttr(Key)`                | Check if attribute exists     |
| `Append(Element)`             | Append child element          |
| `Insert(Position, Element)`   | Insert child element          |
| `Clear(Decompose)`            | Remove all children           |
| `Extract`                     | Remove from parent            |
| `Text`                        | Get text content              |

### Properties

| Property          | Type         | Description        |
| ----------------- | ------------ | ------------------ |
| `TagName`         | string       | Element tag name   |
| `Attrs`           | TDictionary  | Element attributes |
| `Contents`        | TList        | Child elements     |
| `Parent`          | ITag         | Parent element     |
| `NextSibling`     | IPageElement | Next sibling       |
| `PreviousSibling` | IPageElement | Previous sibling   |
| `Text`            | string       | Text content       |

## Differences from Python BeautifulSoup

| Feature            | Python               | Delphi                  |
| ------------------ | -------------------- | ----------------------- |
| Memory Management  | Garbage collected    | Manual/Interface-based  |
| String Type        | Unicode              | UTF-16 (Delphi string)  |
| Dynamic Properties | `soup.tag_name`      | `Soup.Find('tag_name')` |
| Multiple Parsers   | lxml, html5lib, etc. | Built-in tokenizer      |

## License

MIT License - See LICENSE file for details.

## Credits

- Original BeautifulSoup by Leonard Richardson
- Delphi port created for the Delphi community
