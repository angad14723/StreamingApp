//
//  MetadataDetailView.swift
//  StreamingApp
//
//  Detailed view for displaying video metadata
//

import SwiftUI

struct MetadataDetailView: View {
    let metadata: VideoMetadata
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Hero Image
                if let heroUrl = metadata.images?.hero ?? metadata.images?.poster {
                    AsyncImage(url: URL(string: heroUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(height: 250)
                    .clipped()
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    // Title
                    Text(metadata.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    // Content Type
                    HStack {
                        Image(systemName: "film")
                        Text(metadata.contentType.capitalized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Series Information
                    if let seriesInfo = metadata.seriesInfo {
                        VStack(alignment: .leading, spacing: 8) {
                            Divider()
                            
                            if let seriesName = seriesInfo.seriesName {
                                InfoRow(label: "Series", value: seriesName)
                            }
                            
                            if let season = seriesInfo.seasonNumber {
                                InfoRow(label: "Season", value: "\(season)")
                            }
                            
                            if let episode = seriesInfo.episodeNumber {
                                InfoRow(label: "Episode", value: "\(episode)")
                            }
                        }
                    }
                    
                    // Release Date
                    if let releaseDate = metadata.releaseDate {
                        Divider()
                        InfoRow(label: "Release Date", value: formatDate(releaseDate))
                    }
                    
                    // Content ID
                    Divider()
                    InfoRow(label: "Content ID", value: "\(metadata.id)")
                    
                    // Description
                    if let description = metadata.description {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                            
                            Text(description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Image URLs
                    if let images = metadata.images {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Image URLs")
                                .font(.headline)
                            
                            if let poster = images.poster {
                                ImageURLRow(label: "Poster", url: poster)
                            }
                            
                            if let thumbnail = images.thumbnail {
                                ImageURLRow(label: "Thumbnail", url: thumbnail)
                            }
                            
                            if let hero = images.hero {
                                ImageURLRow(label: "Hero", url: hero)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Metadata")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatDate(_ dateString: String) -> String {
        // Try to parse and format the date
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label + ":")
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct ImageURLRow: View {
    let label: String
    let url: String
    @State private var showingCopiedAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
            
            HStack {
                Text(url)
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Button(action: {
                    UIPasteboard.general.string = url
                    showingCopiedAlert = true
                    
                    // Hide alert after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showingCopiedAlert = false
                    }
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(6)
            
            if showingCopiedAlert {
                Text("Copied!")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
        }
    }
}

#Preview {
    NavigationStack {
        MetadataDetailView(metadata: VideoMetadata(
            id: 1260128382,
            title: "The Night Manager",
            description: "A luxury hotel night manager gets recruited by a government agent to infiltrate an arms dealer's inner circle.",
            contentType: "SERIES",
            releaseDate: "2023-02-17T00:00:00.000Z",
            images: ImageAssets(
                poster: "https://img.hotstar.com/image/upload/f_auto,q_90,w_384/sources/r1/cms/prod/8234/1678234-h-4a0e9e6e1d3e",
                thumbnail: "https://img.hotstar.com/image/upload/f_auto,q_90,w_256/sources/r1/cms/prod/8234/1678234-t-4a0e9e6e1d3e",
                hero: "https://img.hotstar.com/image/upload/f_auto,q_90,w_1920/sources/r1/cms/prod/8234/1678234-h-4a0e9e6e1d3e"
            ),
            seriesInfo: SeriesInfo(
                seriesName: "The Night Manager",
                seasonNumber: 1,
                episodeNumber: nil
            )
        ))
    }
}
