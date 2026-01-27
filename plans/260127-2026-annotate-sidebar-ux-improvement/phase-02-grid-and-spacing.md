# Phase 2: Grid and Spacing

**Effort:** 6 hours
**Priority:** High
**Dependencies:** Phase 1 (DesignTokens.swift)

## Objective

Apply consistent 8pt grid system across all sidebar sections. Standardize item sizes and gaps.

## Changes Summary

| Component | Before | After |
|-----------|--------|-------|
| Grid item size | 44px | 48px |
| Color swatch size | 28px | 32px |
| Grid gap | 6px | 8px |
| Section spacing | 12px | 16px |
| Internal spacing | 6-10px | 8px |

## Implementation

### Step 2.1: Update AnnotateSidebarView.swift

**File:** `ClaudeShot/Features/Annotate/Views/AnnotateSidebarView.swift`

**Change 1: Main VStack spacing (line 16)**

```swift
// BEFORE
VStack(alignment: .leading, spacing: 12) {

// AFTER
VStack(alignment: .leading, spacing: Spacing.md) {  // 16px
```

**Change 2: Padding (line 64)**

```swift
// BEFORE
.padding(12)

// AFTER
.padding(Spacing.md)  // 16px
```

**Change 3: Gradient section grid (lines 97-98)**

```swift
// BEFORE
LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {

// AFTER
LazyVGrid(
  columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: GridConfig.backgroundColumns),
  spacing: Spacing.sm
) {
```

**Change 4: Color section grid (line 211)**

```swift
// BEFORE
LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 5), spacing: 4) {

// AFTER
LazyVGrid(
  columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: GridConfig.colorColumns),
  spacing: Spacing.sm
) {
```

**Change 5: Color circle size (line 218)**

```swift
// BEFORE
.frame(width: 28, height: 28)

// AFTER
.frame(width: Size.colorSwatch, height: Size.colorSwatch)  // 32px
```

**Change 6: Section internal spacing (lines 94, 120)**

```swift
// BEFORE
VStack(alignment: .leading, spacing: 6) {

// AFTER
VStack(alignment: .leading, spacing: Spacing.sm) {  // 8px
```

### Step 2.2: Update AnnotateSidebarComponents.swift

**File:** `ClaudeShot/Features/Annotate/Views/AnnotateSidebarComponents.swift`

**Change 1: GradientPresetButton size (lines 34-35)**

```swift
// BEFORE
.frame(width: 44, height: 44)

// AFTER
.frame(width: Size.gridItem, height: Size.gridItem)  // 48px
```

**Change 2: GradientPresetButton radius (lines 32, 36-37)**

```swift
// BEFORE
RoundedRectangle(cornerRadius: 6)

// AFTER
RoundedRectangle(cornerRadius: Size.radiusMd)  // 8px
```

**Change 3: WallpaperPresetButton size (lines 64-65)**

```swift
// BEFORE
.frame(width: 44, height: 44)

// AFTER
.frame(width: Size.gridItem, height: Size.gridItem)  // 48px
```

**Change 4: CustomWallpaperButton size (lines 93-94)**

```swift
// BEFORE
.frame(width: 44, height: 44)

// AFTER
.frame(width: Size.gridItem, height: Size.gridItem)  // 48px
```

**Change 5: AddWallpaperButton size (line 114)**

```swift
// BEFORE
.frame(width: 44, height: 44)

// AFTER
.frame(width: Size.gridItem, height: Size.gridItem)  // 48px
```

**Change 6: ColorSwatch size (line 170)**

```swift
// BEFORE
.frame(width: 24, height: 24)

// AFTER
.frame(width: Size.colorSwatchSmall, height: Size.colorSwatchSmall)  // 24px (keep for inline pickers)
```

**Change 7: AlignmentGrid spacing (lines 212, 214)**

```swift
// BEFORE
VStack(spacing: 2) {
  // ...
  HStack(spacing: 2) {

// AFTER
VStack(spacing: Spacing.xs) {  // 4px
  // ...
  HStack(spacing: Spacing.xs) {  // 4px
```

### Step 2.3: Update AnnotateSidebarSections.swift

**File:** `ClaudeShot/Features/Annotate/Views/AnnotateSidebarSections.swift`

**Change 1: SidebarGradientSection grid (line 21)**

```swift
// BEFORE
LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {

// AFTER
LazyVGrid(
  columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: GridConfig.backgroundColumns),
  spacing: Spacing.sm
) {
```

**Change 2: SidebarWallpaperSection grid (line 45)**

```swift
// BEFORE
LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {

// AFTER
LazyVGrid(
  columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: GridConfig.backgroundColumns),
  spacing: Spacing.sm
) {
```

**Change 3: Section VStack spacing consistency (lines 18, 42, 118, 135)**

```swift
// BEFORE (varies: 8, 6, 8, 8)
VStack(alignment: .leading, spacing: 8) {

// AFTER (consistent)
VStack(alignment: .leading, spacing: Spacing.sm) {  // 8px
```

## Visual Comparison

```
BEFORE                          AFTER
+--+--+--+--+                   +----+----+----+----+
|44|44|44|44|  6px gap          | 48 | 48 | 48 | 48 |  8px gap
+--+--+--+--+                   +----+----+----+----+
|44|44|44|44|                   | 48 | 48 | 48 | 48 |
+--+--+--+--+                   +----+----+----+----+

Colors: 28px, 5 cols, 4px      Colors: 32px, 6 cols, 8px
```

## Validation Checklist

- [ ] All grid items render at 48x48px
- [ ] All color swatches render at 32x32px
- [ ] 8px gaps between all grid items
- [ ] 16px section spacing
- [ ] No visual clipping or overflow
- [ ] Sidebar width accommodates new sizes

## Next Phase

Proceed to [Phase 3: Interaction States](./phase-03-interaction-states.md) to add hover and focus states.
