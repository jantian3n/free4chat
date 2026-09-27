import { describe, expect, it } from "vitest"
import { isAllowedOrigin } from "./origin"

describe("isAllowedOrigin", () => {
  it("accepts default production and local origins", () => {
    expect(isAllowedOrigin("https://free4.chat")).toBe(true)
    expect(isAllowedOrigin("https://www.free4.chat")).toBe(true)
    expect(isAllowedOrigin("http://localhost:3000")).toBe(true)
  })

  it("rejects null origin", () => {
    expect(isAllowedOrigin(null)).toBe(false)
  })

  it("rejects random untrusted origins by default", () => {
    expect(isAllowedOrigin("https://evil.com")).toBe(false)
    expect(isAllowedOrigin("https://attacker.example")).toBe(false)
  })

  it("accepts custom origins when configured via env object", () => {
    const env = {
      ALLOWED_ORIGINS: "https://my-vps.example.com, https://chat.internal:8443",
    }
    expect(isAllowedOrigin("https://my-vps.example.com", env)).toBe(true)
    expect(isAllowedOrigin("https://chat.internal:8443", env)).toBe(true)
    expect(isAllowedOrigin("https://evil.com", env)).toBe(false)
  })

  it("accepts any non-null origin when ALLOW_ANY_ORIGIN is true", () => {
    const env = { ALLOW_ANY_ORIGIN: "true" }
    expect(isAllowedOrigin("https://any-domain.com", env)).toBe(true)
    expect(isAllowedOrigin("http://192.168.1.100:3000", env)).toBe(true)
    expect(isAllowedOrigin(null, env)).toBe(false)
  })

  it("accepts local development loopback addresses on any port", () => {
    expect(isAllowedOrigin("http://localhost:3001")).toBe(true)
    expect(isAllowedOrigin("http://127.0.0.1:8080")).toBe(true)
    expect(isAllowedOrigin("http://[::1]:3000")).toBe(true)
  })
})
