---
name: hwc-stimulus-fundamentals
description: Master Stimulus controller patterns including lifecycle hooks, value callbacks, outlets, targets, and events. Use this skill when the user asks about Stimulus value callbacks, target callbacks, outlets API, keyboard events, auto-sorting, Web Share API, Core Web Vitals, or general Stimulus controller patterns. (user)
location: user
---

# Stimulus Fundamentals

You are an expert in Stimulus.js controller patterns. Help developers master lifecycle hooks, value callbacks, outlets, targets, events, and best practices for building maintainable Stimulus controllers.

## Core Principles

- Use values for reactive state that should trigger updates
- Use targets for DOM element references
- Use outlets for inter-controller communication
- Use CSS classes for presentation logic
- Clean up resources in `disconnect()`
- Guard against undefined state in value callbacks (they can fire before `connect()`)

## Common Patterns

### Value Changed Callbacks

**When to use**: React to state changes, especially when integrating third-party libraries.

**GOOD - Reactive updates with safe guards**:

```javascript
import { Controller } from '@hotwired/stimulus';
import Chart from 'chart.js';

export default class extends Controller {
  static targets = ['canvas'];
  static values = { data: Array };

  connect() {
    this.chart = new Chart(this.canvasTarget, {
      type: 'line',
      data: { datasets: [{ data: this.dataValue }] }
    });
  }

  disconnect() {
    this.chart?.destroy();
  }

  dataValueChanged() {
    // Guard: callback can fire before connect()
    if (!this.chart) return;
    
    this.chart.data.datasets[0].data = this.dataValue;
    this.chart.update('none'); // 'none' disables animation
  }
}
```

**BAD - No guard against early callback**:

```javascript
dataValueChanged() {
  // Crashes if called before connect()!
  this.chart.data.datasets[0].data = this.dataValue;
}
```

See: `references/2023-08-29-stimulus-value-changed-callbacks.md`

---

### Outlets API (Inter-Controller Communication)

**When to use**: Pass data or trigger actions between controllers.

**GOOD - Declare outlets and call methods on them**:

```html
<div data-controller="dashboard"
     data-dashboard-job-outlet=".job"
     data-dashboard-widget-outlet=".widget">
  
  <div class="job" data-controller="job" id="job-1">...</div>
  <div class="job" data-controller="job" id="job-2">...</div>
  
  <div class="widget" data-controller="widget" 
       data-widget-status-value="running">...</div>
</div>
```

```javascript
// dashboard_controller.js
export default class extends Controller {
  static outlets = ['job', 'widget'];
  static values = { jobs: Array };

  jobsValueChanged() {
    // Update each job outlet
    this.jobOutlets.forEach((outlet) => {
      const job = this.jobsValue.find(j => j.id === outlet.element.id);
      outlet.refresh(job);
    });

    // Update widget counters
    this.widgetOutlets.forEach((outlet) => {
      const count = this.jobsValue.filter(
        j => j.status === outlet.statusValue
      ).length;
      outlet.update(count);
    });
  }
}

// job_controller.js
export default class extends Controller {
  static targets = ['indicator'];
  static classes = ['queued', 'running', 'completed'];

  refresh(job) {
    // Remove all status classes, add current
    this.indicatorTarget.classList.remove(
      ...this.queuedClasses,
      ...this.runningClasses,
      ...this.completedClasses
    );
    this.indicatorTarget.classList.add(...this[`${job.status}Classes`]);
  }
}

// widget_controller.js
export default class extends Controller {
  static values = { status: String };
  static targets = ['count'];

  update(count) {
    this.countTarget.textContent = count;
  }
}
```

**BAD - Using private API**:

```javascript
// Don't use private API for controller communication
const otherController = this.application
  .getControllerForElementAndIdentifier(element, 'other'); // Private!
```

See: `references/2023-12-19-stimulus-outlets-api.md`

---

### Target Callbacks

**When to use**: React when targets are connected/disconnected (e.g., from Turbo Stream updates).

**GOOD - Update UI when targets change**:

```javascript
export default class extends Controller {
  static targets = ['item'];
  static values = { count: Number };

  itemTargetConnected(target) {
    this.countValue = this.itemTargets.length;
  }

  itemTargetDisconnected(target) {
    this.countValue = this.itemTargets.length;
  }

  countValueChanged() {
    this.element.querySelector('.count').textContent = this.countValue;
  }
}
```

See: `references/2024-05-07-stimulus-target-callbacks.md`

---

### KeyboardEvent Handling

**When to use**: Handle keyboard shortcuts without third-party libraries.

**GOOD - Stimulus action filters**:

```html
<div data-controller="shortcuts"
     data-action="keydown.ctrl+s@document->shortcuts#save
                  keydown.escape@document->shortcuts#cancel
                  keydown.enter->shortcuts#submit">
  <input type="text">
  <button>Save</button>
</div>
```

```javascript
export default class extends Controller {
  save(event) {
    event.preventDefault(); // Prevent browser save dialog
    // Save logic
  }

  cancel(event) {
    // Cancel logic
  }

  submit(event) {
    // Submit logic
  }
}
```

**Supported modifiers**: `ctrl`, `alt`, `shift`, `meta`  
**Supported keys**: `enter`, `tab`, `esc`, `space`, `up`, `down`, `left`, `right`, plus letter/number keys

See: `references/2023-10-24-stimulus-keyboardevent-101.md`

---

### Action Parameters

**When to use**: Pass data to actions declaratively from HTML.

**GOOD - Data attributes for parameters**:

```html
<div data-controller="modal">
  <button data-action="click->modal#open"
          data-modal-id-param="settings"
          data-modal-size-param="large">
    Settings
  </button>
  
  <button data-action="click->modal#open"
          data-modal-id-param="help"
          data-modal-size-param="small">
    Help
  </button>
</div>
```

```javascript
export default class extends Controller {
  open({ params: { id, size } }) {
    const modal = document.querySelector(`#${id}-modal`);
    modal.classList.add(`modal--${size}`);
    modal.showModal();
  }
}
```

**BAD - Reading data attributes manually**:

```javascript
open(event) {
  // Don't manually read data attributes
  const id = event.target.dataset.modalIdParam; // Use params instead!
}
```

See: `references/2024-01-16-stimulus-action-parameters.md`

---

### MutationObserver for Auto-Sorting

**When to use**: React to DOM changes from WebSocket/Turbo Stream messages.

**GOOD - Sort items by timestamp when added out of order**:

```javascript
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  connect() {
    this.observer = new MutationObserver((mutations) => {
      this.sort();
    });
    
    this.observer.observe(this.element, { childList: true });
  }

  disconnect() {
    this.observer.disconnect();
  }

  sort() {
    const items = [...this.element.children];
    items.sort((a, b) => {
      return new Date(a.dataset.timestamp) - new Date(b.dataset.timestamp);
    });
    items.forEach(item => this.element.appendChild(item));
  }
}
```

See: `references/2023-12-05-stimulus-auto-sorting.md`

---

### Web Share API

**When to use**: Native share dialogs on mobile and supported browsers.

**GOOD - Feature detection with graceful fallback**:

```html
<div data-controller="share"
     data-share-title-value="Check this out"
     data-share-url-value="https://example.com">
  <button data-action="click->share#share" 
          data-share-target="button"
          class="hidden">
    Share
  </button>
</div>
```

```javascript
export default class extends Controller {
  static targets = ['button'];
  static values = { title: String, text: String, url: String };

  connect() {
    // Only show button if Web Share is supported
    if (navigator.canShare?.({ url: this.urlValue })) {
      this.buttonTarget.classList.remove('hidden');
    }
  }

  async share() {
    try {
      await navigator.share({
        title: this.titleValue,
        text: this.textValue,
        url: this.urlValue
      });
    } catch (err) {
      if (err.name !== 'AbortError') {
        console.error('Share failed:', err);
      }
    }
  }
}
```

**Note**: Web Share API is not supported in Firefox desktop.

See: `references/2025-11-25-stimulus-web-share-api.md`

---

## Stimulus Lifecycle

| Method | When it's called |
|--------|------------------|
| `initialize()` | Once, when controller is instantiated |
| `connect()` | Each time element is connected to DOM |
| `disconnect()` | Each time element is disconnected from DOM |
| `{name}ValueChanged()` | When a value changes (can fire before connect!) |
| `{name}TargetConnected()` | When a target is added to DOM |
| `{name}TargetDisconnected()` | When a target is removed from DOM |

## Declaration Patterns

```javascript
export default class extends Controller {
  // DOM element references
  static targets = ['input', 'output'];
  
  // Reactive state
  static values = { 
    count: { type: Number, default: 0 },
    items: Array 
  };
  
  // Inter-controller communication
  static outlets = ['other-controller'];
  
  // CSS class mappings
  static classes = ['active', 'hidden'];
}
```

## Full Article References

- [Stimulus - Value Changed Callbacks](references/2023-08-29-stimulus-value-changed-callbacks.md)
- [Stimulus - Outlets API](references/2023-12-19-stimulus-outlets-api.md)
- [Stimulus - Target Callbacks](references/2024-05-07-stimulus-target-callbacks.md)
- [Stimulus - KeyboardEvent 101](references/2023-10-24-stimulus-keyboardevent-101.md)
- [Stimulus - Action Parameters](references/2024-01-16-stimulus-action-parameters.md)
- [Stimulus - Auto-Sorting with MutationObserver](references/2023-12-05-stimulus-auto-sorting.md)
- [Stimulus - Web Share API](references/2025-11-25-stimulus-web-share-api.md)
- [Core Web Vitals Optimization](references/2024-06-18-fundamentals-core-web-vitals.md)
