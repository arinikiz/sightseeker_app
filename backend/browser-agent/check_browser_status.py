"""
Check and setup AWS Bedrock AgentCore Browser
"""
import boto3
import json
import time

REGION = "us-east-1"
BROWSER_NAME = "myAgentCoreBrowser"

def get_or_create_execution_role():
    """Create or get the execution role for AgentCore browser"""
    iam = boto3.client('iam')
    role_name = "BedrockAgentCoreExecutionRole"
    
    try:
        response = iam.get_role(RoleName=role_name)
        print(f"   ✅ Execution role exists: {response['Role']['Arn']}")
        return response['Role']['Arn']
    except iam.exceptions.NoSuchEntityException:
        print(f"   Creating execution role: {role_name}")
        
        trust_policy = {
            "Version": "2012-10-17",
            "Statement": [{
                "Effect": "Allow",
                "Principal": {"Service": "bedrock-agentcore.amazonaws.com"},
                "Action": "sts:AssumeRole"
            }]
        }
        
        response = iam.create_role(
            RoleName=role_name,
            AssumeRolePolicyDocument=json.dumps(trust_policy),
            Description="Execution role for Bedrock AgentCore Browser"
        )
        
        permissions_policy = {
            "Version": "2012-10-17",
            "Statement": [{
                "Effect": "Allow",
                "Action": [
                    "bedrock-agentcore:*",
                    "bedrock:InvokeModel*"
                ],
                "Resource": "*"
            }]
        }
        
        iam.put_role_policy(
            RoleName=role_name,
            PolicyName="BedrockAgentCorePermissions",
            PolicyDocument=json.dumps(permissions_policy)
        )
        
        print(f"   ✅ Created execution role: {response['Role']['Arn']}")
        print("   Waiting 10 seconds for role to propagate...")
        time.sleep(10)
        return response['Role']['Arn']

def wait_for_browser_ready(control_client, browser_id, max_wait=120):
    """Wait for browser to be in ACTIVE status"""
    print(f"   Waiting for browser to be ready (max {max_wait}s)...")
    start_time = time.time()
    
    while time.time() - start_time < max_wait:
        try:
            response = control_client.get_browser(browserId=browser_id)
            status = response.get('status', 'UNKNOWN')
            print(f"   Browser status: {status}")
            
            if status in ['ACTIVE', 'READY']:
                return True
            elif status in ['FAILED', 'DELETED']:
                print(f"   ❌ Browser failed with status: {status}")
                return False
                
            time.sleep(10)
        except Exception as e:
            print(f"   Error checking status: {e}")
            time.sleep(10)
    
    print("   ⚠️ Timeout waiting for browser")
    return False

def create_browser(control_client, role_arn):
    """Create a browser resource"""
    print(f"\n   Creating browser: {BROWSER_NAME}")
    try:
        response = control_client.create_browser(
            name=BROWSER_NAME,
            executionRoleArn=role_arn,
            networkConfiguration={
                'networkMode': 'PUBLIC'
            }
        )
        browser_id = response.get('browserId', response.get('browserIdentifier', BROWSER_NAME))
        print(f"   ✅ Browser created: {browser_id}")
        return browser_id
    except control_client.exceptions.ConflictException:
        print(f"   Browser {BROWSER_NAME} already exists")
        # List browsers to find it
        response = control_client.list_browsers()
        for b in response.get('browsers', []):
            if BROWSER_NAME in b.get('browserId', '') or BROWSER_NAME in b.get('name', ''):
                return b.get('browserId', b.get('browserIdentifier'))
        return None
    except Exception as e:
        print(f"   ❌ Error creating browser: {e}")
        return None

def check_browser_service():
    print("=" * 60)
    print("Checking Bedrock AgentCore Browser Service")
    print("=" * 60)
    
    runtime_client = boto3.client('bedrock-agentcore', region_name=REGION)
    control_client = boto3.client('bedrock-agentcore-control', region_name=REGION)
    
    print("\n1. Checking clients...")
    print(f"   ✅ Runtime client created for {REGION}")
    print(f"   ✅ Control client created for {REGION}")
    
    # List browsers
    print("\n2. Listing available browsers...")
    try:
        response = control_client.list_browsers()
        browsers = response.get('browserSummaries', response.get('browsers', []))
        print(f"   Found {len(browsers)} browsers")
        print(f"   Raw response: {json.dumps(response, indent=2, default=str)}")
        
        browser_id = None
        for b in browsers:
            # Try different key names
            bid = b.get('browserId') or b.get('browserIdentifier') or b.get('name', 'unknown')
            status = b.get('status', 'unknown')
            print(f"      - {bid}: {status}")
            if status in ['ACTIVE', 'READY'] and browser_id is None:
                browser_id = bid
        
        if len(browsers) == 0:
            print("\n3. No browsers found. Creating one...")
            role_arn = get_or_create_execution_role()
            browser_id = create_browser(control_client, role_arn)
            if browser_id:
                if not wait_for_browser_ready(control_client, browser_id):
                    print("   ❌ Browser not ready")
                    return
        elif browser_id is None and len(browsers) > 0:
            # Browsers exist but none are ACTIVE - get the first one
            b = browsers[0]
            browser_id = b.get('browserId') or b.get('browserIdentifier') or b.get('name')
            print(f"\n3. Waiting for browser {browser_id} to become ACTIVE...")
            if not wait_for_browser_ready(control_client, browser_id):
                print("   ❌ Browser not ready")
                return
        else:
            print(f"\n3. Using active browser: {browser_id}")
            
    except Exception as e:
        print(f"   ❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return
    
    if not browser_id:
        print("   ❌ No browser available")
        return
        
    # Try to start a test session
    print(f"\n4. Starting test browser session with: {browser_id}")
    try:
        response = runtime_client.start_browser_session(
            browserIdentifier=browser_id,
            name="diagnosticTestSession"
        )
        session_id = response.get('sessionId')
        print(f"   ✅ Session created: {session_id}")
        
        streams = response.get('streams', {})
        automation_stream = streams.get('automationStream', {})
        print(f"   Automation endpoint: {automation_stream.get('streamEndpoint', 'N/A')}")
        print(f"   Automation status: {automation_stream.get('streamStatus', 'N/A')}")
        
        # Stop the test session
        print("\n5. Stopping test session...")
        try:
            runtime_client.stop_browser_session(
                browserIdentifier=browser_id,
                sessionId=session_id
            )
            print(f"   ✅ Session stopped")
        except Exception as e:
            print(f"   ⚠️ Error stopping session: {e}")
            
        print(f"\n" + "=" * 60)
        print(f"✅ SUCCESS! Browser is ready.")
        print(f"   Use this in browser_agent.py:")
        print(f"   BROWSER_ID = \"{browser_id}\"")
        print("=" * 60)
        
    except Exception as e:
        print(f"   ❌ Error starting session: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    check_browser_service()
