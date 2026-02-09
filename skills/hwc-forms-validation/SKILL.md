---
name: hwc-forms-validation
description: Handle form submissions, inline editing, real-time validation, and typeahead with Hotwire. Use this skill when building interactive forms. (user)
location: user
---

# Forms & Validation

You are an expert in Hotwire form patterns. Help developers build interactive forms with proper validation feedback, inline editing, typeahead search, and modal forms using Turbo Frames and Stimulus.

## Core Principles

- Wrap forms in Turbo Frames to scope updates and capture validation errors
- Use HTTP status codes correctly: 422 for validation errors, 303 for successful redirects
- Use the `form` attribute to associate controls outside their parent form
- Handle `turbo:submit-end` for custom post-submission behavior
- Preserve focus and selection state during frame updates

## Common Patterns

### External Form Controls

**When to use**: Form controls rendered inside a Turbo Frame need to submit to a form outside the frame (e.g., sorting/filtering controls in results).

**GOOD - Using the form attribute**:

```html
<form id="search-form" data-controller="faceted-search">
  <input type="text" name="query">
  <input type="number" name="published_before">
</form>

<turbo-frame id="results" src="/results">
  <!-- This select submits to search-form even though it's in a frame -->
  <select name="sort" form="search-form" 
          data-action="input->faceted-search#perform">
    <option value="name_asc">Name A-Z</option>
    <option value="name_desc">Name Z-A</option>
  </select>
  
  <ul><!-- results --></ul>
</turbo-frame>
```

```erb
<%# Rails view helper %>
<%= select_tag :sort, 
    options_for_select([["Name A-Z", "name_asc"], ["Name Z-A", "name_desc"]], params[:sort]),
    form: "search-form",
    data: { action: "input->faceted-search#perform" } %>
```

**BAD - Duplicating form controls**:

```html
<!-- Don't duplicate controls in multiple places -->
<form id="search-form">
  <select name="sort">...</select>
</form>

<turbo-frame id="results">
  <select name="sort">...</select> <!-- Duplicate! Out of sync! -->
</turbo-frame>
```

See: `references/2026-02-03-turbo-frames-external-form.md`

---

### Modal Forms with Validation

**When to use**: Forms inside `<dialog>` elements that need to show validation errors and close on success.

**GOOD - Turbo Frame inside dialog with turbo:submit-end handler**:

```html
<dialog id="editDialog">
  <turbo-frame id="edit-form">
    <form action="/items" method="post">
      <p class="errors"><%= @errors if @errors.present? %></p>
      <input type="text" name="name" required>
      <button type="submit">Save</button>
    </form>
  </turbo-frame>
</dialog>

<button onclick="document.getElementById('editDialog').showModal()">
  Edit Item
</button>
```

```javascript
const dialog = document.getElementById('editDialog');

dialog.addEventListener('turbo:submit-end', async (e) => {
  const { ok, url } = e.detail.fetchResponse.response;
  
  if (ok) {
    // Success: close dialog and navigate
    dialog.close();
    Turbo.visit(url, { action: 'replace' });
  }
  // Validation errors: Turbo Frame swaps in error messages automatically
});
```

```ruby
# Rails controller
def create
  @item = Item.new(item_params)
  
  if @item.save
    redirect_to items_path, status: :see_other
  else
    @errors = @item.errors.full_messages.join(', ')
    render :new, status: :unprocessable_entity
  end
end
```

**BAD - No Turbo Frame (errors not displayed)**:

```html
<!-- Without a Turbo Frame, validation errors cause a full page swap -->
<dialog id="editDialog">
  <form action="/items" method="post">
    <!-- Errors won't show in modal! -->
  </form>
</dialog>
```

See: `references/2024-05-21-turbo-frames-modals-validation.md`

---

### Inline Editing

**When to use**: Edit content in place without navigating to a separate edit page.

**GOOD - Turbo Frame swap between display and edit views**:

```html
<!-- Display view -->
<turbo-frame id="title-editor">
  <a href="/posts/1/edit_title">
    <%= @post.title %>
  </a>
</turbo-frame>

<!-- Edit view (returned by /posts/1/edit_title) -->
<turbo-frame id="title-editor">
  <form action="/posts/1/title" method="patch">
    <input type="text" name="post[title]" value="<%= @post.title %>" 
           autofocus id="post_title">
  </form>
</turbo-frame>
```

```javascript
// Auto-submit on blur and select text on focus
document.addEventListener('turbo:frame-render', () => {
  const input = document.querySelector('#post_title');
  if (!input) return;
  
  input.select(); // Select all text for easy replacement
  
  input.addEventListener('focusout', (e) => {
    e.target.closest('form').requestSubmit();
  });
});
```

**BAD - Inline editing without proper focus management**:

```javascript
// Don't forget to handle focus and selection
document.addEventListener('turbo:frame-render', () => {
  // Missing: text selection, auto-submit on blur
});
```

See: `references/2024-02-27-turbo-frames-inline-edit.md`

---

### Typeahead Search

**When to use**: Filter results as user types in a search field.

**GOOD - Debounced form submission with Turbo Frame**:

```html
<form action="/search" data-controller="debounce" data-turbo-frame="results">
  <input type="search" name="q" 
         data-action="input->debounce#perform"
         data-debounce-wait-value="300">
</form>

<turbo-frame id="results">
  <!-- Search results rendered here -->
</turbo-frame>
```

```javascript
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static values = { wait: { type: Number, default: 300 } };
  
  perform() {
    clearTimeout(this.timeout);
    this.timeout = setTimeout(() => {
      this.element.requestSubmit();
    }, this.waitValue);
  }
}
```

**BAD - No debouncing (fires on every keystroke)**:

```html
<!-- Don't submit on every input event -->
<form data-action="input->form#submit">
  <input type="search" name="q"> <!-- Too many requests! -->
</form>
```

See: `references/2023-11-07-turbo-frames-typeahead-search.md`

---

### Flash Messages Outside Frames

**When to use**: Display flash messages when a form inside a Turbo Frame is submitted.

**GOOD - Extract flash from response and inject**:

```javascript
document.addEventListener('turbo:submit-end', async (e) => {
  const html = await e.detail.fetchResponse.responseHTML;
  const doc = new DOMParser().parseFromString(html, 'text/html');
  const flash = doc.querySelector('#flash-messages');
  
  if (flash) {
    document.querySelector('#flash-messages').replaceWith(flash);
  }
});
```

See: `references/2024-08-27-turbo-frames-flash.md`

---

## HTTP Status Codes for Forms

| Scenario | Status Code | Turbo Behavior |
|----------|-------------|----------------|
| Validation errors | 422 | Re-renders form with errors |
| Success (redirect) | 303 | Follows redirect |
| Success (same page) | 200 | Replaces content |

## Key Turbo Events for Forms

| Event | When it fires | Common use |
|-------|--------------|------------|
| `turbo:submit-start` | Form submission begins | Disable buttons, show loading |
| `turbo:submit-end` | Form submission completes | Handle success, close modals |
| `turbo:frame-render` | Frame content swapped | Attach event listeners, focus management |

## Full Article References

- [Turbo Frames - External Forms](references/2026-02-03-turbo-frames-external-form.md)
- [Turbo Frames - Modals with Validation](references/2024-05-21-turbo-frames-modals-validation.md)
- [Turbo Frames - Inline Edit](references/2024-02-27-turbo-frames-inline-edit.md)
- [Turbo Frames - Typeahead Search](references/2023-11-07-turbo-frames-typeahead-search.md)
- [Turbo Frames - Typeahead Validation](references/2025-10-20-turbo-frames-typeahead-validation.md)
- [Turbo Frames - Flash Messages](references/2024-08-27-turbo-frames-flash.md)
- [Stimulus - Action Parameters](references/2024-01-16-stimulus-action-parameters.md)
