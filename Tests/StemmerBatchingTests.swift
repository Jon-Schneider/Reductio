/**
 This file is part of the Reductio package.
 (c) Sergio Fernández <fdz.sergio@gmail.com>

 For the full copyright and license information, please view the LICENSE
 file that was distributed with this source code.
 */

import Testing

@testable import Reductio

@Suite("Stemmer batching tests")
struct StemmerBatchingTests {

  @Test("Batched sentence stemming matches individual stemming")
  func batchedSentenceStemmingMatchesIndividualStemming() {
    let sentences = [
      "The runners were running swiftly.",
      "Anyhow, orbital signals pulsed brightly.",
      "Swift developers built resilient libraries."
    ]

    let batchedStems = Stemmer.stemmingWordsInSentences(sentences)
    let individualStems = sentences.map(Stemmer.stemmingWordsInText)

    #expect(batchedStems == individualStems)
  }

  @Test("Batched sentence stemming preserves empty sentence slots")
  func batchedSentenceStemmingPreservesEmptySentenceSlots() {
    let stems = Stemmer.stemmingWordsInSentences(["", "Signal orbit."])

    #expect(stems.count == 2)
    #expect(stems[0].isEmpty)
    #expect(stems[1] == Stemmer.stemmingWordsInText("Signal orbit."))
  }
}
