// --- PRODUCTION CONFIGURATION ---
// Set SERVER_IP to your server's IP/domain for remote deployment.
// Leave empty ('') to auto-detect from the browser URL (for local dev on port 8000).
const SERVER_IP: string = '';      // e.g. '3.108.201.222' or 'example.com'
const SERVER_PORT: string = '';    // e.g. '8000' (leave empty to auto-detect)
const PROTOCOL: string = 'http';   // 'http' or 'https'

// Logic to determine the API URL
let baseUrlStr = document.baseURI;
if (SERVER_IP && SERVER_IP.length > 0) {
    const portPart = SERVER_PORT ? `:${SERVER_PORT}` : '';
    baseUrlStr = `${PROTOCOL}://${SERVER_IP}${portPart}/`;
}

const base_url = new URL(baseUrlStr);

export const environment = {
  production: true,
  apiBaseUrl: base_url.href + 'api/',
  apiVersion: '9', // match src/paperless/settings.py
  appTitle: 'Newel-Docs',
  tag: 'prod',
  version: '2.20.3',
  webSocketHost: base_url.host,
  webSocketProtocol: base_url.protocol === 'https:' ? 'wss:' : 'ws:',
  webSocketBaseUrl: base_url.pathname + 'ws/',
}
