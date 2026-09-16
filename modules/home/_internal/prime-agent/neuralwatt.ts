import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const PROVIDER_ID = "neuralwatt";
const BASE_URL = "https://api.neuralwatt.com/v1";
const MODELS_URL = `${BASE_URL}/models`;
const API_KEY_ENV = "NEURALWATT_API_KEY";
const FALLBACK_MAX_OUTPUT_TOKENS = 65_536;

type ThinkingLevel = "off" | "minimal" | "low" | "medium" | "high" | "xhigh" | "max";

type NeuralwattModel = {
  id: string;
  max_model_len?: number;
  metadata?: {
    display_name?: string;
    deprecated?: boolean;
    capabilities?: {
      tools?: boolean;
      streaming?: boolean;
      reasoning?: boolean;
      vision?: boolean;
    };
    reasoning?: {
      mandatory?: boolean;
      accepted_efforts?: string[];
    };
    pricing?: {
      input_per_million?: number;
      output_per_million?: number;
      cached_input_per_million?: number | null;
    };
    limits?: {
      max_context_length?: number | null;
      max_output_tokens?: number | null;
    };
  };
};

type NeuralwattModelsResponse = {
  data?: NeuralwattModel[];
};

function thinkingLevelMap(model: NeuralwattModel): Partial<Record<ThinkingLevel, string | null>> | undefined {
  if (!model.metadata?.capabilities?.reasoning) return undefined;

  const contract = model.metadata.reasoning;
  const accepted = new Set(contract?.accepted_efforts ?? []);
  const result: Partial<Record<ThinkingLevel, string | null>> = {
    // Mandatory-reasoning models must not expose an off setting.
    off: !contract?.mandatory && accepted.has("none") ? "none" : null,
  };

  for (const level of ["minimal", "low", "medium", "high", "xhigh", "max"] as const) {
    // An empty list means the model has fixed reasoning. Neuralwatt safely
    // ignores reasoning.effort for those models, so leave the levels usable.
    if (accepted.size > 0) result[level] = accepted.has(level) ? level : null;
  }

  return result;
}

function toProviderModel(model: NeuralwattModel) {
  const metadata = model.metadata ?? {};
  const capabilities = metadata.capabilities ?? {};
  const pricing = metadata.pricing ?? {};
  const contextWindow = metadata.limits?.max_context_length ?? model.max_model_len ?? 128_000;
  const maxTokens =
    metadata.limits?.max_output_tokens ??
    Math.min(FALLBACK_MAX_OUTPUT_TOKENS, Math.max(4_096, Math.floor(contextWindow / 4)));

  return {
    id: model.id,
    name: metadata.display_name ?? model.id,
    api: "openai-responses" as const,
    reasoning: capabilities.reasoning === true,
    thinkingLevelMap: thinkingLevelMap(model),
    // Neuralwatt's Responses compatibility endpoint currently rejects image
    // and file input, even when the underlying model supports vision.
    input: ["text"] as const,
    cost: {
      input: pricing.input_per_million ?? 0,
      output: pricing.output_per_million ?? 0,
      cacheRead: pricing.cached_input_per_million ?? pricing.input_per_million ?? 0,
      cacheWrite: 0,
    },
    contextWindow,
    maxTokens,
    compat: {
      // These are OpenAI-specific cache/session features. Neuralwatt accepts
      // prompt_cache_key but does not document these two extensions.
      sendSessionIdHeader: false,
      supportsLongCacheRetention: false,
    },
  };
}

async function discoverModels(): Promise<ReturnType<typeof toProviderModel>[]> {
  const headers: Record<string, string> = { Accept: "application/json" };
  const apiKey = process.env[API_KEY_ENV];
  if (apiKey) headers.Authorization = `Bearer ${apiKey}`;

  const response = await fetch(MODELS_URL, {
    headers,
    signal: AbortSignal.timeout(8_000),
  });
  if (!response.ok) {
    throw new Error(`${response.status} ${response.statusText}`);
  }

  const payload = (await response.json()) as NeuralwattModelsResponse;
  if (!Array.isArray(payload.data) || payload.data.length === 0) {
    throw new Error("the model catalog was empty");
  }

  return payload.data
    .filter((model) =>
      Boolean(
        model.id &&
          !model.metadata?.deprecated &&
          model.metadata?.capabilities?.tools !== false &&
          model.metadata?.capabilities?.streaming !== false,
      ),
    )
    .map(toProviderModel);
}

export default async function (pi: ExtensionAPI) {
  let models: ReturnType<typeof toProviderModel>[];

  try {
    models = await discoverModels();
  } catch (error) {
    // Keep the provider usable during a transient catalog outage. This model
    // is the stable model used throughout Neuralwatt's public quickstart.
    console.warn(
      `[neuralwatt] Could not refresh ${MODELS_URL}: ${error instanceof Error ? error.message : String(error)}`,
    );
    models = [
      toProviderModel({
        id: "glm-5.2",
        max_model_len: 1_048_560,
        metadata: {
          display_name: "GLM-5.2",
          capabilities: { tools: true, streaming: true, reasoning: true },
          reasoning: {
            mandatory: false,
            accepted_efforts: ["none", "minimal", "low", "medium", "high", "xhigh", "max"],
          },
          pricing: { input_per_million: 1.45, output_per_million: 4.5 },
        },
      }),
    ];
  }

  pi.registerProvider(PROVIDER_ID, {
    name: "Neuralwatt",
    baseUrl: BASE_URL,
    apiKey: API_KEY_ENV,
    api: "openai-responses",
    models,
  });
}
