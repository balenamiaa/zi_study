# ZiStudy Design System

This document outlines the design system used in ZiStudy, including colors, typography, spacing, and component usage guidelines. ZiStudy follows a modern, clean aesthetic with a focus on readability, usability, and visual appeal.

## Table of Contents

1. [Color Palette](#color-palette)
2. [Typography](#typography)
3. [Spacing and Layout](#spacing-and-layout)
4. [Components](#components)
5. [Best Practices](#best-practices)
6. [Effects and Animations](#effects-and-animations)
7. [Iconography](#iconography)
8. [Component Encapsulation](#component-encapsulation)
9. [Design Principles](#design-principles)
10. [daisyUI Integration](#daisyui-integration)

## Color Palette

ZiStudy uses daisyUI with custom theme colors defined in oklch color format. The system supports both dark and light themes.

### Dark Theme (Default)

| Variable | oklch | Usage |
|----------|-------|-------|
| --color-base-100 | oklch(24% 0.023 329.708) | Main background |
| --color-base-200 | oklch(21% 0.021 329.708) | Subtle background, card background |
| --color-base-300 | oklch(16% 0.019 329.708) | Accent background, borders |
| --color-base-content | oklch(72.354% 0.092 79.129) | Main content text |
| --color-primary | oklch(71.996% 0.123 62.756) | Primary buttons, links, accents |
| --color-primary-content | oklch(14.399% 0.024 62.756) | Text on primary backgrounds |
| --color-secondary | oklch(34.465% 0.029 199.194) | Secondary actions, complementary elements |
| --color-secondary-content | oklch(86.893% 0.005 199.194) | Text on secondary backgrounds |
| --color-accent | oklch(42.621% 0.074 224.389) | Accent elements, highlights |
| --color-accent-content | oklch(88.524% 0.014 224.389) | Text on accent backgrounds |
| --color-neutral | oklch(16.51% 0.015 326.261) | Neutral elements |
| --color-neutral-content | oklch(83.302% 0.003 326.261) | Text on neutral backgrounds |
| --color-info | oklch(79.49% 0.063 184.558) | Information messages, states |
| --color-info-content | oklch(15.898% 0.012 184.558) | Text on info backgrounds |
| --color-success | oklch(74.722% 0.072 131.116) | Success messages, states |
| --color-success-content | oklch(14.944% 0.014 131.116) | Text on success backgrounds |
| --color-warning | oklch(88.15% 0.14 87.722) | Warning messages, states |
| --color-warning-content | oklch(17.63% 0.028 87.722) | Text on warning backgrounds |
| --color-error | oklch(77.318% 0.128 31.871) | Error messages, states |
| --color-error-content | oklch(15.463% 0.025 31.871) | Text on error backgrounds |

### Light Theme

| Variable | oklch | Usage |
|----------|-------|-------|
| --color-base-100 | oklch(98% 0.016 73.684) | Main background |
| --color-base-200 | oklch(95% 0.038 75.164) | Subtle background, card background |
| --color-base-300 | oklch(90% 0.076 70.697) | Accent background, borders |
| --color-base-content | oklch(40% 0.123 38.172) | Main content text |
| --color-primary | oklch(0% 0 0) | Primary buttons, links, accents |
| --color-primary-content | oklch(100% 0 0) | Text on primary backgrounds |
| --color-secondary | oklch(22.45% 0.075 37.85) | Secondary actions, complementary elements |
| --color-secondary-content | oklch(90% 0.076 70.697) | Text on secondary backgrounds |
| --color-accent | oklch(46.44% 0.111 37.85) | Accent elements, highlights |
| --color-accent-content | oklch(90% 0.076 70.697) | Text on accent backgrounds |
| --color-neutral | oklch(55% 0.195 38.402) | Neutral elements |
| --color-neutral-content | oklch(98% 0.016 73.684) | Text on neutral backgrounds |
| --color-info | oklch(42% 0.199 265.638) | Information messages, states |
| --color-info-content | oklch(90% 0.076 70.697) | Text on info backgrounds |
| --color-success | oklch(43% 0.095 166.913) | Success messages, states |
| --color-success-content | oklch(90% 0.076 70.697) | Text on success backgrounds |
| --color-warning | oklch(82% 0.189 84.429) | Warning messages, states |
| --color-warning-content | oklch(41% 0.112 45.904) | Text on warning backgrounds |
| --color-error | oklch(70% 0.191 22.216) | Error messages, states |
| --color-error-content | oklch(39% 0.141 25.723) | Text on error backgrounds |

### Design Tokens

| Token | Value | Usage |
|-------|-------|-------|
| --radius-selector | 0.5rem (dark), 2rem (light) | Rounded corners for selectors |
| --radius-field | 0.5rem | Rounded corners for input fields |
| --radius-box | 1rem | Rounded corners for boxes, cards |
| --size-selector | 0.21875rem (dark), 0.25rem (light) | Size for selectors |
| --size-field | 0.25rem | Size for fields |
| --border | 2px | Border width |
| --depth | 1 | Depth effect intensity |
| --noise | 1 | Noise texture intensity |

## Typography

ZiStudy uses a combination of fonts to create hierarchy and visual interest:

### Font Families

- **Headers**: Poppins (semi-bold, medium)
- **Body**: Inter (regular, medium)

### Font Sizes

| Element | Size | Weight | Line Height |
|---------|------|--------|-------------|
| h1 | 2.5rem (40px) | 500 | 1.2 |
| h2 | 2rem (32px) | 500 | 1.25 |
| h3 | 1.5rem (24px) | 500 | 1.3 |
| h4 | 1.25rem (20px) | 500 | 1.35 |
| h5 | 1.125rem (18px) | 500 | 1.4 |
| h6 | 1rem (16px) | 500 | 1.5 |
| Body text | 1rem (16px) | 400 | 1.5 |
| Small text | 0.875rem (14px) | 400 | 1.5 |
| Caption | 0.75rem (12px) | 400 | 1.5 |
| Button text | 0.875rem (14px) | 500 | 1.5 |

## Spacing and Layout

ZiStudy follows a 4px grid system for spacing and layout. The following spacing increments are used throughout the application:

| Name | Size | Usage |
|------|------|-------|
| xs | 4px | Very small gaps |
| sm | 8px | Small gaps, internal padding |
| md | 16px | Standard spacing |
| lg | 24px | Larger separation between related elements |
| xl | 32px | Section spacing |
| 2xl | 48px | Major section divisions |
| 3xl | 64px | Page-level spacing |

### Container Widths

- **Small**: 640px
- **Medium**: 768px
- **Large**: 1024px
- **Extra Large**: 1280px
- **2XL**: 1536px
- **Max Content Width**: 1440px

## Components

### Buttons

#### Variants

- **Primary**: Solid buttons with primary color background, used for main actions
- **Secondary**: Solid buttons with secondary color background, used for alternative actions
- **Outlined**: Border only with transparent background, less emphasis than primary/secondary
- **Text**: No border or background, used for the least emphasis or in tight spaces

#### Button States

- **Normal**: Default state
- **Hover**:
  - Light mode: Slightly darker background (#D81B60) for primary buttons, subtle background for text/outlined variants
  - Dark mode: Pink-tinted hover state (rgba(240, 98, 146, 0.12)) for better consistency with dark theme
- **Active**: Darker background color, slight inset appearance
- **Disabled**: Reduced opacity, no interaction
- **Focus**: Focus ring using primary color at reduced opacity

### Cards

Cards are used to group related content and actions:

- **Standard card**: Basic container with padding and light border
- **Card with header**: Includes a title area with optional subtitle
- **Card with icon**: Header can include an icon for visual interest
- **Card with footer**: Contains actions at the bottom
- **Elevated card**: With shadow levels (1-5) for visual hierarchy

### Form Controls

#### Text Input

- **Standard**: With label, optional helper text
- **With icons**: Leading or trailing icons
- **States**: Normal, focus, disabled, error, autofill
- **Variants**: Outlined, filled

##### Autofill Handling

Form inputs have special styling to handle browser autofill functionality using Tailwind's autofill utilities:
- Maintains dark mode background when browser autofills inputs
- Explicitly sets text color to white in dark mode to ensure visibility
- Ensures cursor color remains visible in autofilled fields
- Applies consistent border styling with the rest of the design system
- Handles combined states (autofill + focus, autofill + active)
- Prevents the default yellow background in both light and dark modes
- Ensures text is immediately visible without requiring user interaction
- Uses Tailwind's autofill modifiers for consistent styling across browsers
- Uses direct text-white class for dark mode to override browser defaults

#### Selection Controls

- **Checkbox**: For multi-select options
- **Radio button**: For single-select options
- **Switch**: For binary on/off states
- **Dropdown**: For selecting from a list

## Effects and Animations

### Ripple Effect

Material-style ripple effect provides tactile feedback for interactive elements:

- Applied to buttons, cards, and other clickable elements
- Created using the `.ripple` class
- Works for nested elements (propagates to parent)
- Subtle but effective visual cue for user interactions

### Micro-interactions

Subtle animations that provide feedback and enhance the user experience:

- Button hover/press states with scale transforms (95%-105%)
- Card hover effects with subtle elevation changes
- Input focus animations with smooth border transitions
- Success/error state animations
- Loading indicators and progress animations

### Transitions

Standard timing functions for smooth UI transitions:

- **Standard**: cubic-bezier(0.4, 0, 0.2, 1) - for most transitions (300ms)
- **Enter**: cubic-bezier(0, 0, 0.2, 1) - for elements entering the screen (225ms)
- **Exit**: cubic-bezier(0.4, 0, 1, 1) - for elements leaving the screen (195ms)
- **Emphasis**: cubic-bezier(0.4, 0, 0.6, 1) - for attention-grabbing elements (500ms)

### Theme Switching

Smooth transition between light and dark themes:

- Background, text, and surface transitions last 300ms
- Icon rotation effect during theme switching (360 degrees)
- Subtle scale effect on theme icon (1.2x)
- Consistent ripple effect across themes
- Color shifts use the standard timing function

## Best Practices

### Accessibility

- Maintain a minimum contrast ratio of 4.5:1 for normal text and 3:1 for large text
- Ensure all interactive elements are keyboard accessible
- Provide text alternatives for non-text content
- Design focus states that are clearly visible

### Responsive Design

- Use fluid layouts that adapt to different screen sizes
- Design mobile-first, then enhance for larger screens
- Use appropriate component sizing for touch targets (minimum 44×44px)
- Test layouts at multiple breakpoints

### Visual Hierarchy

- Use size, color, and spacing to create clear hierarchy
- Maintain consistent alignment throughout the interface
- Group related elements visually
- Limit the number of visual weights on a single screen

### Color Usage

- Use the primary color for main actions and key elements
- Apply accent colors sparingly for emphasis
- Rely on neutral colors for most UI elements
- Ensure color is not the only means of conveying information
- Dark theme uses pink-tinted background for brand consistency
- Light theme uses soft pink-tinted background for a calm, modern feel

## Iconography

ZiStudy uses **Lucide Icons** for all iconography. Lucide provides a comprehensive, consistent set of modern, clean icons that align perfectly with our design aesthetic. All icons should use the ZiIcon component which wraps Lucide icons.

### Usage Guidelines
- All icons should use the `ZiIcon` component with the appropriate icon from the `Icons` enum.
- Standard size classes should be used (e.g., `text-sm`, `text-2xl`, etc.).
- Color classes should follow our color system (e.g., `text-primary dark:text-primary-300`).
- Icons should have appropriate aria-labels for accessibility.

### Icon Styling
- Use consistent sizing within context (navigation, buttons, etc.)
- Apply subtle animations for interactive icons (hover, active states)
- Maintain adequate spacing around icons (minimum 4px)
- Use the same weight/style throughout the application

#### Common Icons (Lucide)
| Usage | Icon Enum |
|-------|----------|
| User | Icons.User |
| Home | Icons.House |
| Study | Icons.Book |
| Notes | Icons.FileText |
| Security | Icons.Shield |
| Settings | Icons.Cog |
| Logout | Icons.Logout |
| Login | Icons.Login |
| Register | Icons.UserPlus |
| Check | Icons.CheckCircle |
| Menu | Icons.Menu |
| Close | Icons.X |
| Dropdown | Icons.ChevronDown |
| Email | Icons.Email |
| Lightning | Icons.Zap |
| Book | Icons.BookOpen |
| Message | Icons.MessageSquare |
| Sparkle | Icons.Sparkles |

## Component Encapsulation

All basic UI elements (such as **inputs**, **buttons**, **selects**, etc.) must be encapsulated as reusable components. This ensures consistency, maintainability, and adherence to the design system. Each component should:
- Encapsulate all styling, icon usage, and state logic.
- Accept parameters for customization (e.g., label, icon, error state, etc.).
- Use FontAwesome for any iconography.
- Follow the patterns shown in the `Input.kt` example (see `src/webMain/kotlin/zi_study/components/Input.kt`).
- Be placed in the `components` package/directory.

This approach applies to:
- Buttons (primary, secondary, outlined, text, etc.)
- Inputs (text, password, email, etc.)
- Selects and dropdowns
- Cards
- Any other reusable UI element

---

## Design Principles

### Clarity
- Content is presented clearly and efficiently
- Visual elements support rather than distract from content
- Information hierarchy guides users through the interface
- Typography enhances readability across all screen sizes

### Consistency
- UI elements behave predictably throughout the application
- Visual language remains consistent across all screens
- Spacing, sizing, and positioning follow established patterns
- Color usage adheres to the defined palette and meanings

### Feedback
- Interactive elements provide clear visual feedback
- System status is always visible and understandable
- Errors are presented constructively with solutions
- Animations and transitions provide context for state changes

### Efficiency
- Common tasks can be completed with minimal steps
- UI is optimized for both novice and expert users
- Layout adapts intelligently to different screen sizes
- Performance is prioritized for a smooth experience

### Delight
- Micro-interactions add moments of delight
- Animations are purposeful and enhance usability
- Visual design is polished and professional
- The overall experience feels cohesive and thoughtful

This design system is a living document and will evolve as ZiStudy grows and develops.

## daisyUI Integration

ZiStudy leverages daisyUI, a component library for Tailwind CSS, to provide consistent and beautiful UI components.

### Theme Configuration

- Dark theme is set as default with `prefersdark` priority
- Light theme is available as an alternative
- Custom colors are defined in oklch format for better color perception
- Theme switching is handled by daisyUI's theme system

### Using daisyUI Components

ZiStudy uses the following daisyUI components:

#### Buttons

```html
<button class="btn btn-primary">Primary Button</button>
<button class="btn btn-secondary">Secondary Button</button>
<button class="btn btn-accent">Accent Button</button>
<button class="btn btn-ghost">Ghost Button</button>
<button class="btn btn-link">Link Button</button>
```

#### Cards

```html
<div class="card bg-base-100 shadow-xl">
  <figure><img src="example.jpg" alt="Example" /></figure>
  <div class="card-body">
    <h2 class="card-title">Card Title</h2>
    <p>Card content goes here</p>
    <div class="card-actions justify-end">
      <button class="btn btn-primary">Action</button>
    </div>
  </div>
</div>
```

#### Form Elements

```html
<div class="form-control w-full max-w-xs">
  <label class="label">
    <span class="label-text">Input Label</span>
  </label>
  <input type="text" placeholder="Type here" class="input input-bordered w-full max-w-xs" />
</div>

<div class="form-control">
  <label class="label cursor-pointer">
    <span class="label-text">Remember me</span>
    <input type="checkbox" class="checkbox checkbox-primary" />
  </label>
</div>
```

#### Alerts

```html
<div class="alert alert-info">
  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="stroke-current shrink-0 w-6 h-6"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
  <span>Information message</span>
</div>

<div class="alert alert-success">
  <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
  <span>Success message</span>
</div>
```

### Phoenix LiveView Integration

ZiStudy integrates daisyUI components with Phoenix LiveView:

- Custom variants for LiveView states: `phx-click-loading`, `phx-submit-loading`, `phx-change-loading`
- LiveView wrapper divs are set to `display: contents` for seamless layout integration
- Loading states are visually represented through daisyUI's loading components

### Custom Component Guidelines

When creating custom components that use daisyUI:

1. Use daisyUI's semantic color classes (`primary`, `secondary`, etc.) instead of specific color values
2. Leverage daisyUI's utility classes for consistent spacing and sizing
3. Follow daisyUI's component patterns for consistent behavior
4. Override styles only when necessary to maintain design system consistency