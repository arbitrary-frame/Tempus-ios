# Tempus - iOS Native Workout Tracker
## Complete App Specification for iOS 26

## App Overview
A minimalist workout logging app built natively for iOS that allows users to quickly record their workout progress without timing constraints. Users can create workout templates and log historical workout data with beautiful progress visualisation using iOS 26's Liquid Glass design language.

## Core Concept
- **NOT a live workout tracker** - users are logging completed workouts with specific dates
- Focus on quick data entry and progress visualisation
- Metric system only (kg, not lbs)
- UK localisation (DD/MM/YYYY, British spelling)
- **iOS 26 native** - embracing Liquid Glass design and modern iOS patterns

---

## Technical Stack

### Development Environment
- **Language:** Swift 6 (strict concurrency enabled)
- **UI Framework:** SwiftUI with Liquid Glass design system
- **Minimum Deployment:** iOS 26.0+
- **IDE:** Xcode 26+
- **Architecture:** MVVM with SwiftUI property wrappers

### Data & Persistence
- **Local Storage:** Swift Data (replaces Core Data)
- **Data Export:** JSON format via Share Sheet
- **No backend required for MVP**
- **Offline-first:** All data stored locally

### iOS Frameworks
- **SwiftUI** - Primary UI framework
- **Swift Data** - Model layer and persistence
- **Swift Charts** - Analytics visualisation with 3D support
- **Foundation** - Core utilities, date formatting
- **Combine** - Reactive data flow (where needed)
- **UIKit interop** - Where SwiftUI limitations exist

---

## iOS 26 Design Integration

### Liquid Glass Design Language
- **Translucent materials** throughout the app
- **Dynamic depth effects** that respond to content
- **Refined animations** using SwiftUI's rebuilt rendering pipeline
- **Adaptive colouring** that reflects and refracts surroundings
- **Icon Composer** for app icon with layered Liquid Glass effects

### iOS Design Principles
- **Native navigation patterns** - NavigationStack with proper hierarchy
- **SF Symbols 7** - Consistent iconography throughout (6,900+ symbols with Draw animations, gradients)
- **Dynamic Type** - Full support for accessibility text sizes
- **Haptic Feedback** - UIFeedbackGenerator for tactile responses
- **Context Menus** - Long-press actions following iOS conventions
- **Pull-to-refresh** - Standard iOS gestures
- **Swipe actions** - Delete, archive, and quick actions on list items

### Colour System
Leveraging iOS 26's semantic colours with custom brand colours:

```swift
// Light Mode
Primary: #004225 (Deep Forest Green)
PrimaryLight: #1B5E3A
Secondary: #D4AF37 (Gold)
Background: Color(.systemGroupedBackground)
Surface: Color(.secondarySystemGroupedBackground)
TextPrimary: Color(.label)
TextSecondary: Color(.secondaryLabel)

// Dark Mode
Primary: #004225
PrimaryDark: #002815
Secondary: #FFD700 (Bright Gold)
Background: Color(.systemGroupedBackground) // iOS handles dark mode
Surface: Color(.secondarySystemGroupedBackground)
TextPrimary: Color(.label)
TextSecondary: Color(.secondaryLabel)
```

**Note:** Use iOS semantic colours where possible for automatic dark mode and accessibility support.

---

## Data Schema

### Swift Data Models

#### Exercise
```swift
@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String // Must be unique via validation
    var exerciseDescription: String?
    var muscleGroup: String
    var tags: [String]
    var imageURL: String? // Local asset or SF Symbol name
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date

    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \WorkoutTemplate.exercises)
    var templates: [WorkoutTemplate]?

    init(name: String, muscleGroup: String, tags: [String] = []) {
        self.id = UUID()
        self.name = name
        self.muscleGroup = muscleGroup
        self.tags = tags
        self.isArchived = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
```

#### WorkoutTemplate
```swift
@Model
final class WorkoutTemplate {
    @Attribute(.unique) var id: UUID
    var name: String
    var templateDescription: String?
    var createdAt: Date
    var updatedAt: Date

    // Relationships
    @Relationship(deleteRule: .nullify)
    var exercises: [Exercise]

    @Relationship(deleteRule: .nullify, inverse: \WorkoutEntry.template)
    var workouts: [WorkoutEntry]?

    init(name: String, exercises: [Exercise] = []) {
        self.id = UUID()
        self.name = name
        self.exercises = exercises
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
```

#### WorkoutEntry
```swift
@Model
final class WorkoutEntry {
    @Attribute(.unique) var id: UUID
    var workoutName: String
    var workoutDate: Date
    var notes: String?
    var createdAt: Date

    // Relationships
    @Relationship(deleteRule: .nullify)
    var template: WorkoutTemplate?

    // Embedded exercises data (not relationships to preserve history)
    @Attribute(.transformable) var exercisesData: [WorkoutExerciseData]

    init(name: String, date: Date, template: WorkoutTemplate? = nil) {
        self.id = UUID()
        self.workoutName = name
        self.workoutDate = date
        self.template = template
        self.exercisesData = []
        self.createdAt = Date()
    }
}

// Codable struct for embedded exercise data
struct WorkoutExerciseData: Codable {
    let exerciseID: UUID
    let exerciseName: String
    var sets: [WorkoutSet]
    var notes: String?
}

struct WorkoutSet: Codable, Identifiable {
    let id: UUID
    let setNumber: Int
    var weightsAndReps: [WeightRep]

    init(setNumber: Int) {
        self.id = UUID()
        self.setNumber = setNumber
        self.weightsAndReps = []
    }
}

struct WeightRep: Codable, Identifiable {
    let id: UUID
    var weight: Double // in kg, supports decimals
    var reps: Int

    init(weight: Double = 0, reps: Int = 0) {
        self.id = UUID()
        self.weight = weight
        self.reps = reps
    }
}
```

---

## App Navigation Structure

### Primary Navigation
```swift
TabView {
    WorkoutsView()
        .tabItem { Label("Workouts", systemImage: "figure.strengthtraining.traditional") }

    ExercisesView()
        .tabItem { Label("Exercises", systemImage: "list.bullet.clipboard") }

    AnalyticsView()
        .tabItem { Label("Analytics", systemImage: "chart.line.uptrend.xyaxis") }
}
```

### Navigation Patterns
- **NavigationStack** for hierarchical navigation
- **Sheet modals** for create/edit flows
- **Full screen covers** for workout logging (prevents accidental dismissal)
- **Context menus** on list items for quick actions
- **Swipe actions** for delete/archive

---

## Screen Specifications

### 1. Workouts Screen (Landing Page)

**Layout:**
- **Navigation Title:** "Workouts" (large title, scrolls to inline)
- **Toolbar:**
  - Trailing: Plus button (primary action)
- **Content:**
  - List with grouped style
  - Chronological order (newest first)
  - Pull-to-refresh support
  - Empty state with SF Symbol illustration

**Workout List Items:**
```swift
// Each row shows:
VStack(alignment: .leading) {
    Text(workoutName) // e.g., "Push Day - 28/09/2025"
        .font(.headline)
    HStack {
        Label("\(exerciseCount) exercises", systemImage: "figure.mixed.cardio")
        Spacer()
        Text(relativeDate) // "2 hours ago" or "15/03/2024"
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}
```

**Context Menu Actions:**
- View Details
- Duplicate Workout
- Delete (with confirmation alert)

**Swipe Actions:**
- Leading: Duplicate (blue)
- Trailing: Delete (red, requires confirmation)

**Plus Button Action Sheet:**
```swift
.confirmationDialog("New Workout", isPresented: $showingNewWorkout) {
    Button("Select Template") { /* Show template picker */ }
    Button("Start from Scratch") { /* Open blank workout */ }
    Button("Create New Template") { /* Navigate to template creation */ }
    Button("Cancel", role: .cancel) { }
}
```

**Empty State:**
- SF Symbol: "figure.strengthtraining.traditional"
- Heading: "No Workouts Yet"
- Subheading: "Tap + to log your first workout"
- ContentUnavailableView with Liquid Glass background

**Haptic Feedback:**
- `.success` when workout saved
- `.warning` on delete confirmation
- `.light` on row tap

---

### 2. Workout Logging Screen

**Presentation:** Full screen cover (prevents accidental dismissal)

**Navigation:**
- Leading: Cancel (with unsaved changes alert if needed)
- Trailing: Save button (prominent, disabled if invalid)
- Title: Editable workout name (tap to edit)

**Header Section:**
```swift
VStack {
    // Workout name (editable)
    TextField("Workout Name", text: $workoutName)
        .font(.title2.bold())
        .multilineTextAlignment(.center)

    // Date picker
    DatePicker("Date", selection: $workoutDate, displayedComponents: .date)
        .datePickerStyle(.compact)
        .environment(\.locale, Locale(identifier: "en_GB"))
}
.padding()
.background(.regularMaterial) // Liquid Glass material
```

**Exercise List:**
- List with inset grouped style
- Reorderable (edit mode with drag handles)
- Each exercise in expandable disclosure group

**Exercise Row Structure:**
```swift
DisclosureGroup {
    // Previous session data
    if let previousData = getPreviousData(for: exercise) {
        VStack(alignment: .leading) {
            Text("Last Session")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text(formatLastSession(previousData)) // "60kg × 8, 8, 6"
                .font(.subheadline)
        }
        .padding(.vertical, 4)
    }

    // Current sets
    ForEach($sets) { $set in
        SetInputRow(set: $set, setNumber: set.setNumber)
    }

    // Add set button
    Button(action: addSet) {
        Label("Add Set", systemImage: "plus.circle.fill")
    }
    .buttonStyle(.borderless)

    // Exercise notes
    TextField("Notes", text: $exerciseNotes, axis: .vertical)
        .lineLimit(2...4)
        .textFieldStyle(.roundedBorder)

} label: {
    HStack {
        Image(systemName: "line.3.horizontal")
            .foregroundStyle(.secondary)
        Text(exerciseName)
            .font(.headline)
        Spacer()
        Text("\(sets.count) sets")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}
```

**Set Entry Component:**
```swift
HStack {
    Text("Set \(setNumber)")
        .font(.subheadline)
        .frame(width: 50, alignment: .leading)

    // Support for drop sets (multiple weight/rep pairs)
    ForEach($weightsAndReps) { $wr in
        HStack(spacing: 4) {
            // Weight input
            TextField("kg", value: $wr.weight, format: .number)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 60)

            Text("×")
                .foregroundStyle(.secondary)

            // Reps input
            TextField("reps", value: $wr.reps, format: .number)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 50)
        }
    }

    // Add drop set button
    Button(action: addDropSet) {
        Image(systemName: "plus.circle")
    }
    .buttonStyle(.borderless)
}
```

**Bottom Toolbar:**
```swift
HStack {
    Button(action: addExercise) {
        Label("Add Exercise", systemImage: "plus.circle.fill")
    }
    Spacer()
    Button("View Progress") {
        // Show quick graphs for current exercises
    }
}
.padding()
.background(.ultraThinMaterial)
```

**Workout Notes:**
- TextEditor at bottom of list
- Placeholder: "Workout notes (optional)"
- Auto-saves as user types

**Haptic Feedback:**
- `.light` on set completion (when both weight and reps entered)
- `.success` on workout saved
- `.warning` on cancel with unsaved changes

---

### 3. Exercise Library Screen

**Navigation:**
- Title: "Exercises" (large title)
- Toolbar:
  - Trailing: Plus button (add new exercise)
  - Filter button (muscle group/tag filters)

**Search:**
```swift
.searchable(text: $searchText, prompt: "Search exercises, muscle groups, or tags")
.searchScopes($searchScope) {
    Text("All").tag(SearchScope.all)
    Text("Name").tag(SearchScope.name)
    Text("Muscle Group").tag(SearchScope.muscleGroup)
    Text("Tags").tag(SearchScope.tags)
}
```

**List Layout:**
```swift
List {
    ForEach(groupedExercises.keys.sorted(), id: \.self) { muscleGroup in
        Section(muscleGroup) {
            ForEach(groupedExercises[muscleGroup]!) { exercise in
                ExerciseRow(exercise: exercise)
            }
        }
    }
}
.listStyle(.insetGrouped)
```

**Exercise Row:**
```swift
HStack(spacing: 12) {
    // Thumbnail
    AsyncImage(url: exercise.imageURL) { image in
        image.resizable().scaledToFill()
    } placeholder: {
        Image(systemName: "figure.strengthtraining.traditional")
            .foregroundStyle(.secondary)
    }
    .frame(width: 60, height: 60)
    .clipShape(RoundedRectangle(cornerRadius: 8))

    VStack(alignment: .leading, spacing: 4) {
        Text(exercise.name)
            .font(.headline)

        // Tags
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                // Muscle group as first tag (prominent)
                Text(exercise.muscleGroup)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.2))
                    .clipShape(Capsule())

                ForEach(exercise.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.secondary.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
        }
    }

    Spacer()

    Image(systemName: "chevron.right")
        .foregroundStyle(.tertiary)
}
```

**Context Menu:**
```swift
.contextMenu {
    Button(action: edit) {
        Label("Edit", systemImage: "pencil")
    }
    Button(action: duplicate) {
        Label("Duplicate", systemImage: "doc.on.doc")
    }
    Divider()
    if canDelete {
        Button(role: .destructive, action: delete) {
            Label("Delete", systemImage: "trash")
        }
    } else {
        Button(action: archive) {
            Label("Archive", systemImage: "archivebox")
        }
    }
}
```

**Swipe Actions:**
```swift
.swipeActions(edge: .trailing) {
    if canDelete {
        Button(role: .destructive, action: delete) {
            Label("Delete", systemImage: "trash")
        }
    } else {
        Button(action: archive) {
            Label("Archive", systemImage: "archivebox")
        }
        .tint(.orange)
    }
}
.swipeActions(edge: .leading) {
    Button(action: edit) {
        Label("Edit", systemImage: "pencil")
    }
    .tint(.blue)
}
```

**Filter Sheet:**
- Multi-select muscle groups
- Multi-select tags
- Clear all filters button
- Apply button (dismisses sheet)

---

### 4. Exercise Creation/Edit Screen

**Presentation:** Sheet modal

**Form Layout:**
```swift
NavigationStack {
    Form {
        Section("Basic Information") {
            TextField("Exercise Name", text: $name)
                .autocorrectionDisabled()

            TextField("Description (optional)", text: $description, axis: .vertical)
                .lineLimit(3...6)
        }

        Section("Classification") {
            Picker("Muscle Group", selection: $muscleGroup) {
                ForEach(MuscleGroup.allCases) { group in
                    Text(group.rawValue).tag(group)
                }
            }

            VStack(alignment: .leading) {
                Text("Tags")
                    .font(.headline)
                TagInputView(tags: $tags)
            }
        }

        Section("Image") {
            Picker("Image Source", selection: $imageSource) {
                Text("SF Symbol").tag(ImageSource.symbol)
                Text("Photo").tag(ImageSource.photo)
            }
            .pickerStyle(.segmented)

            if imageSource == .symbol {
                SFSymbolPicker(selection: $selectedSymbol)
            } else {
                PhotosPicker(selection: $photoSelection, matching: .images) {
                    Label("Choose Photo", systemImage: "photo")
                }
            }
        }
    }
    .navigationTitle(isEditing ? "Edit Exercise" : "New Exercise")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button(isEditing ? "Save" : "Create") {
                saveExercise()
            }
            .disabled(!isValid)
        }
    }
}
```

**Validation:**
- Exercise name must be unique
- Muscle group must be selected
- Show inline error messages

---

### 5. Template Management

**Template List Screen:**
- Accessible from Workouts tab (secondary navigation)
- List of templates with exercise count
- Pull to refresh
- Context menus for edit/duplicate/delete

**Template Creation:**
```swift
NavigationStack {
    Form {
        Section("Template Information") {
            TextField("Template Name", text: $name)
            TextField("Description (optional)", text: $description, axis: .vertical)
        }

        Section("Exercises") {
            ForEach(selectedExercises) { exercise in
                HStack {
                    Image(systemName: "line.3.horizontal")
                        .foregroundStyle(.secondary)
                    Text(exercise.name)
                    Spacer()
                    Button(role: .destructive, action: { removeExercise(exercise) }) {
                        Image(systemName: "minus.circle.fill")
                    }
                    .buttonStyle(.borderless)
                }
            }
            .onMove(perform: moveExercises)

            Button(action: showExercisePicker) {
                Label("Add Exercise", systemImage: "plus.circle.fill")
            }
        }
    }
    .navigationTitle(isEditing ? "Edit Template" : "New Template")
    .toolbar {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Save") { saveTemplate() }
                .disabled(!isValid)
        }
        ToolbarItem(placement: .principal) {
            Button("Reorder") { editMode.toggle() }
        }
    }
    .environment(\.editMode, $editMode)
}
```

**Exercise Picker Sheet:**
- Searchable list of all exercises
- Multiple selection enabled
- Grouped by muscle group
- Selected exercises show checkmark

**Deletion Rules:**
- Cannot delete template if used in any workouts
- Show alert: "This template is used in X workouts and cannot be deleted"

---

### 6. Analytics Screen

**Layout Options:**
```swift
Picker("View By", selection: $viewMode) {
    Text("Templates").tag(ViewMode.templates)
    Text("Exercises").tag(ViewMode.exercises)
}
.pickerStyle(.segmented)
.padding()
```

**Template View:**
```swift
List(templates) { template in
    NavigationLink(destination: TemplateAnalyticsView(template: template)) {
        HStack {
            VStack(alignment: .leading) {
                Text(template.name)
                    .font(.headline)
                Text("\(template.exercises.count) exercises")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            // Mini sparkline preview
            MiniSparkline(data: getRecentVolume(for: template))
                .frame(width: 60, height: 30)
        }
    }
}
```

**Template Analytics Detail:**
```swift
ScrollView {
    VStack(spacing: 20) {
        // Summary stats
        StatsGrid(template: template)

        // Graph for each exercise
        ForEach(template.exercises) { exercise in
            VStack(alignment: .leading) {
                Text(exercise.name)
                    .font(.headline)

                // Metric toggle
                Picker("Metric", selection: $selectedMetric) {
                    Text("Avg Weight").tag(Metric.averageWeight)
                    Text("Total Volume").tag(Metric.totalVolume)
                    Text("Max Weight").tag(Metric.maxWeight)
                }
                .pickerStyle(.segmented)

                // Swift Charts line graph
                Chart(getWorkoutData(for: exercise)) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value(selectedMetric.rawValue, dataPoint.value)
                    )
                    .foregroundStyle(Color.accentColor)

                    // Overlay reps as secondary line
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Reps", dataPoint.reps)
                    )
                    .foregroundStyle(.secondary)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.day().month())
                    }
                }
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    .padding()
}
```

**Exercise View:**
- List of all exercises (including unused ones)
- Filter by muscle group/tags
- Tap to see exercise-specific analytics across all templates

**Date Range Picker:**
- Toolbar button: "Last 5 workouts" (default)
- Sheet with options:
  - Last 5/10/20 workouts
  - Last 30/90/180 days
  - All time
  - Custom date range

**Empty State:**
- "No workout data yet for this exercise"
- Button to start logging workouts

---

## iOS-Native Features (MVP)

### Haptic Feedback
```swift
import UIKit

enum HapticFeedback {
    case light, medium, heavy, success, warning, error

    func trigger() {
        switch self {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}
```

**Usage Guidelines:**
- Set completed: `.light`
- Exercise added: `.medium`
- Workout saved: `.success`
- Delete action: `.warning`
- Validation error: `.error`
- Respect user's haptic settings (reduced motion)

### Spotlight Search
```swift
import CoreSpotlight
import UniformTypeIdentifiers

// Index workouts
func indexWorkout(_ workout: WorkoutEntry) {
    let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
    attributeSet.title = workout.workoutName
    attributeSet.contentDescription = "\(workout.exercisesData.count) exercises on \(formatDate(workout.workoutDate))"
    attributeSet.keywords = ["workout", "training", workout.template?.name ?? ""]

    let item = CSSearchableItem(
        uniqueIdentifier: workout.id.uuidString,
        domainIdentifier: "com.tempus.workout",
        attributeSet: attributeSet
    )

    CSSearchableIndex.default().indexSearchableItems([item])
}

// Handle search results
func handleSpotlightSearch(identifier: String) {
    // Navigate to workout detail
}
```

### Context Menus
Following iOS design patterns:
- Primary actions at top
- Destructive actions at bottom (separated by divider)
- Icons from SF Symbols
- Haptic feedback on long press

### Share Sheet Integration
```swift
// Export single workout
func shareWorkout(_ workout: WorkoutEntry) {
    let jsonData = try? JSONEncoder().encode(workout)
    let jsonString = String(data: jsonData!, encoding: .utf8)!

    let activityVC = UIActivityViewController(
        activityItems: [jsonString],
        applicationActivities: nil
    )

    // Present share sheet
}

// Export all data
func exportAllData() {
    let allData = ExportData(
        exercises: modelContext.fetch(Exercise.self),
        templates: modelContext.fetch(WorkoutTemplate.self),
        workouts: modelContext.fetch(WorkoutEntry.self),
        exportDate: Date()
    )

    let jsonData = try? JSONEncoder().encode(allData)
    // Present share sheet with JSON file
}
```

### Privacy & Permissions

**Privacy Manifest (PrivacyInfo.xcprivacy):**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

**Required Permissions:**
- **Photo Library (optional):** For custom exercise images
  - `NSPhotoLibraryUsageDescription`: "Add custom images to your exercises"
- **No tracking:** Zero data collection, zero analytics
- **No network calls:** Completely offline app

**Privacy Statement in App Store:**
- "Tempus does not collect, transmit, or share any user data"
- "All data is stored locally on your device"
- "No account required, no analytics, no tracking"

**Settings Integration:**
```swift
// App Settings bundle (Settings.bundle)
// Allow users to:
// - Clear all data
// - Export data
// - View privacy policy
// - Contact support
```

---

## Accessibility

### VoiceOver Support
```swift
// Exercise row example
.accessibilityElement(children: .combine)
.accessibilityLabel("\(exercise.name), \(exercise.muscleGroup)")
.accessibilityHint("Double tap to view exercise details")

// Set input
.accessibilityLabel("Set \(setNumber), Weight: \(weight) kilograms, Reps: \(reps)")
```

### Dynamic Type
- All text uses iOS text styles (`.headline`, `.body`, `.caption`)
- Custom fonts scale with Dynamic Type
- Test at all accessibility sizes (XS - XXXL)
- Layout adapts to larger text (vertical stacking when needed)

### Colour & Contrast
- Minimum 4.5:1 contrast ratio for body text
- Minimum 3:1 for large text and UI elements
- Differentiate Without Colour (icons + text, not colour alone)
- Support for Increase Contrast accessibility setting

### Reduced Motion
```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

var animation: Animation {
    reduceMotion ? .none : .spring(response: 0.3)
}
```

### Keyboard Navigation (iPad)
- Tab key navigation through all interactive elements
- Keyboard shortcuts for common actions:
  - `⌘N` - New workout
  - `⌘E` - New exercise
  - `⌘S` - Save
  - `⌘W` - Close/Cancel

---

## Validation Rules

### Exercise Validation
- Exercise name must be unique (case-insensitive)
- Exercise name cannot be empty
- Muscle group must be selected
- Archive exercises that are used in workouts (cannot delete)
- Can delete exercises that have never been used

### Template Validation
- Template name cannot be empty
- Must contain at least one exercise
- Cannot delete templates referenced by workouts
- Show warning when trying to delete with count: "Used in X workouts"

### Workout Validation
- Workout date cannot be in the future
- At least one exercise with one set required
- Weight and reps must be positive numbers
- Weight supports decimals (0.5kg increments)
- Unsaved changes alert when dismissing

### Input Validation
- Weight: 0.5 - 999.5 kg
- Reps: 1 - 999
- Real-time validation with inline error messages
- Disabled save button until valid

---

## Data Export & Backup

### Export Format
```json
{
  "exportDate": "2025-09-30T10:30:00Z",
  "appVersion": "1.0.0",
  "exercises": [...],
  "templates": [...],
  "workouts": [...]
}
```

### Export Options
1. **Share Sheet:** Quick share to Files, Notes, etc.
2. **Files App Integration:** Save directly to iCloud Drive
3. **AirDrop:** Share to other devices
4. **Email:** Attach as JSON file

### Import (Future)
- Validate JSON structure
- Merge or replace existing data
- Show preview before importing

---

## Localisation

### UK English
- Date format: DD/MM/YYYY (using `en_GB` locale)
- British spelling throughout:
  - "Visualisation" not "Visualization"
  - "Organise" not "Organize"
  - "Analyse" not "Analyze"
- Metric system only (kg, not lbs)
- 24-hour time format optional (respect device settings)

### String Localisation
```swift
// Use LocalizedStringKey for all user-facing strings
Text("workouts.title") // "Workouts"
Text("workouts.empty.title") // "No Workouts Yet"

// Pluralisation
Text("exercises.count", count: exerciseCount) // "1 exercise" / "5 exercises"
```

### Date Formatting
```swift
let formatter = DateFormatter()
formatter.locale = Locale(identifier: "en_GB")
formatter.dateStyle = .medium
formatter.timeStyle = .none
// Output: "30 Sep 2025"
```

---

## Key User Flows

### First-Time User Experience
1. Launch app → Welcome screen (optional onboarding)
2. Main screen shows empty state with clear CTA
3. Tap + → "Create New Template" (guided)
4. Add template name → Select exercises → Save
5. Tap + again → "Select Template" → Choose created template
6. Log first workout with helpful placeholders
7. Save → Success haptic + confirmation
8. View in workout list → Celebrate first entry!

### Regular User - Quick Logging
1. Launch app → Sees workout history
2. Tap + → Recent templates at top of sheet
3. Select template → Pre-filled with previous data
4. Quick updates to weights/reps
5. Swipe between exercises
6. Tap Save → Success feedback
7. Total time: < 2 minutes

### Progress Analysis Flow
1. Navigate to Analytics tab
2. See template list with sparklines
3. Tap template → Detailed graphs
4. Toggle between metrics (weight/volume/max)
5. Scrub timeline to see specific dates
6. Switch to Exercise view for cross-template comparison
7. Share graph via screenshot

---

## iOS-Native Enhancements (Future Roadmap)

These features are encouraged but not required for MVP. They showcase iOS-native capabilities and can be added incrementally.

### Widgets (iOS 26)
- **Small Widget:** Workout count this week + last workout date
- **Medium Widget:** Recent workouts list (last 3)
- **Large Widget:** Weekly summary with mini charts
- **Lock Screen Widget:** Days since last workout

### App Intents & Shortcuts
```swift
struct LogWorkoutIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Workout"
    static var description: LocalizedStringResource = "Quickly log a workout from your template"

    @Parameter(title: "Template")
    var template: WorkoutTemplate

    func perform() async throws -> some IntentResult {
        // Open app to workout logging screen
    }
}
```

**Suggested Shortcuts:**
- "Log Push Day"
- "View workout history"
- "Show progress for Bench Press"

### Focus Mode Integration
- **Workout Focus:** Filter notifications, suggest Tempus app
- **API Integration:** Detect active Focus mode
- **Smart Suggestions:** "You usually work out at this time"

### Apple Health Integration
- **Export:** Write workouts to HealthKit as strength training sessions
- **Read:** Body weight for tracking relative strength
- **Privacy:** Explicit user permission required

### iPad Optimizations
- **Split View:** Template list + detail view
- **Sidebar Navigation:** Persistent navigation on larger screens
- **Multi-column Layout:** Analytics with multiple graphs side-by-side
- **Keyboard Shortcuts:** Full keyboard navigation
- **Drag & Drop:** Drag exercises between templates

### iCloud Sync (CloudKit)
- **Private Database:** User data only
- **Conflict Resolution:** Last-write-wins with timestamp
- **Manual Sync Trigger:** Pull-to-refresh in Settings
- **Sync Status Indicator:** Show in Settings

### Live Activities (Limited Use)
- **Quick Entry Session:** Show timer for data entry session (not workout timer)
- **Dynamic Island:** Current exercise name during logging

---

## App Store Requirements

### App Information
- **Name:** Tempus
- **Subtitle:** Minimalist Workout Tracker
- **Category:** Health & Fitness
- **Age Rating:** 4+

### App Store Description
*Focus on UK audience, emphasise simplicity and privacy*

### Keywords
workout, training, gym, fitness, strength, log, tracker, progress, weightlifting, bodybuilding

### Screenshots
- iOS 26 Liquid Glass design showcase
- Light and dark mode examples
- Key screens: Workouts list, logging, analytics
- Captions highlighting UK localisation

### App Preview Video
- 30-second overview
- Show: Create template → Log workout → View progress
- Emphasise speed and simplicity

### Privacy Label
- **Data Not Collected:** Highlight this prominently
- No third-party SDKs that track users
- All data processing happens on-device

---

## Architecture & Code Organisation

### Project Structure
```
Tempus/
├── App/
│   ├── TempusApp.swift (App entry point)
│   └── ContentView.swift (Tab navigation)
├── Models/
│   ├── Exercise.swift (Swift Data model)
│   ├── WorkoutTemplate.swift
│   ├── WorkoutEntry.swift
│   └── Supporting/
│       ├── WorkoutExerciseData.swift
│       └── Enums.swift
├── Views/
│   ├── Workouts/
│   │   ├── WorkoutsListView.swift
│   │   ├── WorkoutLoggingView.swift
│   │   └── Components/
│   ├── Exercises/
│   │   ├── ExercisesListView.swift
│   │   ├── ExerciseDetailView.swift
│   │   └── ExerciseFormView.swift
│   ├── Analytics/
│   │   ├── AnalyticsView.swift
│   │   ├── TemplateAnalyticsView.swift
│   │   └── Charts/
│   └── Templates/
│       ├── TemplatesListView.swift
│       └── TemplateFormView.swift
├── ViewModels/
│   ├── WorkoutsViewModel.swift
│   ├── ExercisesViewModel.swift
│   └── AnalyticsViewModel.swift
├── Services/
│   ├── DataManager.swift (Swift Data operations)
│   ├── ExportService.swift
│   ├── SpotlightService.swift
│   └── HapticsManager.swift
├── Utilities/
│   ├── Extensions/
│   ├── Formatters/
│   └── Constants.swift
└── Resources/
    ├── Assets.xcassets
    ├── Localizable.xcstrings
    └── PrivacyInfo.xcprivacy
```

### MVVM Pattern with SwiftUI
```swift
// ViewModel example
@Observable
final class WorkoutsViewModel {
    private let modelContext: ModelContext
    private(set) var workouts: [WorkoutEntry] = []
    var searchText = ""
    var isLoading = false

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchWorkouts()
    }

    func fetchWorkouts() {
        let descriptor = FetchDescriptor<WorkoutEntry>(
            sortBy: [SortDescriptor(\.workoutDate, order: .reverse)]
        )
        workouts = (try? modelContext.fetch(descriptor)) ?? []
    }

    func deleteWorkout(_ workout: WorkoutEntry) {
        modelContext.delete(workout)
        try? modelContext.save()
        HapticsManager.shared.trigger(.warning)
        fetchWorkouts()
    }
}
```

### Swift Data Setup
```swift
@main
struct TempusApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for: Exercise.self, WorkoutTemplate.self, WorkoutEntry.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
        } catch {
            fatalError("Failed to initialise model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
```

### Async/Await for Future Networking
```swift
// Prepare for future CloudKit sync
actor DataSyncManager {
    func syncWithCloud() async throws {
        // Async network operations
    }
}
```

---

## Testing Strategy

### Unit Tests
- Model validation logic
- Data transformation (export/import)
- Date formatting
- Calculations (volume, averages)

### UI Tests
- Key user flows (create workout, log exercise)
- Navigation paths
- Form validation
- Accessibility labels

### Manual Testing
- VoiceOver navigation
- Dynamic Type at all sizes
- Dark mode throughout app
- Haptic feedback appropriate
- Keyboard navigation (iPad)

---

## Performance Considerations

### Swift Data Optimization
- Fetch only required properties with `#Predicate`
- Batch operations for large datasets
- Background context for heavy operations
- Cascade delete rules configured correctly

### SwiftUI Performance
- `@Observable` macro for granular updates
- Avoid unnecessary view updates
- Lazy loading for long lists
- Image caching for exercise thumbnails

### Launch Time
- Target: < 1 second cold launch
- Lazy initialisation of heavy services
- Defer non-critical setup

### Memory
- Monitor for leaks in navigation stack
- Release large objects when not needed
- Test with large datasets (1000+ workouts)

---

## MVP Feature Checklist

### Core Features (Must Have)
- ✅ Exercise library (create, edit, archive, delete)
- ✅ Workout templates (create, edit, duplicate, delete with validation)
- ✅ Workout logging (with previous data display)
- ✅ Set entry with drop set support
- ✅ Basic analytics (line charts by template/exercise)
- ✅ Data export (JSON via Share Sheet)
- ✅ UK localisation (dates, spelling, metric system)
- ✅ Dark mode support
- ✅ Haptic feedback throughout
- ✅ Context menus and swipe actions
- ✅ Spotlight search integration
- ✅ Privacy manifest
- ✅ Full accessibility support

### Nice to Have (Can Defer)
- ⚪ Widgets
- ⚪ Shortcuts
- ⚪ Focus Mode integration
- ⚪ Apple Health integration
- ⚪ iPad optimisations
- ⚪ iCloud sync
- ⚪ Data import
- ⚪ Advanced filtering
- ⚪ Graph export as images

---

## Future Roadmap (Post-MVP)

### Version 1.1
- Widgets (Home Screen + Lock Screen)
- App Shortcuts integration
- Data import functionality
- Advanced filtering and sorting

### Version 1.2
- Apple Health export
- Focus Mode suggestions
- iPad split-view optimisations
- Keyboard shortcuts

### Version 2.0
- iCloud sync with CloudKit
- Multi-device support
- Apple Watch companion app
- Live Activities for quick entry
- Personal records tracking
- Advanced analytics (trends, predictions)

### Version 3.0
- Social features (optional)
- Video exercise guides
- AI-powered workout suggestions
- Premium features (StoreKit integration)

---

## Development Timeline Estimate

### Phase 1: Foundation (Week 1-2)
- Project setup with Swift Data
- Data models and relationships
- Basic navigation structure
- Liquid Glass design system

### Phase 2: Core Features (Week 3-5)
- Exercise library implementation
- Template management
- Workout logging screen
- Previous workout data display

### Phase 3: Analytics (Week 6-7)
- Swift Charts integration
- Template analytics
- Exercise analytics
- Date range filtering

### Phase 4: Polish (Week 8-9)
- Haptics throughout
- Context menus and swipe actions
- Spotlight integration
- Accessibility audit

### Phase 5: Testing & Submission (Week 10)
- Beta testing
- Bug fixes
- App Store assets
- Privacy manifest verification
- Submit for review

**Total MVP Timeline:** 10 weeks for solo developer

---

## Design Assets Required

### App Icon
- iOS 26 Liquid Glass icon (Icon Composer)
- Multiple sizes for all contexts
- Tinted versions for different appearances

### SF Symbols
Primary symbols used:
- `figure.strengthtraining.traditional` (Workouts)
- `list.bullet.clipboard` (Exercises)
- `chart.line.uptrend.xyaxis` (Analytics)
- `plus.circle.fill` (Add actions)
- `line.3.horizontal` (Reorder handle)

### Custom Images (Optional)
- Exercise placeholder thumbnails
- Empty state illustrations
- Onboarding graphics

---

## Additional Notes

### Why iOS 26 Only?
- Leverage latest Liquid Glass APIs
- Swift Data improvements in iOS 26
- Smaller codebase without legacy support
- Target early adopters of new iOS versions
- Easier to maintain single target

### Offline-First Philosophy
- All features work without network
- No loading states for data
- Instant feedback
- Privacy by default

### UK Market Focus
- British spelling in all text
- DD/MM/YYYY dates exclusively
- Metric system (kg only)
- Consider UK App Store featuring

### Extensibility
Architecture designed for future expansion:
- CloudKit sync layer ready
- HealthKit integration points identified
- Widget extension structure planned
- Shortcuts support foundation in place

---

## Support & Maintenance

### User Support
- In-app settings with:
  - Export data
  - Clear all data (with confirmation)
  - Email support link
  - Privacy policy
  - Version number

### Analytics (None)
- No crash reporting in MVP
- No usage analytics
- User privacy paramount
- Consider privacy-respecting analytics post-MVP (on-device only)

### Updates
- Regular iOS updates support
- Bug fixes via TestFlight beta
- Feature requests via GitHub Issues or email
- Transparent roadmap

---

## Conclusion

Tempus is a privacy-focused, iOS 26-native workout tracker that embraces Apple's latest design language and platform features. By targeting iOS 26 exclusively, we can deliver a polished, modern experience that feels at home on iPhone while respecting user privacy and staying offline-first.

The MVP focuses on core workout logging and progress visualisation, with a clear roadmap for iOS-native enhancements that can be added incrementally based on user feedback.

**Design Philosophy:** Simple, fast, private, beautiful.

**Target User:** UK-based fitness enthusiasts who value privacy and want a no-nonsense workout tracker that feels native to iOS.

**Success Metrics:**
- App launches per week
- Workouts logged per user
- User retention (without tracking individuals)
- App Store ratings and reviews