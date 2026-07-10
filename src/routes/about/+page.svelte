<script lang="ts">
	import * as About from "$lib/sections/about";
	import { InfoIcon } from "lucide-svelte";
	import avatarNullptr from "$lib/assets/avatars/nullptr.jpg";
	import avatarLiam from "$lib/assets/avatars/liam.jpg";
	import avatarJovannMC from "$lib/assets/avatars/jovannmc.jpg";
	import avatarRealmy from "$lib/assets/avatars/realmy.jpg";
	import avatarAzurejelly from "$lib/assets/avatars/azurejelly.jpg";
	import { PUB_DONATION_URL, PUB_STRIPE_KEY } from "$env/static/public";
	import { DISABLE_ALL_EXTERNAL_REQUESTS } from "$lib/util/consts";
	import { m } from "$lib/paraglide/messages";

	/* interface Donator {
		name: string;
		amount?: string | number;
		avatar: string;
	} */

	interface Contributor {
		name: string;
		github: string;
		avatar: string;
		role?: string;
	}

	// const donors: Donator[] = [];

	const mainContribs: Contributor[] = [
		{
			name: "nullptr",
			github: "https://github.com/not-nullptr",
			role: m["about.credits.roles.lead_developer"](),
			avatar: avatarNullptr,
		},
		{
			name: "JovannMC",
			github: "https://github.com/JovannMC",
			role: m["about.credits.roles.developer"](),
			avatar: avatarJovannMC,
		},
		{
			name: "Liam",
			github: "https://x.com/z2rMC",
			role: m["about.credits.roles.designer"](),
			avatar: avatarLiam,
		},
	];

	const notableContribs: Contributor[] = [
		{
			name: "azurejelly",
			github: "https://github.com/azurejelly",
			role: m["about.credits.roles.docker_ci"](),
			avatar: avatarAzurejelly,
		},
		{
			name: "Realmy",
			github: "https://github.com/RealmyTheMan",
			role: m["about.credits.roles.former_cofounder"](),
			avatar: avatarRealmy,
		},
	];

	let ghContribs: Contributor[] = [];

	const donationsEnabled = PUB_STRIPE_KEY
		&& PUB_DONATION_URL
		&& !DISABLE_ALL_EXTERNAL_REQUESTS;
</script>

<div class="flex flex-col h-full items-center">
	<h1 class="hidden md:block text-[40px] tracking-tight leading-[72px] mb-6">
		<InfoIcon size="40" class="inline-block -mt-2 mr-2" />
		{m["about.title"]()}
	</h1>

	<div
		class="w-full max-w-[1280px] flex flex-col md:flex-row gap-4 p-4 md:px-4 md:py-0"
	>
		<!-- Why FormatCube? & Credits -->
		<div class="flex flex-col gap-4 flex-1">
			{#if donationsEnabled}
				<About.Donate />
			{/if}
			<About.Why />
			<About.Sponsors />
		</div>

		<!-- Resources & Credits -->
		<div class="flex flex-col gap-4 flex-1">
			<About.Resources />
			<About.Credits {mainContribs} {notableContribs} {ghContribs} />
		</div>
	</div>
</div>
