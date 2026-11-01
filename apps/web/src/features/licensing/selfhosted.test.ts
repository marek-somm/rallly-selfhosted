import { beforeEach, describe, expect, it, vi } from "vitest";

const { licenseRead } = vi.hoisted(() => ({ licenseRead: vi.fn() }));
vi.mock("@rallly/database", () => ({
  prisma: { instanceLicense: { findFirst: licenseRead } },
}));
vi.mock("next/cache", () => ({ unstable_cache: (fn: unknown) => fn }));
vi.mock("@/lib/constants", () => ({ isSelfHosted: true }));
vi.mock("@/env", () => ({ env: {} }));
vi.mock("@rallly/billing", () => ({}));
vi.mock("@/features/billing/constants", () => ({ isBillingEnabled: false }));
vi.mock("@/features/billing/data", () => ({ getSpaceSubscription: vi.fn() }));
vi.mock("@/features/instance-policy/data", () => ({
  getInstancePolicy: vi.fn(),
}));
vi.mock("@/features/space/utils", () => ({
  createSpaceDTO: vi.fn(),
  fromDBRole: vi.fn(),
  isSpaceBrandingActive: vi.fn(),
}));

describe("community self-hosting", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    licenseRead.mockRejectedValue(
      new Error("Commercial licensing is unavailable"),
    );
  });

  it("keeps accounts, space membership and branding available without a licensing database or service", async () => {
    const { getUserLimit, getWhiteLabelAddon, loadInstanceLicense } =
      await import("./data");
    const { getTotalSeatsForSpace } = await import("../space/data");
    expect(await getUserLimit()).toBe(Number.POSITIVE_INFINITY);
    expect(await getTotalSeatsForSpace("community-space")).toBe(
      Number.POSITIVE_INFINITY,
    );
    expect(await getWhiteLabelAddon()).toBe(true);
    expect(await loadInstanceLicense()).toBeNull();
    expect(licenseRead).not.toHaveBeenCalled();
  });

  it("does not contact a commercial licensing server through a legacy activation action", async () => {
    const request = vi.spyOn(globalThis, "fetch");
    const { LicenseManager } = await import("./mutations");
    const manager = new LicenseManager({
      apiUrl: "https://licensing.example.invalid",
    });
    await expect(manager.validateLicenseKey({ key: "unused" })).rejects.toThrow(
      "disabled in this community fork",
    );
    expect(request).not.toHaveBeenCalled();
    request.mockRestore();
  });
});
