import { render } from 'preact';
import { LocationProvider, Router, Route } from 'preact-iso';
import { Header } from './components/Header.jsx';
import { Home } from './pages/Home/index.jsx';
import { NotFound } from './pages/_404.jsx';
import './style.css';

export function App() {
	return (
		<LocationProvider>
			<main class="mx-auto p-4">
				<Header />
				<Router>
					<Home path='/' />
					<NotFound default />
				</Router>
			</main>
		</LocationProvider>
	);
}

render(<App />, document.getElementById('app'));
