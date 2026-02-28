// TODO: Lambda handler — POST /agent/chat
// Calls AWS Bedrock AgentCore to get AI travel guide responses

// import { BedrockAgentRuntimeClient, InvokeAgentCommand } from "@aws-sdk/client-bedrock-agent-runtime";

export const handler = async (event: any) => {
  // const { sessionId, message } = JSON.parse(event.body);

  // TODO: Initialize BedrockAgentRuntimeClient
  // TODO: Send InvokeAgentCommand with agentId, agentAliasId, sessionId, inputText
  // TODO: Stream and collect response chunks

  return {
    statusCode: 200,
    headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    body: JSON.stringify({ response: "AI agent not yet configured", sessionId: "" }),
  };
};
