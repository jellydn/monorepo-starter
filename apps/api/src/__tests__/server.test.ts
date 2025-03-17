import supertest from "supertest";
import { describe, expect, it } from "vitest";
import { createServer } from "../server";

describe("Server Integration", () => {
	const app = supertest(createServer());

	it("should have CORS enabled", async () => {
		const response = await app.get("/api/health");
		expect(response.headers["access-control-allow-origin"]).toBe("*");
	});

	it("should have x-powered-by disabled", async () => {
		const response = await app.get("/api/health");
		expect(response.headers["x-powered-by"]).toBeUndefined();
	});

	describe("API Prefix", () => {
		it("should return 404 with JSON for non-existent endpoints", async () => {
			const response = await app
				.get("/api/non-existent")
				.set("Accept", "application/json");

			expect(response.status).toBe(404);
			expect(response.type).toBe("application/json");
			expect(response.body).toEqual({ error: "Not Found" });
		});

		it("should return 404 with JSON for endpoints without /api prefix", async () => {
			const response = await app
				.get("/health")
				.set("Accept", "application/json");

			expect(response.status).toBe(404);
			expect(response.type).toBe("application/json");
			expect(response.body).toEqual({ error: "Not Found" });
		});
	});
});
