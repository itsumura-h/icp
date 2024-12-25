import { useLocation } from 'preact-iso';

export function Header() {
	const { url } = useLocation();

	return (
		<header class="navbar">
			<nav>
				<a href="/" class={`${url == '/' && 'active'} btn`}>
					Home
				</a>
				<a href="/404" class={`${url == '/404' && 'active'} btn ml-2`}>
					404
				</a>
			</nav>
		</header>
	);
}
