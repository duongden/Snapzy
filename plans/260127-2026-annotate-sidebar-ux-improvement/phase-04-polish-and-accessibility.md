# Phase 4: Polish and Accessibility

**Effort:** 3 hours
**Priority:** Medium
**Dependencies:** Phases 1-3

## Objective

Add section headers with expand/collapse, focus states for keyboard navigation, and VoiceOver support.

## Implementation

### Step 4.1: Enhanced Section Header with Expand/Collapse

**File:** `ClaudeShot/Features/Annotate/Views/AnnotateSidebarComponents.swift`

```swift
struct CollapsibleSectionHeader: View {
  let title: String
  let itemCount: Int?
  @Binding var isExpanded: Bool
  let showMoreAction: (() -> Void)?

  init(
    title: String,
    itemCount: Int? = nil,
    isExpanded: Binding<Bool> = .constant(true),
    showMoreAction: (() -> Void)? = nil
  ) {
    self.title = title
    self.itemCount = itemCount
    self._isExpanded = isExpanded
    self.showMoreAction = showMoreAction
  }

  var body: some View {
    HStack {
      Text(title)
        .font(Typography.sectionHeader)
        .foregroundColor(SidebarColors.labelSecondary)
        .textCase(.uppercase)

      if let count = itemCount {
        Text("\(count)")
          .font(Typography.labelSmall)
          .foregroundColor(SidebarColors.labelTertiary)
          .padding(.horizontal, 6)
          .padding(.vertical, 2)
          .background(Capsule().fill(SidebarColors.itemDefault))
      }

      Spacer()

      if showMoreAction != nil {
        Button {
          showMoreAction?()
        } label: {
          Text(isExpanded ? "Show less" : "Show more")
            .font(Typography.labelSmall)
            .foregroundColor(.accentColor)
        }
        .buttonStyle(.plain)
      }
    }
  }
}
```

### Step 4.2: Focus State Modifier

**File:** `ClaudeShot/Features/Annotate/Views/DesignTokens.swift`

```swift
struct FocusableItemStyle: ViewModifier {
  let isSelected: Bool
  @FocusState.Binding var isFocused: Bool

  func body(content: Content) -> some View {
    content
      .overlay(
        RoundedRectangle(cornerRadius: Size.radiusMd)
          .stroke(
            isFocused ? Color.accentColor : .clear,
            lineWidth: 2
          )
          .padding(-2)
      )
      .accessibilityAddTraits(isSelected ? .isSelected : [])
  }
}
```

### Step 4.3: VoiceOver Labels

**Add to GradientPresetButton:**

```swift
.accessibilityLabel("\(preset.rawValue) gradient")
.accessibilityHint("Double tap to apply this gradient background")
.accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
```

**Add to WallpaperPresetButton:**

```swift
.accessibilityLabel("\(preset.displayName) wallpaper")
.accessibilityHint("Double tap to apply this wallpaper")
.accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
```

**Add to ColorSwatch:**

```swift
.accessibilityLabel(colorName(for: color))
.accessibilityHint("Double tap to apply this color")
.accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)

// Helper function
private func colorName(for color: Color) -> String {
  switch color {
  case .red: return "Red"
  case .orange: return "Orange"
  case .yellow: return "Yellow"
  case .green: return "Green"
  case .blue: return "Blue"
  case .purple: return "Purple"
  case .pink: return "Pink"
  case .white: return "White"
  case .black: return "Black"
  case .gray: return "Gray"
  default: return "Custom color"
  }
}
```

### Step 4.4: Section Dividers

**File:** `ClaudeShot/Features/Annotate/Views/AnnotateSidebarView.swift`

```swift
// Add between major sections
struct SectionDivider: View {
  var body: some View {
    Rectangle()
      .fill(Color.secondary.opacity(0.15))
      .frame(height: 1)
      .padding(.vertical, Spacing.sm)
  }
}

// Usage in main VStack:
noneButton
SectionDivider()
gradientSection
wallpaperSection
colorSection
SectionDivider()
slidersSection
// ...
```

## Validation Checklist

- [ ] Tab key navigates through all interactive elements
- [ ] Focus ring visible on focused elements
- [ ] VoiceOver announces all buttons correctly
- [ ] Section headers show item counts
- [ ] Show more/less toggles work
- [ ] Dividers provide visual separation

## Final Testing

1. Enable VoiceOver (Cmd+F5)
2. Navigate sidebar with Tab key
3. Verify all announcements are clear
4. Test in both light and dark mode
5. Test with "Increase contrast" enabled

## Completion Criteria

- All 4 phases implemented
- No visual regressions
- Accessibility audit passes
- Code review approved
