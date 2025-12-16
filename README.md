# VoiceSearchBarKit

VoiceSearchBarKit is a reusable **SwiftUI search bar library** for iOS that provides:

* Text-based search
* Voice search (Speech-to-Text)
* Built-in debounce for efficient real-time searching
* Cancel support to clear search and reset results
* Simple integration with lists, arrays, or APIs

The library focuses only on **search input handling**.
You control how and where the data is searched.

---

## Requirements

* iOS 15 or later
* SwiftUI
* Xcode 14+

---

## Installation (Swift Package Manager)

### Step 1: Add Dependency

1. Open your Xcode project
2. Go to **File → Add Packages…**
3. Enter the repository URL:

```
https://github.com/Excelsior-Technologies-Community/VoiceSearchBarKit
```

4. Select the latest version
5. Add the package to your app target

---

## Importing the Library

In any SwiftUI file where you want to use the search bar:

```swift
import VoiceSearchBarKit
```

---

## Basic Usage (Search Input Only)

If you only want to receive search text (for logging, API calls, etc.):

```swift
SearchBarView { text in
    print(text)
}
```

* The callback is **debounced**
* Called for both typing and voice input
* Empty text is sent when the user taps Cancel

---

## Full Basic Example

```swift
import SwiftUI
import VoiceSearchBarKit

struct ContentView: View {

    var body: some View {
        VStack {

            SearchBarView { text in
                print("Search text:", text)
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
```

---

## Implementing Search With Local Data (Most Common Use Case)

### Scenario

You have a local list of data and want to:

* Filter it as the user types
* Support voice search
* Reset results when Cancel is tapped

---

## Step 1: Original and Filtered Data

Always keep **two arrays**:

```swift
@State private var originalData = [
    "Noman Belim",
    "Rahul Patel",
    "Amit Shah",
    "Neha Sharma",
    "Rohit Mehta",
    "iOS Developer",
    "SwiftUI Engineer"
]

@State private var filteredData: [String] = []
```

* `originalData` never changes
* `filteredData` updates based on search input

---

## Step 2: Add SearchBarView With Debounce

```swift
SearchBarView(
    placeholder: "Search users",
    debounceTime: 0.5
) { text in
    handleSearch(text)
}
```

* `debounceTime` controls how often search is triggered
* Ideal for APIs and large lists

---

## Step 3: Display Filtered Results

```swift
List(filteredData, id: \.self) { item in
    Text(item)
}
```

---

## Full Working Example (Search + List)

This is the **recommended reference example** for new developers.

```swift
import SwiftUI
import VoiceSearchBarKit

struct ContentView: View {

    @State private var originalData = [
        "Noman Belim",
        "Rahul Patel",
        "Amit Shah",
        "Neha Sharma",
        "Rohit Mehta",
        "iOS Developer",
        "SwiftUI Engineer"
    ]

    @State private var filteredData: [String] = []

    var body: some View {

        VStack {

            SearchBarView(
                placeholder: "Search users",
                debounceTime: 0.5
            ) { text in
                handleSearch(text)
            }

            List(filteredData, id: \.self) { item in
                Text(item)
            }
        }
        .onAppear {
            filteredData = originalData
        }
    }

    private func handleSearch(_ text: String) {

        if text.isEmpty {
            filteredData = originalData
        } else {
            filteredData = originalData.filter {
                $0.localizedCaseInsensitiveContains(text)
            }
        }
    }
}

#Preview {
    ContentView()
}
```

---

## How Voice Search Works

* User taps the microphone icon
* Speech is converted to text
* Text is inserted into the search field
* The same debounced `onSearch` callback is triggered
* Your existing search logic runs automatically

Voice and typing use **the same search pipeline**.

---

## Cancel Behavior

When the user taps **Cancel**:

* Search text is cleared
* Voice recording stops (if active)
* `onSearch("")` is called
* Your data resets to the original state

No extra handling is required.

---

## Required Permissions

Add the following keys to your app’s **Info.plist**:

```xml
<key>NSSpeechRecognitionUsageDescription</key>
<string>Voice search is used to convert speech into text.</string>

<key>NSMicrophoneUsageDescription</key>
<string>Microphone access is required for voice search.</string>
```

---

## Common Use Cases

* Search lists and tables
* Filter local data
* Debounced API search
* Voice-enabled product search
* User lookup
* Content filtering

---

## Design Principles

* SearchBarView handles input only
* You control the data and search logic
* No business logic inside the library
* SwiftUI-native and reusable
* Production-ready
