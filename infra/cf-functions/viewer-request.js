// The recipes page moved to danielsonhub.com in November 2026.
var HUB_RECIPES = 'https://danielsonhub.com/recipes';

// Path to append to HUB_RECIPES for an old recipes URL, or null if the URI is
// not a recipes URL. /p/kitchen is the older bookmark for the same page.
function hubRecipesSuffix(uri) {
  if (uri === '/p/recipes' || uri === '/p/recipes.html' ||
      uri === '/p/kitchen' || uri === '/p/kitchen.html') {
    return '';
  }
  if (uri === '/p/recipes.json') {
    return '/recipes.json';
  }
  if (uri.indexOf('/p/recipes/') === 0) {
    return uri.slice('/p/recipes'.length);
  }
  if (uri.indexOf('/p/photos/') === 0) {
    return uri.slice('/p'.length);
  }
  return null;
}

// Rebuilds the viewer's query string, values as received (same pattern as
// AWS's normalize-query-string example), with a leading '?' when not empty.
function queryString(querystring) {
  var parts = [];
  for (var key in querystring) {
    var param = querystring[key];
    if (param.multiValue) {
      param.multiValue.forEach(function (mv) {
        parts.push(key + '=' + mv.value);
      });
    } else {
      parts.push(key + '=' + param.value);
    }
  }
  return parts.length > 0 ? '?' + parts.join('&') : '';
}

function handler(event) {
  var request = event.request;
  var uri = request.uri;

  // Recipes redirect: must run before the generic .html-strip rule below,
  // otherwise /p/recipes.html would redirect to /p/recipes first.
  var suffix = hubRecipesSuffix(uri);
  if (suffix !== null) {
    return {
      statusCode: 301,
      statusDescription: 'Moved Permanently',
      headers: {
        location: { value: HUB_RECIPES + suffix + queryString(request.querystring) },
      },
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
