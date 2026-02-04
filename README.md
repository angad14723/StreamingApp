# Metadata Retrieval App (For Education Purpose)

An iOS SwiftUI application that retrieves video metadata from a streaming service using reverse-engineered non-public APIs.

## Features

- 🔍 **Search by Title**: Find content by entering video/show titles
- 🆔 **Lookup by ID**: Direct metadata fetch using content ID
- 📊 **Rich Metadata Display**: View title, description, series info, release dates, and images
- 🖼️ **Image URLs**: Copy poster, thumbnail, and hero image URLs
- ⚡ **Fast & Responsive**: Modern SwiftUI interface with async/await

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Installation

1. Clone or download this repository
2. Open `StreamingApp.xcodeproj` in Xcode
3. Select a simulator or connected device
4. Press `Cmd+R` to build and run

## Usage

### Search by Title

1. Launch the app
2. Ensure "By Title" is selected
3. Enter a video or show name (e.g., "The Night Manager")
4. Tap the search button
5. Browse results and tap to view details

### Lookup by Content ID

1. Switch to "By Content ID" tab
2. Enter a Hotstar content ID (e.g., `1260128382`)
3. Tap search to view metadata directly

## API Endpoints

The app uses Hotstar's internal BFF (Backend For Frontend) APIs:

- **Search**: `https://www.****.com/api/internal/bff/v2/pages/search?search_query={query}`
- **Content**: `https://www.****.com/api/internal/bff/v2/pages/watch?content_id={id}`

> **Note**: These are non-public BFF APIs designed for the web frontend. The response structure is deeply nested and contains UI-specific data. The app extracts only the relevant metadata fields.

### Authentication

The API requires authentication via the `x-hs-usertoken` header (JWT token). The app uses a guest token extracted from the browser session. 

**Important**: The guest token expires after approximately 24 hours. For production use, implement proper token refresh logic.

## Project Structure

```
StreamingApp/
├── Models.swift              # Data models (VideoMetadata, SearchResult, etc.)
├── StreamingAPI.swift          # API client with search and fetch methods
├── SearchView.swift          # Main search interface
├── MetadataDetailView.swift  # Detailed metadata display
└── ContentView.swift         # Root view
```

## Example

**Search**: "The Night Manager"

**Result**:
- Title: The Night Manager
- Type: SERIES
- Season: 1
- Release Date: Feb 17, 2023
- Description: A luxury hotel night manager gets recruited...
- Images: Poster, Thumbnail, Hero URLs

## Notes

- This app uses **non-public APIs** that may change without notice
- Authentication headers are hardcoded for demonstration
- No API keys required
- For educational purposes only

## License

This is a demonstration project for educational purposes.
