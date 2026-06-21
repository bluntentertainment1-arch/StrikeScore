import Foundation

struct MatchResponse: Codable {
    let matches: [Match]
}

struct Match: Codable, Identifiable {
    let id: Int
    let utcDate: String
    let status: String
    let minute: Int?
    let stage: String?
    let group: String?
    let homeTeam: Team
    let awayTeam: Team
    let score: Score

    var isLive: Bool {
        status == "IN_PLAY" || status == "LIVE"
    }

    var isFinished: Bool {
        status == "FINISHED"
    }

    var displayTime: String {
        if isLive {
            return minute != nil ? "\(minute!)'" : "LIVE"
        } else if isFinished {
            return "FT"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            formatter.timeZone = TimeZone(identifier: "UTC")
            if let date = formatter.date(from: utcDate) {
                formatter.dateFormat = "HH:mm"
                formatter.timeZone = TimeZone.current
                return formatter.string(from: date)
            }
            return "--:--"
        }
    }

    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")
        if let date = formatter.date(from: utcDate) {
            formatter.dateFormat = "EEEE, MMM d"
            formatter.timeZone = TimeZone.current
            return formatter.string(from: date)
        }
        return ""
    }
}

struct Team: Codable {
    let id: Int
    let name: String
    let shortName: String?
    let crest: String?
}

struct Score: Codable {
    let fullTime: ScoreDetail?
    let halfTime: ScoreDetail?
}

struct ScoreDetail: Codable {
    let home: Int?
    let away: Int?

    var displayHome: String {
        home != nil ? "\(home!)" : "-"
    }

    var displayAway: String {
        away != nil ? "\(away!)" : "-"
    }
}
