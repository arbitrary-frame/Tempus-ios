# Tempus Roadmap

## ✅ Completed (v1.0.0 - October 2025)

### Core Features
- ✅ Workout logging with exercises, sets, weights, reps
- ✅ Workout routines with emoji icons
- ✅ Exercise library with muscle groups
- ✅ Drop set support
- ✅ Workout history with editing
- ✅ Data export/import (JSON)
- ✅ Dark/light mode
- ✅ Settings screen
- ✅ Haptic feedback throughout
- ✅ Performance optimizations (15-20% faster)

### Analytics & Visualization
- ✅ Weekly workout statistics card
- ✅ Workout calendar with visual history
- ✅ Weekly goal tracking with progress rings
- ✅ Streak tracking for consistency
- ✅ Week-over-week trend indicators
- ✅ Exercise count and weight tracking

### Widgets
- ✅ Goal Progress Widget (Small)
- ✅ Exercises Widget (Small)
- ✅ Weight Widget (Small)
- ✅ Combined Stats Widget (Medium)
- ✅ Real-time widget sync

### Polish
- ✅ Onboarding flow
- ✅ iOS 26 Liquid Glass design
- ✅ Previous workout preview
- ✅ Repeat set button
- ✅ Comprehensive documentation

---

## 🎯 Next Up - Advanced Analytics (v1.1.0)

**Target:** Next development session

### Phase 1: Data Model Validation & Enhancement

**Goal:** Ensure we have the correct baseline data models to support rich analytics

**Tasks:**
- [ ] **Audit Current Data Models**
  - Review `WorkoutEntry`, `WorkoutExerciseData`, `WorkoutSet`, `WeightRep`
  - Identify missing fields for analytics (timestamps, duration, rest periods, etc.)
  - Ensure proper data capture for trend analysis

- [ ] **Add Missing Analytics Data**
  - Workout duration (start/end timestamps)
  - Rest periods between sets (optional)
  - Exercise order in workout
  - Notes/form cues per set
  - 1RM calculations/estimates
  - Volume calculations (weight × reps × sets)

- [ ] **Create Analytics Helper Models**
  - Personal records tracking
  - Volume over time calculations
  - Strength progression metrics
  - Frequency analysis

### Phase 2: Apple Health-Inspired Analytics Views

**Inspiration:** Apple Health app design patterns and interactions

**Core Analytics Screens:**

1. **Enhanced Analytics Dashboard**
   - [ ] Large, scrollable cards with graphs
   - [ ] Period selector (Week/Month/Year/All Time)
   - [ ] Summary statistics at top
   - [ ] Tap cards to drill into details

2. **Volume Over Time Graph**
   - [ ] Line chart showing total volume (weight × reps) per workout
   - [ ] Rolling averages (7-day, 30-day)
   - [ ] Trend lines and predictions
   - [ ] Compare muscle groups

3. **Exercise Performance Trends**
   - [ ] Individual exercise progress charts
   - [ ] Max weight progression
   - [ ] Volume progression
   - [ ] Personal records highlighted
   - [ ] Comparison to previous periods

4. **Workout Frequency Visualization**
   - [ ] Enhanced calendar heatmap (already have basic calendar)
   - [ ] Intensity indicators (light/medium/heavy workouts)
   - [ ] Consistency streaks visualization
   - [ ] Weekly/monthly patterns

5. **Personal Records Dashboard**
   - [ ] All-time bests per exercise
   - [ ] Recent PRs highlighted
   - [ ] 1RM estimates
   - [ ] Volume PRs

6. **Muscle Group Distribution**
   - [ ] Pie/donut chart of muscle group volume
   - [ ] Balance analysis (push/pull ratio)
   - [ ] Recommendations for balanced training

### Phase 3: Interactive Stats System (Future)

**Goal:** Customizable analytics similar to Apple Watch Activity rings

**Features:**
- [ ] **Widget-style Stats Cards**
  - Modular stat cards on workouts list
  - Long-press to configure which stats show
  - Drag to reorder
  - Tap to expand/drill down

- [ ] **Available Stats Modules**
  - Current: Workouts this week, Exercises, Weight
  - Add: Volume trend, PR count, Rest days, Consistency score
  - Add: Favorite exercise, Most improved, Workout duration
  - Add: Custom calculations

- [ ] **Stat Card Manager**
  - Settings screen to add/remove cards
  - Preview before adding
  - Save custom layouts
  - Reset to defaults

### Technical Implementation Notes

**Charting Library:**
- Use Swift Charts (iOS 16+) for native SwiftUI charts
- Liquid Glass aesthetic with material backgrounds
- Smooth animations and interactions
- Accessibility support

**Data Calculations:**
- Cached computed properties for performance
- Background thread calculations for heavy stats
- SwiftData queries optimized with predicates
- Consider IndexedDB pattern for fast lookups

**Design Consistency:**
- Match existing Liquid Glass design
- Orange accent color for highlights
- Material backgrounds for cards
- Smooth spring animations
- Haptic feedback on interactions

---

## 🔮 Future Enhancements (v1.2+)

### Smart Features
- [ ] Progressive overload suggestions
- [ ] Workout recommendations based on history
- [ ] Rest day suggestions
- [ ] Deload week detection
- [ ] Plateau detection and breaking strategies

### Apple Ecosystem Integration
- [ ] Apple Watch companion app
  - Rest timer
  - Quick workout logging
  - Heart rate tracking
  - Workout detection
- [ ] Apple Health integration
  - Export workouts to Health
  - Import heart rate data
  - Sync with Fitness app
- [ ] Siri shortcuts
  - "Log my workout"
  - "Show my stats"
  - "Start rest timer"

### Social & Sharing
- [ ] Share workout summaries
- [ ] Share PR achievements
- [ ] Export workout images for social media
- [ ] Friend comparison (optional)

### Advanced Training
- [ ] Workout programs/periodization
- [ ] Supersets and circuits
- [ ] Tempo tracking (3-0-1-0)
- [ ] RPE (Rate of Perceived Exertion)
- [ ] Cardio tracking
- [ ] Bodyweight exercise support

### Data & Sync
- [ ] iCloud sync across devices
- [ ] Backup/restore to iCloud
- [ ] CSV export for data analysis
- [ ] Import from other fitness apps
- [ ] Export to Google Sheets

### iPad & Mac
- [ ] iPad-optimized layouts
- [ ] Mac Catalyst app
- [ ] Multi-column layouts
- [ ] Keyboard shortcuts

### Accessibility
- [ ] Full VoiceOver support
- [ ] Dynamic Type throughout
- [ ] High contrast mode
- [ ] Voice control
- [ ] Switch control optimization

---

## 📊 Analytics v1.1 Success Metrics

**Must Have:**
- ✅ Volume over time chart working
- ✅ Exercise performance trends visible
- ✅ Personal records tracked and displayed
- ✅ All charts use iOS 26 Liquid Glass design
- ✅ Data models support analytics calculations

**Nice to Have:**
- Muscle group distribution chart
- Comparison period selectors
- Export analytics data
- Share analytics screenshots

**Future:**
- Customizable stat cards
- Predictive analytics
- AI-powered insights

---

## 🗓️ Release Strategy

**v1.0.0** - October 2025 ✅
- Core workout tracking
- Widgets
- Basic analytics
- Complete documentation

**v1.1.0** - Next Sprint 🎯
- Advanced analytics dashboard
- Apple Health-inspired charts
- Enhanced data models
- PR tracking

**v1.2.0** - Future
- Apple Watch app
- Smart recommendations
- Social features

**v2.0.0** - Long-term
- AI-powered insights
- Full Apple ecosystem integration
- Advanced periodization

---

**Last Updated:** October 1, 2025
**Current Version:** v1.0.0
**Next Milestone:** Analytics v1.1.0
