//
//  Models.swift
//  StreamingApp
//
//  Data models for Hotstar API responses
//

import Foundation

// MARK: - Video Metadata
struct VideoMetadata: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String?
    let contentType: String
    let releaseDate: String?
    let images: ImageAssets?
    let seriesInfo: SeriesInfo?
    
    enum CodingKeys: String, CodingKey {
        case id = "contentId"
        case title
        case description
        case contentType
        case releaseDate
        case images = "imageAssets"
        case seriesInfo
    }
}

// MARK: - Series Information
struct SeriesInfo: Codable {
    let seriesName: String?
    let seasonNumber: Int?
    let episodeNumber: Int?
    
    enum CodingKeys: String, CodingKey {
        case seriesName
        case seasonNumber
        case episodeNumber
    }
}

// MARK: - Image Assets
struct ImageAssets: Codable {
    let poster: String?
    let thumbnail: String?
    let hero: String?
    
    var allImages: [String] {
        [poster, thumbnail, hero].compactMap { $0 }
    }
}

// MARK: - Search Response
struct SearchResponse: Codable {
    let results: [SearchResult]
    
    enum CodingKeys: String, CodingKey {
        case results = "body"
    }
}

struct SearchResult: Codable, Identifiable {
    let id: Int
    let title: String
    let contentType: String
    let thumbnail: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "contentId"
        case title
        case contentType
        case thumbnail = "imageUrl"
    }
}

// MARK: - Content Detail Response
struct ContentDetailResponse: Codable {
    let body: ContentBody
}

struct ContentBody: Codable {
    let results: ContentResults
}

struct ContentResults: Codable {
    let item: ContentItem
}

struct ContentItem: Codable {
    let contentId: Int
    let title: String
    let description: String?
    let assetType: String
    let startDate: String?
    let images: [ImageItem]?
    let showName: String?
    let seasonNo: Int?
    let episodeNo: Int?
    
    func toVideoMetadata() -> VideoMetadata {
        let imageAssets = ImageAssets(
            poster: images?.first(where: { $0.imageType == "POSTER" })?.url,
            thumbnail: images?.first(where: { $0.imageType == "THUMBNAIL" })?.url,
            hero: images?.first(where: { $0.imageType == "HERO" })?.url
        )
        
        let seriesInfo = (showName != nil || seasonNo != nil || episodeNo != nil) ? SeriesInfo(
            seriesName: showName,
            seasonNumber: seasonNo,
            episodeNumber: episodeNo
        ) : nil
        
        return VideoMetadata(
            id: contentId,
            title: title,
            description: description,
            contentType: assetType,
            releaseDate: startDate,
            images: imageAssets,
            seriesInfo: seriesInfo
        )
    }
}

struct ImageItem: Codable {
    let imageType: String
    let url: String
}

// MARK: - BFF API Response Models

/// Top-level response from BFF API
struct BFFSearchResponse: Codable {
    let success: BFFSuccess?
}

struct BFFSuccess: Codable {
    let page: BFFPage
}

struct BFFPage: Codable {
    let spaces: BFFSpaces
}

struct BFFSpaces: Codable {
    let headerTray: BFFHeaderTray?
    
    enum CodingKeys: String, CodingKey {
        case headerTray = "header_tray"
    }
}

struct BFFHeaderTray: Codable {
    let widgetWrappers: [BFFWidgetWrapper]?
    
    enum CodingKeys: String, CodingKey {
        case widgetWrappers = "widget_wrappers"
    }
}

struct BFFWidgetWrapper: Codable {
    let widget: BFFWidget
}

struct BFFWidget: Codable {
    let data: BFFWidgetData
}

struct BFFWidgetData: Codable {
    let title: String?
    let contentInfo: [String]?
    let image: BFFImage?
    let primaryCta: BFFPrimaryCta?
    
    enum CodingKeys: String, CodingKey {
        case title
        case contentInfo = "content_info"
        case image
        case primaryCta = "primary_cta"
    }
    
    /// Convert BFF widget data to SearchResult
    func toSearchResult() -> SearchResult? {
        guard let title = title,
              let contentId = extractContentId() else {
            return nil
        }
        
        let thumbnail = image?.src.flatMap { "https://img10.hotstar.com/image/upload/f_auto/\($0)" }
        let contentType = contentInfo?.first ?? "unknown"
        
        return SearchResult(
            id: contentId,
            title: title,
            contentType: contentType,
            thumbnail: thumbnail
        )
    }
    
    /// Extract content ID from the page navigation URL
    private func extractContentId() -> Int? {
        guard let pageUrl = primaryCta?.actions?.onClick?.first?.pageNavigation?.pageUrl else {
            return nil
        }
        
        // Extract content_id from URL like "/v2/pages/watch?content_id=1260128382"
        if let range = pageUrl.range(of: "content_id="),
           let endRange = pageUrl[range.upperBound...].range(of: "&") {
            let idString = String(pageUrl[range.upperBound..<endRange.lowerBound])
            return Int(idString)
        } else if let range = pageUrl.range(of: "content_id=") {
            let idString = String(pageUrl[range.upperBound...])
            return Int(idString)
        }
        
        return nil
    }
}

struct BFFImage: Codable {
    let src: String?
}

struct BFFPrimaryCta: Codable {
    let actions: BFFActions?
}

struct BFFActions: Codable {
    let onClick: [BFFOnClick]?
    
    enum CodingKeys: String, CodingKey {
        case onClick = "on_click"
    }
}

struct BFFOnClick: Codable {
    let pageNavigation: BFFPageNavigation?
    
    enum CodingKeys: String, CodingKey {
        case pageNavigation = "page_navigation"
    }
}

struct BFFPageNavigation: Codable {
    let pageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case pageUrl = "page_url"
    }
}
