import { type IRouter, type RequestHandler, Router } from "express";

const router: IRouter = Router();

const healthHandler: RequestHandler = (_, res) => {
	res.json({ ok: true });
};

router.get("/health", healthHandler);

export default router;
