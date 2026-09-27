import "@testing-library/jest-dom/vitest"

if (typeof window !== "undefined") {
  class MockStorage implements Storage {
    [name: string]: any
    getItem(key: string): string | null {
      return Object.prototype.hasOwnProperty.call(this, key) ? this[key] : null
    }
    setItem(key: string, value: string): void {
      this[key] = String(value)
    }
    removeItem(key: string): void {
      delete this[key]
    }
    clear(): void {
      for (const key of Object.keys(this)) {
        delete this[key]
      }
    }
    key(index: number): string | null {
      return Object.keys(this)[index] ?? null
    }
    get length(): number {
      return Object.keys(this).length
    }
  }

  if (!window.localStorage) {
    Object.defineProperty(window, "localStorage", {
      value: new MockStorage(),
      writable: true,
      configurable: true,
    })
  }
  if (!window.sessionStorage) {
    Object.defineProperty(window, "sessionStorage", {
      value: new MockStorage(),
      writable: true,
      configurable: true,
    })
  }
}

