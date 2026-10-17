/// The time lockscreen previews draw; tests and headless previews replace it
/// so that images don't change with the wall clock.
DateTime Function() lockscreenNow = DateTime.now;
