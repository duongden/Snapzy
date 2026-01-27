# Phase 3: Interaction States

**Effort:** 4 hours
**Priority:** High
**Dependencies:** Phase 1, Phase 2

## Objective

Add consistent hover and focus states to all interactive elements. Currently only `BlurTypeButton` has hover states.

## Components to Update

1. GradientPresetButton
2. WallpaperPresetButton
3. CustomWallpaperButton
4. AddWallpaperButton
5. ColorSwatch / CompactColorSwatchGrid
6. None button
7. AlignmentCell

## Implementation

### Step 3.1: Update GradientPresetButton

**File:** `ClaudeShot/Features/Annotate/Views/AnnotateSidebarComponents.swift`
**Lines:** 25-42

```swift
// REPLACE ENTIRE STRUCT
struct GradientPresetButton: View {
  let preset: GradientPreset
  let isSelected: Bool
  let action: () -> Void

  @State private var isHovering = false

  var body: some View {
    Button(action: action) {
      RoundedRectangle(cornerRadius: Size.radiusMd)
        .fill(LinearGradient(colors: preset.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
        .frame(width: Size.gridItem, height: Size.gridItem)
        .overlay(
          RoundedRectangle(cornerRadius: Size.radiusMd)
            .stroke(borderColor, lineWidth: borderWidth)
        )
        .scaleEffect(isHovering && !isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovering)
    }
    .buttonStyle(.plain)
    .onHover { isHovering = $0 }
  }

  private var borderColor: Color {
    if isSelected { return SidebarColors.borderSelected }
    if isHovering { return SidebarColors.borderHover }
    return .clear
  }

  private var borderWidth: CGFloat {
    isSelected ? Size.strokeSelected : Size.strokeDefault
  }
}
```

### Step 3.2: Update WallpaperPresetButton

**File:** `ClaudeShot/Features/Annotate/Views/AnnotateSidebarComponents.swift`
**Lines:** 56-73

```swift
struct WallpaperPresetButton: View {
  let preset: WallpaperPreset
  let isSelected: Bool
  let action: () -> Void

  @State private var isHovering = false

  var body: some View {
    Button(action: action) {
      RoundedRectangle(cornerRadius: Size.radiusMd)
        .fill(preset.gradient)
        .frame(width: Size.gridItem, height: Size.gridItem)
        .overlay(
          RoundedRectangle(cornerRadius: Size.radiusMd)
            .stroke(borderColor, lineWidth: borderWidth)
        )
        .scaleEffect(isHovering && !isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovering)
    }
    .buttonStyle(.plain)
    .onHover { isHovering = $0 }
  }

  private var borderColor: Color {
    if isSelected { return SidebarColors.borderSelected }
    if isHovering { return SidebarColors.borderHover }
    return .clear
  }

  private var borderWidth: CGFloat {
    isSelected ? Size.strokeSelected : Size.strokeDefault
  }
}
```

### Step 3.3: Update AddWallpaperButton with Distinct Style

**File:** `ClaudeShot/Features/Annotate/Views/AnnotateSidebarComponents.swift`
**Lines:** 106-122

```swift
struct AddWallpaperButton: View {
  let action: () -> Void

  @State private var isHovering = false

  var body: some View {
    Button(action: action) {
      RoundedRectangle(cornerRadius: Size.radiusMd)
        .fill(isHovering ? SidebarColors.actionButtonHover : SidebarColors.actionButton)
        .frame(width: Size.gridItem, height: Size.gridItem)
        .overlay(
          RoundedRectangle(cornerRadius: Size.radiusMd)
            .strokeBorder(
              style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]),
              antialiased: true
            )
            .foregroundColor(isHovering ? .primary.opacity(0.6) : .primary.opacity(0.3))
        )
        .overlay(
          Image(systemName: "plus")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(isHovering ? .primary.opacity(0.8) : .primary.opacity(0.5))
        )
        .scaleEffect(isHovering ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovering)
    }
    .buttonStyle(.plain)
    .onHover { isHovering = $0 }
  }
}
```

### Step 3.4: Update ColorSwatch with Hover

**File:** `ClaudeShot/Features/Annotate/Views/AnnotateSidebarComponents.swift`
**Lines:** 161-178

```swift
struct ColorSwatch: View {
  let color: Color
  let isSelected: Bool
  let action: () -> Void

  @State private var isHovering = false

  var body: some View {
    Button(action: action) {
      Circle()
        .fill(color)
        .frame(width: Size.colorSwatchSmall, height: Size.colorSwatchSmall)
        .overlay(
          Circle()
            .stroke(borderColor, lineWidth: borderWidth)
        )
        .scaleEffect(isHovering && !isSelected ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.12), value: isHovering)
    }
    .buttonStyle(.plain)
    .onHover { isHovering = $0 }
  }

  private var borderColor: Color {
    if isSelected { return SidebarColors.borderSelected }
    if isHovering { return SidebarColors.borderHover }
    return Color.secondary.opacity(0.3)
  }

  private var borderWidth: CGFloat {
    isSelected ? Size.strokeSelected : Size.strokeDefault
  }
}
```

### Step 3.5: Update None Button

**File:** `ClaudeShot/Features/Annotate/Views/AnnotateSidebarView.swift`
**Lines:** 72-89

```swift
// Add @State for hover at struct level if needed, or create separate component

struct NoneBackgroundButton: View {
  let isSelected: Bool
  let action: () -> Void

  @State private var isHovering = false

  var body: some View {
    Button(action: action) {
      Text("None")
        .font(Typography.labelMedium)
        .foregroundColor(.primary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .background(
          RoundedRectangle(cornerRadius: Size.radiusMd)
            .fill(backgroundColor)
        )
        .overlay(
          RoundedRectangle(cornerRadius: Size.radiusMd)
            .stroke(isHovering ? SidebarColors.borderHover : .clear, lineWidth: 1)
        )
    }
    .buttonStyle(.plain)
    .onHover { isHovering = $0 }
  }

  private var backgroundColor: Color {
    if isSelected { return SidebarColors.itemSelected }
    if isHovering { return SidebarColors.itemHover }
    return SidebarColors.itemDefault
  }
}
```

### Step 3.6: Update AlignmentCell

**File:** `ClaudeShot/Features/Annotate/Views/AnnotateSidebarComponents.swift`
**Lines:** 234-248

```swift
struct AlignmentCell: View {
  let alignment: ImageAlignment
  let isSelected: Bool
  let action: () -> Void

  @State private var isHovering = false

  var body: some View {
    Button(action: action) {
      Rectangle()
        .fill(backgroundColor)
        .frame(width: 20, height: 20)
        .cornerRadius(Size.radiusSm)
    }
    .buttonStyle(.plain)
    .onHover { isHovering = $0 }
  }

  private var backgroundColor: Color {
    if isSelected { return Color.accentColor }
    if isHovering { return Color.secondary.opacity(0.5) }
    return Color.secondary.opacity(0.3)
  }
}
```

## Validation Checklist

- [ ] All buttons show hover state on mouse enter
- [ ] Scale animation is smooth (0.15s duration)
- [ ] Selected state takes priority over hover
- [ ] Add button has distinct dashed border style
- [ ] Color swatches scale on hover
- [ ] No flickering during rapid hover changes

## Next Phase

Proceed to [Phase 4: Polish and Accessibility](./phase-04-polish-and-accessibility.md).
