/**
 This file is part of the Reductio package.
 (c) Sergio Fernández <fdz.sergio@gmail.com>

 For the full copyright and license information, please view the LICENSE
 file that was distributed with this source code.
 */

import Testing

@testable import Reductio

@Suite("Stopword filtering tests")
struct StopwordFilteringTests {

  @Test("Anyhow is removed from keyword extraction")
  func anyhowIsRemovedFromKeywords() {
    let keywords = "Anyhow signal orbit anyhow.".keywords

    #expect(!keywords.contains("anyhow"))
    #expect(keywords.contains("signal"))
    #expect(keywords.contains("orbit"))
  }

  @Test("Anyhow is removed from sentence stems")
  func anyhowIsRemovedFromSentenceWords() {
    let sentence = Sentence(text: "Anyhow signal orbit.")

    #expect(!sentence.words.contains("anyhow"))
    #expect(sentence.words.contains("signal"))
    #expect(sentence.words.contains("orbit"))
  }
}
