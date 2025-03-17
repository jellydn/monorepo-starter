import { Router, type IRouter, type Request, type RequestHandler } from "express";
import { authMiddleware } from "../middleware/auth";
import type { auth } from "@repo/auth";

const router: IRouter = Router();

type Session = typeof auth.$Infer.Session;
type User = Session["user"];

// Define custom request type with user property
interface AuthenticatedRequest extends Request {
	user: User;
}

const meHandler: RequestHandler = async (req, res) => {
	const authReq = req as AuthenticatedRequest;
	// The user object is attached by the auth middleware
	res.json({ user: authReq.user });
};

router.get("/me", authMiddleware, meHandler);

export default router;