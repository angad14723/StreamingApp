//
//  HotstarAPI.swift
//  StreamingApp
//
//  API client for Hotstar reverse-engineered endpoints
//

import Foundation
import Combine

enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case notFound
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .notFound:
            return "Content not found"
        case .serverError(let code):
            return "Server error: \(code)"
        }
    }
}

@MainActor
class HotstarAPI: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let baseURL = "https://www.hotstar.com/api/internal/bff/v2/pages"
    
    // Authentication token (guest token)
    private var userToken: String?
    private let deviceId = UUID().uuidString
    
    // Headers mimicking browser requests with authentication
    private var defaultHeaders: [String: String] {
        var headers = [
            "Accept": "application/json",
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
            "x-country-code": "in",
            "x-hs-platform": "ios",
            "x-hs-device-id": deviceId,
            "x-request-id": UUID().uuidString
        ]
        
        if let token = userToken {
            headers["x-hs-usertoken"] = token
        }
        
        return headers
    }
    
    // Initialize with guest token
    init() {
        // Guest token extracted from browser (expires ~24 hours)
        self.userToken = "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ7XCJoSWRcIjpcIjNiOTEyMjg3Nzg1MzQwYzY4ZWVlNjZkZjUxNjcyOWU5XCIsXCJwSWRcIjpcIjA0ZWIwM2IzN2VmOTRiZWJhOWZiZmM4NTU2MGJjMTg5XCIsXCJkd0hpZFwiOlwiZTA0NGE0NDRmYmMzZWY0M2YyOGQ1MjhlYTQwMzg0OWRjMjM1ODhhMDYzNDE5NDg1MmQ5YjkxZmYzZjkzMzRlOFwiLFwiZHdQaWRcIjpcIjcwY2Q0MzgyNjI3ZDc3ZjVmMDdkNDIwYzZhZDI2MjMxYTk1OTZlZWFlNzY0ODc1MjVhNDFlOTNlM2NlZjI5ODRcIixcIm9sZEhpZFwiOlwiM2I5MTIyODc3ODUzNDBjNjhlZWU2NmRmNTE2NzI5ZTlcIixcIm9sZFBpZFwiOlwiMDRlYjAzYjM3ZWY5NGJlYmE5ZmJmYzg1NTYwYmMxODlcIixcImlzUGlpVXNlck1pZ3JhdGVkXCI6ZmFsc2UsXCJuYW1lXCI6XCJZb3VcIixcImlwXCI6XCIxODIuNzQuMTI4LjI1MlwiLFwiY291bnRyeUNvZGVcIjpcImluXCIsXCJjdXN0b21lclR5cGVcIjpcIm51XCIsXCJ0eXBlXCI6XCJndWVzdFwiLFwiaXNFbWFpbFZlcmlmaWVkXCI6ZmFsc2UsXCJpc1Bob25lVmVyaWZpZWRcIjpmYWxzZSxcImRldmljZUlkXCI6XCI3MzdmOTctMzY2YmE0LTZiYjQ0Yi0xZTU1MGZcIixcInByb2ZpbGVcIjpcIkFEVUxUXCIsXCJ2ZXJzaW9uXCI6XCJ2MlwiLFwic3Vic2NyaXB0aW9uc1wiOntcImluXCI6e319LFwiaXNzdWVkQXRcIjoxNzcwMTc5ODUyMjEwLFwiZHBpZFwiOlwiMDRlYjAzYjM3ZWY5NGJlYmE5ZmJmYzg1NTYwYmMxODlcIixcInN0XCI6MSxcImRhdGFcIjpcIkNnUUlBRG9BQ2d3SUFDSUlrQUdtNzhPM3dqTUtCQWdBUWdBS0JBZ0FLZ0FLQkFnQU1nQUtCQWdBRWdBPVwifSIsImlzcyI6IlVNIiwiZXhwIjoxNzcwMjY2MjUyLCJqdGkiOiJiMDViM2M5Zjc0ODc0YzExYWE2OGZmNGQxZTFhYjY1ZiIsImlhdCI6MTc3MDE3OTg1MiwiYXBwSWQiOiIiLCJ0ZW5hbnQiOiIiLCJ2ZXJzaW9uIjoiMV8wIiwiYXVkIjoidW1fYWNjZXNzIn0.ldbbYICNbRHuzqVBP-_ZK3iiiR31Hwj5ANzK_A2wgK8"
    }
    
    // MARK: - Search by Title
    func searchByTitle(_ query: String) async throws -> [SearchResult] {
        guard !query.isEmpty else { return [] }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        // BFF search endpoint
        let urlString = "\(baseURL)/search?search_query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        defaultHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                // Try to decode the BFF response
                let decoder = JSONDecoder()
                do {
                    let bffResponse = try decoder.decode(BFFSearchResponse.self, from: data)
                    return parseBFFSearchResults(from: bffResponse)
                } catch {
                    // Fallback to manual parsing
                    if let results = try? parseBFFSearchResultsManually(from: data) {
                        return results
                    }
                    throw APIError.decodingError(error)
                }
            case 404:
                throw APIError.notFound
            default:
                throw APIError.serverError(httpResponse.statusCode)
            }
        } catch let error as APIError {
            errorMessage = error.errorDescription
            throw error
        } catch {
            let apiError = APIError.networkError(error)
            errorMessage = apiError.errorDescription
            throw apiError
        }
    }
    
    // MARK: - Fetch by Content ID
    func fetchMetadata(contentId: String) async throws -> VideoMetadata {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        // BFF content detail endpoint
        let urlString = "\(baseURL)/watch?content_id=\(contentId)"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        defaultHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                let decoder = JSONDecoder()
                do {
                    let detailResponse = try decoder.decode(ContentDetailResponse.self, from: data)
                    return detailResponse.body.results.item.toVideoMetadata()
                } catch {
                    // Try alternative parsing
                    if let metadata = try? parseContentMetadata(from: data) {
                        return metadata
                    }
                    throw APIError.decodingError(error)
                }
            case 404:
                throw APIError.notFound
            default:
                throw APIError.serverError(httpResponse.statusCode)
            }
        } catch let error as APIError {
            errorMessage = error.errorDescription
            throw error
        } catch {
            let apiError = APIError.networkError(error)
            errorMessage = apiError.errorDescription
            throw apiError
        }
    }
    
    // MARK: - Helper Methods
    
    /// Parse BFF search response into SearchResult array
    private func parseBFFSearchResults(from response: BFFSearchResponse) -> [SearchResult] {
        guard let widgetWrappers = response.success?.page.spaces.headerTray?.widgetWrappers else {
            return []
        }
        
        return widgetWrappers.compactMap { wrapper in
            wrapper.widget.data.toSearchResult()
        }
    }
    
    /// Manually parse BFF search results from raw JSON data
    private func parseBFFSearchResultsManually(from data: Data) throws -> [SearchResult] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? [String: Any],
              let page = success["page"] as? [String: Any],
              let spaces = page["spaces"] as? [String: Any],
              let headerTray = spaces["header_tray"] as? [String: Any],
              let widgetWrappers = headerTray["widget_wrappers"] as? [[String: Any]] else {
            return []
        }
        
        var results: [SearchResult] = []
        
        for wrapper in widgetWrappers {
            guard let widget = wrapper["widget"] as? [String: Any],
                  let data = widget["data"] as? [String: Any],
                  let title = data["title"] as? String else {
                continue
            }
            
            // Extract content ID from primary_cta
            var contentId: Int?
            if let primaryCta = data["primary_cta"] as? [String: Any],
               let actions = primaryCta["actions"] as? [String: Any],
               let onClick = actions["on_click"] as? [[String: Any]],
               let firstClick = onClick.first,
               let pageNav = firstClick["page_navigation"] as? [String: Any],
               let pageUrl = pageNav["page_url"] as? String {
                contentId = extractContentIdFromUrl(pageUrl)
            }
            
            guard let id = contentId else { continue }
            
            // Extract thumbnail
            var thumbnail: String?
            if let image = data["image"] as? [String: Any],
               let src = image["src"] as? String {
                thumbnail = "https://img1.hotstar.com/\(src)"
            }
            
            // Extract content type from content_info
            let contentType: String
            if let contentInfo = data["content_info"] as? [String],
               let firstInfo = contentInfo.first {
                contentType = firstInfo
            } else {
                contentType = "unknown"
            }
            
            results.append(SearchResult(
                id: id,
                title: title,
                contentType: contentType,
                thumbnail: thumbnail
            ))
        }
        
        return results
    }
    
    /// Extract content ID from URL string
    private func extractContentIdFromUrl(_ url: String) -> Int? {
        if let range = url.range(of: "content_id="),
           let endRange = url[range.upperBound...].range(of: "&") {
            let idString = String(url[range.upperBound..<endRange.lowerBound])
            return Int(idString)
        } else if let range = url.range(of: "content_id=") {
            let idString = String(url[range.upperBound...])
            return Int(idString)
        }
        return nil
    }
    
    private func parseSearchResults(from results: [[String: Any]]) throws -> [SearchResult] {
        var searchResults: [SearchResult] = []
        
        for result in results {
            if let contentId = result["contentId"] as? Int,
               let title = result["title"] as? String,
               let contentType = result["assetType"] as? String {
                let thumbnail = result["imageUrl"] as? String
                searchResults.append(SearchResult(
                    id: contentId,
                    title: title,
                    contentType: contentType,
                    thumbnail: thumbnail
                ))
            }
        }
        
        return searchResults
    }
    
    private func parseContentMetadata(from data: Data) throws -> VideoMetadata {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let body = json["body"] as? [String: Any],
              let results = body["results"] as? [String: Any],
              let item = results["item"] as? [String: Any],
              let contentId = item["contentId"] as? Int,
              let title = item["title"] as? String else {
            throw APIError.invalidResponse
        }
        
        let description = item["description"] as? String
        let contentType = item["assetType"] as? String ?? "unknown"
        let releaseDate = item["startDate"] as? String
        
        // Parse images
        var imageAssets: ImageAssets?
        if let images = item["images"] as? [[String: Any]] {
            let poster = images.first(where: { $0["imageType"] as? String == "POSTER" })?["url"] as? String
            let thumbnail = images.first(where: { $0["imageType"] as? String == "THUMBNAIL" })?["url"] as? String
            let hero = images.first(where: { $0["imageType"] as? String == "HERO" })?["url"] as? String
            imageAssets = ImageAssets(poster: poster, thumbnail: thumbnail, hero: hero)
        }
        
        // Parse series info
        var seriesInfo: SeriesInfo?
        if let showName = item["showName"] as? String {
            seriesInfo = SeriesInfo(
                seriesName: showName,
                seasonNumber: item["seasonNo"] as? Int,
                episodeNumber: item["episodeNo"] as? Int
            )
        }
        
        return VideoMetadata(
            id: contentId,
            title: title,
            description: description,
            contentType: contentType,
            releaseDate: releaseDate,
            images: imageAssets,
            seriesInfo: seriesInfo
        )
    }
}
