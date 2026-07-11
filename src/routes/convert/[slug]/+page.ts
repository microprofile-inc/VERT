import { conversionPairs, formatDisplayNames, formatDisplayNamesZh } from "$lib/seo/conversion-pairs";
import { paraglideMiddleware } from "$lib/paraglide/server.js";

export const entries = () => {
	return conversionPairs.map((p) => ({ slug: p.slug }));
};

export const load = ({ params }: { params: { slug: string } }) => {
	const slug = params.slug;
	const pair = conversionPairs.find((p) => p.slug === slug);

	if (!pair) {
		return {
			slug,
			from: "",
			to: "",
			fromDisplay: "",
			toDisplay: "",
			fromDisplayZh: "",
			toDisplayZh: "",
			category: "image" as const,
			titleEn: "Format Converter",
			titleZh: "格式转换",
			descriptionEn: "Convert files online for free",
			descriptionZh: "免费在线文件格式转换",
		};
	}

	const fromUpper = formatDisplayNames[pair.from] || pair.from.toUpperCase();
	const toUpper = formatDisplayNames[pair.to] || pair.to.toUpperCase();
	const fromZh = formatDisplayNamesZh[pair.from] || fromUpper;
	const toZh = formatDisplayNamesZh[pair.to] || toUpper;

	return {
		slug,
		from: pair.from,
		to: pair.to,
		fromDisplay: fromUpper,
		toDisplay: toUpper,
		fromDisplayZh: fromZh,
		toDisplayZh: toZh,
		category: pair.category,
		titleEn: `Convert ${fromUpper} to ${toUpper} Online Free`,
		titleZh: `${fromZh}转${toZh} - 在线免费转换`,
		descriptionEn: `Free online ${fromUpper} to ${toUpper} converter. Convert your ${pair.from} files to ${pair.to} instantly, with 100% local processing in your browser. No file size limit, no registration required.`,
		descriptionZh: `免费在线${fromZh}转${toZh}工具。在浏览器本地完成转换，无需上传文件，无文件大小限制，无需注册。`,
	};
};
