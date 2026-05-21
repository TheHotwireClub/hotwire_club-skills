---
title: Turbo Streams - Custom Stream Actions - pushState
date: 2026-04-14
categories:
- Turbo Streams
- Stimulus
tags:
- Custom Stream Actions
- History API
- pushState
- popstate
- turbo-stream
description: Synchronize browser history with Turbo Stream responses using a custom push_state action, a Stimulus controller, and the popstate event.
free: false
ready: true
---

## Table of Contents

- [Problem](#problem)
- [Solution](#solution)
- [Implementation](#implementation)
- [Custom stream action](#custom-stream-action)
- [Stimulus controller](#stimulus-controller)
- [Rails controller](#rails-controller)
- [Key Points](#key-points)

## Problem

When Turbo Stream responses update the page, the browser's Back and Forward buttons know nothing about the change. State stored client-side (for example in `localStorage`) is invisible to the history stack, so navigating Back leaves the page entirely instead of restoring a previous state.

## Solution

`history.pushState(state, "", url)` takes two relevant arguments:

- the **URL**, shown in the address bar and used on refresh (human-facing);
- the **state object**, stored in the history entry and handed back via `event.state` on `popstate` (machine-facing).

Build a custom `push_state` Turbo Stream action that pushes both, and a Stimulus controller that reads `event.state` on `popstate` to re-fetch the correct content. The forward direction (user picks an option) is driven by the stream action; the backward direction (user hits Back) is driven by the controller.

## Implementation

### Custom stream action

Register `push_state` on Turbo's `StreamActions`:

```js
// app.js
import { StreamActions } from "@hotwired/turbo"

StreamActions.push_state = function () {
  const url = this.getAttribute("url")
  const state = JSON.parse(this.getAttribute("state"))
  history.pushState(state, "", url)
}
```

The server emits a matching tag. The `state` attribute is JSON carrying the restore URL:

```html
<turbo-stream action="push_state"
              url="/versions/v2.0"
              state='{"restoreUrl":"/versions/v2.0?restore=1"}'>
</turbo-stream>
```

### Stimulus controller

```js
import { Controller } from "@hotwired/stimulus"
import { get } from "@rails/request.js"

export default class extends Controller {
  static targets = ["select", "form"]

  navigate() {
    this.formTarget.action = `/versions/${this.selectTarget.value}`
    this.selectTarget.disabled = true
    this.formTarget.requestSubmit()
  }

  restore(event) {
    if (!event.state || !event.state.restoreUrl) return
    get(event.state.restoreUrl, { responseKind: "turbo-stream" })
  }
}
```

`restore` is wired to `popstate@window`:

```html
<div data-controller="version-selector"
     data-action="popstate@window->version-selector#restore">
  <form data-version-selector-target="form" data-turbo-stream="true">
    <select data-version-selector-target="select"
            data-action="version-selector#navigate">
      <option value="v1.0">v1.0</option>
      <option value="v2.0">v2.0</option>
      <option value="v3.0">v3.0</option>
    </select>
  </form>
</div>
```

`data-turbo-stream="true"` on the form makes Turbo send an `Accept: text/vnd.turbo-stream.html` header.

### Rails controller

```ruby
class VersionsController < ApplicationController
  def show
    @version = params[:id]

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("content", partial: "versions/content"),
          turbo_stream.replace("version-selector", partial: "versions/selector"),
          *push_state_stream
        ]
      end
    end
  end

  private

  def push_state_stream
    return [] if params[:restore]

    state = { restoreUrl: version_path(@version, restore: 1) }
    [tag.turbo_stream(action: "push_state",
                      url: version_path(@version),
                      state: state.to_json)]
  end
end
```

## Key Points

- `history.pushState` stores a URL (for the user and for refresh) and a state object (for your JavaScript).
- `popstate` fires only on actual Back/Forward navigation, never when you call `pushState` yourself.
- The custom `push_state` action is registered on `StreamActions`; `this` inside the function is the `<turbo-stream>` element.
- The restore URL carries `restore=1` so the server omits the `push_state` tag — otherwise every Back press would push a new history entry, creating a loop.
- The forward path (stream action) and backward path (Stimulus `restore`) are separate mechanisms producing one unified UX.
- TurboPower ships an equivalent `push_state` action out of the box.
