---
title: Stimulus - Promise-Returning Outlet Methods
date: 2026-07-22
categories:
- Stimulus
tags:
- Outlets
- Deferred Promises
- async/await
- dialog
- Confirm Dialog
- Controller Communication
description: Turn a Stimulus controller into an await-able API by returning a promise from an outlet method and resolving it from a dialog's button handlers.
free: false
ready: true
---

## Table of Contents

- [Problem](#problem)
- [Solution](#solution)
- [Implementation](#implementation)
- [Markup](#markup)
- [Confirm controller](#confirm-controller)
- [List-item controller](#list-item-controller)
- [Key Points](#key-points)

## Problem

Stimulus controllers usually communicate via dispatched events, which are fire-and-forget and have no return channel. A confirm-before-delete flow built on events (`confirm:ask` out, `confirm:answer` back) splits the delete logic across two handlers, needs `pendingForm` state to remember which item is pending, and makes every list item listen to answers meant for its siblings.

## Solution

Use the **deferred-promise pattern**: a public `ask()` method creates a promise, stashes its `resolve` function on the controller instance, and returns the promise. The promise is created now but settled later, from a completely different call stack (the dialog's button handlers). Exposed through an outlet, the controller becomes an await-able mini-API that other controllers call like a library function.

## Implementation

### Markup

The confirm controller sits on a `<dialog>`. Yes / No buttons call `yes` / `no`; the dialog's native `close` event (Escape) and clicks on it (backdrop) are wired declaratively. Each list item declares the dialog as its `confirm` outlet.

```html
<dialog
  id="confirm-dialog"
  data-controller="confirm"
  data-action="close->confirm#closed click->confirm#backdropClick"
>
  <p data-confirm-target="message"></p>
  <div class="dialog-actions">
    <button type="button" data-action="click->confirm#no">No</button>
    <button type="button" data-action="click->confirm#yes" class="danger">
      Yes
    </button>
  </div>
</dialog>

<ul>
  <li data-controller="list-item" data-list-item-confirm-outlet="#confirm-dialog">
    Item 1
    <form action="/items/1/delete" method="post">
      <button data-action="list-item#delete">Delete</button>
    </form>
  </li>
</ul>
```

The server handles deletion via POST-redirect-GET.

### Confirm controller

`ask()` sets the text, opens the dialog with `showModal()`, and returns a promise whose `resolve` is stored on `this`. `yes` and `no` delegate to an `answer()` helper that closes the dialog, calls the stored `resolve` and nulls it out. Nulling makes `answer()` idempotent, so the `close` event firing afterwards can't settle anything twice.

```js
// controllers/confirm_controller.js
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['message'];

  async ask(message) {
    // Caveat: if a previous ask is still pending, settle it before we
    // overwrite this.resolve -- otherwise the first caller hangs forever.
    this.resolve?.(false);

    this.messageTarget.textContent = message;
    this.element.showModal();

    return new Promise((resolve) => {
      this.resolve = resolve;
    });
  }

  yes() {
    this.answer(true);
  }

  no() {
    this.answer(false);
  }

  // Teaser: Escape triggers the dialog's native close event, so resolving
  // here means callers never hang on a dismissed dialog.
  closed() {
    this.answer(false);
  }

  // Teaser: for backdrop clicks, the <dialog> element itself is the target
  // (clicks inside land on its children).
  backdropClick(event) {
    if (event.target === this.element) this.answer(false);
  }

  answer(value) {
    this.element.close();
    this.resolve?.(value);
    this.resolve = null;
  }
}
```

- **Escape:** `<dialog>` fires a native `close` event, so `closed()` resolves with `false` for free.
- **Backdrop:** clicks inside the dialog land on its children, but a backdrop click targets the `<dialog>` element itself; `backdropClick()` checks exactly that.
- **Concurrent asks:** a second `ask()` while one is pending would overwrite `this.resolve` and leave the first caller awaiting forever. The previous promise is settled with `false` first.

### List-item controller

The two-handler event dance collapses into one linear method that reads like synchronous code:

```js
// controllers/list_item_controller.js
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static outlets = ['confirm'];

  async delete(event) {
    event.preventDefault();

    if (await this.confirmOutlet.ask('Delete this item?')) {
      event.target.closest('form').requestSubmit();
    }
  }
}
```

## Key Points

- Events have no return value; a promise-returning method gives controllers a request/response shape.
- Deferred promise: `return new Promise(resolve => { this.resolve = resolve })`, then call `this.resolve(value)` from another handler.
- Combine with outlets (`static outlets = ["confirm"]`, `data-list-item-confirm-outlet="#confirm-dialog"`) so any controller can `await this.confirmOutlet.ask(...)`.
- Null out `resolve` after settling so repeated settle paths (button, then `close` event) are harmless.
- Every exit path must settle the promise: buttons, Escape (`close` event) and backdrop clicks (`event.target === this.element`).
- Pick an explicit policy for concurrent asks (queue, reject, or refuse); this solution settles the previous one with `false`. A silently unresolved promise is one of the nastiest bugs to track down.
