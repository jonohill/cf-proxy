export interface Env {
	UPSTREAM_URL: string;
}

export default {
	
	async fetch(request: Request, env: Env, _ctx: ExecutionContext): Promise<Response> {

		const upstreamUrl = new URL(env.UPSTREAM_URL);
		const reqUrl = new URL(request.url);
		reqUrl.hostname = upstreamUrl.hostname;
		reqUrl.pathname = upstreamUrl.pathname.replace(/\/$/, "")
			+ '/' + reqUrl.pathname.replace(/^\//, "");
		
		const response = await fetch(reqUrl, {
			method: request.method,
			headers: request.headers,
			body: request.body,
		});

		const { readable, writable } = new TransformStream();
		response.body?.pipeTo(writable);

		return new Response(readable, response);
	},

};
