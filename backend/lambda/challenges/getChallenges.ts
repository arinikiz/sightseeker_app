// TODO: Lambda handler — GET /challenges
// Fetch all challenges from DynamoDB challenges table

export const handler = async (event: any) => {
  // TODO: Query DynamoDB
  return {
    statusCode: 200,
    headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    body: JSON.stringify({ challenges: [] }),
  };
};
