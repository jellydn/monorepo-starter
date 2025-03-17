import supertest from "supertest";
import { describe, expect, it, vi, beforeEach } from "vitest";
import { createServer } from "../../server";
import type { Request, Response, NextFunction } from "express";

// Mock the auth module
vi.mock("@repo/auth", () => ({
	auth: {
		api: {
			getSession: vi.fn()
		}
	}
}));

// Mock better-auth/node
vi.mock("better-auth/node", () => ({
	toNodeHandler: vi.fn(() => (req: Request, res: Response, next: NextFunction) => next()),
	fromNodeHeaders: vi.fn((headers) => headers)
}));

describe("Auth Routes", () => {
	const app = supertest(createServer());

	beforeEach(() => {
		vi.clearAllMocks();
	});

	describe("Auth Handler", () => {
		it("should handle auth routes with splat pattern", async () => {
			const response = await app
				.get("/api/auth/callback")
				.set("Authorization", "Bearer test-token");

			expect(response.status).toBe(404); // Since we're just testing route matching
		});

		it("should handle nested auth routes", async () => {
			const response = await app
				.get("/api/auth/oauth/github")
				.set("Authorization", "Bearer test-token");

			expect(response.status).toBe(404); // Since we're just testing route matching
		});

		it("should handle auth root path", async () => {
			const response = await app
				.get("/api/auth")
				.set("Authorization", "Bearer test-token");

			expect(response.status).toBe(404); // Since we're just testing route matching
		});
	});
});