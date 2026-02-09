---
title: Turbo Frames - Render Flash Messages Upon Form Submission
date: '2024-08-27'
tags:
- "turbo:submit-end"
- "turbo-frames"
- "flash-messages"
- "form-submission"
free: false
ready: true
description: Intercept form submission responses to render flash messages that are
  outside the originating Turbo Frame
---

## Problem

When submitting forms within a Turbo Frame, flash messages that exist outside the frame are not automatically updated. The server typically renders the full template including flash messages, but only the targeted Turbo Frame content is exchanged.

## Solution

Use the `turbo:submit-end` event to intercept the form submission response and extract flash message content from the full HTML response. The `fetchResponse` object in the event detail contains the complete HTML response, which can be parsed to update flash elements outside the frame.

## Implementation

### HTML Structure

```html
<body>
  <span id="notice">{{notice}}</span>
  <span id="alert">{{alert}}</span>

  <turbo-frame id="form-wrapper">
    <p>Current Status: {{status}}</p>

    <form action="/update" method="post">
      <label for="status">New status:</label>
      <input type="text" name="status" autocomplete="off" />

      <input type="submit" />
    </form>
  </turbo-frame>
</body>
```

### JavaScript Implementation

```js
import '@hotwired/turbo';
import 'controllers';

Turbo.start();

document.addEventListener('turbo:load', () => {
  document.addEventListener('turbo:submit-end', async ({ detail }) => {
    const { fetchResponse } = detail;

    const html = await fetchResponse.responseHTML;

    const template = document.createElement('template');
    template.innerHTML = html.trim();

    document.querySelector('#notice').innerHTML =
      template.content.querySelector('#notice').innerHTML;
    document.querySelector('#alert').innerHTML =
      template.content.querySelector('#alert').innerHTML;
  });
});
```

## Technical Details

1. The `turbo:submit-end` event provides a `fetchResponse` object in `event.detail`
2. `fetchResponse.responseHTML` returns a Promise that resolves to the full HTML response
3. A temporary `template` element is created to parse the HTML response into a DOM structure
4. Flash elements are extracted from the parsed template and used to update the corresponding elements in the document
5. The template element is automatically discarded after use

## Notes

- The server should reset flash messages to empty strings after they've been used
- This approach avoids full page navigation while still updating elements outside the Turbo Frame
- The `template` element is used because it doesn't render its contents, making it ideal for parsing HTML without affecting the visible DOM
