# Technical Specification — Issue #5

## 1. Issue Overview

| Field | Value |
| --- | --- |
| Title | Inside the footer, when user hovers on "Contact Us" not text being displayed |
| Description | The footer's "Contact Us" link showed no hover tooltip, unlike the neighboring "Cookie Policy" link which displays help text on hover. The link navigates to the Contact page where users can message admin about an issue. |
| Labels | none |
| Priority | Low |
| Status | **CLOSED** — already resolved in PR #6 (commit `b2fe8ff`), merged to `master` via `66a2873` |

## 2. Problem Analysis

`src/components/Footer.jsx` renders a row of footer links (Privacy Policy, Terms of Service, Cookie Policy, Contact Us). "Cookie Policy" used a `group`/`group-hover` Tailwind pattern to reveal an absolutely-positioned tooltip `<div>` on hover, giving the user context before they click. "Contact Us" had the same `group relative hover:text-white` wrapper classes but was missing the tooltip `<div>`, so hovering produced no explanatory text — inconsistent with the adjacent link and unhelpful for users unsure why they'd click through to the Contact page.

Root cause: an omitted UI element (tooltip markup) on one link, not a logic or state bug. Verified by comparing the "Cookie Policy" (`Footer.jsx:152-160`) and "Contact Us" (`Footer.jsx:161-171`) blocks directly.

## 3. Proposed Solution (as implemented)

Reuse the exact tooltip pattern already established for "Cookie Policy" — no new component, styling system, or state was introduced:

- Add a `pointer-events-none absolute bottom-full ... opacity-0 ... group-hover:opacity-100` tooltip `<div>` inside the "Contact Us" `<Link>`, matching border, background, spacing, and the CSS-triangle arrow (`border-t-gray-800`) used by "Cookie Policy".
- Tooltip copy: "Have a question or issue? Reach out to our support team here." — matches the issue's stated intent (explaining that clicking navigates to a page to message admin).
- No JavaScript/state changes; purely a Tailwind-driven CSS hover reveal, consistent with existing conventions (see `.claude/rules/coding-standards.md` — Tailwind utility classes exclusively, no inline styles).

Trade-off: none of note — this is a minimal, low-risk, purely presentational addition scoped to a single file.

## 4. Step-by-Step Implementation (already completed)

1. **Read `Footer.jsx`** — identify the "Cookie Policy" tooltip pattern as the template to replicate.
2. **Add tooltip markup to "Contact Us"** — insert the same tooltip `<div>` structure inside the existing `<Link to="/contact">`, updating only the visible copy.
3. **Visual/manual verification** — confirm hover state renders identically in position/animation to "Cookie Policy".

## 5. Verification Strategy

### Unit Tests
- Not applicable — no logic branches introduced; this is static JSX/CSS markup with no testable behavior beyond rendering.

### Integration Tests
- Not applicable — no data flow, routing, or state changes.

### Manual Checks
- Run `npm run dev`, hover over "Contact Us" in the footer → tooltip "Have a question or issue? Reach out to our support team here." appears above the link, matching "Cookie Policy" positioning/animation.
- Run `npm run lint` → no new lint errors.
- Confirm clicking "Contact Us" still navigates to `/contact` (unchanged `<Link>` behavior).

## 6. Files to Modify

| File Path | Nature of Change |
| --- | --- |
| `src/components/Footer.jsx` | Added tooltip `<div>` (lines 167-170) inside the existing "Contact Us" `<Link>` block |

## 7. New Files to Create

None.

## 8. Existing Utilities to Leverage

| Utility | Benefit |
| --- | --- |
| Existing "Cookie Policy" tooltip pattern (Tailwind `group`/`group-hover`) | Guarantees visual/behavioral consistency without introducing new CSS or a tooltip component/library |

## 9. Acceptance Criteria

- [x] Hovering "Contact Us" in the footer displays help text explaining the link's purpose
- [x] Tooltip styling/animation matches the existing "Cookie Policy" tooltip
- [x] No regression to "Contact Us" link's navigation to `/contact`
- [ ] `npm run lint` run locally to confirm no lint regressions (flagged as not run in the original fix's CI environment)

## 10. Out of Scope

- Adding tooltips to "Privacy Policy" or "Terms of Service" (they currently have no `href`/route and no tooltip — not part of this issue)
- Any redesign of the footer layout or tooltip component extraction
- Accessibility enhancements (e.g., `aria-describedby`, keyboard-focus-triggered tooltips) — not requested in the issue
