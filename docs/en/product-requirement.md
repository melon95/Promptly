Product Requirement Document (PRD): Promptly for macOS
Version: 2.0
Date: June 11, 2025

1. Vision & Overview

Promptly for macOS is a native macOS application designed for developers, content creators, researchers, and any professional who frequently interacts with Large Language Models (LLMs). It aims to provide a centralized, efficient, and aesthetically pleasing platform for creating, organizing, searching, and quickly using various prompts.

The application will serve as the user's "Prompt Knowledge Base," liberating high-value prompts from scattered notes and chat histories. It will be seamlessly integrated into the user's workflow through an intuitive desktop application interface and keyboard shortcuts, offering an efficient prompt management experience.

2. Target Audience

*   **Software Developers:** Storing and managing prompts for code generation, debugging, API calls, etc.
*   **Content Creators/Marketers:** Managing creative prompts for article outlines, social media copy, ad slogans, etc.
*   **Students/Researchers:** Organizing academic prompts for literature analysis, data processing, thesis writing assistance, etc.
*   **AI Power Users:** Any individual who needs to systematically manage and reuse high-quality prompts.

3. Problem & Opportunity

Current Pain Points:

*   **Scattered Storage:** Prompts are scattered across memos, text documents, and chat logs, making them difficult to find and manage.
*   **Difficult Reuse:** Excellent prompts are hard to reuse and iterate on; users often have to rethink them or dig through history.
*   **Lack of Organization:** Without a unified system for categories, tags, or search, managing a growing number of prompts becomes chaotic.
*   **Workflow Interruption:** Frequent switching between the AI interface and the application where prompts are stored is inefficient.
*   **Tedious Variable Replacement:** Many prompts contain variables (e.g., [insert text here] or [specify language]) that need to be replaced manually, which is time-consuming and error-prone.

Product Opportunity:
Developing a lightweight, fast tool that is deeply integrated with the macOS system can significantly improve the efficiency and experience of user interaction with AI, becoming a key part of high-value workflows.

4. Functional Requirements

We will prioritize features into P0 (Core Features), P1 (Important Features), and P2 (Future Iterations).

P0 - Core Features (Implemented)

*   **Prompt Creation & Editing:**
    *   Support for setting a clear **Title** for each prompt.
    *   Support for adding a detailed **Description** to explain the prompt's purpose.
    *   A clean **Content** input area for writing and pasting prompt text.
    *   Auto-save after editing, no manual action required.
*   **Prompt List & Global Search:**
    *   Display all prompts in a list on the main interface.
    *   Provide a real-time **Global Search Box** to quickly filter prompts by title, description, and content.
    *   Support for the `⌘F` shortcut to quickly focus on the search box.
*   **Category Management System:**
    *   Users can assign each prompt to a specific **Category**.
    *   Support for creating, editing, and deleting custom categories.
    *   Provide functionality in the sidebar to filter prompts by category.
    *   Each category displays the number of prompts it contains.
*   **Quick Access & Usage:**
    *   **Standard macOS Application Interface:** Provide a complete desktop application experience.
    *   **Keyboard Shortcuts:** Support for `⌘N` (New Prompt), `⌘F` (Search), `⌘⇧F` (Show Favorites), etc.
    *   **One-Click Copy:** A prominent "Copy" button on each prompt to copy its content to the clipboard with one click.
*   **Favorites Functionality:**
    *   Users can mark frequently used prompts as "Favorites."
    *   A dedicated "Favorites" view in the sidebar for quick access to the most important prompts.
    *   Display the number of prompts in the Favorites.
*   **iCloud Sync:**
    *   Seamlessly sync all prompts and categories across the user's Mac devices via iCloud.
    *   Provide a sync toggle in the settings for users to enable or disable it freely.
*   **Multi-language Support:**
    *   Support for multiple interface languages, including Simplified Chinese, English, etc.
    *   Users can switch languages in the settings.
*   **Local Data Storage:**
    *   All data is securely stored on the local device by default, ensuring privacy.

P1 - Important Features (In Development)

*   **Parameterized Prompts (Variable Functionality):**
    *   Support for using placeholders in prompt content, such as `{{sentence_to_translate}}` or `{{programming_language}}`.
    *   When a user selects such a prompt, the application will intelligently identify the variables and present a simple form for the user to fill them in. The complete, substituted prompt is then copied to the clipboard.
*   **Rich Text & Code Highlighting:**
    *   The prompt content area will support Markdown syntax, especially syntax highlighting for code blocks (```), to improve the readability of code-related prompts.

P2 - Future Iterations (V2.0+)

*   **Prompt Generation:**
    *   Integrate an AI model to intelligently generate high-quality prompts based on user-input keywords or requirements.
*   **Prompt Testing:**
    *   Provide a testing environment where users can quickly test a prompt's performance across different large language models and compare the results.
*   **Usage Statistics & Analysis:**
    *   Record the usage frequency and last used time for each prompt.
    *   Intelligently sort prompts based on usage statistics.
    *   Provide a data analysis view to help users understand their usage habits.
*   **Version History:**
    *   Automatically record the modification history of prompts, allowing users to view and revert to previous versions.
*   **Prompt Sharing:**
    *   Generate a unique link or file to make it easy for users to share a single prompt or a set of prompts with others.
*   **Community Library (Optional):**
    *   Establish a platform where users can anonymously or publicly share, discover, and import high-quality prompts contributed by the community.

5. Non-Functional Requirements

*   **Performance:**
    *   The application must launch and respond extremely quickly, especially when functions are called via keyboard shortcuts.
    *   The search function should remain smooth even with over 1000 prompts.
*   **User Experience (UI/UX):**
    *   Adhere to Apple's Human Interface Guidelines to provide a native macOS experience.
    *   The interface design should be clean, intuitive, focused on core functionality, and have no learning curve.
    *   Perfect support for both light and dark modes in macOS.
*   **Security:**
    *   User data belongs entirely to the user. Data is stored locally by default. If iCloud sync is enabled, it is done only through the user's own Apple ID and is not uploaded to any third-party servers.
*   **Compatibility:**
    *   Support the latest version of macOS and be backward compatible with at least two major versions.

6. Technology Stack (Recommended)

*   **Language:** Swift
*   **UI Framework:** SwiftUI (for a modern UI, better performance, and cross-platform potential)
*   **Data Persistence:** SwiftData (for native support of iCloud sync)
*   **Distribution Channel:** Mac App Store

7. Success Metrics

*   **User Activity:** Daily/Monthly Active Users (DAU/MAU).
*   **Core Feature Usage Rate:** The number of daily prompt creations and copies; the usage ratio of category and favorites features.
*   **App Store Rating & Reviews:** Aim for a user rating of 4.5 stars or higher.
*   **User Retention Rate:** The 30-day user retention rate is a key indicator of the product's long-term value. 