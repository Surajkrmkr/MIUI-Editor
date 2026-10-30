# Design

Process, in this order, for every theme:

0. Know which user the theme is for (list_users). If my request does not name one, ask me and wait for the answer before anything else. Pass it as user to get_base_spec and list_widget_styles; use only styles from that user's own sets.

1. Write a 2-line design brief before any JSON: the mood, the clock style, the main widget, the color scheme, and what makes it different from the last themes.
2. Study references. Design references come only from the AI preset folder: call list_references, then get_reference on at least two that suit the wallpaper and look at the pictures. Take layout, spacing and proportions from them. Never use the Preset folder (list_presets, get_preset) for ideas. If the AI preset folder is empty, stop and tell me.
3. Call get_base_spec with the title, user, wallpaper, week and folder, and read its layout_guide. It only shows where things fit and how big they are; it is not a design. Make your own: change the clock arrangement and position, what the card shows, the unlock control and the colors. Do not copy a reference exactly.
4. Add a widget from list_widgets and apply a style from list_widget_styles to the unlock control and to any analog clock, calendar, shortcut set or other widget that has styles. If get_widget warns that positions are off the screen, re-place the elements yourself.
5. Check the layout with preview_lockscreen after every change that moves or adds an element. It is much faster than build_theme. Look at the picture for overlaps, elements near the edges and text that is hard to read. Fix what you see and preview again. Use preview_icons the same way for the icon colors and shape.
6. Run validate_spec and fix every warning it gives, not only the errors. It also tells you when the design is too close to an earlier theme or to the starter layout; change the clock style, the widgets, the unlock control or the color scheme until it stops.
7. Run build_theme once, at the end, with week and folder. Do not use it to iterate.
8. Save the finished spec as THEMES/specs/Week<N>/<theme name>.json so later themes are compared with it.

Every theme gets its own design. Across a batch, change the clock type and its position, the widgets, the unlock style and where it sits, and the color scheme.

validate_spec already checks, so do not spend effort on these: the minimum number of elements, a clock, a widget (other than music), a decoration, more than one font size, swipeUpUnlock, no dragToUnlock, system apps only in shortcuts, the hour and minute staying together, the date parts staying together, elements on the screen, and text contrast.

# Clock and DateTime

- Choose an analog or digital clock to suit the layout. Use seconds only when they help the design; use a dot clock when a horizontal clock calls for it.
- Choose a large, medium, or small clock based on the wallpaper composition, available space, and the visual weight of other elements. Keep the clock prominent without covering important wallpaper details or crowding nearby content.
- Center the time group as a whole rather than positioning each part independently, and keep the gap between hour, separator and minute even.
- Align the month, week and day deliberately; do not spread them across the available width.
- A clock does not always need a stroke. Use a gradient or a single color as appropriate, with enough contrast against the wallpaper. Add AM/PM or week information only when it improves the layout.
- Add DateTime text alongside the clock when useful. Choose short or full weekday and month formats to fit the available space, and adjust text weight when it helps readability or hierarchy.

# Widgets

- Avoid crowding the lockscreen with widgets. Size the main and supporting widgets to the wallpaper composition and available screen space; keep them legible without obscuring the subject or competing with the clock.
- Within each widget card, align related content to a shared vertical centerline; align text baselines where appropriate. Use consistent inner padding and compact, intentional gaps between icons, values, and labels. Do not spread items to the card edges or leave large empty gaps just to fill the card width.
- Keep consistent, intentional gaps between widgets and between widgets and the clock, date, and screen edges. Leave enough separation to distinguish each widget without wasting space, and check the final preview for crowding, misalignment, or awkwardly large gaps.
- Match widget colors to the wallpaper palette and preserve clear contrast and usable spacing.

# Shortcuts

- Size shortcuts proportionally to the screen and available layout: large enough to recognize and interact with, but not so large that they dominate or crowd the lockscreen.
- Use system icons only, not third-party icon packs. Match shortcut colors to the wallpaper palette while keeping the icons legible.

# Icons

- App icon colors come from the wallpaper. Call view_wallpaper and take icons.background.colors (one or two) from its palette, then check the home preview.
- Keep the icon vector centered and about 60% of the icon background size. Choose gradients, textures, and effects to complement the wallpaper without reducing icon legibility.

# Safe area

- Keep content at least 40 canvas px from the top edge (its top no higher than
  dy -260) so it never runs under the status bar or camera cutout, and at
  least 40 px from the bottom edge (its bottom no lower than dy 260) so it
  clears the gesture bar.
  validate_spec warns with lockscreen.top_edge and lockscreen.bottom_edge.
  Backgrounds, shapes and the swipe-up area may bleed to the edges.

# Output

- Build with week (and folder) so themes go to THEMES/Week<week>. Do not pass out_dir, and never write themes into the repository.
