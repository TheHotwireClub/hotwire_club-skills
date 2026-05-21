---
title: Turbo Frames - Chained Selects
date: 2026-03-24
categories:
- Turbo Frames
- Stimulus
tags:
- select
- forms
- chained selects
- dependent dropdowns
- turbo-frame
description: Build dependent dropdown menus that update dynamically using a Turbo Frame and a small Stimulus controller.
free: false
ready: true
---

## Table of Contents

- [Problem](#problem)
- [Solution](#solution)
- [Implementation](#implementation)
- [HTML structure](#html-structure)
- [Stimulus controller](#stimulus-controller)
- [Rails controller](#rails-controller)
- [Rails view (index.html.erb)](#rails-view-indexhtmlerb)
- [Key Points](#key-points)

## Problem

Dependent dropdowns (pick a country, then pick a city) traditionally require fetching JSON and manually rebuilding `<option>` elements, or managing loading state in a component framework. With Turbo Frames the server simply re-renders the HTML.

## Solution

Wrap the dependent `<select>` in a `<turbo-frame>`. When the first select changes, set the frame's `src` to a URL carrying the chosen value as a query parameter. The server filters the options and returns the updated frame. A small Stimulus controller wires the change event to the frame's `src`.

## Implementation

### HTML structure

```html
<form data-controller="chained-select">
  <select name="country_id"
          data-chained-select-target="country"
          data-action="chained-select#change">
    <option value="">Choose a country…</option>
    <option value="1">Germany</option>
    <option value="2">Austria</option>
  </select>

  <turbo-frame id="city_select" data-chained-select-target="cityFrame"></turbo-frame>
</form>
```

### Stimulus controller

```js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["country", "cityFrame"]

  change() {
    const countryId = this.countryTarget.value

    if (countryId) {
      this.cityFrameTarget.src = `/cities?country_id=${countryId}`
    } else {
      this.cityFrameTarget.removeAttribute("src")
      this.cityFrameTarget.innerHTML = ""
    }
  }
}
```

Setting `src` triggers Turbo to fetch and swap the frame. Resetting the country to the placeholder removes `src` and empties the frame.

### Rails controller

```ruby
class CitiesController < ApplicationController
  def index
    @cities = City.where(country_id: params[:country_id]).order(:name)
    render :index
  end
end
```

### Rails view (index.html.erb)

```erb
<turbo-frame id="city_select">
  <%= select_tag :city_id,
    options_from_collection_for_select(@cities, :id, :name),
    prompt: "Choose a city…" %>
</turbo-frame>
```

## Key Points

- The dependent `<select>` lives inside a `<turbo-frame>`; updating the frame's `src` reloads it.
- The server filters its option list from a query parameter — no JSON API, no manual DOM manipulation.
- The Stimulus controller only translates a change event into a `src` assignment.
- Removing `src` and clearing `innerHTML` resets the frame when the parent select returns to its placeholder.
- The pattern composes: a third level (city → neighborhood) is another frame plus another `src` assignment.
