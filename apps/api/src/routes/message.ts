import { Router, type IRouter, type RequestHandler } from "express";

const router: IRouter = Router();

interface MessageParams {
	name: string;
}

const messageHandler: RequestHandler<MessageParams> = (req, res) => {
	const { name } = req.params;

	// Validate name parameter
	if (!name || !name.trim()) {
		res.status(400).json({ error: "Name is required" });
		return;
	}

	// Validate name length
	if (name.trim().length > 50) {
		res.status(400).json({ error: "Name must be less than 50 characters" });
		return;
	}

	// Validate name format (allow letters, numbers, spaces, and common special characters)
	const nameRegex = /^[a-zA-Z0-9\s\-_.']+$/;
	if (!nameRegex.test(name)) {
		res.status(400).json({ error: "Name contains invalid characters" });
		return;
	}

	res.json({ message: `hello ${name.trim()}` });
};

router.get("/:name", messageHandler);

export default router;