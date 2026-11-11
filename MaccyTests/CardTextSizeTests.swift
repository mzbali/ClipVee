import Defaults
import Foundation
import Testing
@testable import Maccy

struct CardTextSizeTests {
  @Test("Card size preserves the old default and round-trips each choice in an isolated suite")
  func persistence() throws {
    let suiteName = "ClipVee.CardTextSizeTests.\(UUID().uuidString)"
    let suite = try #require(UserDefaults(suiteName: suiteName))
    defer { suite.removePersistentDomain(forName: suiteName) }
    let key = Defaults.Key<CardTextSize>("cardTextSize", default: .standard, suite: suite)
    #expect(Defaults.Keys.cardTextSize.defaultValue == .standard)
    #expect(Defaults[key] == .standard)
    for size in CardTextSize.allCases {
      Defaults[key] = size
      let reloaded = Defaults.Key<CardTextSize>("cardTextSize", default: .standard, suite: suite)
      #expect(Defaults[reloaded] == size)
      #expect(suite.integer(forKey: "cardTextSize") == size.rawValue)
    }
    suite.set(99, forKey: "cardTextSize")
    #expect(Defaults[key] == .standard)
    Defaults.reset(key)
    #expect(Defaults[key] == .standard)
  }
}
