<script lang="ts">
	import { Check } from "lucide-svelte";
	import type { WorkerStatus } from "$lib/converters/converter.svelte";
	import Tooltip from "./Tooltip.svelte";

	interface Props {
		progress: number;
		status: WorkerStatus;
		label: string;
		size?: number;
	}

	let { progress, status, label, size = 28 }: Props = $props();

	const stroke = 3;
	const radius = $derived((size - stroke) / 2);
	const circumference = $derived(2 * Math.PI * radius);
	const dashOffset = $derived(
		progress >= 0
			? circumference - (progress / 100) * circumference
			: circumference * 0.25,
	);

	const color = $derived(
		status === "ready"
			? "var(--accent-green, #22c55e)"
			: status === "error"
				? "var(--accent-red, #ef4444)"
				: "var(--accent-purple, #F2ABEE)",
	);

	const tooltipText = $derived(
		status === "ready"
			? `${label}转换已准备就绪`
			: status === "error"
				? `${label}转换加载失败`
				: progress >= 0
					? `${label}转换加载中 ${progress}%`
					: `${label}转换加载中...`,
	);
</script>

<div class="wasm-progress">
	<Tooltip {tooltipText} position="top">
		<svg
			width={size}
			height={size}
			viewBox="0 0 {size} {size}"
			class={status === "downloading" && progress < 0
				? "indeterminate"
				: ''}
		>
			<circle
				cx={size / 2}
				cy={size / 2}
				{radius}
				fill="none"
				stroke="var(--separator, #e5e5e5)"
				stroke-width={stroke}
			/>
			<circle
				cx={size / 2}
				cy={size / 2}
				{radius}
				fill="none"
				stroke={color}
				stroke-width={stroke}
				stroke-linecap="round"
				stroke-dasharray={circumference}
				stroke-dashoffset={dashOffset}
				transform="rotate(-90 {size / 2} {size / 2})"
				style={progress >= 0
					? `transition: stroke-dashoffset 0.2s ease-out;`
					: 'animation: wasm-spin 1s linear infinite;'}
			/>
			{#if status === "downloading" && progress >= 0}
				<text
					x={size / 2}
					y={size / 2}
					text-anchor="middle"
					dominant-baseline="central"
					font-size={size * 0.32}
					fill={color}
					font-weight="600"
				>
					{progress}
				</text>
			{:else if status === "ready"}
				<foreignObject x="0" y="0" width={size} height={size}>
					<div
						class="w-full h-full flex items-center justify-center"
						style="color: {color};"
					>
						<Check size={size * 0.5} />
					</div>
				</foreignObject>
			{/if}
		</svg>
	</Tooltip>
</div>

<style>
	.wasm-progress {
		display: flex;
		align-items: center;
		justify-content: center;
	}

	@keyframes wasm-spin {
		from {
			transform: rotate(0deg);
		}
		to {
			transform: rotate(360deg);
		}
	}

	.indeterminate {
		animation: wasm-spin 1s linear infinite;
		transform-origin: center;
	}
</style>
