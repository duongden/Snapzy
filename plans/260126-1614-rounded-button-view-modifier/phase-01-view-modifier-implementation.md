# Phase 01: Corner Radius & Button Modifier Implementation

## Context Links
- Parent Plan: [plan.md](./plan.md)
- Dependencies: None
- Docs: N/A

## Overview
| Field | Value |
|-------|-------|
| Date | 2026-01-26 |
| Description | Create CornerRadius and Button ViewModifiers with selective corner support |
| Priority | Medium |
| Implementation Status | ⬜ Not Started |
| Review Status | 🟡 Pending |

## Key Insights
- SwiftUI's built-in `.cornerRadius()` doesn't support selective corners
- Need custom `Shape` to clip specific corners using `UIRectCorner` equivalent for macOS
- `.button()` modifier should compose with `.cornerRadius()` for flexibility

## Requirements
1. **RectCorner OptionSet** - Define corners: `.topLeft`, `.topRight`, `.bottomLeft`, `.bottomRight`, `.allCorners`
2. **`.rounded()`** - Default 8pt, all corners
3. **`.rounded(_:corners:)`** - Custom radius with selective corners
4. **`.button()`** - Apply button styling (padding, background, foreground, stroke)

## Architecture

```
ClaudeShot/Core/
├── View+CornerRadius.swift  <- NEW FILE
│   ├── RectCorner (OptionSet)
│   ├── RoundedCornerShape (Shape)
│   └── View extension: .cornerRadius(), .cornerRadius(_:corners:)
│
└── View+ButtonStyle.swift   <- NEW FILE
    ├── ButtonStyleModifier (ViewModifier)
    └── View extension: .button()
```

## Related Code Files
| File | Purpose |
|------|---------|
| `ClaudeShot/Core/View+CornerRadius.swift` | NEW - Corner radius with selective corners |
| `ClaudeShot/Core/View+ButtonStyle.swift` | NEW - Button appearance modifier |

## Implementation Steps

### Step 1: Create RectCorner OptionSet & Shape
```swift
// View+CornerRadius.swift

struct RectCorner: OptionSet {
    let rawValue: Int

    static let topLeft = RectCorner(rawValue: 1 << 0)
    static let topRight = RectCorner(rawValue: 1 << 1)
    static let bottomLeft = RectCorner(rawValue: 1 << 2)
    static let bottomRight = RectCorner(rawValue: 1 << 3)
    static let allCorners: RectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}

struct RoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: RectCorner

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let tl = corners.contains(.topLeft) ? radius : 0
        let tr = corners.contains(.topRight) ? radius : 0
        let bl = corners.contains(.bottomLeft) ? radius : 0
        let br = corners.contains(.bottomRight) ? radius : 0

        // Draw path with selective corner radii
        path.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
        path.addArc(...)  // top-right
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
        path.addArc(...)  // bottom-right
        path.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
        path.addArc(...)  // bottom-left
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
        path.addArc(...)  // top-left
        path.closeSubpath()

        return path
    }
}
```

### Step 2: Create View Extension for Corner Radius
```swift
extension View {
    /// Default corner radius (8pt, all corners)
    func cornerRadius(_ radius: CGFloat = 8) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: .allCorners))
    }

    /// Custom corner radius with selective corners
    func cornerRadius(_ radius: CGFloat, corners: RectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}
```

### Step 3: Create Button Style Modifier
```swift
// View+ButtonStyle.swift

struct ButtonStyleModifier: ViewModifier {
    var backgroundColor: Color
    var foregroundColor: Color
    var strokeColor: Color?
    var strokeWidth: CGFloat
    var horizontalPadding: CGFloat
    var verticalPadding: CGFloat
    var cornerRadius: CGFloat
    var corners: RectCorner

    func body(content: Content) -> some View {
        content
            .foregroundColor(foregroundColor)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(backgroundColor)
            .overlay(
                RoundedCornerShape(radius: cornerRadius, corners: corners)
                    .stroke(strokeColor ?? .clear, lineWidth: strokeWidth)
            )
            .cornerRadius(cornerRadius, corners: corners)
    }
}

extension View {
    /// Apply button styling to any view
    func button(
        backgroundColor: Color = .clear,
        foregroundColor: Color = .primary,
        strokeColor: Color? = nil,
        strokeWidth: CGFloat = 1,
        horizontalPadding: CGFloat = 16,
        verticalPadding: CGFloat = 8,
        cornerRadius: CGFloat = 8,
        corners: RectCorner = .allCorners
    ) -> some View {
        modifier(ButtonStyleModifier(...))
    }
}
```

## Usage Examples

```swift
// Default corner radius (8pt, all corners)
Image("photo")
    .cornerRadius()

// Custom corner radius with selective corners
Rectangle()
    .cornerRadius(20, corners: [.topLeft, .bottomRight])

// Text styled as filled button
Text("Done")
    .button(backgroundColor: .blue, foregroundColor: .white)

// Text styled as outline button
Text("Save as...")
    .button(strokeColor: .gray, foregroundColor: .white)

// Combined: button with selective corners
Text("Custom")
    .button(backgroundColor: .green, cornerRadius: 12, corners: [.topLeft, .topRight])
```

## Todo List
- [ ] Create `ClaudeShot/Core/View+CornerRadius.swift`
  - [ ] Implement `RectCorner` OptionSet
  - [ ] Implement `RoundedCornerShape` Shape
  - [ ] Implement View extension `.cornerRadius()` methods
- [ ] Create `ClaudeShot/Core/View+ButtonStyle.swift`
  - [ ] Implement `ButtonStyleModifier`
  - [ ] Implement View extension `.button()` method
- [ ] Add files to Xcode project
- [ ] Test with sample views

## Success Criteria
- [ ] `.cornerRadius()` applies 8pt to all corners by default
- [ ] `.cornerRadius(20, corners: [.topLeft, .bottomRight])` rounds only specified corners
- [ ] `.button()` applies padding, background, foreground, stroke styling
- [ ] All colors fully customizable (not hardcoded)
- [ ] Works with any View (Text, Image, HStack, etc.)

## Risk Assessment
| Risk | Impact | Mitigation |
|------|--------|------------|
| Low | Standard SwiftUI Shape/ViewModifier pattern | Follow existing conventions |

## Security Considerations
- None - UI styling only

## Next Steps
After approval:
1. Implement `View+CornerRadius.swift`
2. Implement `View+ButtonStyle.swift`
3. Add to Xcode project
4. Test implementations
