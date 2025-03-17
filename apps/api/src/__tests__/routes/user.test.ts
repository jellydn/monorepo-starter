import supertest from "supertest";
import { describe, expect, it, vi, beforeEach } from "vitest";
import { createServer } from "../../server";
import { auth } from "@repo/auth";
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

describe("User Routes", () => {
	const app = supertest(createServer());
	const mockUser = {
		id: "user_123",
		email: "test@example.com",
		name: "Test User",
		emailVerified: true,
		createdAt: new Date("2024-01-01"),
		updatedAt: new Date("2024-01-01"),
		image: "https://example.com/avatar.jpg"
	};

	const mockSession = {
		id: "session_123",
		createdAt: new Date("2024-01-01"),
		updatedAt: new Date("2024-01-01"),
		userId: mockUser.id,
		expiresAt: new Date("2024-12-31"),
		token: "valid-token"
	};

	beforeEach(() => {
		vi.clearAllMocks();
	});

	describe("GET /api/me", () => {
		it("should return 401 when no session exists", async () => {
			vi.mocked(auth.api.getSession).mockResolvedValueOnce(null);

			const response = await app
				.get("/api/me")
				.set("Authorization", "Bearer invalid-token");

			expect(response.status).toBe(401);
			expect(response.body).toEqual({ error: "Unauthorized" });
			expect(response.type).toBe("application/json");
		});

		it("should return 200 and user data when session exists", async () => {
			vi.mocked(auth.api.getSession).mockResolvedValueOnce({
				session: mockSession,
				user: mockUser
			});

			const response = await app
				.get("/api/me")
				.set("Authorization", "Bearer valid-token");

			expect(response.status).toBe(200);
			expect(response.type).toBe("application/json");
			expect(response.body).toEqual({
				user: {
					...mockUser,
					createdAt: mockUser.createdAt.toISOString(),
					updatedAt: mockUser.updatedAt.toISOString()
				}
			});
		});

		it("should handle server errors gracefully", async () => {
			vi.mocked(auth.api.getSession).mockRejectedValueOnce(
				new Error("Auth service error")
			);

			const response = await app
				.get("/api/me")
				.set("Authorization", "Bearer test-token");

			expect(response.status).toBe(500);
			expect(response.type).toBe("application/json");
			expect(response.body).toEqual({ error: "Internal Server Error" });
		});

		it("should handle malformed authorization header", async () => {
			const response = await app
				.get("/api/me")
				.set("Authorization", "malformed-token");

			expect(response.status).toBe(401);
			expect(response.type).toBe("application/json");
			expect(response.body).toEqual({ error: "Unauthorized" });
		});
	});
});