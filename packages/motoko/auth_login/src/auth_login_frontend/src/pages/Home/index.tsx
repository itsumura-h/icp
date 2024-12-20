import { useState, useEffect } from "preact/hooks";
import { AuthClient, LocalStorage } from "@dfinity/auth-client";
import { Actor } from "@dfinity/agent";

export function Home() {
	const [principal, setPrincipal] = useState("");
	const [isAuthenticated, setIsAuthenticated] = useState(false);

	const login = async () => {
		const authClient = await AuthClient.create();
		authClient.login({
			// 7 days in nanoseconds
			maxTimeToLive: BigInt(7 * 24 * 60 * 60 * 1000 * 1000 * 1000),
			onSuccess: async () => {
				console.log("success to login");
			},
		});
		console.log({ authClient })
	}

	useEffect(() => {
		(async () => {
			await login();
		})()
	}, [])

	return (
		<article class="container mx-auto">
			<h1 className="text-3xl font-bold underline">Home</h1>
		</article>
	);
}
