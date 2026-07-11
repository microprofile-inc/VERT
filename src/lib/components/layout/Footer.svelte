<script lang="ts">
	import { m } from "$lib/paraglide/messages";
	import { converters } from "$lib/converters";
	import WasmProgress from "$lib/components/visual/WasmProgress.svelte";

	const year = new Date().getFullYear();

	const activeConverters = $derived(
		converters.filter((c) => c.name !== "vertd"),
	);

	const converterLabels: Record<string, string> = {
		imagemagick: m["upload.cards.images"](),
		ffmpeg: m["upload.cards.audio"](),
		pandoc: m["upload.cards.documents"](),
	};
</script>

<footer
	class="hidden md:block w-full h-14 border-t border-separator fixed bottom-0 mt-12"
>
	<div
		class="w-full h-full flex items-center justify-between text-muted px-4 relative"
	>
		<div class="flex items-center gap-2 w-48">
			{#each activeConverters as converter (converter.name)}
				<WasmProgress
					progress={converter.downloadProgress}
					status={converter.status}
					label={converterLabels[converter.name] || converter.name}
					size={26}
				/>
			{/each}
		</div>

		<div class="flex items-center gap-3">
			<p>{m["footer.copyright"]({ year })}</p>
			<p>•</p>
			<a
				class="hover:underline font-normal"
				href="/privacy/"
			>
				{m["footer.privacy_policy"]()}
			</a>
		</div>

		<div class="w-48"></div>
	</div>

	<div
		class="absolute bottom-0 left-0 w-full h-24 -z-10 pointer-events-none"
		style="background: linear-gradient(to bottom, transparent, var(--bg) 100%)"
	></div>
</footer>
