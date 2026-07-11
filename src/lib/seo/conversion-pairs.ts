/** Conversion pair: from → to format, with optional aliases for URL variants */
export interface ConversionPair {
	/** source format (no dot, canonical name from converter) */
	from: string;
	/** target format (no dot, canonical name from converter) */
	to: string;
	/** URL-safe slug, e.g. "png-to-jpg" */
	slug: string;
	/** converter name: "image" | "audio" | "document" */
	category: "image" | "audio" | "document";
}

function makeSlug(from: string, to: string): string {
	return `${from}-to-${to}`;
}

const imagePairs: [string, string[]][] = [
	["png", ["jpg", "webp", "avif", "gif", "svg", "bmp", "ico", "tiff", "jxl"]],
	["jpg", ["png", "webp", "avif", "gif", "bmp", "tiff"]],
	["webp", ["png", "jpg", "gif", "avif", "bmp"]],
	["avif", ["png", "jpg", "webp"]],
	["heic", ["png", "jpg", "webp"]],
	["svg", ["png", "jpg", "webp"]],
	["gif", ["png", "jpg", "webp"]],
	["bmp", ["png", "jpg"]],
	["tiff", ["png", "jpg"]],
	["ico", ["png"]],
	["jxl", ["png", "jpg", "webp"]],
];

const audioPairs: [string, string[]][] = [
	["mp3", ["wav", "flac", "ogg", "aac", "m4a", "wma", "opus", "aiff"]],
	["wav", ["mp3", "flac", "ogg", "aac", "opus"]],
	["flac", ["mp3", "wav", "ogg"]],
	["ogg", ["mp3", "wav"]],
	["aac", ["mp3", "wav"]],
	["m4a", ["mp3"]],
	["wma", ["mp3"]],
	["opus", ["mp3", "wav"]],
	["aiff", ["mp3"]],
	["amr", ["mp3"]],
	["ac3", ["mp3"]],
	["weba", ["mp3"]],
];

const documentPairs: [string, string[]][] = [
	["docx", ["doc", "md", "html", "rtf", "csv", "epub", "odt"]],
	["md", ["docx", "html", "epub"]],
	["html", ["docx", "md"]],
	["epub", ["docx", "html"]],
	["odt", ["docx"]],
	["csv", ["docx"]],
	["json", ["docx"]],
	["rst", ["docx", "md", "html"]],
	["rtf", ["docx"]],
];

function buildPairs(
	pairs: [string, string[]][],
	category: ConversionPair["category"],
): ConversionPair[] {
	const result: ConversionPair[] = [];
	for (const [from, targets] of pairs) {
		for (const to of targets) {
			result.push({ from, to, slug: makeSlug(from, to), category });
		}
	}
	return result;
}

export const conversionPairs: ConversionPair[] = [
	...buildPairs(imagePairs, "image"),
	...buildPairs(audioPairs, "audio"),
	...buildPairs(documentPairs, "document"),
];

/** Display name for format (used on SEO pages) */
export const formatDisplayNames: Record<string, string> = {
	png: "PNG",
	jpg: "JPG",
	jpeg: "JPEG",
	webp: "WebP",
	avif: "AVIF",
	gif: "GIF",
	svg: "SVG",
	bmp: "BMP",
	ico: "ICO",
	tiff: "TIFF",
	tif: "TIF",
	heic: "HEIC",
	jxl: "JXL",
	hdr: "HDR",
	psd: "PSD",
	eps: "EPS",
	jfif: "JFIF",
	jpe: "JPE",
	pbm: "PBM",
	pgm: "PGM",
	ppm: "PPM",
	pnm: "PNM",
	mp3: "MP3",
	wav: "WAV",
	flac: "FLAC",
	ogg: "OGG",
	aac: "AAC",
	m4a: "M4A",
	wma: "WMA",
	opus: "Opus",
	aiff: "AIFF",
	amr: "AMR",
	ac3: "AC3",
	weba: "WEBA",
	docx: "DOCX",
	doc: "DOC",
	md: "Markdown",
	html: "HTML",
	rtf: "RTF",
	csv: "CSV",
	epub: "EPUB",
	odt: "ODT",
	json: "JSON",
	rst: "reStructuredText",
};

/** Chinese display name for format */
export const formatDisplayNamesZh: Record<string, string> = {
	...formatDisplayNames,
	svg: "SVG",
	html: "HTML",
	rtf: "RTF",
	csv: "CSV",
	json: "JSON",
	md: "Markdown",
	rst: "RST",
	m4a: "M4A",
	docx: "DOCX",
	doc: "DOC",
	epub: "EPUB",
	odt: "ODT",
};
