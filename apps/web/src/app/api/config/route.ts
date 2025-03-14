import { NextResponse } from "next/server";

// Store the build time when the server starts
const BUILD_TIME = new Date().toISOString();

export async function GET() {
	// Get the API URL from the environment variable
	const apiUrl = process.env.API_URL || "http://localhost:3001";

	// Log the API URL for debugging
	console.log("API URL from environment:", apiUrl);

	// Return the configuration as JSON
	return NextResponse.json({
		apiUrl,
		buildTime: BUILD_TIME,
		timestamp: new Date().toISOString(),
		environment: process.env.NODE_ENV,
	});
}
