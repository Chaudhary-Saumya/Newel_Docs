// This file can be replaced during build by using the `fileReplacements` array.
// `ng build --configuration production` replaces `environment.ts` with `environment.prod.ts`.
// The list of file replacements can be found in `angular.json`.

export const environment = {
  production: false,

  // MUST be relative so Angular proxy is used
  apiBaseUrl: '/api/',
  apiVersion: '9',

  appTitle: 'Newel-Docs Logo',
  tag: 'dev',
  version: 'DEVELOPMENT',

  // WebSocket MUST also go through proxy
  webSocketProtocol: 'ws:',
  webSocketHost: 'localhost:8000',
  webSocketBaseUrl: '/ws/',
};


/*
 * For easier debugging in development mode, you can import the following file
 * to ignore zone related error stack frames such as `zone.run`, `zoneDelegate.invokeTask`.
 *
 * This import should be commented out in production mode because it will have a negative impact
 * on performance if an error is thrown.
 */
// import 'zone.js/plugins/zone-error';  // Included with Angular CLI.
