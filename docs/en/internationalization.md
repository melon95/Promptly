# PromptPal Internationalization Feature Implementation

## Overview

PromptPal now supports multi-language internationalization to provide a localized user experience for global users.

## Supported Languages

| Language          | Language Code | Status    |
| ----------------- | ------------- | --------- |
| English           | `en`          | ✅ Complete |
| Simplified Chinese| `zh-Hans`     | ✅ Complete |

## Implementation Architecture

### Core Components

1.  **LocalizationManager**
    -   Singleton pattern to manage the current language setting.
    -   Supports runtime language switching.
    -   Automatically saves user language preferences.

2.  **String Extensions**
    -   Provides convenient localization methods.
    -   Supports parameterized strings.
    -   Integrated with SwiftUI `Text` views.

3.  **Localization File Structure**
    ```
    PromptPal/Resources/
    ├── en.lproj/Localizable.strings      # English
    └── zh-Hans.lproj/Localizable.strings # Simplified Chinese
    ```

### Usage

#### In Swift Code

```swift
// Basic usage
let title = "app.name".localized

// With parameters
let message = "search.results".localized(with: count)

// With a default value
let text = "optional.key".localized(defaultValue: "Default")
```

#### In SwiftUI Views

```swift
// Localized text
Text(localized: "main.empty.title")

// TextField placeholder
TextField("prompt.title.placeholder".localized, text: $title)

// Button title
Button("prompt.save".localized) { /* action */ }
```

#### Language Switching

```swift
// Get the localization manager
@StateObject private var localizationManager = LocalizationManager.shared

// Language picker
Picker("Language", selection: $localizationManager.currentLanguage) {
    ForEach(LocalizationManager.SupportedLanguage.allCases) { language in
        Text(language.displayName).tag(language)
    }
}
```

## Localization Key Naming Conventions

### Naming Rules

-   Use a dot-separated hierarchical structure.
-   Group by functional modules.
-   Keep key names concise and descriptive.

### Grouping Examples

```
app.*           # App general
menubar.*       # Menu bar
main.*          # Main interface
prompt.*        # Prompt management
tags.*          # Tag system
parameters.*    # Parameterization feature
settings.*      # Settings interface
search.*        # Search related
error.*         # Error messages
confirm.*       # Confirmation dialogs
```

## Translation Integrity Validation

Use the validation script to check translation integrity:

```bash
python3 scripts/validate_localization.py
```

The validation includes:

-   ✅ Checking if all language keys are complete.
-   ✅ Verifying if there are any empty translations.
-   ✅ Identifying redundant or missing keys.
-   ✅ Ensuring correct formatting.

## Adding Support for a New Language

### Step 1: Create Localization Directory

```bash
mkdir -p PromptPal/Resources/[language-code].lproj
```

### Step 2: Copy and Translate the Strings File

```bash
cp PromptPal/Resources/en.lproj/Localizable.strings PromptPal/Resources/[language-code].lproj/
```

### Step 3: Update LocalizationManager

Add the new language to the `SupportedLanguage` enum:

```swift
enum SupportedLanguage: String, CaseIterable {
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case japanese = "ja"
    case newLanguage = "[language-code]"  // New language
}
```

### Step 4: Add Display Name

```swift
var displayName: String {
    switch self {
    case .newLanguage:
        return "Language Name"
    // ... other cases
    }
}
```

### Step 5: Validate Translation

Run the validation script to ensure translation integrity.

## Best Practices

### 1. Development Guidelines

-   All user-visible text must be localized.
-   Avoid hard-coding strings.
-   Use meaningful key names and comments.

### 2. Text Handling

-   Consider text length differences across languages.
-   Design flexible UI layouts.
-   Handle plural forms and formatted parameters.

### 3. Testing and Validation

-   Test the UI display for all supported languages.
-   Verify the runtime language switching functionality.
-   Check for text truncation and layout issues.

### 4. Performance Optimization

-   Use the singleton pattern to avoid redundant object creation.
-   Cache localized strings appropriately.
-   Avoid frequent file I/O.

## File Checklist

### Core Files

-   `PromptPal/Utilities/LocalizationManager.swift` - Localization Manager
-   `PromptPal/Views/LanguageSettingsView.swift` - Language Settings UI
-   `PromptPal/ContentView.swift` - Updated main view (with internationalization)

### Localization Files

-   `PromptPal/Resources/en.lproj/Localizable.strings` - English translations
-   `PromptPal/Resources/zh-Hans.lproj/Localizable.strings` - Simplified Chinese translations

### Tool Files

-   `scripts/validate_localization.py` - Translation validation script
-   `.cursor/rules/internationalization-guidelines.mdc` - Development guidelines

## Future Expansion

Languages planned for support:

-   🔄 日本語 (Japanese)
-   🔄 Français (French)
-   🔄 Deutsch (German)
-   🔄 Español (Spanish)
-   🔄 한국어 (Korean)

## Contributing Translations

We welcome community contributions for translations! Please refer to the following:

1.  Review the existing `en.lproj/Localizable.strings` file.
2.  Create a translation file for the corresponding language.
3.  Run the validation script to ensure integrity.
4.  Submit a Pull Request.

---

> 💡 **Tip**: For more detailed development guidelines, please refer to `.cursor/rules/internationalization-guidelines.mdc` 