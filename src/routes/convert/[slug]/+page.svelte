<script lang="ts">
	import Uploader from "$lib/components/functional/Uploader.svelte";
	import { locale, preferredOutputFormat } from "$lib/store/index.svelte";
	import { Check, Download, Upload } from "lucide-svelte";
	import { onMount } from "svelte";
	import { m } from "$lib/paraglide/messages";

	const { data } = $props();
	const {
		fromDisplay,
		toDisplay,
		fromDisplayZh,
		toDisplayZh,
		titleEn,
		titleZh,
		descriptionEn,
		descriptionZh,
		to,
	} = $derived(data);

	const isZh = $derived(
		$locale === "zh-Hans" || $locale === "zh-Hant",
	);

	const pageTitle = $derived(
		isZh ? `${titleZh} - FormatCube` : `${titleEn} - FormatCube`,
	);
	const pageDesc = $derived(isZh ? descriptionZh : descriptionEn);
	const h1Text = $derived(
		isZh ? `${fromDisplayZh}转${toDisplayZh}` : `${fromDisplay} to ${toDisplay} Converter`,
	);
	const heroDesc = $derived(isZh ? titleZh : descriptionEn);

	onMount(() => {
		preferredOutputFormat.set(data.to);
	});
</script>

<svelte:head>
	<title>{pageTitle}</title>
	<meta name="title" content={pageTitle} />
	<meta name="description" content={pageDesc} />
	<meta property="og:title" content={pageTitle} />
	<meta property="og:description" content={pageDesc} />
	<meta name="twitter:title" content={pageTitle} />
	<meta name="twitter:description" content={pageDesc} />
</svelte:head>

<article class="max-w-4xl w-full mx-auto px-6 md:px-8 pb-20">
	<!-- Hero -->
	<section class="text-center py-12 md:py-16">
		<h1 class="text-3xl md:text-5xl font-bold tracking-tight mb-4">
			{h1Text}
		</h1>
		<p class="text-lg md:text-xl text-muted mb-8 max-w-2xl mx-auto">
			{heroDesc}
		</p>
		<div class="max-w-md mx-auto">
			<Uploader class="w-full h-48" />
		</div>
		<p class="text-sm text-muted mt-3">
			{m["seo.drop_hint"]({ from: fromDisplay })}
		</p>
	</section>

	<!-- How To -->
	<section class="mb-12">
		<h2 class="text-2xl font-bold mb-6 text-center">
			{m["seo.how_to_title"]({ from: fromDisplay, to: toDisplay })}
		</h2>
		<div class="grid md:grid-cols-3 gap-6">
			<div class="bg-panel rounded-2xl p-6 shadow-panel text-center">
				<div
					class="w-12 h-12 rounded-full bg-accent-blue flex items-center justify-center mx-auto mb-4"
				>
					<Upload size="24" color="black" />
				</div>
				<h3 class="font-bold mb-2">{m["seo.step1_title"]()}</h3>
				<p class="text-sm text-muted">
					{m["seo.step1_desc"]({ from: fromDisplay })}
				</p>
			</div>
			<div class="bg-panel rounded-2xl p-6 shadow-panel text-center">
				<div
					class="w-12 h-12 rounded-full bg-accent-purple flex items-center justify-center mx-auto mb-4"
				>
					<Check size="24" color="black" />
				</div>
				<h3 class="font-bold mb-2">{m["seo.step2_title"]()}</h3>
				<p class="text-sm text-muted">
					{m["seo.step2_desc"]({ to: toDisplay })}
				</p>
			</div>
			<div class="bg-panel rounded-2xl p-6 shadow-panel text-center">
				<div
					class="w-12 h-12 rounded-full bg-accent-green flex items-center justify-center mx-auto mb-4"
				>
					<Download size="24" color="black" />
				</div>
				<h3 class="font-bold mb-2">{m["seo.step3_title"]()}</h3>
				<p class="text-sm text-muted">
					{m["seo.step3_desc"]({ to: toDisplay })}
				</p>
			</div>
		</div>
	</section>

	<!-- Benefits -->
	<section class="mb-12">
		<h2 class="text-2xl font-bold mb-6 text-center">
			{m["seo.why_title"]({ from: fromDisplay, to: toDisplay })}
		</h2>
		<div class="grid md:grid-cols-2 gap-4">
			<div class="flex items-start gap-3 bg-panel rounded-xl p-4 shadow-panel">
				<Check size="20" class="text-accent-green mt-0.5 flex-shrink-0" />
				<div>
					<h4 class="font-bold">{m["seo.free_title"]()}</h4>
					<p class="text-sm text-muted">{m["seo.free_desc"]()}</p>
				</div>
			</div>
			<div class="flex items-start gap-3 bg-panel rounded-xl p-4 shadow-panel">
				<Check size="20" class="text-accent-green mt-0.5 flex-shrink-0" />
				<div>
					<h4 class="font-bold">{m["seo.local_title"]()}</h4>
					<p class="text-sm text-muted">{m["seo.local_desc"]()}</p>
				</div>
			</div>
			<div class="flex items-start gap-3 bg-panel rounded-xl p-4 shadow-panel">
				<Check size="20" class="text-accent-green mt-0.5 flex-shrink-0" />
				<div>
					<h4 class="font-bold">{m["seo.nolimit_title"]()}</h4>
					<p class="text-sm text-muted">{m["seo.nolimit_desc"]()}</p>
				</div>
			</div>
			<div class="flex items-start gap-3 bg-panel rounded-xl p-4 shadow-panel">
				<Check size="20" class="text-accent-green mt-0.5 flex-shrink-0" />
				<div>
					<h4 class="font-bold">{m["seo.privacy_title"]()}</h4>
					<p class="text-sm text-muted">{m["seo.privacy_desc"]()}</p>
				</div>
			</div>
		</div>
	</section>

	<!-- Bottom CTA -->
	<section class="text-center">
		<p class="text-muted mb-4">
			{m["seo.ready_text"]({ from: fromDisplay, to: toDisplay })}
		</p>
	</section>
</article>
