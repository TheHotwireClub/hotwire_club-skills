---
title: Stimulus - Optimistic Toast Notifications with Auto-Save
date: 2026-05-26
categories:
- Stimulus
tags:
- Outlets
- Optimistic UI
- Auto-Save
- Toast Notifications
- Notyf
- Third-Party Library Wrapper
- Debounce
- fetch
description: Build an auto-save form that fires a toast notification the instant it submits, not when the server responds, using Stimulus outlets.
free: false
ready: true
---

## Table of Contents

- [Problem](#problem)
- [Solution](#solution)
- [Implementation](#implementation)
- [Markup](#markup)
- [Toast controller](#toast-controller)
- [Auto-save controller](#auto-save-controller)
- [Debounced variant](#debounced-variant)
- [Configurable messages](#configurable-messages)
- [Why Outlets Instead of Events or Global State](#why-outlets-instead-of-events-or-global-state)
- [Key Points](#key-points)

## Problem

The standard Hotwire way to confirm an auto-save is to have the server respond with a Turbo Stream such as `turbo_stream.append "toast"`. That ties the feedback to the round trip: if the server takes 800ms, the user sees nothing for 800ms.

## Solution

Fire the confirmation toast optimistically, the moment the request leaves the browser, and follow up with an error toast only if the response is not ok. Instant feedback in the happy path, honest feedback in the sad path.

Split the behavior into two small controllers linked by a single Stimulus outlet:

- `auto-save` submits the form via `fetch` and calls `this.toastOutlet.show(...)`.
- `toast` wraps the [Notyf](https://github.com/caroso1222/notyf) notification library (~3 KB) and exposes a single `show(message, variant)` method.

Unlike the morph-based optimistic UI (swapping DOM state and reconciling with a Turbo 8 morph), this is a side-channel notification: no HTML is replaced. Optimistic UI fits auto-save well because failures of simple attribute updates, toggles and preference changes are rare.

## Implementation

### Markup

Each input triggers a save on `change`. The form declares the toast outlet by CSS selector, pointing at the toast container.

```html
<form action="/settings" method="post"
      data-controller="auto-save"
      data-auto-save-toast-outlet="#toast-container">
  <input name="display_name" data-action="change->auto-save#save">
  <select name="theme" data-action="change->auto-save#save">
    <option>light</option>
    <option>dark</option>
  </select>
</form>

<div id="toast-container" data-controller="toast"></div>
```

Notyf is pinned in the import map; its CSS is loaded with a `<link>` tag.

### Toast controller

Notyf is instantiated in `connect()` with a 3-second duration, top-right positioning and dismissible toasts. `show()` maps the app-level `danger` variant (the Bootstrap / component-library convention) to Notyf's `error`, so no other code needs to know which toast library is underneath.

`disconnect()` dismisses lingering toasts when the element is removed from the DOM (Turbo morph or page navigation), so they don't hang around orphaned. Cleaning up in `disconnect()` is a good habit whenever wrapping a third-party library.

```js
// controllers/toast_controller.js
import { Controller } from '@hotwired/stimulus';
import { Notyf } from 'notyf';

export default class extends Controller {
  connect() {
    this.notyf = new Notyf({
      duration: 3000,
      position: { x: 'right', y: 'top' },
      dismissible: true,
    });
  }

  disconnect() {
    this.notyf?.dismissAll();
  }

  show(message, variant = 'success') {
    const method = variant === 'danger' ? 'error' : variant;
    this.notyf[method](message);
  }
}
```

### Auto-save controller

`this.toastOutlet.show("Saved!", "success")` runs **before** `await fetch()`. Everything before the first `await` executes synchronously, so the toast renders immediately and the request runs in the background. A non-2xx response triggers a second, red toast.

```js
// controllers/auto_save_controller.js
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static outlets = ['toast'];

  async save() {
    const body = new FormData(this.element);

    // Optimistic: show success before the server responds
    this.toastOutlet.show('Saved!', 'success');

    const response = await fetch(this.element.action, {
      method: 'POST',
      body,
      headers: { Accept: 'application/json' },
    });

    if (!response.ok) {
      this.toastOutlet.show('Save failed', 'danger');
    }
  }
}
```

### Debounced variant

Tabbing quickly through several fields would otherwise fire overlapping requests and stack "Saved!" toasts. Split the controller into a public `save()` action that resets a 400ms timer on every change, and a private `#submit()` that dispatches the request **and** the optimistic toast together:

```js
// controllers/auto_save_controller.js
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static outlets = ['toast'];

  save() {
    clearTimeout(this.timeout);
    this.timeout = setTimeout(() => this.#submit(), 400);
  }

  disconnect() {
    clearTimeout(this.timeout);
  }

  async #submit() {
    const body = new FormData(this.element);

    this.toastOutlet.show('Saved!', 'success');

    const response = await fetch(this.element.action, {
      method: 'POST',
      body,
      headers: { Accept: 'application/json' },
    });

    if (!response.ok) {
      this.toastOutlet.show('Save failed', 'danger');
    }
  }
}
```

Rapid changes collapse into one request and one notification. The toast fires on the leading edge of the **request**, not the trailing edge of the debounce. Moving it into `save()` (before the timeout) would announce "Saved!" 400ms before anything was even attempted. Inside `#submit()` the toast is optimistic about the outcome but honest about the timing: the request is genuinely in flight.

### Configurable messages

Stimulus values let each form override the default text without touching the controller:

```js
static values = { successMessage: { type: String, default: "Saved!" } }
// ...
this.toastOutlet.show(this.successMessageValue, "success")
```

```html
<form data-controller="auto-save"
      data-auto-save-success-message-value="Profile updated"
      data-auto-save-toast-outlet="#toast-container">
```

## Why Outlets Instead of Events or Global State

A custom event caught by the toast controller, or a global `window.toast.show()`, would also work. Outlets add two things:

1. **Stimulus validates the connection.** If the outlet selector doesn't match an element with the right controller, Stimulus warns in development. Events and globals fail silently.
2. **The dependency is explicit in the HTML.** `data-auto-save-toast-outlet="#toast-container"` documents that the two controllers are connected; with events you have to trace an event name across files.

The cost is one extra HTML attribute.

## Key Points

- Optimistic feedback means showing the toast when the request is **dispatched**, not when the response arrives; call it before the first `await`.
- Outlets give a direct method call between controllers: `static outlets = ["toast"]` plus `data-auto-save-toast-outlet="<selector>"`, then `this.toastOutlet.show(...)`.
- Wrapping a third-party library in a Stimulus controller keeps its import, configuration and cleanup (`disconnect()`) in one place; swapping Notyf for a hand-rolled toast doesn't affect any outlet consumer.
- Debounce in the public action, but fire the toast in the private method that actually sends the request.
