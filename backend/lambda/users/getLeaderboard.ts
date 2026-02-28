// TODO: Lambda handler — GET /leaderboard
// Query leaderboard table, support weekly/alltime period filter

export const handler = async (event: any) => {
  // TODO: Query DynamoDB leaderboard table
  return {
    statusCode: 200,
    headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    body: JSON.stringify({ leaderboard: [] }),
  };
};
