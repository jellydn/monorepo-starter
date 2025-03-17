"use client";

import { Button } from "@repo/ui/button";
import { type ChangeEvent, type FormEvent, useEffect, useState } from "react";

async function getApiConfigUrl() {
	try {
		const response = await fetch("/api/config");

		if (!response.ok) {
			throw new Error(`Failed to fetch config: ${response.status}`);
		}

		const data = await response.json();
		return {
			apiUrl: data.apiUrl,
			buildTime: data.buildTime,
		};
	} catch {
		return {
			apiUrl: null,
			buildTime: null,
		};
	}
}

export default function Web() {
	const [name, setName] = useState<string>("");
	const [response, setResponse] = useState<{ message: string } | null>(null);
	const [error, setError] = useState<string | undefined>();
	const [apiUrl, setApiUrl] = useState<string | null>(null);
	const [buildTime, setBuildTime] = useState<string | null>(null);
	const [loading, setLoading] = useState(true);

	// Fetch the API URL from the server
	useEffect(() => {
		async function fetchApiUrl() {
			try {
				const config = await getApiConfigUrl();
				setApiUrl(config.apiUrl || "http://localhost:3001");
				setBuildTime(config.buildTime || new Date().toISOString());
			} catch {
				setApiUrl("http://localhost:3001");
				setBuildTime(new Date().toISOString());
			} finally {
				setLoading(false);
			}
		}

		fetchApiUrl();
	}, []);

	// biome-ignore lint/correctness/useExhaustiveDependencies: This will reset the response and error when the name changes
	useEffect(() => {
		setResponse(null);
		setError(undefined);
	}, [name]);

	const onChange = (e: ChangeEvent<HTMLInputElement>) =>
		setName(e.target.value);

	const onSubmit = async (e: FormEvent<HTMLFormElement>) => {
		e.preventDefault();

		if (!apiUrl) {
			setError("API URL not available");
			return;
		}

		// Add validation for required name field
		if (!name.trim()) {
			setError("Name is required");
			return;
		}

		try {
			const result = await fetch(`${apiUrl}/api/message/${name}`);
			if (!result.ok) {
				const errorData = await result.json();
				setError(errorData.error || "Failed to get greeting");
				return;
			}
			const response = await result.json();
			setResponse(response);
		} catch {
			setError("Unable to fetch response");
		}
	};

	const onReset = () => {
		setName("");
	};

	// Format the build time to a more readable format
	const formatBuildTime = (isoString: string | null) => {
		if (!isoString) return "Unknown";
		try {
			const date = new Date(isoString);
			return date.toLocaleString();
		} catch {
			return isoString;
		}
	};

	if (loading) {
		return (
			<div
				style={{
					display: "flex",
					justifyContent: "center",
					alignItems: "center",
					height: "100vh",
					background: "linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%)",
				}}
			>
				<div
					style={{
						padding: "2rem",
						borderRadius: "8px",
						background: "white",
						boxShadow: "0 4px 6px rgba(0, 0, 0, 0.1)",
						textAlign: "center",
					}}
				>
					<p style={{ fontSize: "1.2rem", color: "#4a5568" }}>
						Loading configuration...
					</p>
					<div
						style={{
							display: "inline-block",
							width: "50px",
							height: "50px",
							border: "3px solid rgba(0, 0, 0, 0.1)",
							borderRadius: "50%",
							borderTopColor: "#3182ce",
							animation: "spin 1s ease-in-out infinite",
							marginTop: "1rem",
						}}
					/>
					<style jsx>{`
						@keyframes spin {
							to { transform: rotate(360deg); }
						}
					`}</style>
				</div>
			</div>
		);
	}

	return (
		<div
			style={{
				minHeight: "100vh",
				background: "linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%)",
				padding: "2rem",
			}}
		>
			<div
				style={{
					maxWidth: "800px",
					margin: "0 auto",
					background: "white",
					borderRadius: "12px",
					boxShadow:
						"0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)",
					overflow: "hidden",
				}}
			>
				<header
					style={{
						background: "#4299e1",
						color: "white",
						padding: "1.5rem 2rem",
						borderBottom: "1px solid #e2e8f0",
					}}
				>
					<h1 style={{ margin: 0, fontSize: "1.8rem", fontWeight: 600 }}>
						Web Application
					</h1>
					<p
						style={{
							margin: "0.5rem 0 0 0",
							fontSize: "0.9rem",
							opacity: 0.8,
						}}
					>
						Connected to: {apiUrl}
					</p>
				</header>

				<main style={{ padding: "2rem" }}>
					<form
						onSubmit={onSubmit}
						style={{
							display: "flex",
							flexDirection: "column",
							gap: "1.5rem",
							maxWidth: "500px",
							margin: "0 auto",
						}}
					>
						<div style={{ textAlign: "center", marginBottom: "1rem" }}>
							<p style={{ fontSize: "1.1rem", color: "#4a5568" }}>
								Enter your name
							</p>
						</div>

						<div
							style={{
								display: "flex",
								flexDirection: "column",
								gap: "0.5rem",
							}}
						>
							<label
								htmlFor="name"
								style={{
									fontWeight: 500,
									color: "#4a5568",
									fontSize: "0.9rem",
								}}
							>
								Your Name
							</label>
							<input
								type="text"
								name="name"
								id="name"
								value={name}
								onChange={onChange}
								placeholder="Enter your name"
								required
								style={{
									width: "92%",
									padding: "0.75rem 1rem",
									borderRadius: "6px",
									border: "1px solid #e2e8f0",
									fontSize: "1rem",
									transition: "border-color 0.2s",
									outline: "none",
								}}
								onFocus={(e) => {
									const target = e.target as HTMLInputElement;
									target.style.borderColor = "#4299e1";
								}}
								onBlur={(e) => {
									const target = e.target as HTMLInputElement;
									target.style.borderColor = "#e2e8f0";
								}}
							/>
						</div>

						<Button
							type="submit"
							style={{
								background: "#4299e1",
								color: "white",
								border: "none",
								padding: "0.75rem 1.5rem",
								borderRadius: "6px",
								fontWeight: 500,
								cursor: "pointer",
								transition: "background 0.2s",
								alignSelf: "center",
								marginTop: "0.5rem",
							}}
						>
							Get Greeting
						</Button>
					</form>

					{error && (
						<div
							style={{
								textAlign: "center",
								marginTop: "2rem",
								padding: "1rem",
								background: "#fed7d7",
								borderRadius: "6px",
								color: "#c53030",
							}}
						>
							<h3 style={{ margin: "0 0 0.5rem 0", fontSize: "1.1rem" }}>
								Error
							</h3>
							<p style={{ margin: 0 }}>{error}</p>
						</div>
					)}

					{response && (
						<div
							style={{
								textAlign: "center",
								marginTop: "2rem",
								padding: "1.5rem",
								background: "#c6f6d5",
								borderRadius: "6px",
								color: "#2f855a",
							}}
						>
							<h3 style={{ margin: "0 0 0.5rem 0", fontSize: "1.2rem" }}>
								Greeting
							</h3>
							<p
								style={{
									margin: "0 0 1.5rem 0",
									fontSize: "1.5rem",
									fontWeight: 500,
								}}
							>
								{response.message}
							</p>
							<Button
								onClick={onReset}
								style={{
									background: "#38a169",
									color: "white",
									border: "none",
									padding: "0.5rem 1rem",
									borderRadius: "6px",
									fontWeight: 500,
									cursor: "pointer",
									transition: "background 0.2s",
								}}
							>
								Reset
							</Button>
						</div>
					)}
				</main>

				<footer
					style={{
						borderTop: "1px solid #e2e8f0",
						padding: "1rem 2rem",
						textAlign: "center",
						color: "#718096",
						fontSize: "0.9rem",
					}}
				>
					<p style={{ margin: 0 }}>
						Monorepo Starter Demo • Built: {formatBuildTime(buildTime)}
					</p>
				</footer>
			</div>
		</div>
	);
}
