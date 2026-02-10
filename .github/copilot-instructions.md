# DOTOG Copilot Instructions

## Project Overview

DOTOG is an idle dungeon crawler game prototype built with Flutter. Korean is the primary language for all user-facing text, comments, and documentation.

## Architecture

### Feature-Based Structure

- Features live in `lib/features/{feature_name}/presentation/`
- Each feature is self-contained with its own screens and widgets
- Current features: `home`, `dungeon`, `codex`
- Shared code: `lib/shared/{widgets,providers}/`

### Data Layer Architecture

#### Shared Models (`lib/shared/models/`)

- **`rarity.dart`**: Enum for item rarity (common, rare, legendary)
- **`player_model.dart`**: Player state (HP, attack, defense, luck, runes, level)
- **`item_model.dart`**: Item/artifact definition with stat bonuses
- **`codex_entry_model.dart`**: Codex entry combining item with collection state

#### Feature-Specific Models

Each feature has a `domain/models/` directory for feature-specific models:

- **Dungeon** (`lib/features/dungeon/domain/models/`):
  - `log_type.dart`: Enum for combat log types
  - `combat_log_model.dart`: Combat log entries with timestamp and type
  - `dungeon_state_model.dart`: Complete dungeon state (floor, player, logs, ontologies)
- **Codex** (`lib/features/codex/domain/models/`):
  - `codex_state_model.dart`: Codex state with filtering and completion tracking

#### Mock Data

Mock data lives in `data/` directories:

- `lib/shared/data/mock_items.dart`: Central item database
- `lib/features/dungeon/data/mock_combat_logs.dart`: Sample combat logs

#### Model Patterns

- Use immutable models with `const` constructors
- Provide `copyWith()` methods for state updates
- Include factory constructors like `.initial()` or `.undiscovered()` for common states
- Models are plain Dart classes (no code generation) for simplicity

Example model:

```dart
class PlayerModel {
  const PlayerModel({
    required this.currentHp,
    required this.maxHp,
    // ... other fields
  });

  final int currentHp;
  final int maxHp;

  PlayerModel copyWith({int? currentHp, int? maxHp}) {
    return PlayerModel(
      currentHp: currentHp ?? this.currentHp,
      maxHp: maxHp ?? this.maxHp,
    );
  }

  factory PlayerModel.initial() => const PlayerModel(currentHp: 120, maxHp: 120);
}
```

### State Management

- **Riverpod** is the state management solution (`flutter_riverpod: ^3.2.1`)
- Providers are defined in `lib/shared/providers/app_providers.dart`
- Wrap new providers in the existing `ProviderScope` (already set up in `main.dart`)

### Navigation

- **go_router** handles routing (`go_router: ^17.1.0`)
- Routes are centralized in `lib/app/router/app_router.dart`
- Add new routes to the `GoRouter` configuration there

## UI/UX Patterns

### Atmospheric Design System

- **Primary Widget**: `AtmosphericScaffold` from `lib/shared/widgets/atmospheric_scaffold.dart`
- Provides consistent gradient backgrounds with glowing orbs
- Standard layout: title, optional subtitle, badge, actions, body, footer
- Use this for all new screens instead of raw `Scaffold`

Example:

```dart
AtmosphericScaffold(
  title: '화면 제목',
  subtitle: '부제목 설명',
  badge: const _Badge(label: '라벨'),
  body: YourContent(),
)
```

### Theme & Colors

Defined in `lib/app/theme/app_theme.dart`. **Always use these exact color values - never create new ones:**

#### Core Colors

- **Primary (Gold)**: `Color(0xFFE7C46A)` - Main accents, highlights, important data
  - Button backgrounds, active state indicators, critical damage in logs
  - Use for text that needs emphasis (values, achievements)
- **Secondary (Teal)**: `Color(0xFF5FD1B7)` - Progress, healing, positive events
  - Progress bars, healing indicators, loot logs, collected items
  - Use for progress/success feedback
- **Surface (Dark Green)**: `Color(0xFF162019)` - Card backgrounds, containers
  - All card/container backgrounds (`withOpacity(0.7)` or `0.75`)
  - Innermost container backgrounds
- **Background (Darkest)**: `Color(0xFF0E1411)` - Screen base
  - Scaffold background, outermost container

- **Text Colors**:
  - Primary text: `Color(0xFFF3F8F2)` - titles, important text
  - Secondary text: `Colors.white70` - labels, descriptions
  - Tertiary text: `Colors.white60` - disabled, secondary info
  - Faint text: `Colors.white38` - very minor info
  - Borders: `Colors.white24` - card/container borders

#### Gradient

Three-color gradient from `Color(0xFF1F2A24)` to `Color(0xFF0E1411)`:

```dart
gradient: const LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFF1F2A24),
    Color(0xFF2A3C33),
    Color(0xFF0E1411),
  ],
),
```

#### Color Rules

1. **Never hardcode colors** - always use constants above
2. **Use `.withOpacity()`** for card backgrounds (0.55, 0.6, 0.7, 0.75)
3. **Primary color** for interactive elements (buttons, active indicators)
4. **Secondary color** only for positive/progress feedback
5. **White opacity variants** for text - never use pure white or pure black

### Typography

- **Primary Font**: `NeoDGM` (pixel-style Korean font)
  - Used for: Main titles, button text, button labels, labels, general UI text
  - Set globally via `ThemeData.fontFamily`
  - Examples: "던전 진입", "비시정지", "재개", "코덱스 열기", "저열", "희귀", "전설"
- **Secondary Font**: `Galmuri11` (pixel-style Korean font for data)
  - Used ONLY for:
    - Numeric displays (HP: "120/120", 층: "5F", 룬: "+12", 수집률: "27%")
    - Combat logs and system messages ("보스를 처치했습니다", "AI 던전 생성 중", "초기화 중")
    - Descriptions with numeric data ("30%에서 다음 보너스: +1 공격")
    - Data summaries and stats ("+3 공격, +2 방어")
  - Add `fontFamily: 'Galmuri11'` to **TextField** style only when it contains numbers or system data

- Font assets in `assets/fonts/`: `NeoDGM.ttf`, `Galmuri11.ttf`

### Component Patterns

#### Private Widgets

- Feature-specific widgets are prefixed with `_` (e.g., `_Badge`, `_StatPill`, `_LogLine`)
- Extract to `lib/shared/widgets/` only if used across multiple features

#### Spacing Standards

- **Section spacing**: `SizedBox(height: 16)` or `height: 18`
- **Element spacing**: `SizedBox(height: 12)` between related elements
- **Tight spacing**: `SizedBox(height: 6-8)` within grouped elements
- **Horizontal spacing**: `SizedBox(width: 10-12)` between inline elements

#### Card Components

All card containers follow this pattern:

```dart
Container(
  padding: const EdgeInsets.all(14),           // Standard card padding
  decoration: BoxDecoration(
    color: const Color(0xFF0E1512).withOpacity(0.75),  // Card background
    borderRadius: BorderRadius.circular(18),   // Standard 18px radius
    border: Border.all(color: Colors.white24),  // Standard border
  ),
  child: content,
)
```

**Card Rules:**

- **Padding**: Always 12-16 (horizontal) and 10-14 (vertical)
- **Border radius**: 12px (small), 14px (medium), 18px (large)
- **Background**: `Color(0xFF0E1512).withOpacity(0.75)` OR `Color(0x FF162019)` for nested
- **Border**: Always `Colors.white24` unless indicating state
- **State borders**: Use primary/secondary colors with `.withOpacity(0.3-0.5)` for emphasis

#### StatePill / Data Display

```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  decoration: BoxDecoration(
    color: const Color(0xFF0E1512).withOpacity(0.55),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: Colors.white24),
  ),
  child: Row(
    children: [
      Text(label, style: TextStyle(fontSize: 10, letterSpacing: 1.1, color: Colors.white60)),
      const SizedBox(width: 8),
      Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
        color: Color(0xFFE7C46A), fontFamily: 'Galmuri11')),  // Always Galmuri11 for numbers
    ],
  ),
)
```

#### Button Styling

- **Filled buttons**: Gold background, rounded 14px corners
- **Outlined buttons**: White text, white24 border
- **Icon buttons**: Use `Colors.white70` color
- **All buttons**: Use NeoDGM font, uppercase labels with letterSpacing

#### Log/Message Display

```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  decoration: BoxDecoration(
    color: const Color(0xFF17221C).withOpacity(0.7),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: borderColor),  // Color varies by log type
  ),
  child: Text(message, style: TextStyle(
    color: textColor,
    fontSize: 12,
    fontFamily: 'Galmuri11',  // Always Galmuri11 for logs
  )),
)
```

#### Animation Rules

- **Fade in**: `FadeTransition` with `CurvedAnimation(Curves.easeOut)` - 300-400ms
- **Slide in**: `SlideTransition` with offset 0 to `Offset(0, 0.12)`-`(0, 0.3)`
- **Rotation**: `RotationTransition` for loading states - 2500ms loop
- **Always dispose**: AnimationControllers must be properly disposed

## Development Workflow

### Running the App

```powershell
flutter run          # Run on connected device
flutter run -d web   # Run on web
flutter doctor       # Check environment setup
```

### Dependencies

```powershell
flutter pub get      # Install dependencies
flutter pub outdated # Check for updates
```

### Code Quality

- Lint rules in `analysis_options.yaml` include `avoid_print` and `prefer_const_constructors`
- Always use `const` constructors where possible
- Use `debugPrint()` instead of `print()` for logging

## Naming Conventions

- **Korean**: All user-facing strings (titles, labels, descriptions)
- **Files**: Snake_case (e.g., `dungeon_screen.dart`, `atmospheric_scaffold.dart`)
- **Classes**: PascalCase (e.g., `DungeonScreen`, `AtmosphericScaffold`)
- **Variables**: camelCase (e.g., `appRouter`, `showTitle`)
- **Private Classes**: Prefix with `_` (e.g., `_Badge`, `_HomeScreenState`)

## Adding New Features

### Step-by-Step Process

1. Create folder structure:
   - `lib/features/{feature_name}/presentation/` - UI screens and widgets
   - `lib/features/{feature_name}/domain/models/` - Feature-specific data models
   - `lib/features/{feature_name}/data/` - Mock data or repositories
2. Define models in `domain/models/` before building UI
3. Add screen file: `{feature_name}_screen.dart`
4. Register route in `lib/app/router/app_router.dart`
5. Use `AtmosphericScaffold` for consistent UI
6. Extract reusable widgets to `lib/shared/widgets/` if used across features
7. Add shared models to `lib/shared/models/` if needed by multiple features

### UI Consistency Checklist for New Screens

- [ ] Using `AtmosphericScaffold` as the root widget
- [ ] Title is in Korean and matches the feature
- [ ] Subtitle (if present) uses **Galmuri11** font for data/descriptions
- [ ] Badge label uses uppercase text with `letterSpacing: 1.2`
- [ ] All numbers use **Galmuri11** font (HP, stats, percentages, strings like "3F", "+12")
- [ ] All system messages use **Galmuri11** font
- [ ] All color values match the theme constants (no new colors!)
- [ ] Card backgrounds use `.withOpacity(0.75)` or `.withOpacity(0.55)`
- [ ] Card borders are `Colors.white24`
- [ ] Text hierarchy follows: primary (0xFFF3F8F2), secondary (white70), tertiary (white60), faint (white38)
- [ ] Spacing follows standards: 16-18 between sections, 12 between elements, 6-8 for tight grouping
- [ ] Buttons use `const` constructors and proper rounded corners
- [ ] No Material colors hardcoded - all from AppTheme
- [ ] All button labels in Korean with NeoDGM font
- [ ] Icons are rendered with default Material Icons font (no fontFamily override)

### Icon Usage Rules

- Only use Material Icons (`Icons.*`)
- Never apply `fontFamily` directly to Icon widgets
- Icon colors should be from the theme palette (white70, white38, primary/secondary colors)
- Typical icon colors: `Colors.white70` for interactive, `Colors.white38` for disabled/locked
- Size: 24 for nav icons, 40-48 for display icons

## Data Modeling Guidelines

1. **Separation**: Keep shared models in `lib/shared/models/`, feature-specific in `{feature}/domain/models/`
2. **Immutability**: All models should be immutable with `const` constructors
3. **Updates**: Use `copyWith()` for state updates
4. **Factories**: Provide named constructors like `.initial()`, `.empty()`, `.undiscovered()`
5. **Computed Properties**: Add getters for derived values (e.g., `bonusSummary`, `completionRate`)
6. **Enums**: Use enums for fixed sets of values (e.g., `Rarity`, `LogType`)
7. **Mock Data**: Place mock data in `data/` directories, never hardcode in UI

## Key Files

- **Entry Point**: [`lib/main.dart`](lib/main.dart) - Wraps app in `ProviderScope`
- **App Root**: [`lib/app/app.dart`](lib/app/app.dart) - Configures MaterialApp with router and theme
- **Router**: [`lib/app/router/app_router.dart`](lib/app/router/app_router.dart) - All route definitions
- **Theme**: [`lib/app/theme/app_theme.dart`](lib/app/theme/app_theme.dart) - Complete theme configuration
- **Shared Scaffold**: [`lib/shared/widgets/atmospheric_scaffold.dart`](lib/shared/widgets/atmospheric_scaffold.dart) - Base layout widget
- **Shared Models**: [`lib/shared/models/`](lib/shared/models/) - Core data models (Player, Item, Rarity, etc.)
- **Mock Items**: [`lib/shared/data/mock_items.dart`](lib/shared/data/mock_items.dart) - Central item database

## Common Anti-Patterns to Avoid

### Design & Colors

❌ **Don't**: Hardcode colors like `Color(0xFF123456)`
✅ **Do**: Use theme constants from `AppTheme` or `app_theme.dart`

❌ **Don't**: Create new shades of colors not in the theme
✅ **Do**: Use `.withOpacity()` to adjust existing colors

❌ **Don't**: Use Material colors directly (`Colors.blue`, `Colors.red`)
✅ **Do**: Use `Color(0xFFE7C46A)` (primary) or `Color(0xFF5FD1B7)` (secondary)

### Fonts & Typography

❌ **Don't**: Add `fontFamily` to Icon widgets
✅ **Do**: Let Icons use their default Material Icons font

❌ **Don't**: Use NeoDGM for numeric values
✅ **Do**: Use `fontFamily: 'Galmuri11'` for numbers (HP: "120/120", "5F", "+12")

❌ **Don't**: Mix fonts inconsistently (e.g., using Galmuri11 for labels)
✅ **Do**: Reserve Galmuri11 ONLY for numbers, logs, and system messages

❌ **Don't**: Hardcode font family in every Text widget
✅ **Do**: Let NeoDGM apply globally through theme, override only when needed (Galmuri11)

### Layout & Components

❌ **Don't**: Create custom Scaffold variations
✅ **Do**: Use `AtmosphericScaffold` for all feature screens

❌ **Don't**: Create random spacing values (15, 17, 13)
✅ **Do**: Use standard spacing (6, 8, 12, 16, 18)

❌ **Don't**: Use `Colors.white` directly for text
✅ **Do**: Use opacity variants (`Colors.white70`, `Colors.white60`, `Colors.white38`)

❌ **Don't**: Use different card border radii arbitrarily
✅ **Do**: Use 12px (small), 14px (medium), 18px (large)

### Code Organization

❌ **Don't**: Put UI directly in features without AtmosphericScaffold
✅ **Do**: Wrap screens in AtmosphericScaffold with title, subtitle, badge

❌ **Don't**: Use English labels in user-facing text
✅ **Do**: Always use Korean for buttons, labels, titles, descriptions

### Naming

❌ **Don't**: Name files with PascalCase: `HomeScreen.dart`
✅ **Do**: Use snake_case: `home_screen.dart`

❌ **Don't**: Create public widgets: `class Badge extends StatelessWidget`
✅ **Do**: Prefix with underscore for feature-specific: `class _Badge extends StatelessWidget`

## Design System Summary

### Quick Reference Card (Keep This Handy!)

#### Colors (never hardcode)

- **Primary**: `0xFFE7C46A` (gold) - buttons, emphasis, critical
- **Secondary**: `0xFF5FD1B7` (teal) - progress, healing, collected
- **Text Primary**: `0xFFF3F8F2` (light) - titles, important
- **Text Secondary**: `Colors.white70` - labels, descriptions
- **Text Tertiary**: `Colors.white60` - disabled, secondary info
- **Text Faint**: `Colors.white38` - very minor text
- **Card BG**: `0xFF0E1512` with `.withOpacity(0.75)` or `.withOpacity(0.55)`
- **Borders**: `Colors.white24` (always)

#### Fonts (global principle)

- **NeoDGM** (global default): Titles, buttons, labels, general text
- **Galmuri11** (overrides ONLY for): Numbers, logs, system messages, stats
  - Examples: "120/120", "5F", "+12", "보스를 처치했습니다", "30%에서 다음: +1 공격"

#### Spacing (always use these)

- Sections: `SizedBox(height: 16)` or `18`
- Elements: `SizedBox(height: 12)`
- Tight: `SizedBox(height: 6-8)`
- Inline: `SizedBox(width: 10-12)`

#### Borders & Radius

- **Radius**: 12px (small), 14px (medium), 18px (large)
- **Color**: `Colors.white24` (default)
- **State/Emphasis**: primary/secondary `.withOpacity(0.3-0.5)`
- **Standard Padding**: 14px for cards, 12px for small elements

#### Root Layout (ALWAYS)

- Widget: `AtmosphericScaffold`
- Title: **Korean**, NeoDGM (default)
- Subtitle: **Galmuri11** (data/description)
- Badge: uppercase + `letterSpacing: 1.2`

#### Icons (Material Icons)

- No `fontFamily` override
- Colors: `Colors.white70` (active), `Colors.white38` (disabled)
- Sizes: 24 (nav), 40-48 (display)

### Before Publishing a New Feature

1. Run through UI Consistency Checklist (above)
2. Check all hardcoded colors against theme constants
3. Ensure all numbers/stats use Galmuri11
4. Confirm all titles/labels use Korean
5. Verify spacing with visual inspection
6. Test hot restart to see theme applied correctly
