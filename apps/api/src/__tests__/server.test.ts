import supertest from "supertest";
import { describe, expect, it } from "vitest";
import { createServer } from "../server";

describe("server", () => {
	it("status check returns 200", async () => {
		await supertest(createServer())
			.get("/status")
			.expect(200)
			.then((res: supertest.Response) => {
				expect(res.body.ok).toBe(true);
			});
	});

	it("message endpoint says hello", async () => {
		await supertest(createServer())
			.get("/message/jared")
			.expect(200)
			.then((res: supertest.Response) => {
				expect(res.body.message).toBe("hello jared");
			});
	});
});
