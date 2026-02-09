---
name: hwc-ux-feedback
description: Implement loading states, progress indicators, optimistic UI, and smooth transitions with Hotwire. Use this skill when building responsive feedback for user actions. (user)
location: user
---

# User Experience & Feedback

You are an expert in Hotwire user experience patterns. Help developers implement loading states, progress indicators, optimistic UI, and smooth page transitions using Turbo Drive and Turbo Frames.

## Core Principles

- Provide immediate visual feedback for user actions
- Use Turbo's built-in `busy` attribute to detect loading states
- Leverage the Turbo progress bar for custom loading indicators
- Implement optimistic UI for perceived performance
- Use `turbo:before-render` for custom page transitions

## Common Patterns

### Loading Spinner for Turbo Frames

**When to use**: Turbo Frames loading content asynchronously (lazy loading or user-triggered navigation).

**GOOD - Using MutationObserver to detect busy attribute**:

```html
<turbo-frame id="content" src="/page1" data-controller="frame-spinner">
  <template data-frame-spinner-target="placeholder">
    <div class="spinner">Loading...</div>
  </template>
</turbo-frame>
```

```javascript
import { Controller } from '@hotwired/stimulus';
import { useMutation } from 'stimulus-use';

export default class extends Controller {
  static targets = ['placeholder'];

  connect() {
    useMutation(this, { attributes: true });
    this.templateNode = this.placeholderTarget.content.cloneNode(true);

    if (this.element.hasAttribute('busy')) {
      this.#renderPlaceholder();
    }
  }

  mutate(entries) {
    entries.filter(e => e.attributeName === 'busy').forEach(() => {
      this.#renderPlaceholder();
    });
  }

  #renderPlaceholder() {
    if (this.element.hasChildNodes()) {
      this.element.firstChild.replaceWith(this.templateNode.cloneNode(true));
    } else {
      this.element.appendChild(this.templateNode.cloneNode(true));
    }
  }
}
```

**BAD - Hardcoded timeouts**:

```javascript
// Don't guess when to show/hide spinner
loadFrame() {
  this.showSpinner();
  setTimeout(() => this.hideSpinner(), 2000); // Brittle!
}
```

**CSS-only alternative** (for simple text indicators):

```css
turbo-frame[busy] {
  font-size: 0;
  * { display: none; }
  &::after {
    font-size: 1rem;
    content: 'Loading...';
  }
}
```

See: `references/2026-01-20-turbo-frames-loading-spinner.md`

---

### Optimistic UI with Turbo 8 Morphs

**When to use**: Immediate feedback for actions like favorites, likes, or toggles where latency would feel sluggish.

**GOOD - Template-based optimistic updates**:

```html
<form method="post" action="/favorites" data-optimistic-form>
  <template class="optimistic-template">
    <turbo-stream action="replace" target="favorite-btn">
      <template>
        <button id="favorite-btn" disabled>
          <!-- Inverse state (optimistic) -->
          <svg class="heart-filled">...</svg>
        </button>
      </template>
    </turbo-stream>
  </template>
  
  <button type="submit" id="favorite-btn">
    <svg class="heart-empty">...</svg>
  </button>
</form>
```

```javascript
document.querySelectorAll('form[data-optimistic-form]').forEach((form) => {
  form.addEventListener('turbo:submit-start', (e) => {
    const template = e.target.querySelector('template.optimistic-template');
    document.body.appendChild(template.content.cloneNode(true));
  });
});
```

**Rails controller with morph reconciliation**:

```ruby
def create
  @favorite = current_user.toggle_favorite(params[:item_id])
  
  respond_to do |format|
    format.turbo_stream { render turbo_stream: turbo_stream.refresh }
  end
end
```

**BAD - Client-side state without reconciliation**:

```javascript
// Don't manage state purely client-side
button.addEventListener('click', () => {
  button.classList.toggle('favorited'); // No server reconciliation!
});
```

See: `references/2024-03-26-optimistic-ui-with-turbo-8-morphs.md`

---

### Custom Progress Bar for Long Operations

**When to use**: Background jobs, file uploads, or any operation with measurable progress.

**GOOD - Reusing Turbo's progress bar with WebSocket**:

```javascript
import consumer from "./channels/consumer"

consumer.subscriptions.create(
  { channel: "ProgressChannel", id: taskId },
  {
    received({ amount }) {
      const progressBar = window.Turbo.navigator.adapter.progressBar;
      progressBar.setValue(amount);
      amount < 1 ? progressBar.show() : progressBar.hide();
    }
  }
);
```

```ruby
# app/jobs/progress_job.rb
class ProgressJob < ApplicationJob
  def perform(task_id)
    progress = 0
    while progress < 1.0
      progress += 0.05
      ActionCable.server.broadcast("progress_#{task_id}", { amount: progress })
      sleep 0.1
    end
  end
end
```

**BAD - Custom progress bar without Turbo integration**:

```javascript
// Don't create a separate progress bar system
const customBar = document.createElement('div');
// ... lots of custom CSS and positioning
```

See: `references/2023-07-18-turbo-drive-progress-bar.md`

---

### Page Transitions with Render Interception

**When to use**: Adding animations or visual polish between page navigations.

**GOOD - Using turbo:before-render for animations**:

```javascript
document.addEventListener('turbo:before-render', async (event) => {
  // Skip for cached previews
  if (document.documentElement.hasAttribute('data-turbo-preview')) {
    return;
  }

  event.preventDefault();

  // Animate out
  document.querySelectorAll('.animate-out').forEach((el, i) => {
    el.classList.add('fly-out');
    el.style.animationDelay = `${i * 100}ms`;
  });

  // Wait for animation, then continue
  setTimeout(() => event.detail.resume(), 500);
});
```

**BAD - Not checking for preview/cache**:

```javascript
// Don't animate on every render including cache restores
document.addEventListener('turbo:before-render', (event) => {
  event.preventDefault();
  animate().then(() => event.detail.resume()); // Runs on back button too!
});
```

See: `references/2023-04-25-turbo-drive-render-interception.md`

---

### Form Activity Indicators

**When to use**: Forms that take time to process (file uploads, complex operations).

**GOOD - Using turbo:submit-start and turbo:submit-end**:

```javascript
document.addEventListener('turbo:submit-start', (e) => {
  const form = e.target;
  form.querySelector('[type="submit"]').disabled = true;
  form.classList.add('submitting');
});

document.addEventListener('turbo:submit-end', (e) => {
  const form = e.target;
  form.querySelector('[type="submit"]').disabled = false;
  form.classList.remove('submitting');
});
```

```css
form.submitting [type="submit"] {
  opacity: 0.5;
  cursor: wait;
}
```

See: `references/2023-06-06-turbo-drive-form-activity-indicators.md`

---

## Key Turbo Events

| Event | When it fires | Common use |
|-------|--------------|------------|
| `turbo:before-render` | Before new content renders | Page transitions, animations |
| `turbo:submit-start` | Form submission begins | Disable buttons, show spinners |
| `turbo:submit-end` | Form submission completes | Re-enable buttons, hide spinners |
| `turbo:frame-load` | Turbo Frame content loaded | Update related UI elements |

## Full Article References

- [Turbo Frames - Loading Spinner](references/2026-01-20-turbo-frames-loading-spinner.md)
- [Optimistic UI with Turbo 8 Morphs](references/2024-03-26-optimistic-ui-with-turbo-8-morphs.md)
- [Turbo Drive - Progress Bar](references/2023-07-18-turbo-drive-progress-bar.md)
- [Turbo Drive - Render Interception](references/2023-04-25-turbo-drive-render-interception.md)
- [Turbo Drive - Form Activity Indicators](references/2023-06-06-turbo-drive-form-activity-indicators.md)
- [Turbo Drive - Swiper View Transitions](references/2024-11-19-turbo-drive-swiper-view-transitions.md)
- [Turbo Drive - ULIDs for Optimistic UI](references/2024-08-13-turbo-drive-ulid.md)
