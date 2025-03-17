import { consola } from "consola";

// Create a custom logger instance
export const logger = consola.create({
	// Set default level based on environment
	level: process.env.NODE_ENV === "production" ? 3 : 4,
	// Add timestamps in development
	formatOptions: {
		date: process.env.NODE_ENV !== "production",
	},
});

// Default export for convenience
export default logger;
