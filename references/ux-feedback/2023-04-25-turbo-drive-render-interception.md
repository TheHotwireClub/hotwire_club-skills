---
title: Turbo Drive - Render Interception
date: 2023-04-25
categories:
- Turbo Drive
tags:
- Rendering
- "turbo:before-render"
- Animations
- Events
- Caching
- Page Transitions
description: Spice up Turbo Drive transitions using rendering interception.
free: true
ready: true
---

## Overview

Turbo Drive intercepts regular link clicks and swaps out the HTML `<body>` without doing a full reload of all the JavaScript and CSS. This is called an Application Visit.

After fetching the new content, but before actually rendering, the `turbo:before-render` event is called. This event allows you to pause rendering and perform custom actions such as animations or page transitions. The event's detail property contains a `resume` method that must be called once you are done.

## Implementation

The `turbo:before-render` event handler can be used to add custom animations or perform asynchronous operations before rendering the new page. Call `event.preventDefault()` to pause rendering, then call `event.detail.resume()` when ready to continue.

Example implementation with a custom fly-out animation:

```js
document.addEventListener('turbo:before-render', async (event) => {
  event.preventDefault();

  if (!document.documentElement.hasAttribute('data-turbo-preview')) {
    document.querySelectorAll('svg').forEach((element, index) => {
      element.classList.add('fly-out');
      element.style.animationDelay = `${index * 100}ms`;
    });

    setTimeout(() => {
      event.detail.resume();
    }, 1000);
  } else {
    event.detail.resume();
  }
});
```

## Caveats

Beware of restoration visits. When HTML is loaded from the cache, the `turbo:before-render` event still fires, which can cause animations to run on cached page loads. Check for `<html data-turbo-preview>` attribute or opt out of caching altogether to avoid this issue.
