import 'dart:html' as html;

class WebUtils {
  static void clearUrl() {
    try {
      html.window.history.replaceState(null, '', html.window.location.pathname);
    } catch (e) {
      // Ignore if called in non-browser context during testing
    }
  }
}
