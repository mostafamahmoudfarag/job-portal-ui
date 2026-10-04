# Technical Specification — Issue #8

## 1. Issue Overview

| Field | Value |
| --- | --- |
| Title | Inside the footer, when user hovers on "Terms of Service" no text being displayed. User click on this link to navigate to Terms of Service page where a message can be sent to admin. So we need to display some help text around this when user hover |
| Description | The footer's "Terms of Service" link shows no help text on hover, unlike the neighboring "Cookie Policy" and "Contact Us" links. The issue asks for hover help text. The issue has no body, labels, or comments. All requirements come from the title. |
| Labels | none |
| Priority | Low |
| Status | OPEN |

## 2. Problem Analysis

`src/components/Footer.jsx:143-172` renders the footer's bottom link row: Privacy Policy, Terms of Service, Cookie Policy and Contact Us.

- **Cookie Policy** (`Footer.jsx:152-160`) and **Contact Us** (`Footer.jsx:161-171`) each contain a tooltip `<div>`. It is hidden with `opacity-0` and shown through the parent's `group` class with `group-hover:opacity-100`.
- **Terms of Service** (`Footer.jsx:148-151`) has the same `group relative` wrapper and hover gradient, but no tooltip `<div>`. Hovering over it shows nothing.

Root cause: the tooltip markup is missing from this one link. There is no logic or state bug. This is the same defect as Issue #5, which was fixed for "Contact Us" in commit `b2fe8ff` (spec: `specs/issue-5-spec.md`).

**The title doesn't match the codebase.** The title says the link "navigate[s] to Terms of Service page where a message can be sent to admin". The repository shows this is not true:

- "Terms of Service" is a plain `<a>` with no `href` (`Footer.jsx:148`), so clicking it does nothing.
- `src/App.jsx` has no Terms of Service route, and `src/pages/` has no matching page.
- The only page where users can message admin is `/contact` (`src/pages/Contact.jsx`, whose messages appear in `admin/contact-messages`).

The title's wording seems to have been copied from Issue #5, which was about "Contact Us". The verified requirement is therefore only the hover help text. The tooltip copy must describe Terms of Service. It must not promise a page or an admin-messaging flow that doesn't exist.

## 3. Proposed Solution

Apply the existing tooltip pattern from Cookie Policy and Contact Us to the "Terms of Service" `<a>`:

- Insert the same tooltip `<div>` as the last child of the Terms of Service `<a>`, with the same classes and the same `border-t-gray-800` triangle arrow.
- Suggested copy: **"Review the rules and guidelines for using JobPortal as a job seeker or employer."** It is accurate, about one line in the `w-56` box, and doesn't promise a destination.
- Change no JavaScript, state or routing. The change uses Tailwind utility classes only, as required by `.claude/rules/coding-standards.md`.

Trade-offs:
- The tooltip markup is now repeated three times. Moving it into a shared `FooterTooltip` component would remove the repetition, but the issue doesn't need it. That refactor is left for a later change; see Out of Scope.
- If the maintainer actually wants a Terms of Service page with an admin-messaging flow, that is a larger feature. It should be raised in a separate issue, not added to this one.

## 4. Step-by-Step Implementation

1. **Copy the template.** Copy the tooltip `<div>` block from "Contact Us" (`Footer.jsx:167-170`).
2. **Insert it into "Terms of Service".** Paste it after the gradient `<div>` at `Footer.jsx:150`, inside the `<a>`. Replace the text with the Terms of Service copy.
3. **Lint.** Run `npm run lint` and confirm there are no new warnings or errors.
4. **Check visually.** Run `npm run dev` and hover over each footer link. Confirm the new tooltip's position and animation match the others.

## 5. Verification Strategy

### Unit Tests
- Not applicable. The project has no test runner (no vitest or jest in `package.json`), and the change is static markup with no logic.

### Integration Tests
- Not applicable. No routing, context or data flow changes.

### Manual Checks
- Hover over "Terms of Service" → the help text appears above the link with the same fade and slide as "Cookie Policy" and "Contact Us".
- Move the mouse away → the tooltip fades out. Because of `pointer-events-none`, it doesn't block clicks on nearby links.
- Hover over the other footer links → their behavior is unchanged.
- Check at a mobile width (~375px), where the links wrap → the tooltip is still readable and not clipped by the viewport.
- Toggle dark/light theme with `ThemeContext` → the footer is always dark, so the tooltip should look the same in both.
- Run `npm run lint` → it passes.

## 6. Files to Modify

| File Path | Nature of Change |
| --- | --- |
| `src/components/Footer.jsx` | Add a tooltip `<div>` (about 4 lines) inside the "Terms of Service" `<a>` (lines 148-151) |

## 7. New Files to Create

None.

## 8. Existing Utilities to Leverage

| Utility | Benefit |
| --- | --- |
| Tooltip pattern in `Footer.jsx` (Cookie Policy, Contact Us) | Gives identical visuals and animation with no new CSS, component or library |
| Tailwind `group` / `group-hover:` variants already on the `<a>` | The hover trigger already exists, so only the tooltip node needs to be added |

## 9. Acceptance Criteria

- [ ] Hovering over "Terms of Service" in the footer shows help text describing what Terms of Service covers
- [ ] The tooltip's style, position and animation match the existing footer tooltips
- [ ] The tooltip copy doesn't promise navigation or admin messaging that doesn't exist
- [ ] No regressions to the other footer links
- [ ] `npm run lint` passes

## 10. Out of Scope

- Creating a Terms of Service page or route, or making the link navigate anywhere. No page exists today, and the issue body doesn't specify one.
- Any admin-messaging feature linked to Terms of Service. That flow already exists at `/contact`.
- A tooltip for "Privacy Policy". It has the same gap, but this issue doesn't mention it. It could be a follow-up issue.
- Extracting a reusable tooltip component, or other footer refactors.
- Accessibility work, such as showing the tooltip on keyboard focus or adding `aria-describedby`. The existing tooltips don't have it either.
