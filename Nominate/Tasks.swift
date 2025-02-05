import Foundation
import NaturalLanguage
import Ollama

/// The model to use for tasks.
private let model: Model.ID = "llama3.2"

/// A date formatter for YYYY-MM-DD format.
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
}()

/// Extracts the most relevant date from the contents of a document.
///
/// - Parameters:
///    - document: The document to extract the date from.
///    - client: The Ollama client to use.
///
/// - Returns: A date, or nil if no date is found.
func extractDate(from document: String, using client: Ollama.Client) async throws -> Date? {
    let sentinel = "No date found"

    let prompt = """
        You are a helpful assistant tasked with extracting the most relevant date from the contents of a document. Please follow these guidelines:

        1. Analyze the given document and identify all dates.
        2. If multiple dates are found, determine the most relevant one based on context (e.g., date of service, invoice date, timestamp).
        4. If no date is found, respond with "\(sentinel)".

        Respond only with the extracted date in YYYY-MM-DD format or "\(sentinel)". Do not include any other text in your response.

        Document content:
        \(document)
        """

    let result = try await client.chat(
        model: model,
        messages: [
            .user(prompt)
        ],
        options: [
            "temperature": 0
        ]
    )

    let string = result.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
    print("DATE: " + string)

    if string == sentinel {
        return nil
    }

    // Try to parse the date using the formatter
    if let date = dateFormatter.date(from: string) {
        return date
    }

    // Fallback to NSDataDetector
    let types: NSTextCheckingResult.CheckingType = [.date]
    guard let detector = try? NSDataDetector(types: types.rawValue) else {
        return nil
    }

    let range = NSRange(string.startIndex..<string.endIndex, in: string)
    let matches = detector.matches(in: string, options: [], range: range)

    // Return the first detected date
    return matches.first?.date
}

/// Summarizes the contents of a document.
///
/// - Parameters:
///    - document: The document to summarize.
///    - client: The Ollama client to use.
///
/// - Returns: The summary of the document.
func generateSummary(of document: String, using client: Ollama.Client) async throws -> String {
    let summaryPrompt = """
        You are a helpful assistant tasked with summarizing the contents of a document. Please follow these guidelines:

        1. Analyze the given document and identify the main topic or purpose.
        2. Summarize the document in a concise manner, capturing the key points and important details.
        3. If the document is a report, include the main findings and recommendations.
        4. If the document is a narrative, include the main events and characters.
        5. If the document is an invoice, include the name of the supplier and patient / student / beneficiary.
        6. Limit your summary to a maximum of 250 words.

        Respond only with the summary. Do not include any other text in your response.

        Document content:
        \(document)
        """

    let result = try await client.chat(
        model: model,
        messages: [.user(summaryPrompt)],
        options: ["temperature": 0]
    )

    let summary = result.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
    print(summary)

    return summary
}

/// The maximum length of a macOS filename in UTF-8 bytes.
private let maxFilenameLength: Int = 255

/// Characters that are not allowed in filenames.
private let disallowedCharacters = CharacterSet.alphanumerics.inverted

/// Words that should be filtered out when generating filenames.
private let unwantedWords: Set<String> = [
    // Articles and basic pronouns
    "the", "a", "an", "i", "we", "you", "they", "he", "she", "it",

    // Common conjunctions and prepositions
    "and", "but", "or", "in", "on", "of", "with", "by", "for", "to", "from", "as", "at",

    // Auxiliary verbs and common verbs
    "is", "are", "were", "was", "be", "have", "has", "had", "do", "does", "did", "can", "will",

    // Relative pronouns and demonstratives
    "that", "which", "this",

    // Adverbs and adjectives
    "only", "just", "very", "new", "more", "most", "other", "some", "such", "own", "same",

    // Time-related words
    "now", "before", "after", "during",

    // Quantity and comparison words
    "few", "any", "each", "so", "than", "too",

    // Common filler words
    "about", "into", "through", "above", "below",

    // Negations
    "no", "nor", "not", "don",

    // File and document-related words
    "based", "generated", "filename", "file", "document", "text", "output", "category", "summary",

    // Content description words
    "key", "details", "information", "note", "notes", "main", "ideas", "concepts",

    // Action verbs (often used in descriptions)
    "depicts", "show", "shows", "display", "illustrates", "presents", "features", "provides",
    "covers", "includes", "discusses", "demonstrates", "describes",

    // Miscellaneous
    "if", "because", "should", "s", "t",
]

func generateFilename(
    for summary: String, date: Date?, extension: String?, with client: Ollama.Client
) async throws -> String {
    let filenamePrompt = """
        Based on the summary below, generate a specific, descriptive filename that captures the essence of the document.
        Limit the filename to a maximum of a dozen words.
        Use nouns and avoid starting with verbs like 'depicts', 'shows', 'presents', etc.
        Do not include any data type words like 'text', 'document', 'pdf', etc.
        Join words with space.
        \(date.map { "Don't include this date in the filename: \(dateFormatter.string(from: $0))" } ?? "")

        Summary: \(summary)

        Output only the filename, without any additional text.

        Filename:
        """

    let filenameResult = try await client.chat(
        model: model,
        messages: [.user(filenamePrompt)],
        options: ["temperature": 0]
    )

    let filename = filenameResult.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: "Filename:", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)

    print(filename)

    var components = [String]()
    if let date = date {
        components.append(dateFormatter.string(from: date))
    }

    let tagger = NLTagger(tagSchemes: [.lemma])
    tagger.string = filename.lowercased()
    components += tagger.tags(
        in: filename.startIndex..<filename.endIndex,
        unit: .word,
        scheme: .lemma,
        options: [.omitWhitespace, .omitOther]
    ).compactMap { tag, range in
        if let lemma = tag?.rawValue, unwantedWords.contains(lemma) {
            return nil
        }

        let word = filename[range]
        if word.isEmpty || unwantedWords.contains(word.lowercased()) {
            return nil
        }

        return String(word)
    }

    let extensionSuffix = `extension`.map { "." + $0 } ?? ""
    let maxLengthWithoutExtension = maxFilenameLength - extensionSuffix.utf8.count

    let sanitizedFilename = components.reduce(into: "") { result, word in
        let potentialResult = result.isEmpty ? word : result + " " + word
        guard potentialResult.utf8.count <= maxLengthWithoutExtension else { return }
        result = potentialResult
    }

    return sanitizedFilename + extensionSuffix
}
