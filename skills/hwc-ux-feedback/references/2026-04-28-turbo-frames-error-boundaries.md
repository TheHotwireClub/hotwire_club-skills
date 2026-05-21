---
title: Turbo Frames - Error Boundaries
date: 2026-04-28
categories:
- Turbo Frames
- Stimulus
tags:
- Error Handling
- Error Boundaries
- Lazy Loading
- turbo:frame-missing
- turbo:fetch-request-error
description: Build a reusable Stimulus controller that catches Turbo Frame failures and shows fallback error states with retry.
free: false
ready: true
---

## Table of Contents

- [Problem](#problem)
- [Solution](#solution)
- [Implementation](#implementation)
- [Markup](#markup)
- [Stimulus controller](#stimulus-controller)
- [Key Points](#key-points)

## Problem

When a Turbo Frame request fails, the user gets Turbo's default "Content Missing" message, or — for a network failure on a lazy-loaded frame — a silently empty frame. There is no fallback UI and no way to recover.

## Solution

Mirror React's Error Boundaries with a Stimulus controller wrapping each frame. It listens for two distinct failure events, suppresses the default behavior, renders fallback UI from a `<template>`, and offers a retry button.

- `turbo:frame-missing` — the HTTP request **succeeded** (a response exists) but the HTML contains no `<turbo-frame>` with a matching `id`. Typical for 4xx/5xx error pages.
- `turbo:fetch-request-error` — the request **failed at the network level**; there is no response at all.

Both are needed for a robust boundary.

## Implementation

### Markup

The `error-boundary` controller lives on a wrapper `<div>` around the frame. The frame is a `frame` target; a `<template>` is the `errorTemplate` target. The event actions are wired on the frame element and bubble up.

```html
<div data-controller="error-boundary">
  <turbo-frame id="notifications" src="/frames/notifications"
               data-error-boundary-target="frame"
               data-action="turbo:frame-missing->error-boundary#handleFrameMissing
                            turbo:fetch-request-error->error-boundary#handleFetchError">
  </turbo-frame>

  <template data-error-boundary-target="errorTemplate">
    <div class="error-state">
      <p data-role="message"></p>
      <button data-action="error-boundary#retry">Retry</button>
    </div>
  </template>
</div>
```

### Stimulus controller

```js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["frame", "errorTemplate"]

  handleFrameMissing(event) {
    event.preventDefault()
    const status = event.detail.response.status
    this.showError(`Something went wrong (${status}). Please try again later.`)
  }

  handleFetchError(event) {
    event.preventDefault()
    const error = event.detail.error
    this.showError("Couldn't reach the server. Check your connection and retry.")
  }

  showError(message) {
    const fragment = this.errorTemplateTarget.content.cloneNode(true)
    fragment.querySelector('[data-role="message"]').textContent = message
    this.frameTarget.innerHTML = ""
    this.frameTarget.appendChild(fragment)
  }

  retry() {
    this.frameTarget.reload()
  }
}
```

- `handleFrameMissing` reads `event.detail.response`, a standard [Response](https://developer.mozilla.org/en-US/docs/Web/API/Response) object, for the status code.
- `handleFetchError` reads `event.detail.error`, an [Error](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Error) object — there is no response.
- `event.preventDefault()` suppresses Turbo's default "Content Missing" handling.
- `retry()` calls `frame.reload()` to re-fetch from the original `src`.

## Key Points

- `turbo:frame-missing` fires on a successful HTTP request whose response lacks a matching `<turbo-frame>` — the typical 4xx/5xx case.
- `turbo:fetch-request-error` fires on a network-level failure with no response at all.
- A robust error boundary handles both events.
- `event.detail.response` is available only for `turbo:frame-missing`; `event.detail.error` only for `turbo:fetch-request-error`.
- `turbo:frame-missing` also provides `event.detail.visit`, a function that replaces the whole page with the error response — useful for auth redirects (401 → login), but the boundary pattern is better for partial failures.
- Calling `frame.reload()` re-fetches the frame from its `src` for retry.
