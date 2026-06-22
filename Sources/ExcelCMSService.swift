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
        
        AppLogger.shared.log("Featured CSV raw (first 500 chars): \(String(csvString.prefix(500)))")

        return parseFeaturedMatches(csv: csvString)
    }

    func fetchEditorial() async throws -> [EditorialItem] {
        guard let url = URL(string: AppConfig.excelEditorialURL) else {
            throw CMSParseError.invalidData
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let csvString = String(data: data, encoding: .utf8) ?? ""
        
        AppLogger.shared.log("Editorial CSV raw (first 500 chars): \(String(csvString.prefix(500)))")

        return parseEditorial(csv: csvString)
    }

    private func parseFeaturedMatches(csv: String) -> [FeaturedMatch] {
        var results: [FeaturedMatch] = []
        let rows = csv.components(separatedBy: CharacterSet.newlines)

        guard rows.count > 1 else { 
            AppLogger.shared.log("ERROR: Featured CSV only has \(rows.count) rows")
            return results 
        }

        AppLogger.shared.log("Featured CSV header: \(rows[0])")
        AppLogger.shared.log("Featured CSV total rows: \(rows.count)")

        for i in 1..<rows.count {
            let row = rows[i].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !row.isEmpty else { continue }

            let columns = parseCSVRow(row)
            
            guard columns.count >= 16 else { 
                AppLogger.shared.log("WARNING: Row \(i) has only \(columns.count) columns, skipping. Content: \(row)")
                continue 
            }

            let match = FeaturedMatch(
                id: columns[0],
                homeTeam: columns[1],
                awayTeam: columns[2],
                homeFlag: columns[3],
                awayFlag: columns[4],
                competition: columns[5],
                matchDate: columns[6],
                matchTime: columns[7],
                venue: columns[8],
                group: columns[9],
                stage: columns[10],
                homeScore: columns[11],
                awayScore: columns[12],
                status: columns[13],
                isLive: columns[14].lowercased() == "true",
                priority: Int(columns[15]) ?? 0,
                active: columns.count > 16 ? columns[16].lowercased() == "true" : true
            )

            if match.isVisible {
                results.append(match)
                AppLogger.shared.log("Added featured match: \(match.homeTeam) vs \(match.awayTeam)")
            }
        }

        return results.sorted { $0.priority < $1.priority }
    }

    private func parseEditorial(csv: String) -> [EditorialItem] {
        var results: [EditorialItem] = []
        let rows = csv.components(separatedBy: CharacterSet.newlines)

        guard rows.count > 1 else { 
            AppLogger.shared.log("ERROR: Editorial CSV only has \(rows.count) rows")
            return results 
        }

        AppLogger.shared.log("Editorial CSV header: \(rows[0])")

        for i in 1..<rows.count {
            let row = rows[i].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !row.isEmpty else { continue }

            let columns = parseCSVRow(row)
            // Now requires 6 columns: id,headline,body,fullContent,datePosted,active
            guard columns.count >= 6 else { 
                AppLogger.shared.log("WARNING: Editorial row \(i) has only \(columns.count) columns, skipping")
                continue 
            }

            let item = EditorialItem(
                id: columns[0],
                headline: columns[1],
                body: columns[2],
                fullContent: columns[3],
                datePosted: columns[4],
                active: columns[5].lowercased() == "true"
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
            if char == "\"" {
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
