---
name: hwc-media-content
description: Handle images, video, audio, file uploads, and playback tracking with Hotwire. Use this skill when integrating media and third-party libraries. (user)
location: user
---

# Media & Rich Content

You are an expert in Hotwire media patterns. Help developers handle images, video, audio, file uploads, playback tracking, and third-party media library integrations using Stimulus.

## Core Principles

- Use Stimulus value callbacks to sync state with third-party libraries
- Leverage Web APIs (Picture-in-Picture, Blob URLs, IntersectionObserver) for native functionality
- Store playback progress in localStorage for persistence across sessions
- Use `URL.createObjectURL()` for instant file previews without server upload
- Clean up resources (blob URLs, observers) in `disconnect()`

## Common Patterns

### Image Upload Previews

**When to use**: Show image previews immediately after file selection, before upload.

**GOOD - Blob URLs with proper cleanup**:

```html
<div data-controller="file-preview">
  <input type="file" accept="image/*" multiple
         data-action="change->file-preview#preview">
  
  <template data-file-preview-target="template">
    <li>
      <img class="thumbnail">
      <span class="filename"></span>
    </li>
  </template>
  
  <ul data-file-preview-target="list"></ul>
</div>
```

```javascript
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['template', 'list'];

  preview(event) {
    for (const file of event.target.files) {
      const url = URL.createObjectURL(file);
      const clone = this.templateTarget.content.cloneNode(true);
      
      const img = clone.querySelector('img');
      img.src = url;
      img.onload = () => URL.revokeObjectURL(url); // Clean up!
      
      clone.querySelector('.filename').textContent = file.name;
      this.listTarget.appendChild(clone);
    }
  }
}
```

**BAD - No blob URL cleanup (memory leak)**:

```javascript
preview(event) {
  for (const file of event.target.files) {
    const url = URL.createObjectURL(file);
    img.src = url; // Memory leak! URL never revoked
  }
}
```

See: `references/media-content/2024-09-17-stimulus-image-upload-previews.md`

---

### Picture-in-Picture Video

**When to use**: Keep video playing in a floating window when scrolled out of view.

**GOOD - IntersectionObserver with stimulus-use**:

```html
<video controls data-controller="pip"
       data-action="enterpictureinpicture->pip#showIndicator 
                    leavepictureinpicture->pip#hideIndicator">
  <source src="/video.mp4" type="video/mp4">
</video>

<div id="pip-indicator" class="hidden">PiP Active</div>
```

```javascript
import { Controller } from '@hotwired/stimulus';
import { useIntersection } from 'stimulus-use';

export default class extends Controller {
  connect() {
    useIntersection(this);
  }

  appear() {
    if (document.pictureInPictureElement) {
      document.exitPictureInPicture();
    }
  }

  disappear() {
    if (!document.pictureInPictureElement && !this.element.paused) {
      this.element.requestPictureInPicture();
    }
  }

  showIndicator() {
    document.querySelector('#pip-indicator').classList.remove('hidden');
  }

  hideIndicator() {
    document.querySelector('#pip-indicator').classList.add('hidden');
  }
}
```

**Note**: Picture-in-Picture requires user interaction with the video first and is not supported in Firefox.

See: `references/media-content/2024-06-04-stimulus-picture-in-picture.md`

---

### Video Progress Tracking

**When to use**: Resume video playback from where the user left off.

**GOOD - localStorage persistence with Stimulus**:

```html
<video data-controller="video-progress"
       data-video-progress-key-value="video-123"
       data-action="timeupdate->video-progress#save 
                    loadedmetadata->video-progress#restore">
  <source src="/video.mp4" type="video/mp4">
</video>
```

```javascript
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static values = { key: String };

  save() {
    localStorage.setItem(this.keyValue, this.element.currentTime);
  }

  restore() {
    const time = localStorage.getItem(this.keyValue);
    if (time) {
      this.element.currentTime = parseFloat(time);
    }
  }
}
```

See: `references/media-content/2024-10-29-stimulus-video-progress-tracker.md`

---

### Progressive Image Loading (Blurhash)

**When to use**: Show a blurred placeholder while high-resolution images load.

**GOOD - Decode blurhash and swap on load**:

```html
<div data-controller="blurhash"
     data-blurhash-hash-value="LEHV6nWB2yk8pyo0adR*.7kCMdnj">
  <canvas data-blurhash-target="canvas" width="32" height="32"></canvas>
  <img data-blurhash-target="image" 
       data-src="/high-res.jpg"
       data-action="load->blurhash#reveal"
       class="hidden">
</div>
```

```javascript
import { Controller } from '@hotwired/stimulus';
import { decode } from 'blurhash';

export default class extends Controller {
  static targets = ['canvas', 'image'];
  static values = { hash: String };

  connect() {
    // Decode and render blurhash to canvas
    const pixels = decode(this.hashValue, 32, 32);
    const ctx = this.canvasTarget.getContext('2d');
    const imageData = ctx.createImageData(32, 32);
    imageData.data.set(pixels);
    ctx.putImageData(imageData, 0, 0);
    
    // Start loading actual image
    this.imageTarget.src = this.imageTarget.dataset.src;
  }

  reveal() {
    this.canvasTarget.classList.add('hidden');
    this.imageTarget.classList.remove('hidden');
  }
}
```

See: `references/media-content/2024-04-23-stimulus-progressive-image-loading-blurhash.md`

---

### Third-Party Library Integration (Wavesurfer)

**When to use**: Wrap audio/video libraries that manage their own state.

**GOOD - Stimulus values as source of truth**:

```html
<div data-controller="waveform"
     data-waveform-markers-value="[]"
     data-waveform-url-value="/audio.mp3">
  <div data-waveform-target="container"></div>
  <button data-action="click->waveform#addMarker">Add Marker</button>
</div>
```

```javascript
import { Controller } from '@hotwired/stimulus';
import WaveSurfer from 'wavesurfer.js';

export default class extends Controller {
  static targets = ['container'];
  static values = { url: String, markers: Array };

  connect() {
    this.wavesurfer = WaveSurfer.create({
      container: this.containerTarget,
      url: this.urlValue
    });
  }

  disconnect() {
    this.wavesurfer.destroy();
  }

  addMarker() {
    const time = this.wavesurfer.getCurrentTime();
    this.markersValue = [...this.markersValue, { time }];
  }

  markersValueChanged() {
    // Sync markers to wavesurfer
    this.wavesurfer.clearMarkers();
    this.markersValue.forEach(m => this.wavesurfer.addMarker(m));
  }
}
```

**Key insight**: Use Stimulus value changed callbacks to keep third-party library state in sync.

See: `references/media-content/2024-07-02-stimulus-wavesurfer-add-markers.md`

---

### Time-Sensitive Content (Scrolling Lyrics)

**When to use**: Update content based on media playback position.

**GOOD - Turbo Frame src updates based on video timecode**:

```html
<video data-controller="lyric-sync"
       data-action="timeupdate->lyric-sync#update">
  <source src="/video.mp4" type="video/mp4">
</video>

<turbo-frame id="lyrics" data-lyric-sync-target="frame">
  <!-- Current lyrics loaded here -->
</turbo-frame>
```

```javascript
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['frame'];

  update() {
    const time = Math.floor(this.element.currentTime);
    const currentSrc = this.frameTarget.src;
    const newSrc = `/lyrics?time=${time}`;
    
    if (currentSrc !== newSrc) {
      this.frameTarget.src = newSrc;
    }
  }
}
```

See: `references/media-content/2024-04-09-turbo-frames-scrolling-lyrics.md`

---

## Useful Web APIs for Media

| API | Purpose | Browser Support |
|-----|---------|-----------------|
| `URL.createObjectURL()` | Create blob URLs for file previews | All browsers |
| `Picture-in-Picture` | Floating video windows | Not Firefox |
| `IntersectionObserver` | Detect when elements enter/leave viewport | All browsers |
| `MediaSession` | Control media from OS/browser UI | Most browsers |

## Full Article References

- [Stimulus - Image Upload Previews](references/media-content/2024-09-17-stimulus-image-upload-previews.md)
- [Stimulus - Picture in Picture](references/media-content/2024-06-04-stimulus-picture-in-picture.md)
- [Stimulus - Video Progress Tracker](references/media-content/2024-10-29-stimulus-video-progress-tracker.md)
- [Stimulus - Progressive Image Loading](references/media-content/2024-04-23-stimulus-progressive-image-loading-blurhash.md)
- [Stimulus - Wavesurfer Add Markers](references/media-content/2024-07-02-stimulus-wavesurfer-add-markers.md)
- [Stimulus - Wavesurfer Remove Markers](references/media-content/2024-07-30-stimulus-wavesurfer-remove-markers.md)
- [Turbo Frames - Scrolling Lyrics](references/media-content/2024-04-09-turbo-frames-scrolling-lyrics.md)
- [Turbo Frames - Swiper Autoplay](references/media-content/2025-01-14-turbo-frames-swiper-autoplay.md)
