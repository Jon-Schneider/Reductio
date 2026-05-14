/**
 This file is part of the Reductio package.
 (c) Sergio Fernández <fdz.sergio@gmail.com>

 For the full copyright and license information, please view the LICENSE
 file that was distributed with this source code.
 */

import Foundation
import NaturalLanguage

enum Stemmer {
  static func stemmingWordsInText(_ text: String) -> [String] {
    stemmingWords(in: text, groupedBy: [text.startIndex..<text.endIndex]).first ?? []
  }

  static func stemmingWordsInSentences(_ sentences: [String]) -> [[String]] {
    guard !sentences.isEmpty else { return [] }

    var text = ""
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

    return stemmingWords(in: text, groupedBy: ranges)
  }

  private static func stemmingWords(in text: String, groupedBy ranges: [Range<String.Index>]) -> [[String]] {
    guard !ranges.isEmpty else { return [] }

    var stems = Array(repeating: [String](), count: ranges.count)
    let tokenizer = NLTokenizer(unit: .word)
    tokenizer.string = text

    let tagger = NLTagger(tagSchemes: [.lemma])
    tagger.string = text

    var rangeIndex = 0
    tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { tokenRange, _ in
      while rangeIndex < ranges.count && tokenRange.lowerBound >= ranges[rangeIndex].upperBound {
        rangeIndex += 1
      }

      guard rangeIndex < ranges.count, ranges[rangeIndex].contains(tokenRange.lowerBound) else {
        return true
      }

      let token = String(text[tokenRange])

      if let tag = tagger.tag(at: tokenRange.lowerBound, unit: .word, scheme: .lemma).0?.rawValue {
        stems[rangeIndex].append(tag.lowercased())
      } else {
        stems[rangeIndex].append(token.lowercased())
      }

      return true
    }
    return stems
  }
}
