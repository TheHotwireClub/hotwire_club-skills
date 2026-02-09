---
title: Stimulus - Progressive Image Loading with Blurhash
date: 2024-04-23
categories:
- Stimulus
tags:
- Lazy Loading
- blurhash
- Progressive Enhancement
- Performance
- Core Web Vitals
description: Improve Largest Contentful Paint using image blurhashes and Stimulus
free: true
ready: true
---

## Overview

Blurhashes provide a way to improve Largest Contentful Paint (LCP) and prevent layout shift when lazy loading images. Using Stimulus, we can create a progressive image loading experience that displays a blurhash placeholder while the actual image loads.

## Implementation

### HTML Structure

Images are wrapped in containers with a Stimulus controller and blurhash value. Images start with `opacity-0` while canvases start with `opacity-100`:

```html
<div
  class="relative rounded-md"
  data-controller="lazy-image"
  data-lazy-image-blurhash-value="qmH{m5I9D%V@WBj@WBj[_4aeM{WAWAayayj[WCx]t7WBRjWBfQj[NIt7t7offkayaxWBR+oLazt7t7kCWBWBxZR+ofj[ofofj[ay"
>
  <img
    src="https://picsum.photos/id/13/300/200"
    data-lazy-image-target="image"
    class="opacity-0 transition-opacity duration-500 rounded-md"
  />
  <canvas
    data-lazy-image-target="canvas"
    class="absolute top-0 left-0 opacity-100 transition-opacity duration-500 rounded-md"
  ></canvas>
</div>
```

### Stimulus Controller

The controller uses the blurhash library to decode and paint the placeholder, then transitions to the loaded image:

```js
import { Controller } from '@hotwired/stimulus';
import { decode } from 'blurhash';

export default class extends Controller {
  static targets = ['image', 'canvas'];
  static values = { blurhash: String };

  connect() {
    const width = this.imageTarget.width;
    const height = this.imageTarget.height;

    this.canvasTarget.width = width;
    this.canvasTarget.height = height;

    const pixels = decode(this.blurhashValue, width, height);
    const ctx = this.canvasTarget.getContext('2d');
    const imageData = ctx.createImageData(width, height);
    imageData.data.set(pixels);
    ctx.putImageData(imageData, 0, 0);

    // simulate slow loading
    // should be this.imageTarget.addEventListener('load', ...)
    setTimeout(() => {
      this.canvasTarget.classList.remove('opacity-100');
      this.canvasTarget.classList.add('opacity-0');
      this.imageTarget.classList.remove('opacity-0');
      this.imageTarget.classList.add('opacity-100');
    }, 500);
  }
}
```

## Key Points

1. Canvas dimensions must match the image dimensions. Use `this.imageTarget.width` and `this.imageTarget.height` to set the canvas size.

2. The blurhash `decode` method returns a pixel array that is converted to `ImageData` and drawn on the canvas using `putImageData`.

3. In production, replace the `setTimeout` with `this.imageTarget.addEventListener('load', ...)` to trigger the transition when the image actually loads.

4. The opacity transition classes provide a smooth fade from blurhash placeholder to the loaded image.
