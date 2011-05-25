/*

DESCRIPTION:
Intercept the request and determine if it's allowed to reach any further.

REASON:
SB route navigation is completely handled on the client

*/var app, no_intercept_list;
require.paths.unshift(process.cwd() + '/lib');
app = require('web');
app.createFrontend('interceptor', function(mw) {
  var dir, html;
  dir = mw.req.pathname.split('/')[1];
  if (-1 === no_intercept_list.indexOf(dir)) {
    html = app.render('marketing/homepage');
    return mw.res.html(html);
  }
  return mw.next();
});
no_intercept_list = ['api'];