---
title: Stimulus - Web Share API
date: '2025-11-25'
tags:
- web apis
- stimulus
- web share api
- feature detection
free: false
ready: true
description: Use the native browser web sharing capabilities from Stimulus
---

The Web Share API allows sharing text, files, and URLs using native browser capabilities. Firefox does not support this API.

## Implementation

A Stimulus controller uses the Web Share API with `navigator.share()` and `navigator.canShare()` for feature detection. The controller accepts four values: `title`, `text`, `url`, and `file`.

### HTML Example

```html
<a
  href="#"
  data-controller="share"
  data-action="click->share#share:prevent"
  data-share-title-value="IMG1000"
  data-share-text-value="Summit Cross"
  data-share-url-value="https://picsum.photos/id/1000/600/400"
  data-share-file-value="https://picsum.photos/id/1000/1200/800"
>
  Share
</a>
```

### Stimulus Controller

```js
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static values = { title: String, text: String, url: String, file: String };

  async connect() {
    this.element.hidden = !navigator.canShare(await this.getShareData());
  }

  async share() {
    await navigator.share(await this.getShareData());
  }

  async getShareData() {
    return {
      title: this.titleValue,
      text: this.textValue,
      url: this.urlValue,
      files: [await this.getFile()],
    };
  }

  async getFile() {
    const response = await fetch(this.fileValue);
    const blob = await response.blob();

    const extension = blob.type.split('/').pop();

    return new File([blob], `${this.titleValue}.${extension}`, {
      type: blob.type,
    });
  }
}
```

## Key Points

- The Web Share API methods are asynchronous and return Promises.
- Share data is an object containing optional `title`, `text`, `url`, and `files` properties.
- The first three values come directly from Stimulus controller values.
- File sharing requires fetching the resource as a blob and wrapping it in a `File` object.
- Feature detection via `navigator.canShare()` should be performed in the `connect()` callback to hide the share element if sharing is not supported.
- The file extension is extracted from the blob's content type to construct the filename.
- `navigator.share()` is called in a Stimulus action triggered on click.
