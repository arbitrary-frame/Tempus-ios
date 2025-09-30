# Tempus Development Workflow

## Git Workflow

### Branch Strategy
- **⛔️ CRITICAL: NEVER EVER work directly on `master` or `main`**
- **⛔️ BEFORE ANY WORK: Check current branch with `git branch`**
- **⛔️ If on master: STOP and create a feature branch immediately**
- Create a feature branch for every task: `feature/task-name`
- Examples: `feature/data-models`, `feature/workout-logging-screen`, `feature/analytics-charts`

### MANDATORY First Step - Before Any Work
1. **Run `git branch` to verify you are NOT on master**
2. **If on master**: Immediately run `git checkout -b feature/descriptive-name`
3. Ensure branch is up to date with master if needed
4. **Double-check you're on the correct feature branch before making ANY changes**

### During Development
1. Work incrementally on the feature branch
2. Build and verify in Xcode frequently
3. **MUST successfully build before requesting code review**
4. Commit logical chunks of work with clear messages

### Code Review Process
1. Assistant builds the feature in Xcode to verify it compiles
2. Assistant commits changes with descriptive messages
3. Assistant notifies user that code is ready for review
4. **User reviews the branch before merging to master**
5. No automatic merging - user approves and merges

### Commit Messages
- Clear, descriptive messages
- Format: "Add [feature]" / "Fix [issue]" / "Update [component]"
- Include context when needed

## Xcode Build Verification

### Before Every Code Review
- Run full build in Xcode: `xcodebuild -project Tempus.xcodeproj -scheme Tempus -destination 'platform=iOS Simulator,name=iPhone 15' build`
- Fix all build errors before proceeding
- No warnings should be introduced if possible
- **Build MUST succeed before user review**

### Build Issues
- If build fails, fix immediately - don't proceed
- Notify user if stuck on build issues
- Never commit broken code

## AI Assistant Guidelines

### What to Do
- Work incrementally and commit frequently
- Always verify builds succeed
- Ask questions when deviating from requirements or project context
- Use TodoWrite to track multi-step features
- Provide clear explanations of changes
- Follow requirements-ios.md specifications strictly

### What NOT to Do
- **⛔️ NEVER EVER work on master/main branch - This is the #1 rule**
- **⛔️ ALWAYS check `git branch` before starting any work**
- Don't push code that doesn't build
- Don't implement Swift tests (user not comfortable with testing yet)
- Don't deviate from requirements without asking first
- Don't merge branches (user will do this after review)

## Debugging Approach

### Simple Debugging Strategy
- Use `print()` statements liberally for debugging
- Add `// DEBUG:` comments to mark temporary debug code
- Log key data flow points:
  - Model creation/updates
  - User actions
  - Data persistence operations
  - Navigation events
- Use descriptive print messages: `print("DEBUG: Workout saved with \(exerciseCount) exercises")`

### Error Handling
- Use clear error messages
- Log errors to console with context
- Present user-friendly alerts when needed
- Never fail silently

## Questions Before Implementation

### Ask User First If:
- Significant deviation from requirements-ios.md
- Architectural decision not covered in requirements
- UI/UX pattern differs from specification
- Adding dependencies or frameworks not listed
- Uncertain about design interpretation
- Trade-offs between different approaches

### Safe to Proceed Without Asking:
- Implementation details within specified requirements
- Variable/function naming
- Code organization within established structure
- Standard iOS patterns (e.g., navigation, alerts)
- Minor UI adjustments that match design intent

## Project Structure Reminders

### Key Files to Reference
- `requirements-ios.md` - Complete specification (source of truth)
- `.claude/project-context.md` - iOS 26 & Liquid Glass context
- `.claude/workflow.md` - This file

### Code Organization
Follow the structure defined in requirements-ios.md:
```
Tempus/
├── App/
├── Models/
├── Views/
├── ViewModels/
├── Services/
├── Utilities/
└── Resources/
```

## Summary Checklist

Before requesting user review:
- [ ] **⛔️ VERIFIED: Not on master branch (run `git branch` to confirm)**
- [ ] Working on feature branch with descriptive name
- [ ] Code follows requirements-ios.md
- [ ] Xcode build succeeds
- [ ] Debug print statements added where helpful
- [ ] Committed with clear message
- [ ] Ready for user review

## ⛔️ CRITICAL RULE - READ FIRST

**BEFORE MAKING ANY CODE CHANGES:**
```bash
# ALWAYS run this command first:
git branch

# If it shows "* master", IMMEDIATELY create a feature branch:
git checkout -b feature/descriptive-name
```

**NO EXCEPTIONS. EVER.**