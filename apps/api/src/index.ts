import { logger } from "@repo/logger";
import { startServer } from "./server";

const port = Number(process.env.PORT) || 3001;

// Start server with proper error handling
startServer(port).catch((error) => {
	logger.error("Failed to start server:", error);
	process.exit(1);
});
