import { auth } from "@repo/auth";
import { logger } from "@repo/logger";
import { fromNodeHeaders } from "better-auth/node";
import type { NextFunction, Request, RequestHandler, Response } from "express";

// Define custom request type with user property
interface AuthenticatedRequest extends Request {
	user: User;
}

type Session = typeof auth.$Infer.Session;
type User = Session["user"];

export const authMiddleware: RequestHandler = async (req, res, next) => {
	try {
		const session = await auth.api.getSession({
			headers: fromNodeHeaders(req.headers),
		});

		if (!session) {
			res.status(401).json({ error: "Unauthorized" });
			return;
		}

		// Add session to request object
		(req as AuthenticatedRequest).user = session.user;
		next();
	} catch (error) {
		logger.error("Auth middleware error:", error);
		res.status(500).json({ error: "Internal Server Error" });
	}
};
