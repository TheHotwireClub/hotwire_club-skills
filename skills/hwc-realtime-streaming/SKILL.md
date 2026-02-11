---
name: hwc-realtime-streaming
description: Implement WebSocket updates, live data, custom stream actions, and state synchronization with Hotwire. Use this skill when the user asks about Turbo Streams, custom stream actions, WebSocket updates, real-time data, inline stream tags, localStorage sync, list animations, inter-tab communication, or hotwire_combobox with live data. (user)
location: user
---

# Real-Time & Streaming

You are an expert in Hotwire real-time patterns. Help developers implement WebSocket updates, custom Turbo Stream actions, live data synchronization, and client-side streaming using Turbo Streams and Stimulus.

## Core Principles

- Turbo Streams can be delivered via WebSocket, SSE, or form responses
- Custom stream actions extend Turbo's 7 default actions for complex UI orchestration
- Inline stream tags enable client-side DOM updates without server communication
- Use ActionCable or Turbo Stream broadcasts for server-pushed updates
- Combine streams with View Transitions API for smooth animations

## Common Patterns

### Custom Stream Actions

**When to use**: Complex UI behaviors that aren't covered by the 7 default actions (append, prepend, replace, update, remove, before, after).

**GOOD - Define custom action on StreamActions**:

```javascript
import { StreamActions } from "@hotwired/turbo"

// Show a dialog
StreamActions.showDialog = function() {
  const target = this.getAttribute('target');
  document.querySelector(target)?.showModal();
};

// Highlight an element temporarily
StreamActions.highlight = function() {
  const element = document.querySelector(this.getAttribute('target'));
  element?.classList.add('highlight');
  setTimeout(() => element?.classList.remove('highlight'), 2000);
};

// Sequential animation cascade
StreamActions.animateCascade = async function() {
  const elements = document.querySelectorAll(this.getAttribute('targets'));
  for (const element of elements) {
    element.classList.add('animate');
    await new Promise(r => setTimeout(r, 250));
  }
};
```

**Rails ERB usage**:

```erb
<%# app/views/items/create.turbo_stream.erb %>
<%= turbo_stream.append "items", partial: "item", locals: { item: @item } %>
<%= turbo_stream.action "highlight", target: "#item_#{@item.id}" %>
<%= turbo_stream.action "showDialog", target: "#success-dialog" %>
```

**BAD - Inline JavaScript in stream responses**:

```erb
<%# Don't embed scripts in streams %>
<script>document.querySelector('#dialog').showModal()</script>
```

See: `references/2023-08-15-turbo-streams-custom-stream-actions.md`

---

### Inline Stream Tags (Client-Side)

**When to use**: Optimistic UI updates or microinteractions without server communication.

**GOOD - Template-based client-side streams**:

```html
<template id="progress-stream">
  <turbo-stream action="replace" target="progress-bar">
    <template>
      <progress id="progress-bar" value="0" max="100"></progress>
    </template>
  </turbo-stream>
</template>

<button id="start">Start</button>
<progress id="progress-bar" value="0" max="100"></progress>
```

```javascript
document.querySelector('#start').addEventListener('click', () => {
  let value = 0;
  const interval = setInterval(() => {
    if (value >= 100) return clearInterval(interval);
    
    value += 5;
    const clone = document.querySelector('#progress-stream')
      .content.cloneNode(true);
    clone.querySelector('progress').value = value;
    document.body.appendChild(clone); // Turbo executes and removes it
  }, 100);
});
```

**Key insight**: Turbo automatically executes and removes any `<turbo-stream>` element added to the DOM.

See: `references/2023-08-01-turbo-streams-inline-stream-tags.md`

---

### WebSocket Broadcasts with ActionCable

**When to use**: Push server updates to multiple connected clients in real-time.

**GOOD - Model broadcasts**:

```ruby
# app/models/message.rb
class Message < ApplicationRecord
  broadcasts_to :chat_room
end

# Or manually broadcast:
Turbo::StreamsChannel.broadcast_append_to(
  "chat_room_#{room.id}",
  target: "messages",
  partial: "messages/message",
  locals: { message: message }
)
```

```erb
<%# Subscribe to the stream %>
<%= turbo_stream_from @chat_room %>

<div id="messages">
  <%= render @messages %>
</div>
```

**GOOD - Broadcast refresh for morphing**:

```ruby
# Trigger a page refresh on all subscribers
Turbo::StreamsChannel.broadcast_refresh_to("dashboard")
```

See: `references/2024-03-12-hotwire-combobox-with-real-time-data.md`

---

### LocalStorage with Custom Stream Actions

**When to use**: Persist ephemeral client state that should survive page reloads.

**GOOD - Custom action to sync localStorage**:

```javascript
import { StreamActions } from "@hotwired/turbo"

StreamActions.setLocalStorage = function() {
  const key = this.getAttribute('key');
  const value = this.getAttribute('value');
  localStorage.setItem(key, value);
};

StreamActions.removeLocalStorage = function() {
  const key = this.getAttribute('key');
  localStorage.removeItem(key);
};
```

```erb
<%= turbo_stream.action "setLocalStorage", key: "current_video", value: @video.id %>
```

See: `references/2024-01-30-turbo-streams-custom-stream-actions-localstorage.md`

---

### List Animations with View Transitions

**When to use**: Animate items being added to lists via Turbo Streams.

**GOOD - Wrap stream render in View Transition**:

```javascript
document.addEventListener('turbo:before-stream-render', (event) => {
  if (event.target.action === 'append') {
    event.preventDefault();
    
    document.startViewTransition(() => {
      event.target.performAction();
    });
  }
});
```

```css
/* Animate new items */
@keyframes slide-in {
  from { opacity: 0; transform: translateY(-20px); }
  to { opacity: 1; transform: translateY(0); }
}

::view-transition-new(list-item) {
  animation: slide-in 0.3s ease-out;
}
```

See: `references/2025-06-10-turbo-streams-list-animation-view-transitions.md`

---

### Inter-Tab Communication

**When to use**: Sync state across browser tabs without WebSocket (same machine only).

**GOOD - Broadcast Channel API with Stimulus**:

```javascript
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static values = { channel: String };
  
  connect() {
    this.channel = new BroadcastChannel(this.channelValue);
    this.channel.onmessage = (event) => this.receive(event.data);
  }
  
  disconnect() {
    this.channel.close();
  }
  
  send(data) {
    this.channel.postMessage(data);
  }
  
  receive(data) {
    // Handle received data from other tabs
    console.log('Received:', data);
  }
}
```

**Note**: Broadcast Channel API only works for tabs on the same machine, not across devices.

See: `references/2023-11-21-stimulus-inter-tab-communication.md`

---

## Default Turbo Stream Actions

| Action | Description |
|--------|-------------|
| `append` | Add content to end of target |
| `prepend` | Add content to beginning of target |
| `replace` | Replace entire target element |
| `update` | Replace target's inner HTML |
| `remove` | Remove target from DOM |
| `before` | Insert content before target |
| `after` | Insert content after target |
| `refresh` | Morph the page (Turbo 8+) |

## Key Events for Streams

| Event | When it fires | Common use |
|-------|--------------|------------|
| `turbo:before-stream-render` | Before stream action executes | Wrap in View Transition, custom logic |
| `turbo:before-fetch-request` | Before stream request | Add headers, modify URL |

## Full Article References

- [Turbo Streams - Custom Stream Actions](references/2023-08-15-turbo-streams-custom-stream-actions.md)
- [Turbo Streams - Inline Stream Tags](references/2023-08-01-turbo-streams-inline-stream-tags.md)
- [Turbo Streams - Video Playlist Management](references/2023-10-10-turbo-streams-custom-stream-actions-video-playlist-management.md)
- [Turbo Streams - LocalStorage Integration](references/2024-01-30-turbo-streams-custom-stream-actions-localstorage.md)
- [Turbo Streams - List Animations](references/2025-06-10-turbo-streams-list-animation-view-transitions.md)
- [Hotwire Combobox with Real-Time Data](references/2024-03-12-hotwire-combobox-with-real-time-data.md)
- [Stimulus - Inter-Tab Communication](references/2023-11-21-stimulus-inter-tab-communication.md)
