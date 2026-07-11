export async function fetchWithProgress(
	url: string,
	onProgress?: (loaded: number, total: number, percent: number) => void,
): Promise<ArrayBuffer> {
	const response = await fetch(url);
	if (!response.ok) {
		throw new Error(
			`Failed to fetch: ${response.status} ${response.statusText}`,
		);
	}

	const contentLength = response.headers.get("Content-Length");
	const total = contentLength ? parseInt(contentLength, 10) : 0;

	if (!response.body || !total) {
		const buffer = await response.arrayBuffer();
		onProgress?.(buffer.byteLength, 0, -1);
		return buffer;
	}

	const reader = response.body.getReader();
	const chunks: Uint8Array[] = [];
	let loaded = 0;

	for (;;) {
		const { done, value } = await reader.read();
		if (done) break;
		chunks.push(value);
		loaded += value.length;
		const percent = Math.round((loaded / total) * 100);
		onProgress?.(loaded, total, percent);
	}

	const result = new Uint8Array(loaded);
	let offset = 0;
	for (const chunk of chunks) {
		result.set(chunk, offset);
		offset += chunk.length;
	}

	return result.buffer;
}
