import { useState } from 'preact/hooks';
import { type Principal } from "@dfinity/principal";
import { useIcp } from "../../libs/icp"

export function Home() {
	const [input, setInput] = useState('');
	const [msg, setMsg] = useState('');
	const [principal, setPrincipal] = useState<Principal | null>(null);

	const { isLogin, icLogin, icLogout, authLoginActor, identity } = useIcp()

	const greet = async () => {
		const greeting = await authLoginActor?.greet(input);
		setMsg(greeting);
		setInput('');
	};

	const getPrincipal = async () => {
		const principal = await authLoginActor.getPrincipal();
		setPrincipal(principal);
	};

	return (
		<>
			<article>
				<h1 class="font-bold text-2xl p-4">Home</h1>
				<section class="p-4">
					<div class="bg-gray-100">
						<div class="p-2">
							<input
								class="input input-bordered"
								type="text"
								placeholder="message"
								value={input}
								onChange={(e) => setInput(e.currentTarget.value)}
							/>
						</div>
						<div class="p-4">
							<button
								type="button"
								class="btn bg-gray-300"
								onClick={greet}
							>
								Greet
							</button>
						</div>
						<p class="p-4">{msg}</p>
					</div>
				</section>

				<section class="p-4">
					<div class="bg-gray-100">
						{isLogin ? (
							<>
								<p class="p-4">{identity?.getPrincipal().toText()}</p>
								<div class="p-4">
									<button class="btn bg-gray-300" type="button" onClick={icLogout}>
										Logout
									</button>
								</div>
							</>
						) : (
							<div class="p-4">
								<button class="btn bg-gray-300" type="button" onClick={icLogin}>
									Login
								</button>
							</div>
						)}
					</div>
				</section>

				<section class=" p-4">
					<form class="bg-gray-100">
						<div class="p-4">
							<button class="btn bg-gray-300" type="button" onClick={getPrincipal}>
								Get Principal
							</button>
						</div>
						<p class="p-4">{principal?.toText()}</p>
					</form>
				</section>

				<section class="p-4">
					<div class="bg-gray-100">
						<IcConnectKit />
					</div>
				</section>

			</article>
		</>
	);
}
