import { auth } from "@repo/auth";
import { toNodeHandler } from "better-auth/node";
import { type IRouter, Router } from "express";

const router: IRouter = Router();

// Mount Better Auth handler - Using Express 5's {*splat} syntax for matching all paths
router.use("/auth/{*splat}", toNodeHandler(auth));

export default router;
