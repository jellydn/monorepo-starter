import supertest from "supertest";
import { describe, expect, it } from "vitest";
import { createServer } from "../../server";

describe("Message Routes", () => {
	const app = supertest(createServer());

	describe("GET /api/message/:name", () => {
		it("should return hello message with the provided name", async () => {
			const testName = "john";
			const response = await app.get(`/api/message/${testName}`);

			expect(response.status).toBe(200);
			expect(response.body).toEqual({ message: `hello ${testName}` });
		});

		it("should handle special characters in name parameter", async () => {
			const testName = "john-doe_123";
			const response = await app.get(`/api/message/${testName}`);

			expect(response.status).toBe(200);
			expect(response.body).toEqual({ message: `hello ${testName}` });
		});

		it("should return 400 when name is empty", async () => {
			const response = await app.get("/api/message/%20");

			expect(response.status).toBe(400);
			expect(response.body).toEqual({ error: "Name is required" });
		});

		it("should return 400 when name is too long", async () => {
			const longName = "a".repeat(51);
			const response = await app.get(`/api/message/${longName}`);

			expect(response.status).toBe(400);
			expect(response.body).toEqual({
				error: "Name must be less than 50 characters",
			});
		});

		it("should return 400 when name contains invalid characters", async () => {
			const invalidName = "john@<script>";
			const response = await app.get(`/api/message/${invalidName}`);

			expect(response.status).toBe(400);
			expect(response.body).toEqual({
				error: "Name contains invalid characters",
			});
		});

		it("should trim whitespace from name", async () => {
			const testName = "  john  ";
			const response = await app.get(`/api/message/${testName}`);

			expect(response.status).toBe(200);
			expect(response.body).toEqual({ message: "hello john" });
		});
	});
});
