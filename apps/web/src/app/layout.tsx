export default function RootLayout({
	children,
}: {
	children: React.ReactNode;
}) {
	return (
		<html lang="en">
			<head>
				<title>Monorepo Starter</title>
				<link rel="stylesheet" href="https://unpkg.com/mvp.css" />
			</head>
			<body>{children}</body>
		</html>
	);
}
