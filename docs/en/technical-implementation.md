Technical Design Document (TDD): PromptPal for macOS
Version: 2.0
Date: June 11, 2025
Related Document: Product Requirement Document (PRD) v2.0

1. Overview

This document aims to provide a comprehensive technical implementation blueprint for the PromptPal for macOS application. Based on the features and goals defined in the Product Requirement Document (PRD), it elaborates on the system architecture, technology choices, data model design, and implementation strategies for core functionalities.

2. System Architecture

To ensure code clarity, maintainability, and testability, we will adopt the MVVM (Model-View-ViewModel) architecture. This architecture is highly suitable for development with SwiftUI.

*   **Model:** Responsible for the application's data and business logic. In this project, this role will be fulfilled by SwiftData models, which will define data structures like `Prompt` and `Category`, and handle all data persistence, iCloud sync, and query logic.
*   **View:** Responsible for UI presentation. It will be built entirely with SwiftUI, defining the user interface in a declarative way. The View itself contains no business logic; it only renders data and passes user actions to the ViewModel.
*   **ViewModel:** Acts as a bridge between the View and the Model. It fetches data from the Model and transforms it into a format that the View can directly display. It also handles user interactions from the View (like button clicks, text input) and calls the appropriate methods on the Model to update the data.

Architecture Diagram:

```
┌─────────────────┐      ┌──────────────────┐      ┌──────────────────┐
│      View       │◀─────▶│    ViewModel     │◀─────▶│      Model       │
│    (SwiftUI)    │      │   (Observable)   │      │   (SwiftData)    │
└─────────────────┘      └──────────────────┘      └──────────────────┘
        │                        │                         ▲
 User   │                        │ Data & Logic            │ Data Persistence
Interactions                     │                         │ & iCloud Sync
────────│───────────────────────>│                         │
        └───────────────────────>│
```

3. Core Technology Stack

*   **Language:** Swift 5.9+
    *   **Reason:** The official language for Apple's ecosystem, featuring modern syntax, strong performance, and safety.
*   **UI Framework:** SwiftUI
    *   **Reason:** Apple's recommended modern UI framework. Its declarative syntax significantly improves development efficiency. Its cross-platform capabilities lay the foundation for future expansion to iOS/iPadOS.
*   **Data Persistence & Sync:** SwiftData
    *   **Reason:** A new framework introduced by Apple at WWDC23 to simplify data persistence. It is built on Core Data but provides a cleaner, macro-based API in Swift. Most importantly, it natively and seamlessly integrates with CloudKit, enabling iCloud sync functionality at a very low cost.
*   **App Life Cycle:** SwiftUI App Life Cycle
    *   **Reason:** Managing the app life cycle in a pure SwiftUI way results in more unified and concise code.

4. Data Model Design

We will use SwiftData's `@Model` macro to define the core data models.

4.1. Prompt Model

```swift
import SwiftData

@Model
final class Prompt {
    var id: UUID
    var title: String
    var promptDescription: String
    var userPrompt: String
    var category: Category?
    var tags: [String]
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date
    var usageCount: Int

    init(
        title: String,
        description: String,
        userPrompt: String,
        category: Category? = nil,
        tags: [String] = [],
        isFavorite: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.promptDescription = description
        self.userPrompt = userPrompt
        self.category = category
        self.tags = tags
        self.isFavorite = isFavorite
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
        self.usageCount = 0
    }
}
```

*   `id`: Unique identifier for data relationships.
*   `title`, `promptDescription`, `userPrompt`: Core data fields.
*   `createdAt`, `updatedAt`: For sorting and version control.
*   `isFavorite`: Implements the favorites feature.
*   `category`: Defines the relationship with the `Category` model.
*   `tags`: An array of strings to store relevant tags.
*   `usageCount`: Records usage frequency for statistical analysis.

4.2. Category Model

```swift
import SwiftData

@Model
final class Category: Identifiable {
    var id: UUID
    var name: String
    var color: String
    var iconName: String
    var isDefault: Bool
    var createdAt: Date

    init(name: String, color: String = "blue", iconName: String = "folder", isDefault: Bool = false) {
        self.id = UUID()
        self.name = name
        self.color = color
        self.iconName = iconName
        self.isDefault = isDefault
        self.createdAt = Date()
    }
}
```

*   `name`: The name of the category.
*   `color`: The display color for the category.
*   `iconName`: The icon name for the category.
*   `isDefault`: Indicates if it is a default category.
*   `createdAt`: The creation timestamp.

5. Key Feature Implementation

5.1. Standard macOS App Architecture

*   **App Type:** A standard macOS desktop application using SwiftUI's `WindowGroup`.
*   **Window Management:**
    *   The main window uses `WindowGroup`, supporting standard macOS window operations.
    *   The settings window uses the `Settings` scene, conforming to macOS design guidelines.
    *   Supports `.windowResizability(.contentSize)` to optimize window size.
*   **Menu Bar Integration:**
    *   Use `Commands` to customize the application menu.
    *   Implement shortcut support, such as `⌘N` for New and `⌘F` for Search.
    *   Use `NotificationCenter` for communication between the menu and views.

5.2. Live Search

*   In SwiftUI views, use the `@Query` property wrapper to fetch SwiftData objects.
    ```swift
    @Query private var prompts: [Prompt]
    @Query private var categories: [Category]
    ```
*   Define an `@State` variable in the View to bind to the search field's text, e.g., `@State private var searchText = ""`.
*   Create a computed property to filter the `prompts` array based on the `searchText`.
    ```swift
    private var filteredPrompts: [Prompt] {
        var filtered = prompts
        
        // Filter by category
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category?.id == category.id }
        }
        
        // Show only favorites
        if showingOnlyFavorites {
            filtered = filtered.filter { $0.isFavorite }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { prompt in
                prompt.title.localizedCaseInsensitiveContains(searchText) ||
                prompt.promptDescription.localizedCaseInsensitiveContains(searchText) ||
                prompt.tags.joined(separator: " ").localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered.sorted { $0.createdAt > $1.createdAt }
    }
    ```
*   The `List` view will iterate over this `filteredPrompts` computed property to display the results. SwiftUI's reactive nature ensures the list updates automatically when conditions change.

5.3. Category Management System

*   **Category Creation:** Users can create new categories via `AddCategoryView`.
*   **Category Editing:** Modify existing category properties through `EditCategoryView`.
*   **Category Deletion:** Implement a smart delete check to prevent deleting categories that contain prompts.
*   **Category Filtering:** Provide a list of categories in the sidebar; clicking one filters the corresponding prompts.

5.4. Favorites System

*   **Data Model:** The `isFavorite` boolean field in the `Prompt` model.
*   **UI Implementation:**
    *   Provide a favorite button on the `Prompt` card.
    *   A dedicated "Favorites" view in the sidebar.
    *   Display the number of prompts in the Favorites.
*   **Filtering Logic:** Controlled by the `showingOnlyFavorites` state variable.

5.5. iCloud Sync (UI Implemented, Configuration Needed)

*   **Project Configuration:** In Xcode's "Signing & Capabilities," add the "iCloud" capability and check "CloudKit."
*   **SwiftData Configuration:** When creating the `ModelContainer`, specify the CloudKit configuration.
    ```swift
    let schema = Schema([Prompt.self, Category.self])
    let cloudConfiguration = ModelConfiguration(
        "CloudStore", 
        schema: schema, 
        isStoredInMemoryOnly: false, 
        allowsSave: true, 
        cloudKitDatabase: .private("iCloud.com.yourcompany.PromptPal")
    )

    let container = try ModelContainer(for: schema, configurations: [cloudConfiguration])
    ```
*   **Settings UI:** An iCloud sync toggle has been implemented, allowing users to enable or disable synchronization.

5.6. Internationalization

*   **Implementation:**
    *   Use a `.localized` extension method to get localized strings.
    *   Support for languages like Simplified Chinese and English.
    *   Manage language switching logic in `LocalizationManager`.
*   **Resource Files:**
    *   `PromptPal/Resources/en.lproj/Localizable.strings`
    *   `PromptPal/Resources/zh-Hans.lproj/Localizable.strings`

5.7. Parameterized Prompts (To Be Implemented)

*   **Placeholder Definition:** Define a placeholder format, e.g., `{{variable_name}}`.
*   **Parsing:** When a user selects a prompt to copy, use a regular expression to extract all `{{...}}` placeholders from `prompt.userPrompt`.
    ```swift
    let regex = try! NSRegularExpression(pattern: "\\{\\{(.+?)\\}\\}")
    ```
*   **Dynamic UI Generation:** Dynamically generate a form view based on the parsed list of placeholders.
*   **Substitution & Copying:** Replace the placeholders with user input and then copy the result to the system clipboard.

6. Future Feature Outlook

6.1. Prompt Generation

*   **Goal:** Integrate an AI model to intelligently generate prompts based on user input.
*   **Technical Challenge:** Requires calling third-party AI service APIs and processing/displaying the results.

6.2. Prompt Testing

*   **Goal:** Provide a testing environment to quickly validate prompt effectiveness.
*   **Technical Challenge:** May require integrating APIs from multiple models and designing a clear comparative testing interface.

7. Deployment & Distribution

*   **Channel:** Mac App Store
*   **Requirements:** Requires enrollment in the Apple Developer Program. The application must be sandboxed and adhere to the App Store Review Guidelines.
*   **Current Configuration:** The app is configured with basic sandboxing permissions, supporting user-selected read-only file access. 