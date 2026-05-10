# Performance Profiling Checklist

Run through this checklist before any release. Use Flutter DevTools > Performance view.

## Cold Start
- [ ] App launches to splash in < 2s on mid-range device
- [ ] Bootstrap API call completes in < 3s on 4G
- [ ] Router redirect chain resolves in < 500ms

## Discover Feed
- [ ] First page of listings renders in < 1s after API response
- [ ] Scrolling through 50+ cards maintains 60fps (check DevTools frame graph)
- [ ] No jank when images load during scroll
- [ ] Filter chip changes do not rebuild entire feed

## Swipe Deck
- [ ] Card gestures are responsive (no frame drops)
- [ ] Card rotation animation is smooth at 60fps
- [ ] Match celebration completes in < 600ms
- [ ] Loading next batch of cards shows no delay

## Chat Thread
- [ ] Scrolling through 100+ messages maintains 60fps
- [ ] Sending a message feels instant (optimistic update)
- [ ] Image loading in chat does not block scroll
- [ ] Polling does not cause visible rebuilds

## Map View
- [ ] Map renders with 50+ markers without jank
- [ ] Marker tap shows info window in < 200ms
- [ ] Filter changes do not reload map tiles unnecessarily
- [ ] RepaintBoundary isolates map from other widgets

## Listing Creation
- [ ] Image upload shows progress feedback
- [ ] Multi-image upload does not freeze UI
- [ ] Form validation is instant per field
- [ ] Submit completes with visual feedback in < 3s

## Share Card
- [ ] Share card image generation does not cause jank
- [ ] Generated image is < 500KB
- [ ] Share sheet opens in < 500ms after tap

## Route Transitions
- [ ] All route transitions complete in < 300ms
- [ ] No frame drops during page transitions
- [ ] Tab switching is instant (< 200ms)

## Memory
- [ ] App uses < 200MB after 10 minutes of use
- [ ] No memory leaks after navigating discover -> listing -> chat -> profile -> back
- [ ] Image cache is bounded (check CachedNetworkImage stats)
- [ ] No dangling subscriptions after page dispose

## Testing With
- Device: Pixel 6a or equivalent mid-range Android
- iOS: iPhone SE (3rd gen) or equivalent
- Network: 4G throttled (Dio connectTimeout: 30s)
- DevTools: Performance > Flutter Frames, CPU Profiler, Memory
