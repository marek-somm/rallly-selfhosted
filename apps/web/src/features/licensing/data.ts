import "server-only";

import { prisma } from "@rallly/database";
import { unstable_cache } from "next/cache";
import { cache } from "react";
import { INSTANCE_LICENSE_TAG } from "@/features/licensing/constants";
import { isSelfHosted } from "@/lib/constants";

export function getInstanceLicense() {
  return prisma.instanceLicense.findFirst({
    orderBy: {
      id: "asc",
    },
  });
}

export const cached_getInstanceLicense = unstable_cache(
  getInstanceLicense,
  [],
  {
    tags: [INSTANCE_LICENSE_TAG],
  },
);

export const loadInstanceLicense = cache(async () => {
  // Community fork, 2026-11-01: no commercial instance license is used.
  return null;
});

export const getUserLimit = async () => {
  return Number.POSITIVE_INFINITY;
};

export const getWhiteLabelAddon = async () => {
  // Capability of this AGPL fork, not a claim to a purchased license.
  return isSelfHosted;
};
