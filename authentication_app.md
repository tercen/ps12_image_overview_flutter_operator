Problem Report for Tercen API Team
Summary
The createServiceFactoryForWebApp() function fails to authenticate when running a Flutter web app locally (localhost) with credentials stored in localStorage, despite the token and serviceUri being correctly set.

Environment
Client: Flutter web app running on localhost:XXXXX
API: stage.tercen.com
Token: Valid JWT stored in localStorage.getItem('tercen.token')
ServiceUri: https://stage.tercen.com stored in localStorage.getItem('tercen.serviceUri')
Token expiry: 2026-02-18 (confirmed still valid)
Observed Behavior
When calling createServiceFactoryForWebApp():

No network requests are made to stage.tercen.com (confirmed via browser Network tab)
Returns error: ServiceError({statusCode: 500, error: FileDocument.client.unknown, reason: TsonError(404, "unknown.typed.data", "Unknown typed data 60")})
Error occurs before any API calls, suggesting authentication initialization failure
Previously Working Scenario
The same code successfully loaded 528 TIFF files from Tercen when:

User had an active Tercen session open in another Chrome window/tab
Same Chrome profile was used (shared session/cookies)
Credentials were available from the shared browser context
Current Failing Scenario
Using Chrome with isolated profile (--user-data-dir):

localStorage credentials are set correctly (confirmed in DevTools)
No Tercen session context available
createServiceFactoryForWebApp() fails silently without making HTTP requests
Hypothesis
createServiceFactoryForWebApp() appears to require:

URL query parameters (e.g., ?taskId=xxx&token=yyy) that only exist when running inside Tercen's iframe, OR
Session cookies/context from an active Tercen browser session
The function does not fall back to reading from localStorage alone when these are missing, even though the token and serviceUri are correctly stored there.

Question for Tercen API Team
Is createServiceFactoryForWebApp() designed to work for local development with only localStorage credentials? If so, what additional configuration is needed? If not, is there an alternative factory method (e.g., createServiceFactoryWithToken()) that supports explicit token-based authentication for local testing?