/**
 This file is part of the Reductio package.
 (c) Sergio Fernández <fdz.sergio@gmail.com>

 For the full copyright and license information, please view the LICENSE
 file that was distributed with this source code.
 */

import Testing

@testable import Reductio

@Suite("Content-word filtering tests")
struct ContentWordFilteringTests {

  @Test("Determiners are removed")
  func determinersAreRemoved() {
    let words = Stemmer.stemmingWordsInText("The cat sat on a mat.")
    #expect(!words.contains("the"))
    #expect(!words.contains("a"))
  }

  @Test("Prepositions are removed")
  func prepositionsAreRemoved() {
    let words = Stemmer.stemmingWordsInText("The cat sat on the mat.")
    #expect(!words.contains("on"))
  }

  @Test("Conjunctions are removed")
  func conjunctionsAreRemoved() {
    let words = Stemmer.stemmingWordsInText("Cats and dogs but not birds.")
    #expect(!words.contains("and"))
    #expect(!words.contains("but"))
  }

  @Test("Pronouns are removed")
  func pronounsAreRemoved() {
    let words = Stemmer.stemmingWordsInText("She gave it to him.")
    #expect(!words.contains("she"))
    #expect(!words.contains("it"))
    #expect(!words.contains("him"))
  }

  @Test("Content nouns survive")
  func contentNounsSurvive() {
    let words = Stemmer.stemmingWordsInText("The signal orbits the beacon.")
    #expect(words.contains("signal"))
    #expect(words.contains("beacon"))
  }

  @Test("Content verbs survive")
  func contentVerbsSurvive() {
    let words = Stemmer.stemmingWordsInText("Engineers design robust systems.")
    #expect(words.contains("design"))
  }

  @Test("Adjectives survive")
  func adjectivesSurvive() {
    let words = Stemmer.stemmingWordsInText("The large bright star faded.")
    #expect(words.contains("large"))
    #expect(words.contains("bright"))
  }

  @Test("Keyword options drop short words")
  func keywordOptionsDropShortWords() {
    let words = Stemmer.stemmingWordsInText("Go run fast now.", options: .keywords)
    for word in words {
      #expect(word.count >= 3)
    }
  }

  @Test("Keyword options drop pure numeric tokens")
  func keywordOptionsDropNumericTokens() {
    let words = Stemmer.stemmingWordsInText("Order 500 units of steel.", options: .keywords)
    #expect(!words.contains("500"))
  }

  @Test("Batched sentence stemming matches individual stemming")
  func batchedMatchesIndividual() {
    let sentences = [
      "The cat sat on the mat.",
      "Engineers design robust systems.",
    ]
    let batched = Stemmer.stemmingWordsInSentences(sentences)
    let individual = sentences.map { Stemmer.stemmingWordsInText($0) }
    #expect(batched == individual)
  }
}
