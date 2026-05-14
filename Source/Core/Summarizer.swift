/**
 This file is part of the Reductio package.
 (c) Sergio Fernández <fdz.sergio@gmail.com>

 For the full copyright and license information, please view the LICENSE
 file that was distributed with this source code.
 */

import Foundation

struct Summarizer: Sendable {
  private let phrases: [Sentence]

  init(text: String) {
    let sentenceTexts = text.sentences
    let stemmedWords = Stemmer.stemmingWordsInSentences(sentenceTexts)
    self.phrases = zip(sentenceTexts, stemmedWords).map(Sentence.init(text:words:))
  }

  func execute() -> [String] {
    guard phrases.count > 1 else { return [] }

    let rank = IndexedTextRank(nodeCount: phrases.count)
    buildGraph(rank: rank)
    return rank.execute()
      .enumerated()
      .sorted {
        if $0.element == $1.element {
          return $0.offset < $1.offset
        }
        return $0.element > $1.element
      }
      .map { phrases[$0.offset].text }
  }

  private func buildGraph(rank: IndexedTextRank) {
    guard phrases.count > 1 else { return }

    let sentenceIDsByWord = buildSentenceIDsByWord()
    var overlapCounts = [SentencePair: Int]()
    overlapCounts.reserveCapacity(phrases.count)

    for sentenceIDs in sentenceIDsByWord.values where sentenceIDs.count > 1 {
      for sourceIndex in 0..<(sentenceIDs.count - 1) {
        for targetIndex in (sourceIndex + 1)..<sentenceIDs.count {
          let pair = SentencePair(sentenceIDs[sourceIndex], sentenceIDs[targetIndex])
          overlapCounts[pair, default: 0] += 1
        }
      }
    }

    for (pair, overlapCount) in overlapCounts {
      let score = score(
        overlapCount: overlapCount,
        between: phrases[pair.source],
        and: phrases[pair.target]
      )
      guard score > 0 else { continue }

      rank.add(edge: pair.source, to: pair.target, weight: score)
      rank.add(edge: pair.target, to: pair.source, weight: score)
    }
  }

  private func buildSentenceIDsByWord() -> [String: [Int]] {
    var sentenceIDsByWord = [String: [Int]]()
    sentenceIDsByWord.reserveCapacity(phrases.reduce(0) { $0 + $1.words.count })
    var seenWords = Set<String>()

    for (index, phrase) in phrases.enumerated() {
      seenWords.removeAll(keepingCapacity: true)
      seenWords.reserveCapacity(phrase.words.count)

      for word in phrase.words where seenWords.insert(word).inserted {
        sentenceIDsByWord[word, default: []].append(index)
      }
    }

    return sentenceIDsByWord
  }

  private func score(overlapCount: Int, between pivotal: Sentence, and node: Sentence) -> Float {
    let pivotalWordCount = Float(pivotal.words.count)
    let nodeWordCount = Float(node.words.count)
    let denominator = log(pivotalWordCount) + log(nodeWordCount)

    guard denominator > 0, denominator.isFinite else { return 0 }
    return Float(overlapCount) / denominator
  }
}

private struct SentencePair: Hashable {
  let source: Int
  let target: Int

  init(_ first: Int, _ second: Int) {
    if first < second {
      self.source = first
      self.target = second
    } else {
      self.source = second
      self.target = first
    }
  }
}


private extension String {
  var sentences: [String] {
    var sentences = [String]()

    self.enumerateSubstrings(in: self.startIndex..<self.endIndex, options: .bySentences) { (substring, _, _, _) in
      if let substring = substring {
        sentences.append(substring)
      }
    }

    return sentences
  }
}
