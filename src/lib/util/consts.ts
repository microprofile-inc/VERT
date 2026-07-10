import { PUB_DISABLE_ALL_EXTERNAL_REQUESTS, PUB_ENV } from "$env/static/public";

export const DISCORD_URL = "https://discord.gg/kqevGxYPak";
export const VERT_NAME =
	PUB_ENV === "development"
		? "FormatCube Local"
		: PUB_ENV === "nightly"
			? "FormatCube Nightly"
			: "FormatCube";
export const CONTACT_EMAIL = "838394225@qq.com";

// i'm not entirely sure this should be in consts.ts, but it is technically a constant as .env is static for VERT
export const DISABLE_ALL_EXTERNAL_REQUESTS =
	PUB_DISABLE_ALL_EXTERNAL_REQUESTS === "true";

export const GB = 1024 * 1024 * 1024;
