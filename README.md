# Nominate

Nominate is a macOS app that renames PDFs based on their contents.

<video src="https://github.com/user-attachments/assets/f42663ac-952a-4924-868a-c4a9d1b18436" width="100%" autoplay loop muted playsinline>
  <source src="https://github.com/user-attachments/assets/f42663ac-952a-4924-868a-c4a9d1b18436" type="video/mp4">
</video>

---

Like many striving for a paperless lifestyle,
I habitually scan and shred every document that comes my way.
While this keeps my desk free of clutter,
it creates a digital mess of PDF files
with nothing but a timestamp to their name.

Rather than go through an rename each file all by hand,
Nominate does this for me automatically.  
See this file, `Scan2025-02-03_123456.pdf`?
Let's drag-and-drop it into Nominate.

Nominate uses a combination of new-fangled AI and old-school NLP techniques
to extract a timestamp and summary of the document's contents,
which get massaged into a short, descriptive filename.

> [!IMPORTANT]
> Nominate performs 100% of its processing on-device.
> Your documents never leave your computer.

![Nominate.app - Suggestion to rename file](https://github.com/user-attachments/assets/c9c31ef8-0a1d-4106-94ea-a034774fdf72)

Moments later, Nominate suggests a new filename:
`2025-01-31 Bank Statement.pdf`.  
_Much better!_

Go ahead and click the <kbd>Apply</kbd> button to rename the file.
Or, you can do the "Human-in-the-Loop" thing and check its work.
Click the Quick Look icon (👁️) to open up a preview
or the magnifying glass icon (🔍) to reveal the file in Finder.

## Requirements

- macOS 15
- Xcode 16
- [Ollama][ollama]

## Setup

Download Ollama with [Homebrew][homebrew]
or directly from [their website][ollama-download].

```console
brew install --cask ollama
```

Download the [llama3.2] model (2GB).

```console
ollama pull llama3.2
```

Clone the Nominate repo and open it in Xcode.

```console
git clone https://github.com/NSHipster/Nominate.git
cd Nominate
xed .
```

In the menu bar, select Product > Run (<kbd>⌘</kbd><kbd>R</kbd>)
to build and run the app.

## Implementation Details

Nominate is a native macOS app written in SwiftUI.
Please do not take this as any kind of endorsement.
To paraphrase
[Werner Herzog describing his feelings about French](https://www.youtube.com/watch?v=ZXY9iSqDbSQ):

> I do understand SwiftUI, but I refuse to write it. 
> It's the last thing I would ever do.
> \[...\]
> For this project I had to write a few things in SwiftUI.
> I regret it.

Nominate uses the [`ollama-swift` package][ollama-swift-package]
to interact with Ollama via its [HTTP server API][ollama-api],
which runs at `http://localhost:11434/api/`.

Apple's [PDFKit framework][pdfkit] is used for
<abbr title="Optical Character Recognition">OCR</abbr>.
The [NaturalLanguage framework][naturallanguage] is used to 
[lemmatize][lemmatization] and remove filler words from filenames.
The [Foundation framework's][foundation] `DateFormatter` class
is used to parse and format dates found in the PDF.

Nominate's UI was inspired by [ImageOptim][imageoptim] by Kornel Lesiński.

## Future Enhancements

- [ ] Pre-built releases available for download
- [ ] Improve user-facing error messages
- [ ] Create onboarding flow for Ollama and model installation
- [ ] Implement model selection settings
- [ ] Support customizable filename templates
- [ ] Enable Quick Action menu integration
- [ ] Allow Dock icon as drop target for files
- [ ] Extend functionality to rename images using [`llama3.2-vision`][llama3.2-vision]

## License

Nominate is released under the [MIT License](/LICENSE.md).

[foundation]: https://developer.apple.com/documentation/foundation
[homebrew]: https://brew.sh
[imageoptim]: https://imageoptim.com/mac
[lemmatization]: https://en.wikipedia.org/wiki/Lemmatization
[llama3.2-vision]: https://ollama.com/blog/llama3.2-vision
[llama3.2]: https://ollama.com/library/llama3.2
[naturallanguage]: https://developer.apple.com/documentation/naturallanguage
[ollama-api]: https://github.com/ollama/ollama/blob/main/docs/api.md
[ollama-download]: https://ollama.com/download
[ollama-swift-package]: https://github.com/mattt/ollama-swift
[ollama]: https://ollama.com
[pdfkit]: https://developer.apple.com/documentation/pdfkit
[quick-action]: https://support.apple.com/guide/mac-help/perform-quick-actions-in-the-finder-on-mac-mchl97ff9142/mac
