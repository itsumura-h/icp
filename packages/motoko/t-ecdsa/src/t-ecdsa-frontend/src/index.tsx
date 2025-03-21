import "preact/debug";
import { hydrate, prerender as ssr } from 'preact-iso';
import { Router, Route, Switch } from "wouter";
import { useHashLocation } from "wouter/use-hash-location";
import { HomePage } from "./pages/Home";
import './style.css';

export function App() {
	return (
		<div class="min-h-screen bg-gray-100 max-w-screen mx-auto">
			<Router hook={useHashLocation} base="/">
				<Switch>
					<Route path="/" component={HomePage} />
				</Switch>
			</Router>
		</div>
	);
}

if (typeof window !== 'undefined') {
	hydrate(<App />, document.getElementById('app'));
}

export async function prerender(data) {
	return await ssr(<App {...data} />);
}
