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

// Cache negative responses briefly to reduce repetitive origin hits.
const NEGATIVE_CACHE_TTL_SECONDS = 60;

// Reuse imported HMAC keys across requests in the same isolate.
const HMAC_KEY_CACHE = new Map();

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
// - AZ_ORIGIN_TIMEOUT_MS: Origin fetch timeout in ms (default 10000)
// - AZ_BAD_REQUEST_HTML: Custom HTML page for 400 responses
// - AZ_FORBIDDEN_HTML: Custom HTML page for 403 responses
// - AZ_MISSING_CONFIG_HTML: Custom HTML page for missing configuration
// - AZ_ORIGIN_FALLBACK_HTML: Custom HTML page for origin errors without status text
// - AZ_INTERNAL_ERROR_HTML: Custom HTML page for 500 responses

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
      return badRequestResponse(request, env);
    }

    const container = pathParts[0];
    const blobPath = pathParts.slice(1).join('/');

    // Security check 1: Explicitly block forbidden container patterns
    for (const pattern of BLOCKED_PATTERNS) {
      if (pattern.test(container)) {
        console.error(`Blocked access attempt to forbidden container: ${container}`);
        return forbiddenResponse(request, env);
      }
    }

    // Security check 2: Whitelist validation (only explicitly allowed containers)
    if (!ALLOWED_CONTAINERS.includes(container)) {
      console.warn(`Access denied to non-whitelisted container: ${container}`);
      return forbiddenResponse(request, env);
    }

    // Get environment variables
    const storageAccount = env.AZ_STORAGE_ACCOUNT;
    const storageKeyB64 = env.AZ_STORAGE_ACCOUNT_KEY;
    const sasTtl = parseInt(env.AZ_SAS_TTL_SECONDS || '120', 10);
    const edgeTtl = parseInt(env.AZ_EDGE_TTL_SECONDS || '86400', 10);
    const browserTtl = parseInt(env.AZ_BROWSER_TTL_SECONDS || '3600', 10);
    const originTimeoutMs = parseInt(env.AZ_ORIGIN_TIMEOUT_MS || '10000', 10);

    if (!storageAccount || !storageKeyB64) {
      return missingConfigResponse(request, env);
    }

    // Create cache key URL (without query string - important!)
    // This ensures the same blob is cached regardless of SAS token variation
    const cacheKeyUrl = new URL(request.url);
    cacheKeyUrl.search = ''; // Remove any query string from incoming request
    const cacheKey = new Request(cacheKeyUrl.toString(), {
      method: 'GET'
    });

    // Try to get from Cloudflare cache first
    const cache = caches.default;
    let response = await cache.match(cacheKey);

    if (response) {
      // Cache HIT - return cached response with indicator
      const cachedHeaders = new Headers(response.headers);
      cachedHeaders.set('X-Cache-Status', 'HIT');

      // HEAD responses must not include a body.
      const responseBody = request.method === 'HEAD' ? null : response.body;
      return new Response(responseBody, {
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
      const encodedBlobPath = blobPath
        .split('/')
        .map(segment => encodeURIComponent(segment))
        .join('/');
      const originUrl = `https://${storageAccount}.blob.core.windows.net/${container}/${encodedBlobPath}?${sasToken}`;

      // Forward only relevant request headers.
      const forwardedHeaders = new Headers();
      const passthroughHeaders = [
        'Accept',
        'Range',
        'If-Range',
        'If-Modified-Since',
        'If-Unmodified-Since',
        'If-Match',
        'If-None-Match'
      ];
      for (const headerName of passthroughHeaders) {
        const headerValue = request.headers.get(headerName);
        if (headerValue) {
          forwardedHeaders.set(headerName, headerValue);
        }
      }

      const abortController = new AbortController();
      const timeoutId = setTimeout(() => abortController.abort(), originTimeoutMs);

      // Fetch from Azure Blob Storage
      let originResponse;
      try {
        originResponse = await fetch(originUrl, {
          method: request.method,
          headers: forwardedHeaders,
          signal: abortController.signal
        });
      } finally {
        clearTimeout(timeoutId);
      }

      if (!originResponse.ok) {
        const isCacheableNegative = originResponse.status === 403 || originResponse.status === 404;
        const negativeHeaders = {
          'Cache-Control': `public, max-age=${NEGATIVE_CACHE_TTL_SECONDS}, s-maxage=${NEGATIVE_CACHE_TTL_SECONDS}`,
          'X-Cache-Status': 'MISS'
        };
        const negativeResponse = originResponse.statusText
          ? new Response(originResponse.statusText, {
              status: originResponse.status,
              headers: negativeHeaders
            })
          : htmlResponse(
              request,
              originResponse.status,
              env.AZ_ORIGIN_FALLBACK_HTML,
              defaultOriginFallbackHtml(),
              negativeHeaders
            );

        // Cache only GET negative responses to reduce repeated origin calls.
        if (isCacheableNegative && request.method === 'GET') {
          ctx.waitUntil(cache.put(cacheKey, negativeResponse.clone()));
        }

        // HEAD responses must not include a body.
        if (request.method === 'HEAD') {
          return new Response(null, {
            status: negativeResponse.status,
            statusText: negativeResponse.statusText,
            headers: negativeResponse.headers
          });
        }

        return negativeResponse;
      }

      // Build cacheable response with proper headers
      const responseHeaders = new Headers();
      
      // Copy content-related headers from origin
      const contentType = originResponse.headers.get('Content-Type');
      const contentEncoding = originResponse.headers.get('Content-Encoding');
      const contentDisposition = originResponse.headers.get('Content-Disposition');
      const contentRange = originResponse.headers.get('Content-Range');
      const contentLength = originResponse.headers.get('Content-Length');
      const acceptRanges = originResponse.headers.get('Accept-Ranges');
      const etag = originResponse.headers.get('ETag');
      const lastModified = originResponse.headers.get('Last-Modified');
      
      if (contentType) responseHeaders.set('Content-Type', contentType);
      if (contentEncoding) responseHeaders.set('Content-Encoding', contentEncoding);
      if (contentDisposition) responseHeaders.set('Content-Disposition', contentDisposition);
      if (contentRange) responseHeaders.set('Content-Range', contentRange);
      if (contentLength) responseHeaders.set('Content-Length', contentLength);
      if (acceptRanges) responseHeaders.set('Accept-Ranges', acceptRanges);
      if (etag) responseHeaders.set('ETag', etag);
      if (lastModified) responseHeaders.set('Last-Modified', lastModified);
      
      // Set cache control headers
      responseHeaders.set('Cache-Control', `public, max-age=${browserTtl}, s-maxage=${edgeTtl}`);
      responseHeaders.set('X-Cache-Status', 'MISS');
      
      // Create response preserving stream to avoid buffering large blobs in memory.
      const responseBody = request.method === 'HEAD' ? null : originResponse.body;
      response = new Response(responseBody, {
        status: originResponse.status,
        statusText: originResponse.statusText,
        headers: responseHeaders
      });

      // Store in cache (non-blocking)
      // Clone the response because the body can only be read once
      if (request.method === 'GET') {
        ctx.waitUntil(cache.put(cacheKey, response.clone()));
      }

      return response;

    } catch (error) {
      console.error('Worker fetch error:', error);
      return internalErrorResponse(request, env);
    }
  }
};

/**
 * Generate Azure Blob Storage SAS token (Service SAS for blob)
 */
async function generateBlobSAS(accountName, accountKeyB64, container, blobPath, ttlSeconds) {
  const now = new Date();
  const start = new Date(now.getTime() - 2 * 60 * 1000);
  const expiry = new Date(now.getTime() + ttlSeconds * 1000);

  // Format dates for Azure SAS
  const st = start.toISOString().slice(0, 19) + 'Z';
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
  const cryptoKey = await getOrCreateHmacKey(accountKeyB64);

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
 * Reuse imported HMAC key inside the current isolate.
 */
async function getOrCreateHmacKey(accountKeyB64) {
  if (HMAC_KEY_CACHE.has(accountKeyB64)) {
    return HMAC_KEY_CACHE.get(accountKeyB64);
  }

  const key = base64ToArrayBuffer(accountKeyB64);
  const cryptoKey = await crypto.subtle.importKey(
    'raw',
    key,
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );

  HMAC_KEY_CACHE.set(accountKeyB64, cryptoKey);
  return cryptoKey;
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

/**
 * Return branded 400 HTML page.
 */
function badRequestResponse(request, env) {
  return htmlResponse(
    request,
    400,
    env.AZ_BAD_REQUEST_HTML,
    '<!doctype html><html lang="en"><head><meta charset="utf-8"><title>Bad Request</title></head><body><h1>400 Bad Request</h1></body></html>',
    { 'Cache-Control': 'no-store' }
  );
}

/**
 * Return branded 403 HTML page.
 */
function forbiddenResponse(request, env) {
  return htmlResponse(
    request,
    403,
    env.AZ_FORBIDDEN_HTML,
    '<!doctype html><html lang="en"><head><meta charset="utf-8"><title>Forbidden</title></head><body><h1>403 Forbidden</h1></body></html>',
    { 'Cache-Control': 'no-store' }
  );
}

/**
 * Return branded 500 page when worker configuration is missing.
 */
function missingConfigResponse(request, env) {
  return htmlResponse(
    request,
    500,
    env.AZ_MISSING_CONFIG_HTML,
    '<!doctype html><html lang="en"><head><meta charset="utf-8"><title>Service Misconfigured</title></head><body><h1>500 Service Misconfigured</h1></body></html>',
    { 'Cache-Control': 'no-store' }
  );
}

/**
 * Return branded generic 500 page.
 */
function internalErrorResponse(request, env) {
  return htmlResponse(
    request,
    500,
    env.AZ_INTERNAL_ERROR_HTML,
    '<!doctype html><html lang="en"><head><meta charset="utf-8"><title>Internal Server Error</title></head><body><h1>500 Internal Server Error</h1></body></html>',
    { 'Cache-Control': 'no-store' }
  );
}

/**
 * Build an HTML response honoring HEAD semantics.
 */
function htmlResponse(request, status, html, fallbackHtml, headers = {}) {
  const responseHeaders = {
    'Content-Type': 'text/html; charset=utf-8',
    ...headers
  };
  const responseBody = request.method === 'HEAD' ? null : (html || fallbackHtml);

  return new Response(responseBody, {
    status,
    headers: responseHeaders
  });
}

function defaultOriginFallbackHtml() {
  return '<!doctype html><html lang="en"><head><meta charset="utf-8"><title>Resource Unavailable</title></head><body><h1>Resource Unavailable</h1></body></html>';
}
