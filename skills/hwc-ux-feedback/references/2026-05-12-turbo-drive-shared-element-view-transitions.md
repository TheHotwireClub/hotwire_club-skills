---
title: Turbo Drive - Shared Element View Transitions
date: 2026-05-12
categories:
- Turbo Drive
tags:
- View Transitions
- view-transition-name
- shared element transition
description: Morph a gallery thumbnail into a full-size hero image across page navigations using the View Transitions API and Turbo Drive.
free: false
ready: true
---

## Table of Contents

- [Problem](#problem)
- [Solution](#solution)
- [Implementation](#implementation)
- [Enable View Transitions](#enable-view-transitions)
- [Index page — unique name per thumbnail](#index-page--unique-name-per-thumbnail)
- [Detail page — matching name on the hero](#detail-page--matching-name-on-the-hero)
- [Optional transition styling](#optional-transition-styling)
- [Key Points](#key-points)

## Problem

A shared element transition — a grid thumbnail smoothly morphing into a hero image on the detail page — normally requires a JavaScript animation library and manual coordinate math. With Turbo Drive and the View Transitions API the browser handles the interpolation.

## Solution

When two elements on different pages share the same `view-transition-name`, the browser automatically interpolates their position, size, and appearance during a navigation. Assign a unique name to each thumbnail on the index page, and the same name to the matching hero image on the detail page.

The name **must be unique per page**: if two elements share a `view-transition-name` at the same time, the transition aborts silently and falls back to a hard cut.

## Implementation

### Enable View Transitions

Turbo Drive opts into the API via a meta tag:

```html
<meta name="view-transition" content="same-origin">
```

### Index page — unique name per thumbnail

Bind a dynamic name to each card image with an inline style. In Rails, the model ID gives a naturally unique name:

```erb
<div class="gallery">
  <% @photos.each do |photo| %>
    <%= link_to photo_path(photo) do %>
      <%= image_tag photo.thumbnail_url,
            style: "view-transition-name: photo-#{photo.id}" %>
      <span><%= photo.title %></span>
    <% end %>
  <% end %>
</div>
```

### Detail page — matching name on the hero

Only one hero exists per detail page, so there is no collision risk — just match the index name:

```erb
<%= image_tag @photo.hero_url,
      style: "view-transition-name: photo-#{@photo.id}" %>
```

When the browser sees `photo-42` disappear from the old page and appear on the new one, it creates the morph animation automatically.

### Optional transition styling

The stylesheet can tune the named transition; Turbo also sets `data-turbo-visit-direction` on `<html>` during rendering, allowing a distinct easing or duration for the reverse (Back) navigation:

```css
::view-transition-group(*) {
  animation-duration: 0.3s;
}

html[data-turbo-visit-direction="back"] ::view-transition-group(*) {
  animation-timing-function: ease-out;
}
```

## Key Points

- Two elements on different pages with the same `view-transition-name` are morphed automatically by the browser — no JavaScript animation code.
- `view-transition-name` must be unique per page; a duplicate aborts the entire transition silently.
- In Rails, scope the name to the model ID (`view-transition-name: photo-<%= photo.id %>`) to guarantee uniqueness in a grid.
- Turbo Drive enables the API with `<meta name="view-transition" content="same-origin">`.
- The reverse (Back) navigation replays the morph automatically; `data-turbo-visit-direction` on `<html>` lets you style it differently.
- Test with Turbo's page cache enabled — a cached snapshot can reintroduce a duplicate `view-transition-name` during restoration.
