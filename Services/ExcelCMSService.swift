import Foundation

class ExcelCMSService {
    static let shared = ExcelCMSService()

    enum CMSParseError: Error {
        case invalidData
        case parseFailed
    }

    func fetchFeaturedMatches() async throws -> [FeaturedMatch] {
        guard let url = URL(string: AppConfig.excelFeaturedURL) else {
            throw CMSParseError.invalidData
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let csvString = String(data: data, encoding: .utf8) ?? ""

        return parseFeaturedMatches(csv: csvString)
    }

    func fetchEditorial() async throws -> [EditorialItem] {
        guard let url = URL(string: AppConfig.excelEditorialURL) else {
            throw CMSParseError.invalidData
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let csvString = String(data: data, encoding: .utf8) ?? ""

        return parseEditorial(csv: csvString)
    }

    private func parseFeaturedMatches(csv: String) -> [FeaturedMatch] {
        var results: [FeaturedMatch] = []
        let rows = csv.components(separatedBy: "\n")

        guard rows.count > 1 else { return results }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"

        for i in 1..<rows.count {
            let row = rows[i].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !row.isEmpty else { continue }

            let columns = parseCSVRow(row)
            guard columns.count >= 10 else { continue }

            let showUntil = dateFormatter.date(from: columns[8]) ?? Date.distantFuture

            let match = FeaturedMatch(
                id: columns[0],
                competition: columns[1],
                homeTeam: columns[2],
                awayTeam: columns[3],
                matchDate: columns[4],
                headline: columns[5],
                subheadline: columns[6],
                priority: Int(columns[7]) ?? 0,
                showUntil: showUntil,
                active: columns[9].lowercased() == "true"
            )

            if match.isVisible {
                results.append(match)
            }
        }

        return results.sorted { $0.priority < $1.priority }
    }

    private func parseEditorial(csv: String) -> [EditorialItem] {
        var results: [EditorialItem] = []
        let rows = csv.components(separatedBy: "\n")

        guard rows.count > 1 else { return results }

        for i in 1..<rows.count {
            let row = rows[i].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !row.isEmpty else { continue }

            let columns = parseCSVRow(row)
            guard columns.count >= 5 else { continue }

            let item = EditorialItem(
                id: columns[0],
                headline: columns[1],
                body: columns[2],
                datePosted: columns[3],
                active: columns[4].lowercased() == "true"
            )

            if item.active {
                results.append(item)
            }
        }

        return results
    }

    private func parseCSVRow(_ row: String) -> [String] {
        var result: [String] = []
        var current = ""
        var insideQuotes = false

        for char in row {
            if char == """ {
                insideQuotes = !insideQuotes
            } else if char == "," && !insideQuotes {
                result.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        result.append(current)

        return result.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
}
