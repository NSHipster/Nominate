# Nominate

Nominate is a macOS app that renames PDFs based on their contents.

![Nominate.app - Drag and drop PDF files onto the area above](https://github.com/user-attachments/assets/d35f1db0-1bf2-43e0-bc5d-0df237459ba2)

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

Nominate uses a combination of new fangled AI and old school NLP techniques
to extract a timestamp and summary of the document's contents,
which get massaged into a short, descriptive filename.

> [!IMPORTANT]
> Nominate performs 100% of its processing on-device.
> Your documents never leave your computer.

![Nominate.app - Suggestion to rename file](https://github.com/user-attachments/assets/c9c31ef8-0a1d-4106-94ea-a034774fdf72)

Moments later, Nominate suggests a new filename:
`2025-01-31 Mercury Bank Statement.pdf`.  
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

## Future Enhancements

- [ ] Improve user-facing error messages
- [ ] Create onboarding flow for Ollama and model installation
- [ ] Implement model selection settings
- [ ] Support customizable filename templates
- [ ] Enable Quick Action menu integration
- [ ] Allow Dock icon as drop target for files
- [ ] Extend functionality to rename images using [`llama3.2-vision`][llama3.2-vision]

## License

Nominate is released under the [MIT License](/LICENSE.md).

[homebrew]: https://brew.sh
[llama3.2]: https://ollama.com/library/llama3.2
[llama3.2-vision]: https://ollama.com/blog/llama3.2-vision
[ollama]: https://ollama.com
[ollama-download]: https://ollama.com/download
[quick-action]: https://support.apple.com/guide/mac-help/perform-quick-actions-in-the-finder-on-mac-mchl97ff9142/mac
