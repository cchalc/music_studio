---
name: ui-and-assets
description: Layout and component conventions (Layouts.app wrapper, flash_group, <.icon>, <.input>), Tailwind v4 setup, asset bundling rules, and UI/UX design standards for this Phoenix app. Use when building pages, layouts, components, or styling. Triggers on Layouts.app, current_scope, flash_group, <.icon> hero-icons, <.input>, Tailwind v4 @import "tailwindcss", @source, @apply, daisyUI, app.js/app.css bundles, inline <script>.
when_to_use: Use for anything visual — layouts, components, Tailwind/CSS, bundling, design polish. For HEEx syntax rules and forms use phoenix-foundations; for LiveView hooks/JS interop use phoenix-liveview.
paths: lib/music_studio_web/components/**/*, lib/music_studio_web/**/*.heex, assets/css/**/*, assets/js/**/*
---

# UI, layouts, assets, and design

## Layout and component conventions (Phoenix v1.8)

- **Always** begin your LiveView templates with `<Layouts.app flash={@flash} ...>` which wraps all inner content.
- The `MusicStudioWeb.Layouts` module is aliased in the `music_studio_web.ex` file, so you can use it without needing to alias it again.
- Anytime you run into errors with no `current_scope` assign:
  - You failed to follow the Authenticated Routes guidelines, or you failed to pass `current_scope` to `<Layouts.app>`.
  - **Always** fix the `current_scope` error by moving your routes to the proper `live_session` and ensure you pass `current_scope` as needed.
- Phoenix v1.8 moved the `<.flash_group>` component to the `Layouts` module. You are **forbidden** from calling `<.flash_group>` outside of the `layouts.ex` module.
- Out of the box, `core_components.ex` imports an `<.icon name="hero-x-mark" class="w-5 h-5"/>` component for hero icons. **Always** use the `<.icon>` component for icons, **never** use `Heroicons` modules or similar.
- **Always** use the imported `<.input>` component for form inputs from `core_components.ex` when available. `<.input>` is imported and using it will save steps and prevent errors.
- If you override the default input classes (`<.input class="myclass px-2 py-1 rounded-lg">`) with your own values, no default classes are inherited, so your custom classes must fully style the input.

## JS and CSS

- **Use Tailwind CSS classes and custom CSS rules** to create polished, responsive, and visually stunning interfaces.
- Tailwind CSS v4 **no longer needs a `tailwind.config.js`** and uses a new import syntax in `app.css`:

      @import "tailwindcss" source(none);
      @source "../css";
      @source "../js";
      @source "../../lib/music_studio_web";

- **Always use and maintain this import syntax** in the `app.css` file for projects generated with `phx.new`.
- **Never** use `@apply` when writing raw CSS.
- **Always** manually write your own tailwind-based components instead of using daisyUI for a unique, world-class design.
- Out of the box **only the `app.js` and `app.css` bundles are supported**:
  - You cannot reference an external vendored script `src` or link `href` in the layouts.
  - You must import the vendor deps into `app.js` and `app.css` to use them.
  - **Never write inline `<script>custom js</script>` tags within templates.**

## UI/UX & design

- **Produce world-class UI designs** with a focus on usability, aesthetics, and modern design principles.
- Implement **subtle micro-interactions** (e.g. button hover effects, smooth transitions).
- Ensure **clean typography, spacing, and layout balance** for a refined, premium look.
- Focus on **delightful details** like hover effects, loading states, and smooth page transitions.
