/**
 This file is part of the Reductio package.
 (c) Sergio Fernández <fdz.sergio@gmail.com>

 For the full copyright and license information, please view the LICENSE
 file that was distributed with this source code.
 */

import Foundation

final class IndexedTextRank {
  private struct Link {
    let source: Int
    let weight: Float
  }

  private var graph: [[Link]]
  private var outlinks: [Float]
  private let configuration: TextRank<Int>.Configuration

  init(nodeCount: Int, configuration: TextRank<Int>.Configuration = TextRank<Int>.Configuration()) {
    precondition(nodeCount >= 0, "Node count must be non-negative")

    self.graph = Array(repeating: [], count: nodeCount)
    self.outlinks = Array(repeating: 0, count: nodeCount)
    self.configuration = configuration
  }

  func add(edge from: Int, to: Int, weight: Float = 1.0) {
    if from == to { return }

    precondition(graph.indices.contains(from), "Source index is out of bounds")
    precondition(graph.indices.contains(to), "Target index is out of bounds")

    graph[to].append(Link(source: from, weight: weight))
    outlinks[from] += 1
  }

  func execute() -> [Float] {
    guard !graph.isEmpty else { return [] }

    let initialScore = max(0.0, min(1.0, configuration.initialScore))
    var currentNodes = Array(repeating: initialScore, count: graph.count)
    var iterationCount = 0

    while iterationCount < configuration.maxIterations {
      guard let stepNodes = iteration(currentNodes) else {
        return currentNodes
      }

      iterationCount += 1

      if iterationCount >= configuration.minIterations {
        if hasConverged(stepNodes, previous: currentNodes) {
          return stepNodes
        }
      }

      currentNodes = stepNodes
    }

    return currentNodes
  }

  private func iteration(_ nodes: [Float]) -> [Float]? {
    let nodeCount = Float(nodes.count)
    guard nodeCount > 0 else { return nil }

    let dampingComponent = (1 - configuration.dampingFactor) / nodeCount
    var vertex = Array(repeating: Float(0), count: graph.count)

    for node in graph.indices {
      var score: Float = 0.0

      for link in graph[node] {
        let outlinkValue = outlinks[link.source]
        guard outlinkValue > 0, !outlinkValue.isNaN, !outlinkValue.isInfinite else {
          continue
        }

        let contribution = nodes[link.source] / outlinkValue * link.weight
        guard !contribution.isNaN, !contribution.isInfinite else {
          continue
        }

        score += contribution
      }

      let finalValue = dampingComponent + configuration.dampingFactor * score
      guard !finalValue.isNaN, !finalValue.isInfinite else {
        return nil
      }

      vertex[node] = finalValue
    }

    return vertex
  }

  private func hasConverged(_ current: [Float], previous: [Float]) -> Bool {
    if current == previous { return true }

    var sumSquaredDiff: Float = 0.0
    var validComparisons = 0

    for index in previous.indices {
      let currentValue = current[index]
      let previousValue = previous[index]

      guard !currentValue.isNaN, !currentValue.isInfinite,
            !previousValue.isNaN, !previousValue.isInfinite else {
        continue
      }

      let diff = currentValue - previousValue
      sumSquaredDiff += diff * diff
      validComparisons += 1
    }

    guard validComparisons > 0 else { return false }

    let rmse = sqrtf(sumSquaredDiff / Float(validComparisons))
    return rmse < configuration.convergenceThreshold
  }
}
