/**
 This file is part of the Reductio package.
 (c) Sergio Fernández <fdz.sergio@gmail.com>

 For the full copyright and license information, please view the LICENSE
 file that was distributed with this source code.
 */

import Testing

@testable import Reductio

@Suite("Indexed TextRank tests")
struct IndexedTextRankTests {

  @Test("Indexed TextRank matches generic TextRank scores")
  func indexedTextRankMatchesGenericScores() {
    let edgeWeights: [(source: Int, target: Int, weight: Float)] = [
      (0, 1, 1.0),
      (1, 0, 1.0),
      (1, 2, 0.8),
      (2, 1, 0.8),
      (2, 3, 0.3),
      (3, 2, 0.3),
      (0, 2, 0.4),
      (2, 0, 0.4)
    ]

    let genericRank = TextRank<Int>()
    let indexedRank = IndexedTextRank(nodeCount: 4)

    (0..<4).forEach(genericRank.add(node:))
    for edgeWeight in edgeWeights {
      genericRank.add(edge: edgeWeight.source, to: edgeWeight.target, weight: edgeWeight.weight)
      indexedRank.add(edge: edgeWeight.source, to: edgeWeight.target, weight: edgeWeight.weight)
    }

    let genericScores = genericRank.execute()
    let indexedScores = indexedRank.execute()

    #expect(indexedScores.count == 4)
    for index in 0..<4 {
      #expect(abs((genericScores[index] ?? 0) - indexedScores[index]) < 0.0001)
    }
  }

  @Test("Indexed TextRank returns disconnected nodes")
  func indexedTextRankReturnsDisconnectedNodes() {
    let scores = IndexedTextRank(nodeCount: 3).execute()

    #expect(scores.count == 3)
    #expect(scores.allSatisfy { $0.isFinite })
    #expect(scores.allSatisfy { $0 > 0 })
  }
}
