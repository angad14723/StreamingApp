//
//  SearchView.swift
//  StreamingApp
//
//  Search interface for finding content by title or ID
//

import SwiftUI

struct SearchView: View {
    @StateObject private var api = HotstarAPI()
    @State private var searchText = ""
    @State private var searchResults: [SearchResult] = []
    @State private var selectedMetadata: VideoMetadata?
    @State private var showingDetail = false
    @State private var searchMode: SearchMode = .title
    
    enum SearchMode {
        case title, contentId
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Search Mode Picker
                Picker("Search Mode", selection: $searchMode) {
                    Text("By Title").tag(SearchMode.title)
                    Text("By Content ID").tag(SearchMode.contentId)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Search Input
                HStack {
                    TextField(searchMode == .title ? "Enter video title..." : "Enter content ID...", 
                             text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    
                    Button(action: performSearch) {
                        if api.isLoading {
                            ProgressView()
                                .frame(width: 20, height: 20)
                        } else {
                            Image(systemName: "magnifyingglass")
                        }
                    }
                    .disabled(searchText.isEmpty || api.isLoading)
                }
                .padding(.horizontal)
                
                // Error Message
                if let errorMessage = api.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                // Results List (for title search)
                if searchMode == .title {
                    if searchResults.isEmpty && !api.isLoading && !searchText.isEmpty {
                        ContentUnavailableView(
                            "No Results",
                            systemImage: "magnifyingglass",
                            description: Text("Try a different search term")
                        )
                    } else {
                        List(searchResults) { result in
                            Button(action: {
                                Task {
                                    await fetchAndShowDetail(contentId: String(result.id))
                                }
                            }) {
                                HStack(spacing: 12) {
                                    // Thumbnail
                                    AsyncImage(url: URL(string: result.thumbnail ?? "")) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                    }
                                    .frame(width: 60, height: 90)
                                    .cornerRadius(8)
                                    
                                    // Title and Type
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(result.title)
                                            .font(.headline)
                                            .lineLimit(2)
                                        
                                        Text(result.contentType.capitalized)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Search Hotstar")
            .sheet(isPresented: $showingDetail) {
                if let metadata = selectedMetadata {
                    NavigationStack {
                        MetadataDetailView(metadata: metadata)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("Done") {
                                        showingDetail = false
                                    }
                                }
                            }
                    }
                }
            }
        }
    }
    
    private func performSearch() {
        Task {
            if searchMode == .title {
                await searchByTitle()
            } else {
                await fetchAndShowDetail(contentId: searchText)
            }
        }
    }
    
    private func searchByTitle() async {
        do {
            searchResults = try await api.searchByTitle(searchText)
        } catch {
            print("Search error: \(error)")
        }
    }
    
    private func fetchAndShowDetail(contentId: String) async {
        do {
            selectedMetadata = try await api.fetchMetadata(contentId: contentId)
            showingDetail = true
        } catch {
            print("Fetch error: \(error)")
        }
    }
}

#Preview {
    SearchView()
}
