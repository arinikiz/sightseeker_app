// TODO: Lambda handler — GET /challenges/{id}/participants
// Query participants table by challengeId

export const handler = async (event: any) => {
  // TODO: Query DynamoDB participants table
  return {
    statusCode: 200,
    headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    body: JSON.stringify({ participants: [] }),
  };
};
