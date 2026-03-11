// --- AWS PRODUCTION CONFIGURATION ---
// Enter your AWS Server IP/Domain and Port here
const SERVER_IP: string = '3.108.201.222';      // e.g. '3.14.15.92' or 'example.com'
const SERVER_PORT: string = '4200';    // e.g. '8000' (leave empty if using standard 80/443 with domain)
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
  appTitle: 'Newel Docs',
  tag: 'prod',
  version: '2.20.3',
  webSocketHost: base_url.host,
  webSocketProtocol: base_url.protocol === 'https:' ? 'wss:' : 'ws:',
  webSocketBaseUrl: base_url.pathname + 'ws/',
}
