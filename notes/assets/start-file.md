# Markdown Formatting Guide

## Basic Text Formatting

This is a paragraph with **bold text**, *italic text*, and ***bold italic text***. You can also use _underscores_ for emphasis.

You can ~~strike through~~ text using two tildes.

## Headings

# Heading Level 1
## Heading Level 2
### Heading Level 3
#### Heading Level 4
##### Heading Level 5
###### Heading Level 6

## Lists

### Unordered Lists

- Item 1
- Item 2
    - Nested item 2.1
    - Nested item 2.2
- Item 3

### Ordered Lists

1. First item
2. Second item
    1. Nested item 2.1
    2. Nested item 2.2
3. Third item

### Task Lists

- [x] Completed task
- [ ] Incomplete task
- [ ] Another task

## Links

[Link to Google](https://www.google.com)
[Link with title](https://www.google.com "Google's Homepage")

## Images

![Alt text for image](https://via.placeholder.com/150)

## Blockquotes

> This is a blockquote
>
> It can span multiple lines
>
>> Nested blockquotes are possible

## Code

Inline `code` with backticks.

```dart
// Code block with syntax highlighting
void main() {
  print('Hello, Markdown!');
  
  for (int i = 0; i < 5; i++) {
    print('Count: $i');
  }
}
```

## Horizontal Rules

Three or more hyphens, asterisks, or underscores:

---

## Tables

| Header 1 | Header 2 | Header 3 |
|----------|----------|----------|
| Cell 1   | Cell 2   | Cell 3   |
| Cell 4   | Cell 5   | Cell 6   |
| Cell 7   | Cell 8   | Cell 9   |

## Footnotes

Here's a sentence with a footnote.[^1]

[^1]: This is the footnote.

## Definition Lists

Term
: Definition

Another term
: Another definition

## Emojis

:smile: :heart: :thumbsup: :rocket:

## LaTeX Math (if supported by your markdown renderer)

Inline math: $E = mc^2$

Block math:

$$
\frac{d}{dx}(x^n) = nx^{n-1}
$$

## Highlighting

==This text is highlighted== (works in some markdown flavors)

## Abbreviations

*[HTML]: Hyper Text Markup Language
*[W3C]: World Wide Web Consortium

HTML is defined by the W3C.

## Conclusion

This document showcases most of the common markdown formatting options. Not all markdown renderers support all these features, so test which ones work in your specific Flutter markdown implementation.