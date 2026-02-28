"""Diagnose AgentCore Browser connectivity issues."""
import boto3
import time
import json

REGION = "us-east-1"

print("=" * 60)
print("DIAGNOSING AGENTCORE BROWSER")
print("=" * 60)

# 1. Check IAM identity
print("\n1. Checking AWS identity...")
sts = boto3.client("sts", region_name=REGION)
identity = sts.get_caller_identity()
account_id = identity["Account"]
arn = identity["Arn"]
print(f"   Account: {account_id}")
print(f"   ARN: {arn}")

# 2. Check IAM permissions for browser
print("\n2. Checking IAM permissions...")
try:
    iam = boto3.client("iam", region_name=REGION)
    # Try to simulate the required actions
    required_actions = [
        "bedrock-agentcore:StartBrowserSession",
        "bedrock-agentcore:StopBrowserSession",
        "bedrock-agentcore:ConnectBrowserAutomationStream",
        "bedrock-agentcore:GetBrowserSession",
    ]
    print(f"   Required actions: {required_actions}")
    print("   (Can't simulate directly - will test via API calls below)")
except Exception as e:
    print(f"   IAM check error: {e}")

# 3. List existing browsers
print("\n3. Listing browsers...")
from bedrock_agentcore._utils.endpoints import get_control_plane_endpoint, get_data_plane_endpoint

control = boto3.client(
    "bedrock-agentcore-control",
    region_name=REGION,
    endpoint_url=get_control_plane_endpoint(REGION),
)
data = boto3.client(
    "bedrock-agentcore",
    region_name=REGION,
    endpoint_url=get_data_plane_endpoint(REGION),
)

try:
    browsers = control.list_browsers(maxResults=10)
    summaries = browsers.get("browserSummaries", [])
    print(f"   Found {len(summaries)} browser(s):")
    for b in summaries:
        print(f"     - {b.get('name', 'N/A')} | ID: {b.get('browserId', 'N/A')} | Status: {b.get('status', 'N/A')} | Type: {b.get('type', 'N/A')}")
except Exception as e:
    print(f"   Error listing browsers: {e}")

# 4. Start a session and check its status
print("\n4. Starting a test browser session...")
try:
    resp = data.start_browser_session(
        browserIdentifier="aws.browser.v1",
        name="diag-test-session",
        sessionTimeoutSeconds=300,
    )
    session_id = resp["sessionId"]
    browser_id = resp["browserIdentifier"]
    streams = resp.get("streams", {})
    auto_stream = streams.get("automationStream", {})

    print(f"   Session ID: {session_id}")
    print(f"   Browser ID: {browser_id}")
    print(f"   Automation stream status: {auto_stream.get('streamStatus', 'N/A')}")
    print(f"   Automation endpoint: {auto_stream.get('streamEndpoint', 'N/A')}")
    print(f"   Full response keys: {list(resp.keys())}")
except Exception as e:
    print(f"   ERROR starting session: {e}")
    import traceback; traceback.print_exc()
    exit(1)

# 5. Poll session status
print("\n5. Polling session status (checking every 5s for 60s)...")
for i in range(12):
    try:
        session_info = data.get_browser_session(
            browserIdentifier=browser_id,
            sessionId=session_id,
        )
        status = session_info.get("status", "UNKNOWN")
        print(f"   [{i*5:3d}s] Status: {status}")

        if status == "READY":
            print("   Session is READY!")
            print(f"   Session details: {json.dumps({k: str(v) for k, v in session_info.items() if k != 'ResponseMetadata'}, indent=4)}")
            break
        elif status in ("FAILED", "TERMINATED"):
            print(f"   Session failed/terminated!")
            print(f"   Details: {json.dumps({k: str(v) for k, v in session_info.items() if k != 'ResponseMetadata'}, indent=4)}")
            break
    except Exception as e:
        print(f"   [{i*5:3d}s] Error checking status: {e}")

    time.sleep(5)

# 6. Try WebSocket connection if session is READY
if status == "READY":
    print("\n6. Attempting WebSocket connection...")
    from bedrock_agentcore.tools.browser_client import BrowserClient
    client = BrowserClient(region=REGION)
    client._identifier = browser_id
    client._session_id = session_id

    ws_url, headers = client.generate_ws_headers()
    print(f"   WebSocket URL: {ws_url}")
    print(f"   Headers: {list(headers.keys())}")

    try:
        import asyncio
        from playwright.async_api import async_playwright

        async def test_connection():
            async with async_playwright() as p:
                print("   Connecting via CDP...")
                browser = await p.chromium.connect_over_cdp(
                    endpoint_url=ws_url, headers=headers
                )
                print("   SUCCESS! Connected to browser!")
                print(f"   Contexts: {len(browser.contexts)}")
                await browser.close()
                print("   Browser closed.")

        asyncio.run(test_connection())
    except Exception as e:
        print(f"   WebSocket connection FAILED: {e}")
else:
    print(f"\n6. Skipping WebSocket test - session status is: {status}")

# 7. Cleanup
print("\n7. Cleaning up test session...")
try:
    data.stop_browser_session(browserIdentifier=browser_id, sessionId=session_id)
    print("   Session stopped.")
except Exception as e:
    print(f"   Cleanup error (may already be stopped): {e}")

print("\n" + "=" * 60)
print("DIAGNOSIS COMPLETE")
print("=" * 60)
