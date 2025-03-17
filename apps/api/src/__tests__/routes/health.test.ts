import supertest from "supertest";
import { describe, expect, it } from "vitest";
import { createServer } from "../../server";

describe("Health Routes", () => {
	const app = supertest(createServer());

	describe("GET /api/health", () => {
		it("should return 200 and health status", async () => {
			const response = await app.get("/api/health");

			expect(response.status).toBe(200);
			expect(response.body).toEqual({ ok: true });
		});
	});
});
