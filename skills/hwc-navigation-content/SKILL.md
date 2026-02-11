---
name: hwc-navigation-content
description: Build pagination, lazy loading, search, filtering, and tabbed navigation with Hotwire. Use this skill when the user asks about Turbo Frame pagination, lazy loading, tabbed navigation, scroll position restoration, faceted search, instant click, Turbo cache lifecycle, or markdown preview. (user)
location: user
---

# Navigation & Content Display

You are an expert in Hotwire navigation and content display patterns. Help developers build pagination, lazy loading, tabbed navigation, search, and filtering using Turbo Drive and Turbo Frames.

## Core Principles

- Use `data-turbo-action="advance"` for browser history support in frame navigation
- Handle active state updates in `turbo:frame-load`, not `turbo:click`
- Use `loading="lazy"` for frames that should load when scrolled into view
- Manage cache lifecycle with `turbo:before-cache` for clean snapshots
- Use `turbo:before-fetch-request` to intercept and modify requests

## Common Patterns

### Tabbed Navigation

**When to use**: Switch between content sections without full page reloads, with browser history support.

**GOOD - Turbo Frame tabs with history and active state**:

```html
<nav aria-label="Tabs">
  <a href="/map" data-turbo-frame="content" data-turbo-action="advance">Map</a>
  <a href="/images" data-turbo-frame="content" data-turbo-action="advance">Images</a>
  <a href="/facts" data-turbo-frame="content" data-turbo-action="advance">Facts</a>
</nav>

<turbo-frame id="content">
  <!-- Tab content rendered here -->
</turbo-frame>
```

```javascript
// Update active tab styling on frame load
document.addEventListener('turbo:frame-load', (event) => {
  document.querySelectorAll('nav a').forEach((link) => {
    const isActive = link.href === event.target.src;
    link.classList.toggle('active', isActive);
    link.setAttribute('aria-current', isActive ? 'page' : null);
  });
});
```

**BAD - Using turbo:click for active state**:

```javascript
// Don't use turbo:click - it fires before the frame loads
document.addEventListener('turbo:click', (e) => {
  // Frame hasn't loaded yet! Active state may be wrong if load fails
  e.target.classList.add('active');
});
```

See: `references/2023-06-20-turbo-frames-tabbed-navigation.md`

---

### Pagination with Browser History

**When to use**: Navigate through pages of data with working back/forward buttons.

**GOOD - Frame pagination with URL rewriting**:

```html
<turbo-frame id="paginated-content">
  <table>
    <!-- Data rows -->
  </table>
  <nav>
    <a href="/?page=1" data-turbo-action="advance">1</a>
    <a href="/?page=2" data-turbo-action="advance">2</a>
    <a href="/?page=3" data-turbo-action="advance">3</a>
  </nav>
</turbo-frame>
```

```javascript
// On page load, set frame src from query param
document.addEventListener('DOMContentLoaded', () => {
  const page = new URL(location.href).searchParams.get('page');
  if (page) {
    document.querySelector('turbo-frame').src = `/pages/${page}`;
  }
});

// Rewrite URL before fetch
document.addEventListener('turbo:before-fetch-request', (event) => {
  const page = new URL(event.detail.url).searchParams.get('page');
  if (page) {
    event.preventDefault();
    event.detail.url.pathname = `/pages/${page}`;
    event.detail.url.search = '';
    event.detail.resume();
  }
});

// Replace history entry with clean URL
document.addEventListener('turbo:frame-load', (event) => {
  const match = event.target.src.match(/pages\/(\d+)/);
  if (match) {
    const url = new URL(location.href);
    url.search = `page=${match[1]}`;
    Turbo.navigator.history.replace(url);
  }
});
```

**BAD - Manual pushState (breaks Turbo's restoration)**:

```javascript
// Don't implement pushState manually
paginationLink.addEventListener('click', () => {
  history.pushState({}, '', `/?page=${page}`); // Breaks Turbo!
});
```

See: `references/2023-07-04-turbo-frames-pagination.md`

---

### Lazy Loading Frames

**When to use**: Defer loading content until it's scrolled into view.

**GOOD - Lazy frame with loading indicator**:

```html
<turbo-frame id="comments" src="/comments" loading="lazy">
  <div class="placeholder">Loading comments...</div>
</turbo-frame>
```

**Track when lazy frames load**:

```html
<li data-controller="section"
    data-section-frame-value="introduction"
    data-action="turbo:frame-load@document->section#markLoaded">
  <a href="#introduction">Introduction</a>
</li>

<turbo-frame id="introduction" src="/intro" loading="lazy">
  Loading...
</turbo-frame>
```

```javascript
export default class extends Controller {
  static values = { frame: String, loaded: Boolean };

  markLoaded(event) {
    if (event.target.id === this.frameValue) {
      this.loadedValue = true;
    }
  }

  loadedValueChanged() {
    if (this.loadedValue) {
      this.element.classList.add('loaded');
    }
  }
}
```

See: `references/2023-09-26-turbo-frames-lazy-loading-lifecycle.md`

---

### Scroll Position Restoration

**When to use**: Preserve scroll position when navigating back to a page.

**GOOD - Store scroll position in sessionStorage**:

```javascript
document.addEventListener('turbo:before-cache', () => {
  const scrollable = document.querySelector('.scrollable-content');
  sessionStorage.setItem('scrollPosition', scrollable.scrollTop);
});

document.addEventListener('turbo:render', () => {
  const position = sessionStorage.getItem('scrollPosition');
  if (position) {
    document.querySelector('.scrollable-content').scrollTop = position;
  }
});
```

See: `references/2023-09-12-turbo-frames-scroll-position-restoration.md`

---

### Cache Lifecycle Management

**When to use**: Clean up UI state before Turbo caches the page.

**GOOD - Reset state before caching**:

```javascript
document.addEventListener('turbo:before-cache', () => {
  // Close dropdowns
  document.querySelectorAll('[data-expanded]').forEach(el => {
    el.removeAttribute('data-expanded');
  });
  
  // Clear temporary messages
  document.querySelectorAll('.flash').forEach(el => el.remove());
  
  // Reset form state
  document.querySelectorAll('form').forEach(form => form.reset());
});
```

**BAD - Leaving transient UI state in cache**:

```javascript
// Don't leave modals open, dropdowns expanded, etc.
// They'll show briefly on back navigation!
```

See: `references/2023-05-23-turbo-drive-cache-lifecycle.md`

---

### Faceted Search

**When to use**: Filter results by multiple criteria with URL state.

**GOOD - Stimulus controller collecting form data into frame src**:

```html
<form data-controller="faceted-search" data-turbo-frame="results">
  <input type="text" name="q" data-action="input->faceted-search#search">
  <select name="category" data-action="change->faceted-search#search">
    <option value="">All</option>
    <option value="books">Books</option>
  </select>
</form>

<turbo-frame id="results" src="/results"></turbo-frame>
```

```javascript
export default class extends Controller {
  search() {
    const params = new URLSearchParams(new FormData(this.element));
    const frame = document.querySelector('turbo-frame#results');
    frame.src = `/results?${params}`;
  }
}
```

See: `references/2024-12-10-stimulus-turbo-frames-faceted-search.md`

---

## Key Turbo Events for Navigation

| Event | When it fires | Common use |
|-------|--------------|------------|
| `turbo:frame-load` | Frame content loaded | Update active states, track loads |
| `turbo:before-fetch-request` | Before frame fetches | Rewrite URLs, add headers |
| `turbo:before-cache` | Before page cached | Clean up transient UI state |
| `turbo:render` | After page renders | Restore scroll position |

## Full Article References

- [Turbo Frames - Tabbed Navigation](references/2023-06-20-turbo-frames-tabbed-navigation.md)
- [Turbo Frames - Pagination](references/2023-07-04-turbo-frames-pagination.md)
- [Turbo Frames - Lazy Loading Lifecycle](references/2023-09-26-turbo-frames-lazy-loading-lifecycle.md)
- [Turbo Frames - Scroll Position Restoration](references/2023-09-12-turbo-frames-scroll-position-restoration.md)
- [Turbo Drive - Cache Lifecycle](references/2023-05-23-turbo-drive-cache-lifecycle.md)
- [Turbo Drive - Custom Rendering](references/2023-05-09-turbo-drive-custom-rendering.md)
- [Turbo Drive - Conditional Instant Click](references/2024-02-13-turbo-drive-conditional-instant-click.md)
- [Faceted Search with Stimulus](references/2024-12-10-stimulus-turbo-frames-faceted-search.md)
- [Turbo Frames - Markdown Preview](references/2024-10-08-turbo-frames-markdown-preview.md)
