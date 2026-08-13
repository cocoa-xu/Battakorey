import Foundation

struct AutomationRateLimitDecision: Equatable {
    let isAllowed: Bool
    let retryAfterSeconds: Int
}

final class AutomationRateLimiter {
    private let lock = NSLock()
    private var requestsByClient: [String: [TimeInterval]] = [:]

    func evaluate(
        client: String,
        limit: Int,
        now: TimeInterval = Date.timeIntervalSinceReferenceDate
    ) -> AutomationRateLimitDecision {
        lock.withLock {
            let cutoff = now - 60
            requestsByClient = requestsByClient.compactMapValues { timestamps in
                let active = timestamps.filter { $0 > cutoff && $0 <= now }
                return active.isEmpty ? nil : active
            }

            var timestamps = requestsByClient[client] ?? []
            guard timestamps.count < max(limit, 1) else {
                let retryAfter = Int(ceil(max((timestamps.first ?? now) + 60 - now, 1)))
                return AutomationRateLimitDecision(
                    isAllowed: false,
                    retryAfterSeconds: retryAfter
                )
            }

            timestamps.append(now)
            requestsByClient[client] = timestamps
            return AutomationRateLimitDecision(isAllowed: true, retryAfterSeconds: 0)
        }
    }

    func reset() {
        lock.withLock { requestsByClient.removeAll() }
    }
}
