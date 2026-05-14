/**
 This file is part of the Reductio package.
 (c) Sergio Fernández <fdz.sergio@gmail.com>

 For the full copyright and license information, please view the LICENSE
 file that was distributed with this source code.
 */

import Testing

@testable import Reductio

@Suite("Summarizer build graph tests")
struct SummarizerBuildGraphTests {

  // MARK: - Empty / trivial inputs

  @Test("Empty text has no sentence vertices")
  func emptyStringReturnsEmpty() {
    #expect("".summarize.isEmpty)
  }

  @Test("Single sentence produces no ranked output")
  func singleSentenceReturnsEmpty() {
    #expect("Luminous harbor signals remain steady.".summarize.isEmpty)
  }

  // MARK: - Sentence vertices

  @Test("Every parsed sentence is represented even without shared words")
  func disconnectedSentencesAreAllReturned() {
    let sentences = [
      "Copper anvils shimmer quietly.",
      "Velvet orbitals drift northward.",
      "Quartz lanterns pulse nightly."
    ]

    let summary = sentences.summarized().trimmed

    #expect(summary.count == sentences.count)
    #expect(Set(summary) == Set(sentences))
  }

  @Test("Repeated sentence occurrences are represented separately")
  func repeatedSentenceOccurrencesArePreserved() {
    let repeated = "Copper anvils shimmer."
    let summary = [repeated, repeated].summarized().trimmed

    #expect(summary == [repeated, repeated])
  }

  @Test("Stopword-only sentences are still graph vertices")
  func stopwordOnlySentencesAreReturned() {
    let sentences = [
      "The and of.",
      "But or yet.",
      "It was an."
    ]

    let summary = sentences.summarized().trimmed

    #expect(summary.count == sentences.count)
    #expect(Set(summary) == Set(sentences))
  }

  @Test("Single-token sentences are still graph vertices")
  func singleTokenSentencesAreReturned() {
    let sentences = [
      "Atlas.",
      "Beacon.",
      "Citrus."
    ]

    let summary = sentences.summarized().trimmed

    #expect(summary.count == sentences.count)
    #expect(Set(summary) == Set(sentences))
  }

  @Test("Repeated single-token sentences are not dropped")
  func repeatedSingleTokenSentencesAreReturned() {
    let repeated = "Atlas."
    let summary = [repeated, repeated].summarized().trimmed

    #expect(summary == [repeated, repeated])
  }

  // MARK: - Pairwise connectivity and ranking

  @Test("Similarity is built between non-adjacent sentences")
  func nonAdjacentRelatedSentencesAreConnected() {
    let relatedA = "Quartz vector lantern orbit."
    let unrelated = "Marble canyon velvet river."
    let relatedB = "Quartz vector lantern orbit signal."

    let summary = [
      relatedA,
      unrelated,
      relatedB
    ].summarized(count: 2).trimmed

    #expect(Set(summary) == [relatedA, relatedB])
  }

  @Test("Edge weights prefer stronger sentence similarity")
  func strongerOverlapRanksAboveWeakerOverlap() {
    let strongPairA = "Solar lattice prism orbit beacon engine."
    let strongPairB = "Solar lattice prism orbit beacon."
    let weakOutlier = "Solar lattice."

    let summary = [
      strongPairA,
      strongPairB,
      weakOutlier
    ].summarized(count: 2).trimmed

    #expect(Set(summary) == [strongPairA, strongPairB])
  }

  @Test("Hub sentence ranks first regardless of input order")
  func hubSentenceRanksFirstRegardlessOfInputOrder() {
    let hub = "Atlas beacon citrus delta ember frost."
    let satellites = [
      "Atlas beacon citrus.",
      "Delta ember frost.",
      "Atlas citrus delta.",
      "Beacon ember frost atlas."
    ]

    let hubFirst = ([hub] + satellites).summarized(count: 1).trimmed
    let hubLast = (satellites + [hub]).summarized(count: 1).trimmed

    #expect(hubFirst == [hub])
    #expect(hubLast == [hub])
  }

  @Test("Bridge sentence ranks above either cluster")
  func bridgeSentenceConnectsTwoClusters() {
    let clusterA1 = "Alpha bravo charlie."
    let clusterA2 = "Alpha bravo delta."
    let bridge = "Charlie delta echo foxtrot."
    let clusterB1 = "Echo foxtrot golf."
    let clusterB2 = "Echo foxtrot hotel."

    let summary = [
      clusterA1,
      clusterA2,
      bridge,
      clusterB1,
      clusterB2
    ].summarized(count: 1).trimmed

    #expect(summary == [bridge])
  }

  @Test("Partial overlap ranks above zero overlap")
  func partialOverlapRanksAboveZeroOverlap() {
    let full = "Alpha bravo charlie delta echo."
    let partial = "Alpha bravo foxtrot golf hotel."
    let none = "India juliet kilo lima mike."

    let summary = [full, partial, none].summarized(count: 2).trimmed

    #expect(Set(summary) == [full, partial])
  }

  // MARK: - Scale

  @Test("Moderate input keeps every unique sentence represented")
  func moderateScaleKeepsEveryUniqueSentenceRepresented() {
    let sentences = (0..<80).map { index in
      "Signal \(index) routes through relay \(index + 1000)."
    }

    let summary = sentences.summarized().trimmed

    #expect(summary.count == sentences.count)
    #expect(Set(summary) == Set(sentences))
  }

  @Test("Large sparse input ranks related sentences without dropping isolated sentences")
  func largeSparseInputRanksRelatedSentences() {
    let relatedA = "Orion quartz lantern vector harbor signal."
    let relatedB = "Orion quartz lantern vector harbor signal beacon."
    var sentences = (0..<240).map { index in
      var words = (0..<12).map { uniqueWord(index * 12 + $0) }
      words[0] = words[0].capitalized
      return words.joined(separator: " ") + "."
    }

    sentences.insert(relatedA, at: 37)
    sentences.insert(relatedB, at: 211)

    let summary = sentences.summarized().trimmed

    #expect(summary.count == sentences.count)
    #expect(Set(summary) == Set(sentences))
    #expect(Set(summary.prefix(2)) == [relatedA, relatedB])
  }

  // MARK: - Count parameter

  @Test("Requesting more sentences than available returns all")
  func requestingMoreThanAvailableReturnsAll() {
    let sentences = [
      "Alpha bravo charlie.",
      "Delta echo foxtrot."
    ]

    let summary = sentences.summarized(count: 10).trimmed

    #expect(summary.count == sentences.count)
    #expect(Set(summary) == Set(sentences))
  }

  @Test("Requesting zero sentences returns empty")
  func requestingZeroReturnsEmpty() {
    let result = [
      "Alpha bravo charlie.",
      "Delta echo foxtrot."
    ].summarized(count: 0)

    #expect(result.isEmpty)
  }
}

private extension Array where Element == String {
  func summarized(count: Int? = nil) -> [String] {
    let text = joined(separator: " ")
    if let count {
      return text.summarize(count: count)
    }
    return text.summarize
  }

  var trimmed: [String] {
    map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
  }
}

private func uniqueWord(_ value: Int) -> String {
  let alphabet = Array("abcdefghijklmnopqrstuvwxyz")
  return "zz\(alphabet[(value / 676) % 26])\(alphabet[(value / 26) % 26])\(alphabet[value % 26])"
}
