/**
 This file is part of the Reductio package.
 (c) Sergio Fernández <fdz.sergio@gmail.com>

 For the full copyright and license information, please view the LICENSE
 file that was distributed with this source code.
 */

import Foundation
import NaturalLanguage

enum Stemmer {

  struct Options: Sendable {
    var minimumWordLength: Int = 1
    var requiresAlphabeticToken: Bool = false

    static let summarization = Options()
    static let keywords = Options(minimumWordLength: 3, requiresAlphabeticToken: true)
  }

  static func stemmingWordsInText(_ text: String, options: Options = .summarization) -> [String] {
    stemmingWords(in: text, groupedBy: [text.startIndex..<text.endIndex], options: options).first ?? []
  }

  static func stemmingWordsInSentences(_ sentences: [String], options: Options = .summarization) -> [[String]] {
    guard !sentences.isEmpty else { return [] }

    var text = ""
    text.reserveCapacity(sentences.reduce(0) { $0 + $1.count + 1 })
    var ranges: [Range<String.Index>] = []
    ranges.reserveCapacity(sentences.count)

    for sentence in sentences {
      if !text.isEmpty {
        text.append("\n")
      }

      let startIndex = text.endIndex
      text.append(sentence)
      ranges.append(startIndex..<text.endIndex)
    }

    return stemmingWords(in: text, groupedBy: ranges, options: options)
  }

  private static let filteredLexicalClasses: Set<NLTag> = [
    .preposition, .determiner, .conjunction, .particle, .pronoun,
  ]

  private static func stemmingWords(
    in text: String,
    groupedBy ranges: [Range<String.Index>],
    options: Options
  ) -> [[String]] {
    guard !ranges.isEmpty else { return [] }

    var stems = Array(repeating: [String](), count: ranges.count)
    let tokenizer = NLTokenizer(unit: .word)
    tokenizer.string = text

    let tagger = NLTagger(tagSchemes: [.lexicalClass, .lemma])
    tagger.string = text

    var rangeIndex = 0
    tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { tokenRange, _ in
      while rangeIndex < ranges.count && tokenRange.lowerBound >= ranges[rangeIndex].upperBound {
        rangeIndex += 1
      }

      guard rangeIndex < ranges.count, ranges[rangeIndex].contains(tokenRange.lowerBound) else {
        return true
      }

      let classTag = tagger.tag(at: tokenRange.lowerBound, unit: .word, scheme: .lexicalClass).0
      if let classTag, filteredLexicalClasses.contains(classTag) {
        return true
      }

      let token = String(text[tokenRange])

      if options.requiresAlphabeticToken && !token.unicodeScalars.contains(where: CharacterSet.letters.contains) {
        return true
      }

      let lemma: String
      if let tag = tagger.tag(at: tokenRange.lowerBound, unit: .word, scheme: .lemma).0?.rawValue {
        lemma = tag.lowercased()
      } else {
        lemma = token.lowercased()
      }

      if lemma.count < options.minimumWordLength {
        return true
      }

      stems[rangeIndex].append(lemma)

      return true
    }
    return stems
  }
}
