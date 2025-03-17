import { betterAuth } from "better-auth";
import { prismaAdapter } from "better-auth/adapters/prisma";
import { db } from "@repo/db";

export const auth = betterAuth({
	// Database configuration
	database: prismaAdapter(db, {
		provider: "postgresql"
	}),
	// Session configuration
	session: {
		expiresIn: 30 * 24 * 60 * 60, // 30 days
	},
	// User configuration
	user: {
		fields: {
			name: "name",
			email: "email",
			emailVerified: "emailVerified",
		},
	},
	// Security configuration
	security: {
		rateLimit: {
			enabled: true,
			maxAttempts: 5,
			windowMs: 15 * 60 * 1000, // 15 minutes
		},
	},
	// Email and password configuration
	emailAndPassword: {
		enabled: true,
		requireEmailVerification: true,
	},
});

// Export type for client usage
export type AuthClient = typeof auth;

// Export auth instance
export default auth;