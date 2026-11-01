import "server-only";

import { cache } from "react";
import { isSelfHosted } from "@/lib/constants";
import { deriveInstancePolicy } from "./utils";

/**
 * Instance policy for the current request. Callable from any server
 * context (tRPC, API routes, emails, other features' data.ts); pages read
 * it through `loadInstancePolicy`.
 */
export const getInstancePolicy = cache(async () => {
  return deriveInstancePolicy({
    isSelfHosted,
    whiteLabelAddon: false,
  });
});
