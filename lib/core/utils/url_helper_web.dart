import 'dart:html' as html;

/// Web-specific implementation of URL helper to clear fragments/hashes
void clearUrlPath() {
  try {
    // Clear the hash/fragment from the URL so refreshing doesn't re-trigger the recovery flow
    html.window.history.replaceState(
      null, 
      '', 
      html.window.location.pathname
    );
  } catch (e) {
    // Fail silently or log error
  }
}
