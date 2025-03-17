import { auth } from "./lib/auth";

export { auth };
// Export type for client usage
export type AuthClient = typeof auth;

