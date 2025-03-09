<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

# Limited Extent Scroll View

---

### A scroll view that shrink wraps content until given height, after which point it starts to scroll.

--- 


https://github.com/user-attachments/assets/b3378fe3-ec16-4c10-8edc-cbc7cbaeb478


- Accepts whatever slivers a `CustomScrollView` would accept.
- Supports infinite scrolling.
- Supports both vertical and horizontal scrolling.
- Supports `SliverPersistentHeader`, `SliverFillRemaining`, etc.

---

### Example:

```dart
// If the total content height of this scroll view turns out 
// to be less than 350, the this will shrink wrap to children's size.
// If content height is greater than 350, the scroll view will scroll.
// Infinite children are supported.
LimitedExtentScrollView(
  maxExtent: 350,
  slivers: [
    SliverList(
      delegate: SliverChildBuilderDelegate((ctx, index) {
        return ListTile(title: Text('Item ${items[index]}'));
      }),
    ),
  ],
)
```
