# Phase 1: Design System Foundation

**Effort:** 4 hours
**Priority:** High (prerequisite for all other phases)

## Objective

Create centralized design tokens for consistent spacing, sizing, and colors across the sidebar.

## Deliverables

1. New `DesignTokens.swift` file with all constants
2. Document token usage guidelines

## Implementation

### Step 1.1: Create DesignTokens.swift

**File:** `ClaudeShot/Features/Annotate/Views/DesignTokens.swift`

```swift
//
//  DesignTokens.swift
//  ClaudeShot
//
//  Centralized design tokens for consistent UI
//

import SwiftUI

// MARK: - Spacing (8pt Grid)

enum Spacing {
  static let xs: CGFloat = 4    // Tight spacing (icons, compact lists)
  static let sm: CGFloat = 8    // Standard gap
  static let md: CGFloat = 16   // Section padding
  static let lg: CGFloat = 24   // Large gaps
  static let xl: CGFloat = 32   // Major sections
}

// MARK: - Sizing

enum Size {
  // Grid items (backgrounds, wallpapers)
  static let gridItem: CGFloat = 48
  static let gridItemSmall: CGFloat = 40

  // Color swatches
  static let colorSwatch: CGFloat = 32
  static let colorSwatchSmall: CGFloat = 24

  // Corner radii
  static let radiusSm: CGFloat = 4
  static let radiusMd: CGFloat = 8
  static let radiusLg: CGFloat = 12

  // Strokes
  static let strokeDefault: CGFloat = 1
  static let strokeSelected: CGFloat = 2
}

// MARK: - Typography

enum Typography {
  static let labelSmall: Font = .system(size: 10)
  static let labelMedium: Font = .system(size: 11, weight: .medium)
  static let sectionHeader: Font = .system(size: 11, weight: .semibold)
  static let body: Font = .system(size: 12)
}

// MARK: - Colors (Semantic)

enum SidebarColors {
  // Backgrounds
  static let itemDefault = Color.primary.opacity(0.05)
  static let itemHover = Color.primary.opacity(0.10)
  static let itemSelected = Color.accentColor.opacity(0.15)

  // Borders
  static let borderDefault = Color.secondary.opacity(0.3)
  static let borderHover = Color.secondary.opacity(0.5)
  static let borderSelected = Color.accentColor

  // Text
  static let labelPrimary = Color.primary
  static let labelSecondary = Color.secondary
  static let labelTertiary = Color.secondary.opacity(0.7)

  // Actions
  static let actionButton = Color.primary.opacity(0.08)
  static let actionButtonHover = Color.primary.opacity(0.15)
}

// MARK: - Grid Configuration

enum GridConfig {
  static let backgroundColumns = 4
  static let colorColumns = 6
  static let gap = Spacing.sm
}
```

### Step 1.2: Define Component Style Protocol

Add to `DesignTokens.swift`:

```swift
// MARK: - Interactive States Protocol

protocol InteractiveStyle {
  var isHovering: Bool { get }
  var isSelected: Bool { get }

  var backgroundColor: Color { get }
  var borderColor: Color { get }
  var borderWidth: CGFloat { get }
}

extension InteractiveStyle {
  var backgroundColor: Color {
    if isSelected { return SidebarColors.itemSelected }
    if isHovering { return SidebarColors.itemHover }
    return SidebarColors.itemDefault
  }

  var borderColor: Color {
    if isSelected { return SidebarColors.borderSelected }
    if isHovering { return SidebarColors.borderHover }
    return .clear
  }

  var borderWidth: CGFloat {
    isSelected ? Size.strokeSelected : Size.strokeDefault
  }
}
```

### Step 1.3: Create Base Button Modifier

Add to `DesignTokens.swift`:

```swift
// MARK: - Sidebar Item Modifier

struct SidebarItemStyle: ViewModifier {
  let isSelected: Bool
  @State private var isHovering = false

  func body(content: Content) -> some View {
    content
      .background(
        RoundedRectangle(cornerRadius: Size.radiusMd)
          .fill(backgroundColor)
      )
      .overlay(
        RoundedRectangle(cornerRadius: Size.radiusMd)
          .stroke(borderColor, lineWidth: borderWidth)
      )
      .onHover { isHovering = $0 }
  }

  private var backgroundColor: Color {
    if isSelected { return SidebarColors.itemSelected }
    if isHovering { return SidebarColors.itemHover }
    return Color.clear
  }

  private var borderColor: Color {
    if isSelected { return SidebarColors.borderSelected }
    if isHovering { return SidebarColors.borderHover }
    return Color.clear
  }

  private var borderWidth: CGFloat {
    isSelected ? Size.strokeSelected : Size.strokeDefault
  }
}

extension View {
  func sidebarItemStyle(isSelected: Bool) -> some View {
    modifier(SidebarItemStyle(isSelected: isSelected))
  }
}
```

## Validation Checklist

- [ ] DesignTokens.swift compiles without errors
- [ ] All spacing values align to 8pt grid
- [ ] Colors work in both light and dark mode
- [ ] ViewModifier applies correctly in preview

## Next Phase

Proceed to [Phase 2: Grid and Spacing](./phase-02-grid-and-spacing.md) to apply tokens to existing components.
