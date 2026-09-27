import { describe, expect, it } from "vitest"

import { handleSfuRequest, type SfuEnv } from "./server"

describe("VPS offline / simulated SFU mode", () => {
  const env: SfuEnv = {
    SFU_ROOM: {
      idFromName: (name: string) => ({ toString: () => name } as never),
      get: () =>
        ({
          fetch: async () =>
            Response.json({ ok: true, expiresAt: Date.now() + 3600000 }),
        } as never),
    } as never,
    ROOMS_KV: {
      get: async () => null,
      put: async () => undefined,
    } as never,
    SFU_MOCK_ENABLED: "true",
    TURNSTILE_DISABLED: "true",
    ALLOW_ANY_ORIGIN: "true",
  }

  it("creates a simulated human session when SFU_MOCK_ENABLED is true without credentials", async () => {
    const res = await handleSfuRequest(
      new Request("https://my-vps.example.com/api/sfu/session", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Origin: "https://my-vps.example.com",
        },
        body: JSON.stringify({
          room: "vps-test-room",
          name: "Alice",
        }),
      }),
      env
    )
    expect(res.status).toBe(200)
    const data = (await res.json()) as {
      sessionId?: string
      participantId?: string
    }
    expect(data.sessionId).toBeDefined()
    expect(data.participantId).toBeDefined()
  })

  it("handles simulated datachannels/establish in mock mode", async () => {
    const res = await handleSfuRequest(
      new Request("https://my-vps.example.com/api/sfu/datachannels/establish", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Origin: "https://my-vps.example.com",
        },
        body: JSON.stringify({
          room: "vps-test-room",
          participantId: "p1",
          token: "tok1",
          sessionId: "sess1",
          dataChannel: {
            location: "remote",
            dataChannelName: "server-events",
          },
        }),
      }),
      env
    )
    expect(res.status).toBe(200)
  })

  it("handles simulated datachannels/new in mock mode", async () => {
    const res = await handleSfuRequest(
      new Request("https://my-vps.example.com/api/sfu/datachannels/new", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Origin: "https://my-vps.example.com",
        },
        body: JSON.stringify({
          room: "vps-test-room",
          participantId: "p1",
          token: "tok1",
          sessionId: "sess1",
          dataChannels: [
            { dataChannelName: "files" },
            { dataChannelName: "app-state" },
          ],
        }),
      }),
      env
    )
    expect(res.status).toBe(200)
    const data = (await res.json()) as { dataChannels: Array<{ id: number }> }
    expect(data.dataChannels).toHaveLength(2)
  })
})
