/**
 * Lambda handler — POST /agent/chat
 * Calls the Bedrock AgentCore travelAgent via its runtime endpoint.
 * This Lambda bridges the Flutter app (via API Gateway) to the
 * deployed Bedrock AgentCore agent.
 *
 * For the primary path, the app now uses Genkit Cloud Functions
 * (chatWithGuide with mode='bedrock') which replicates the
 * Planner → Research → Guide pipeline directly in Genkit.
 *
 * This Lambda remains as an alternative direct invocation path for
 * testing or when Genkit Cloud Functions are not deployed.
 */

const AGENT_RUNTIME_ENDPOINT =
  process.env.BEDROCK_AGENT_ENDPOINT ??
  'arn:aws:bedrock-agentcore:us-east-1:975263988636:runtime/travelAgent_Agent-HET7Du6ZKx';

export const handler = async (event: any) => {
  const body = JSON.parse(event.body ?? '{}');
  const { sessionId, message, challenges = [], history = [] } = body;

  try {
    // Invoke the Bedrock AgentCore runtime
    const payload = JSON.stringify({
      prompt: message,
      challenges,
      history,
    });

    // In production, this would use the Bedrock AgentCore SDK:
    // const client = new BedrockAgentCoreClient({ region: 'us-east-1' });
    // const response = await client.invokeAgent({ agentArn: AGENT_RUNTIME_ENDPOINT, payload });
    //
    // For now, proxy to the AgentCore HTTP endpoint if deployed locally:
    const agentUrl = process.env.AGENT_LOCAL_URL ?? 'http://localhost:8080/invocations';

    const response = await fetch(agentUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: payload,
    });

    const resultText = await response.text();
    let result;
    try {
      result = JSON.parse(resultText);
    } catch {
      result = { response: resultText, route: null };
    }

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify({
        response: result.response ?? 'No response from agent',
        route: result.route ?? null,
        sessionId: sessionId ?? '',
      }),
    };
  } catch (error: any) {
    console.error('Agent invocation error:', error);
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify({
        response: 'Sorry, the AI agent is temporarily unavailable. Please try again.',
        sessionId: sessionId ?? '',
        error: error.message,
      }),
    };
  }
};
