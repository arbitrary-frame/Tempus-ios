# Tempus Import/Export Data Format Specification

**Version:** 1.1.0
**Last Updated:** October 2025

This document provides a complete specification for creating JSON files that can be imported into Tempus. Use this to convert written workout data into an importable format.

---

## Table of Contents

1. [Root Structure](#root-structure)
2. [User Settings](#user-settings)
3. [Metadata](#metadata)
4. [Exercise Definitions](#exercise-definitions)
5. [Workout Routines](#workout-routines)
6. [Workouts](#workouts)
7. [Complete Example](#complete-example)
8. [Validation Rules](#validation-rules)
9. [Common Pitfalls](#common-pitfalls)

---

## Root Structure

The top-level JSON object contains all your workout data, exercise library, routines, and settings.

```json
{
  "version": "1.1.0",
  "exportDate": "2025-10-20T14:30:00Z",
  "userSettings": { ... },
  "metadata": { ... },
  "exercises": [ ... ],
  "routines": [ ... ],
  "workouts": [ ... ]
}
```

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `version` | String | ✅ | Format version (use "1.1.0") |
| `exportDate` | ISO8601 Date | ✅ | When this data was exported/created |
| `userSettings` | Object | ✅ | User preferences (name, goals) |
| `metadata` | Object | ✅ | Summary statistics about the export |
| `exercises` | Array | ✅ | Exercise library (definitions) |
| `routines` | Array | ✅ | Saved workout templates (can be empty `[]`) |
| `workouts` | Array | ✅ | Completed workouts (can be empty `[]`) |

---

## User Settings

Your personal preferences and goals.

```json
{
  "userSettings": {
    "userName": "Ronak",
    "weeklyWorkoutGoal": 3
  }
}
```

### Fields

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `userName` | String | ✅ | Can be empty string `""` |
| `weeklyWorkoutGoal` | Integer | ✅ | Must be between 1-7 (workouts per week) |

---

## Metadata

Summary statistics about your export. Used for display during import confirmation.

```json
{
  "metadata": {
    "exportDate": "2025-10-20T14:30:00Z",
    "appVersion": "1.0.0",
    "totalWorkouts": 7,
    "totalExercises": 17,
    "totalRoutines": 3,
    "dateRange": {
      "earliest": "2025-09-15T10:00:00Z",
      "latest": "2025-10-18T18:30:00Z"
    }
  }
}
```

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `exportDate` | ISO8601 Date | ✅ | When data was exported |
| `appVersion` | String | ✅ | App version (use "1.0.0") |
| `totalWorkouts` | Integer | ✅ | Count of workouts in export |
| `totalExercises` | Integer | ✅ | Count of exercise definitions |
| `totalRoutines` | Integer | ✅ | Count of routines |
| `dateRange` | Object | ❌ | Earliest/latest workout dates (null if no workouts) |

**Note:** If you have no workouts, set `dateRange` to `null` and `totalWorkouts` to `0`.

---

## Exercise Definitions

The exercise library. Each exercise needs a unique UUID and defines what the exercise is.

```json
{
  "exercises": [
    {
      "id": "a1b2c3d4-1234-5678-90ab-cdef12345678",
      "name": "Barbell Bench Press",
      "description": "Chest press on flat bench",
      "muscleGroup": "Chest",
      "tags": ["compound", "barbell"],
      "imageURL": null,
      "isArchived": false,
      "createdAt": "2025-09-01T10:00:00Z",
      "updatedAt": "2025-09-01T10:00:00Z"
    },
    {
      "id": "b2c3d4e5-2345-6789-01bc-def234567890",
      "name": "Dumbbell Bicep Curl",
      "description": "Bicep curl with dumbbells",
      "muscleGroup": "Arms",
      "tags": ["unilateral", "dumbbell"],
      "imageURL": null,
      "isArchived": false,
      "createdAt": "2025-09-01T10:05:00Z",
      "updatedAt": "2025-09-01T10:05:00Z"
    }
  ]
}
```

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | UUID String | ✅ | Unique identifier (e.g., "a1b2c3d4-1234-5678-90ab-cdef12345678") |
| `name` | String | ✅ | Exercise name (must be unique) |
| `description` | String | ❌ | Optional description (can be `null` or `""`) |
| `muscleGroup` | String | ✅ | One of: "Chest", "Back", "Legs", "Shoulders", "Arms", "Core", "Full Body" |
| `tags` | Array[String] | ✅ | Tags (can be empty `[]`). Important: include "unilateral" for dumbbell/single-leg exercises |
| `imageURL` | String | ❌ | Optional image URL (usually `null`) |
| `isArchived` | Boolean | ✅ | `true` = archived (hidden), `false` = active |
| `createdAt` | ISO8601 Date | ✅ | When exercise was created |
| `updatedAt` | ISO8601 Date | ✅ | When exercise was last modified |

### Valid Muscle Groups

- `"Chest"`
- `"Back"`
- `"Legs"`
- `"Shoulders"`
- `"Arms"`
- `"Core"`
- `"Full Body"`

### Common Tags

- `"unilateral"` - **IMPORTANT:** Marks exercises where weight is logged per side (dumbbells, single-leg). Volume calculation will double the weight.
- `"compound"` - Multi-joint movement
- `"barbell"` - Uses barbell
- `"dumbbell"` - Uses dumbbells
- `"bodyweight"` - Bodyweight only
- `"machine"` - Machine-based

**Critical:** Always tag dumbbell exercises and single-leg exercises with `"unilateral"` so volume is calculated correctly (weight × 2).

---

## Workout Routines

Saved workout templates. Users can start a workout from a routine.

```json
{
  "routines": [
    {
      "id": "c3d4e5f6-3456-7890-12cd-ef3456789012",
      "name": "Push Day",
      "description": "Chest, shoulders, triceps",
      "emoji": "💪",
      "exerciseIDs": [
        "a1b2c3d4-1234-5678-90ab-cdef12345678",
        "d4e5f6a7-4567-8901-23de-f45678901234"
      ],
      "createdAt": "2025-09-05T12:00:00Z",
      "updatedAt": "2025-09-05T12:00:00Z"
    }
  ]
}
```

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | UUID String | ✅ | Unique identifier |
| `name` | String | ✅ | Routine name (e.g., "Push Day") |
| `description` | String | ❌ | Optional description (can be `null` or `""`) |
| `emoji` | String | ❌ | Optional emoji icon (e.g., "💪", can be `null` or `""`) |
| `exerciseIDs` | Array[UUID String] | ✅ | List of exercise IDs (must match IDs from `exercises` array) |
| `createdAt` | ISO8601 Date | ✅ | When routine was created |
| `updatedAt` | ISO8601 Date | ✅ | When routine was last modified |

---

## Workouts

Completed workouts with exercises, sets, weights, and reps.

```json
{
  "workouts": [
    {
      "id": "e5f6a7b8-5678-9012-34ef-567890123456",
      "routineID": "c3d4e5f6-3456-7890-12cd-ef3456789012",
      "name": "Morning Push Day",
      "date": "2025-10-18T09:00:00Z",
      "notes": "Felt strong today!",
      "createdAt": "2025-10-18T09:45:00Z",
      "exercises": [
        {
          "exerciseID": "a1b2c3d4-1234-5678-90ab-cdef12345678",
          "name": "Barbell Bench Press",
          "muscleGroup": "Chest",
          "isUnilateral": false,
          "notes": null,
          "sets": [
            {
              "setNumber": 1,
              "weightsAndReps": [
                { "weight": 60.0, "reps": 10 }
              ]
            },
            {
              "setNumber": 2,
              "weightsAndReps": [
                { "weight": 70.0, "reps": 8 }
              ]
            },
            {
              "setNumber": 3,
              "weightsAndReps": [
                { "weight": 75.0, "reps": 6 }
              ]
            }
          ]
        },
        {
          "exerciseID": "b2c3d4e5-2345-6789-01bc-def234567890",
          "name": "Dumbbell Bicep Curl",
          "muscleGroup": "Arms",
          "isUnilateral": true,
          "notes": "Per arm",
          "sets": [
            {
              "setNumber": 1,
              "weightsAndReps": [
                { "weight": 12.5, "reps": 12 }
              ]
            },
            {
              "setNumber": 2,
              "weightsAndReps": [
                { "weight": 15.0, "reps": 10 }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

### Workout Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | UUID String | ✅ | Unique identifier |
| `routineID` | UUID String | ❌ | ID of routine used (can be `null` for quick logs) |
| `name` | String | ✅ | Workout name (e.g., "Morning Push Day") |
| `date` | ISO8601 Date | ✅ | When workout was performed |
| `notes` | String | ❌ | Optional workout notes (can be `null` or `""`) |
| `createdAt` | ISO8601 Date | ✅ | When workout was logged in app |
| `exercises` | Array[ExerciseData] | ✅ | Exercises performed in workout |

### Exercise Data Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `exerciseID` | UUID String | ✅ | Must match ID from `exercises` array |
| `name` | String | ✅ | Exercise name (snapshotted at time of workout) |
| `muscleGroup` | String | ❌ | Muscle group (can be `null`, usually filled) |
| `isUnilateral` | Boolean | ✅ | **CRITICAL:** `true` for dumbbell/single-leg, `false` for bilateral |
| `notes` | String | ❌ | Optional exercise notes (can be `null` or `""`) |
| `sets` | Array[Set] | ✅ | Sets performed for this exercise |

### Set Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `setNumber` | Integer | ✅ | Set number (1, 2, 3, ...) |
| `weightsAndReps` | Array[WeightRep] | ✅ | Weight/rep pairs (usually 1, but supports drop sets) |

### Weight/Rep Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `weight` | Double | ✅ | Weight in kg (e.g., `60.0`, `12.5`, `0.0` for bodyweight) |
| `reps` | Integer | ✅ | Number of reps (e.g., `10`, `12`) |

---

## Complete Example

Here's a minimal valid import file with 1 exercise, 1 routine, and 1 workout:

```json
{
  "version": "1.1.0",
  "exportDate": "2025-10-20T14:30:00Z",
  "userSettings": {
    "userName": "Alex",
    "weeklyWorkoutGoal": 4
  },
  "metadata": {
    "exportDate": "2025-10-20T14:30:00Z",
    "appVersion": "1.0.0",
    "totalWorkouts": 1,
    "totalExercises": 2,
    "totalRoutines": 1,
    "dateRange": {
      "earliest": "2025-10-15T18:00:00Z",
      "latest": "2025-10-15T18:00:00Z"
    }
  },
  "exercises": [
    {
      "id": "f1e2d3c4-1111-2222-3333-abcdef123456",
      "name": "Squats",
      "description": "Barbell back squat",
      "muscleGroup": "Legs",
      "tags": ["compound", "barbell"],
      "imageURL": null,
      "isArchived": false,
      "createdAt": "2025-10-01T10:00:00Z",
      "updatedAt": "2025-10-01T10:00:00Z"
    },
    {
      "id": "a2b3c4d5-2222-3333-4444-bcdef2345678",
      "name": "Dumbbell Shoulder Press",
      "description": "Overhead press with dumbbells",
      "muscleGroup": "Shoulders",
      "tags": ["unilateral", "dumbbell"],
      "imageURL": null,
      "isArchived": false,
      "createdAt": "2025-10-01T10:05:00Z",
      "updatedAt": "2025-10-01T10:05:00Z"
    }
  ],
  "routines": [
    {
      "id": "b3c4d5e6-3333-4444-5555-cdef34567890",
      "name": "Leg Day",
      "description": "Lower body workout",
      "emoji": "🦵",
      "exerciseIDs": [
        "f1e2d3c4-1111-2222-3333-abcdef123456"
      ],
      "createdAt": "2025-10-05T12:00:00Z",
      "updatedAt": "2025-10-05T12:00:00Z"
    }
  ],
  "workouts": [
    {
      "id": "c4d5e6f7-4444-5555-6666-def456789012",
      "routineID": "b3c4d5e6-3333-4444-5555-cdef34567890",
      "name": "Evening Leg Day",
      "date": "2025-10-15T18:00:00Z",
      "notes": "Good session",
      "createdAt": "2025-10-15T19:00:00Z",
      "exercises": [
        {
          "exerciseID": "f1e2d3c4-1111-2222-3333-abcdef123456",
          "name": "Squats",
          "muscleGroup": "Legs",
          "isUnilateral": false,
          "notes": null,
          "sets": [
            {
              "setNumber": 1,
              "weightsAndReps": [
                { "weight": 100.0, "reps": 5 }
              ]
            },
            {
              "setNumber": 2,
              "weightsAndReps": [
                { "weight": 110.0, "reps": 5 }
              ]
            },
            {
              "setNumber": 3,
              "weightsAndReps": [
                { "weight": 120.0, "reps": 3 }
              ]
            }
          ]
        },
        {
          "exerciseID": "a2b3c4d5-2222-3333-4444-bcdef2345678",
          "name": "Dumbbell Shoulder Press",
          "muscleGroup": "Shoulders",
          "isUnilateral": true,
          "notes": "Weight per dumbbell",
          "sets": [
            {
              "setNumber": 1,
              "weightsAndReps": [
                { "weight": 20.0, "reps": 10 }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

---

## Validation Rules

### UUIDs
- All `id` fields must be valid UUIDs (format: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)
- Generate UUIDs using online tools or programming languages
- Each ID must be unique across its type (no duplicate exercise IDs, workout IDs, etc.)

### Dates
- All dates must be ISO8601 format with timezone: `"2025-10-20T14:30:00Z"`
- Use UTC timezone (ends with `Z`)
- Example valid: `"2025-10-15T18:00:00Z"`
- Example invalid: `"2025-10-15"`, `"15/10/2025"`, `"2025-10-15 18:00:00"`

### References
- `workouts[].routineID` must match a `routines[].id` (or be `null`)
- `workouts[].exercises[].exerciseID` must match an `exercises[].id`
- `routines[].exerciseIDs[]` must match `exercises[].id`

### Numbers
- Weights: Positive doubles (e.g., `60.0`, `12.5`, `0.0`)
- Reps: Positive integers (e.g., `10`, `12`)
- Set numbers: Start at 1 and increment sequentially

### Unilateral Flag
- **CRITICAL:** Set `isUnilateral: true` for:
  - Dumbbell exercises (curls, rows, presses)
  - Single-leg exercises (Bulgarian split squats, single-leg deadlifts)
  - Single-arm exercises (cable curls, single-arm rows)
- Set `isUnilateral: false` for:
  - Barbell exercises (bench press, squats, deadlifts)
  - Machine exercises (leg press, chest press)
  - Bodyweight bilateral exercises (push-ups, pull-ups)

**Why this matters:** Unilateral exercises have volume doubled (weight × 2) because you log weight per hand/leg but lift with both sides.

---

## Common Pitfalls

### ❌ Wrong Date Format
```json
"date": "2025-10-15"  // WRONG - Missing time and timezone
```
```json
"date": "2025-10-15T18:00:00Z"  // CORRECT
```

### ❌ Invalid UUID
```json
"id": "12345"  // WRONG - Not a UUID
```
```json
"id": "f1e2d3c4-1111-2222-3333-abcdef123456"  // CORRECT
```

### ❌ Broken References
```json
"exerciseID": "unknown-id"  // WRONG - Doesn't exist in exercises array
```
```json
"exerciseID": "f1e2d3c4-1111-2222-3333-abcdef123456"  // CORRECT - Matches exercise
```

### ❌ Forgetting Unilateral Flag
```json
{
  "name": "Dumbbell Bicep Curl",
  "isUnilateral": false  // WRONG - Dumbbells are unilateral!
}
```
```json
{
  "name": "Dumbbell Bicep Curl",
  "isUnilateral": true,  // CORRECT
  "tags": ["unilateral", "dumbbell"]  // Also tag it
}
```

### ❌ Missing Required Fields
```json
{
  "name": "Push Day"
  // WRONG - Missing id, createdAt, updatedAt, exerciseIDs
}
```

### ❌ Wrong Muscle Group
```json
"muscleGroup": "Biceps"  // WRONG - Not in valid list
```
```json
"muscleGroup": "Arms"  // CORRECT - Use one of: Chest, Back, Legs, Shoulders, Arms, Core, Full Body
```

---

## Generating UUIDs

### Online Tools
- https://www.uuidgenerator.net/version4
- https://www.uuid-generator.com/

### Programming Languages

**Python:**
```python
import uuid
print(str(uuid.uuid4()))  # e.g., "f1e2d3c4-1111-2222-3333-abcdef123456"
```

**JavaScript:**
```javascript
crypto.randomUUID()  // e.g., "f1e2d3c4-1111-2222-3333-abcdef123456"
```

**Command Line (macOS/Linux):**
```bash
uuidgen | tr '[:upper:]' '[:lower:]'
```

---

## Import Process

When you import a JSON file:

1. **Validation** - App checks JSON structure and required fields
2. **Confirmation** - Shows summary (X workouts, Y exercises, Z routines)
3. **Warning** - Confirms you want to **REPLACE ALL** existing data
4. **Import** - Deletes existing data and imports new data
5. **Success** - Confirms import and reloads widgets

**⚠️ IMPORTANT:** Import is **destructive**. It replaces ALL your current data. Export your existing data first if you want to keep it!

---

## Testing Your Import File

1. **Validate JSON syntax** - Use https://jsonlint.com/
2. **Check UUIDs** - All must be valid UUID format
3. **Verify dates** - All must be ISO8601 with timezone (`Z`)
4. **Check references** - Exercise IDs, routine IDs must match
5. **Test with small file** - Start with 1 workout before importing hundreds
6. **Backup existing data** - Export current data before importing

---

## Need Help?

If you encounter import errors:

1. Check the error message - it will tell you what's wrong
2. Validate your JSON syntax
3. Ensure all required fields are present
4. Verify UUID and date formats
5. Check that all ID references exist

**Common error messages:**
- `"Failed to read import file"` - JSON syntax error
- `"Invalid exercise ID"` - Exercise ID doesn't exist in exercises array
- `"The data couldn't be read because it is missing"` - Required field is missing

---

**Built with 🧡 by Ronak Pattani with [Claude Code](https://claude.com/claude-code)**
