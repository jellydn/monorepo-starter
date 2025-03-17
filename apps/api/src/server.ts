import { logger } from "@repo/logger";
import { json, urlencoded } from "body-parser";
import cors from "cors";
import express, {
	type Express,
	type Request,
	type Response,
	type NextFunction,
} from "express";
import morgan from "morgan";
import routes from "./routes";

export const createServer = (): Express => {
	const app = express();

	// Global middleware
	app
		.disable("x-powered-by")
		.use(morgan("dev"))
		// In Express 5, extended defaults to false, but we'll set it explicitly for clarity
		.use(urlencoded({ extended: false }))
		.use(json())
		.use(cors());

	// Mount all routes under /api prefix
	app.use("/api", routes);

	// 404 handler - Express 5 requires status codes to be integers
	app.use((req: Request, res: Response) => {
		res.status(404).json({ error: "Not Found" });
	});

	// Error handler - Express 5 now automatically handles rejected promises
	app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
		logger.error(err.stack);
		// Express 5 requires status codes to be integers between 100-999
		res.status(500).json({ error: "Internal Server Error" });
	});

	return app;
};

// Export a function to start the server with proper error handling
export const startServer = (port: number): Promise<void> => {
	const app = createServer();

	return new Promise((resolve, reject) => {
		const server = app.listen(port, () => {
			if (server.address() === null) {
				reject(new Error("Failed to start server"));
				return;
			}
			logger.info(`Server listening on port ${port}`);
			resolve();
		});
	});
};
