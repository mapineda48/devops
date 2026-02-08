/**
 * Cloudflare Worker - SAS Gateway for Azure Blob Storage
 * 
 * This worker acts as a secure proxy to Azure Blob Storage.
 * It generates SAS tokens server-side and fetches blobs without exposing
 * the SAS token to the client. Responses are cached at Cloudflare edge
 * using the Cache API for explicit cache control.
 */

// Allowed containers (whitelist to prevent open proxy)
const ALLOWED_CONTAINERS = ['public'];

// Blocked container patterns (explicit deny - takes precedence over whitelist)
const BLOCKED_PATTERNS = [
  /^data-/i,     // Block all containers starting with 'data-' (private data containers)
  /^private/i,   // Block anything starting with 'private'
  /^\$/,         // Block special Azure containers like $logs, $web, etc.
];

// Environment variables (bound via Terraform):
// - AZ_STORAGE_ACCOUNT: Storage account name
// - AZ_STORAGE_ACCOUNT_KEY: Storage account key (base64)
// - AZ_SAS_TTL_SECONDS: SAS token TTL (default 120)
// - AZ_EDGE_TTL_SECONDS: Edge cache TTL (default 86400)
// - AZ_BROWSER_TTL_SECONDS: Browser cache TTL (default 3600)

export default {
  async fetch(request, env, ctx) {
    // Only allow GET and HEAD methods
    if (request.method !== 'GET' && request.method !== 'HEAD') {
      return new Response('Method Not Allowed', { status: 405 });
    }

    const url = new URL(request.url);
    const path = url.pathname;

    // Parse path: /<container>/<blobPath...>
    const pathParts = path.split('/').filter(p => p.length > 0);
    
    if (pathParts.length < 2) {
      return new Response('Bad Request: Path must be /<container>/<blob>', { status: 400 });
    }

    const container = pathParts[0];
    const blobPath = pathParts.slice(1).join('/');

    // Security check 1: Explicitly block forbidden container patterns
    for (const pattern of BLOCKED_PATTERNS) {
      if (pattern.test(container)) {
        console.error(`Blocked access attempt to forbidden container: ${container}`);
        return new Response('Forbidden', { status: 403 });
      }
    }

    // Security check 2: Whitelist validation (only explicitly allowed containers)
    if (!ALLOWED_CONTAINERS.includes(container)) {
      console.warn(`Access denied to non-whitelisted container: ${container}`);
      return new Response('Forbidden', { status: 403 });
    }

    // Get environment variables
    const storageAccount = env.AZ_STORAGE_ACCOUNT;
    const storageKeyB64 = env.AZ_STORAGE_ACCOUNT_KEY;
    const sasTtl = parseInt(env.AZ_SAS_TTL_SECONDS || '120', 10);
    const edgeTtl = parseInt(env.AZ_EDGE_TTL_SECONDS || '86400', 10);
    const browserTtl = parseInt(env.AZ_BROWSER_TTL_SECONDS || '3600', 10);

    if (!storageAccount || !storageKeyB64) {
      return new Response('Internal Server Error: Missing storage configuration', { status: 500 });
    }

    // Create cache key URL (without query string - important!)
    // This ensures the same blob is cached regardless of SAS token variation
    const cacheKeyUrl = new URL(request.url);
    cacheKeyUrl.search = ''; // Remove any query string from incoming request
    const cacheKey = new Request(cacheKeyUrl.toString(), {
      method: 'GET',
      headers: request.headers
    });

    // Try to get from Cloudflare cache first
    const cache = caches.default;
    let response = await cache.match(cacheKey);

    if (response) {
      // Cache HIT - return cached response with indicator
      const cachedHeaders = new Headers(response.headers);
      cachedHeaders.set('X-Cache-Status', 'HIT');
      return new Response(response.body, {
        status: response.status,
        statusText: response.statusText,
        headers: cachedHeaders
      });
    }

    // Cache MISS - fetch from origin
    try {
      // Generate SAS token
      const sasToken = await generateBlobSAS(
        storageAccount,
        storageKeyB64,
        container,
        blobPath,
        sasTtl
      );

      // Build origin URL with SAS
      const originUrl = `https://${storageAccount}.blob.core.windows.net/${container}/${blobPath}?${sasToken}`;

      // Fetch from Azure Blob Storage
      const originResponse = await fetch(originUrl, {
        method: request.method,
        headers: {
          'Accept': request.headers.get('Accept') || '*/*',
          'Accept-Encoding': request.headers.get('Accept-Encoding') || 'gzip, deflate, br'
        }
      });

      if (!originResponse.ok) {
        return new Response(originResponse.statusText, { status: originResponse.status });
      }

      // Read the body as ArrayBuffer first (streams can only be read once)
      const body = await originResponse.arrayBuffer();

      // Build cacheable response with proper headers
      const responseHeaders = new Headers();
      
      // Copy content-related headers from origin
      const contentType = originResponse.headers.get('Content-Type');
      const etag = originResponse.headers.get('ETag');
      const lastModified = originResponse.headers.get('Last-Modified');
      
      if (contentType) responseHeaders.set('Content-Type', contentType);
      if (etag) responseHeaders.set('ETag', etag);
      if (lastModified) responseHeaders.set('Last-Modified', lastModified);
      
      // Set cache control headers
      responseHeaders.set('Cache-Control', `public, max-age=${browserTtl}, s-maxage=${edgeTtl}`);
      responseHeaders.set('X-Cache-Status', 'MISS');
      
      // Create the response to cache (using ArrayBuffer, not stream)
      response = new Response(body, {
        status: originResponse.status,
        statusText: originResponse.statusText,
        headers: responseHeaders
      });

      // Store in cache (non-blocking)
      // Clone the response because the body can only be read once
      ctx.waitUntil(cache.put(cacheKey, response.clone()));

      return response;

    } catch (error) {
      return new Response(`Internal Server Error: ${error.message}`, { status: 500 });
    }
  }
};

/**
 * Generate Azure Blob Storage SAS token (Service SAS for blob)
 */
async function generateBlobSAS(accountName, accountKeyB64, container, blobPath, ttlSeconds) {
  const now = new Date();
  const expiry = new Date(now.getTime() + ttlSeconds * 1000);

  // Format dates for Azure SAS
  const st = now.toISOString().slice(0, 19) + 'Z';
  const se = expiry.toISOString().slice(0, 19) + 'Z';

  // SAS parameters
  const sp = 'r';           // Permissions: read
  const sv = '2022-11-02';  // API version
  const sr = 'b';           // Resource: blob
  const spr = 'https';      // Protocol: https only

  // Canonical resource
  const canonicalResource = `/blob/${accountName}/${container}/${blobPath}`;

  // String to sign (order matters!)
  const stringToSign = [
    sp,                    // signedPermissions
    st,                    // signedStart
    se,                    // signedExpiry
    canonicalResource,     // canonicalizedResource
    '',                    // signedIdentifier
    '',                    // signedIP
    spr,                   // signedProtocol
    sv,                    // signedVersion
    sr,                    // signedResource
    '',                    // signedSnapshotTime
    '',                    // signedEncryptionScope
    '',                    // rscc (Cache-Control)
    '',                    // rscd (Content-Disposition)
    '',                    // rsce (Content-Encoding)
    '',                    // rscl (Content-Language)
    ''                     // rsct (Content-Type)
  ].join('\n');

  // Sign with HMAC-SHA256
  const key = base64ToArrayBuffer(accountKeyB64);
  const cryptoKey = await crypto.subtle.importKey(
    'raw',
    key,
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );

  const encoder = new TextEncoder();
  const signature = await crypto.subtle.sign(
    'HMAC',
    cryptoKey,
    encoder.encode(stringToSign)
  );

  const sig = arrayBufferToBase64(signature);

  // Build SAS query string
  const params = new URLSearchParams({
    sp,
    st,
    se,
    spr,
    sv,
    sr,
    sig
  });

  return params.toString();
}

/**
 * Convert base64 string to ArrayBuffer
 */
function base64ToArrayBuffer(base64) {
  const binaryString = atob(base64);
  const bytes = new Uint8Array(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes.buffer;
}

/**
 * Convert ArrayBuffer to base64 string
 */
function arrayBufferToBase64(buffer) {
  const bytes = new Uint8Array(buffer);
  let binary = '';
  for (let i = 0; i < bytes.byteLength; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary);
}
