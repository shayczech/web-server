function handler(event) {
  var request = event.request;
  var uri = request.uri;

  // Legacy bookmark redirect — must run before the generic .html-strip rule
  // below, otherwise /p/kitchen.html would redirect to /p/kitchen instead of
  // straight to /p/recipes.
  if (uri === '/p/kitchen' || uri === '/p/kitchen.html') {
    return {
      statusCode: 301,
      statusDescription: 'Moved Permanently',
      headers: { location: { value: '/p/recipes' } },
    };
  }

  // Strip a trailing .html and redirect to the clean URL.
  if (uri.length > 5 && uri.slice(-5) === '.html') {
    var stripped = uri.slice(0, -5);
    return {
      statusCode: 301,
      statusDescription: 'Moved Permanently',
      headers: { location: { value: stripped === '' ? '/' : stripped } },
    };
  }

  // Clean-URL rewrite for the origin fetch (deterministic — no
  // existence-check is available at the edge, unlike nginx's try_files).
  if (uri.slice(-1) === '/') {
    request.uri = uri + 'index.html';
  } else {
    var lastSegment = uri.slice(uri.lastIndexOf('/') + 1);
    if (lastSegment.indexOf('.') === -1) {
      request.uri = uri + '.html';
    }
  }

  return request;
}
