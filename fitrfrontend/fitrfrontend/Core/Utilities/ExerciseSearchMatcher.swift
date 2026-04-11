//
//  MeasurementType+Display.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 3/16/26.
//

import Foundation

struct ExerciseSearchMatcher {
  static func filterAndSort(_ exercises: [ExerciseResponse], query: String) -> [ExerciseResponse] {
    let preparedQuery = PreparedText(query)

    if preparedQuery.normalized.isEmpty {
      return exercises.sorted(by: isAlphabeticalOrder)
    }

    let ranked = exercises.compactMap { exercise -> RankedExercise? in
      let preparedName = PreparedText(exercise.name)
      guard let rank = matchRank(for: preparedName, query: preparedQuery) else {
        return nil
      }
      return RankedExercise(exercise: exercise, rank: rank)
    }

    return ranked
      .sorted { lhs, rhs in
        if lhs.rank != rhs.rank {
          return lhs.rank < rhs.rank
        }
        return isAlphabeticalOrder(lhs.exercise, rhs.exercise)
      }
      .map(\.exercise)
  }

  private static func isAlphabeticalOrder(_ lhs: ExerciseResponse, _ rhs: ExerciseResponse) -> Bool {
    let order = lhs.name.localizedCaseInsensitiveCompare(rhs.name)
    if order == .orderedSame {
      return lhs.id < rhs.id
    }
    return order == .orderedAscending
  }

  private static func matchRank(for candidate: PreparedText, query: PreparedText) -> Int? {
    guard !query.normalized.isEmpty else {
      return 0
    }

    let hasCompactContainment = !query.compact.isEmpty && candidate.compact.contains(query.compact)
    let allTokenPrefixMatches = allQueryTokensMatch(candidateTokens: candidate.tokens, queryTokens: query.tokens) {
      $0.hasPrefix($1)
    }
    let allTokenSubstringMatches = allQueryTokensMatch(
      candidateTokens: candidate.tokens,
      queryTokens: query.tokens
    ) { $0.contains($1) }

    guard hasCompactContainment || allTokenSubstringMatches else {
      return nil
    }

    if candidate.normalized == query.normalized || candidate.compact == query.compact {
      return 0
    }

    if candidate.normalized.hasPrefix(query.normalized) || candidate.compact.hasPrefix(query.compact) {
      return 1
    }

    if allTokenPrefixMatches {
      return 2
    }

    if allTokenSubstringMatches {
      return 3
    }

    return 4
  }

  private static func allQueryTokensMatch(
    candidateTokens: [String],
    queryTokens: [String],
    matcher: (String, String) -> Bool
  ) -> Bool {
    guard !queryTokens.isEmpty else {
      return false
    }

    return queryTokens.allSatisfy { queryToken in
      candidateTokens.contains { candidateToken in
        matcher(candidateToken, queryToken)
      }
    }
  }
}

private struct RankedExercise {
  let exercise: ExerciseResponse
  let rank: Int
}

private struct PreparedText {
  let normalized: String
  let compact: String
  let tokens: [String]

  init(_ source: String) {
    let folded = source.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    let punctuationAgnostic = folded.replacingOccurrences(
      of: "[^\\p{L}\\p{N}]+",
      with: " ",
      options: .regularExpression
    )
    let collapsed = punctuationAgnostic.replacingOccurrences(
      of: "\\s+",
      with: " ",
      options: .regularExpression
    )
    let cleaned = collapsed.trimmingCharacters(in: .whitespacesAndNewlines)

    normalized = cleaned
    compact = cleaned.replacingOccurrences(of: " ", with: "")
    tokens = cleaned.split(separator: " ").map(String.init)
  }
}
