import Foundation
import EventKit

#if os(macOS)
import Darwin

func getExecutablePath() -> URL? {
    var bufsize = UInt32(PATH_MAX)
    let buf = UnsafeMutablePointer<Int8>.allocate(capacity: Int(bufsize))
    defer { buf.deallocate() }
    let result = _NSGetExecutablePath(buf, &bufsize)
    if result != 0 {
        return nil
    }
    let path = String(cString: buf)
    return URL(fileURLWithPath: path).standardized.deletingLastPathComponent()
}
#else
func getExecutablePath() -> URL? {
    return nil
}
#endif

let store = EKEventStore()
let semaphore = DispatchSemaphore(value: 0)

let defaultDaysToFetch = 1
let daysToFetch: Int = {
    if CommandLine.arguments.count > 1, let arg = Int(CommandLine.arguments[1]), arg > 0 {
        return arg
    }
    return defaultDaysToFetch
}()

func loadAllowedCalendars(from allCalendars: [EKCalendar]) -> [EKCalendar] {
    guard let binaryDir = getExecutablePath() else {
        return allCalendars
    }
    let fileURL = binaryDir.appendingPathComponent("calendars.txt")
    do {
        let contents = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = contents
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let allowed = Set(lines)
        let selected = allCalendars.filter { allowed.contains($0.title) }
        if selected.isEmpty {
            return allCalendars
        }
        return selected
    } catch {
        return allCalendars
    }
}

func conferenceURL(_ event: EKEvent) -> String {
    let urlPattern = "https?://[^\\s<>\"]+"
    let providers = ["zoom.us", "meet.google.com", "teams.microsoft.com", "webex.com",
                     "officehours.com", "meet.jit.si", "whereby.com", "around.co", "gather.town"]

    var candidates: [String] = []
    if let u = event.url?.absoluteString { candidates.append(u) }
    for field in [event.location, event.notes] {
        guard let text = field else { continue }
        var searchRange = text.startIndex..<text.endIndex
        while let r = text.range(of: urlPattern, options: .regularExpression, range: searchRange) {
            candidates.append(String(text[r]))
            searchRange = r.upperBound..<text.endIndex
        }
    }

    for c in candidates {
        for p in providers where c.contains(p) { return c }
    }
    if let u = event.url?.absoluteString { return u }
    return ""
}

func fetchEvents() {
    let allCalendars = store.calendars(for: .event)
    let selectedCalendars = loadAllowedCalendars(from: allCalendars)
    if selectedCalendars.isEmpty {
        return
    }

    let now = Date()
    var calendar = Calendar.current
    calendar.locale = Locale(identifier: "en_US_POSIX")

    if let targetDay = calendar.date(byAdding: .day, value: daysToFetch - 1, to: now),
        let endOfTargetDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: targetDay) {

        let predicate = store.predicateForEvents(withStart: now, end: endOfTargetDay, calendars: selectedCalendars)
        let events = store.events(matching: predicate).sorted { $0.startDate < $1.startDate }

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        for event in events where event.endDate > now {
            if event.isAllDay { continue }
            let startTime = timeFormatter.string(from: event.startDate)
            let endTime = timeFormatter.string(from: event.endDate)
            let dateString = dateFormatter.string(from: event.startDate)
            let title = (event.title ?? "(No Title)")
                .replacingOccurrences(of: "\u{00A0}", with: " ")
                .replacingOccurrences(of: "\u{2013}", with: "-")
            let link = conferenceURL(event)
            print("\(dateString) \(startTime)-\(endTime) | \(title) | \(link)")
        }
    }
}

if #available(macOS 14.0, *) {
    store.requestFullAccessToEvents { granted, _ in
        if granted {
            fetchEvents()
        } else {
            FileHandle.standardError.write("calendar access denied\n".data(using: .utf8)!)
        }
        semaphore.signal()
    }
} else {
    store.requestAccess(to: .event) { granted, _ in
        if granted {
            fetchEvents()
        }
        semaphore.signal()
    }
}

_ = semaphore.wait(timeout: .distantFuture)
