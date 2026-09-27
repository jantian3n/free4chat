const DEFAULT_ALLOWED_ORIGINS = new Set([
  "https://free4.chat",
  "https://www.free4.chat",
  "http://localhost:3000",
])

export interface OriginEnv {
  ALLOWED_ORIGINS?: string
  APP_ORIGIN?: string
  ALLOW_ANY_ORIGIN?: string
  NEXT_PUBLIC_APP_URL?: string
}

export function isAllowedOrigin(
  origin: string | null,
  env?: OriginEnv
): boolean {
  if (origin === null) return false
  if (DEFAULT_ALLOWED_ORIGINS.has(origin)) return true

  const allowAny =
    env?.ALLOW_ANY_ORIGIN === "true" ||
    env?.ALLOW_ANY_ORIGIN === "1" ||
    (typeof process !== "undefined" &&
      (process.env.ALLOW_ANY_ORIGIN === "true" ||
        process.env.ALLOW_ANY_ORIGIN === "1"))
  if (allowAny) return true

  const configured =
    env?.ALLOWED_ORIGINS ||
    env?.APP_ORIGIN ||
    env?.NEXT_PUBLIC_APP_URL ||
    (typeof process !== "undefined"
      ? process.env.ALLOWED_ORIGINS ||
        process.env.APP_ORIGIN ||
        process.env.CUSTOM_ORIGIN ||
        process.env.NEXT_PUBLIC_APP_URL ||
        process.env.APP_URL
      : "")

  if (configured) {
    const list = configured
      .split(",")
      .map((s) => s.trim())
      .filter(Boolean)
    for (const item of list) {
      if (item === origin) return true
      try {
        const u = new URL(item.startsWith("http") ? item : `http://${item}`)
        if (u.origin === origin) return true
      } catch {
        // ignore
      }
    }
  }

  // Also accept local development loopback origins on any port
  try {
    const parsed = new URL(origin)
    if (
      parsed.hostname === "localhost" ||
      parsed.hostname === "127.0.0.1" ||
      parsed.hostname === "[::1]"
    ) {
      return true
    }
  } catch {
    // ignore
  }

  return false
}
