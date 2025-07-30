# main.py
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
import subprocess
import asyncio
import os
import json
import yaml
from pathlib import Path
import shutil
import hcl2

app = FastAPI()

# --- Static File Serving ---
app.mount("/static", StaticFiles(directory="static"), name="static")

# --- HCL Generation Helper ---
def to_hcl(data, indent=0):
    """Recursively converts a Python dictionary to an HCL string."""
    hcl_string = ""
    indent_space = "  " * indent
    for key, value in data.items():
        if isinstance(value, dict):
            hcl_string += f'{indent_space}{key} = {{\n'
            hcl_string += to_hcl(value, indent + 1)
            hcl_string += f'{indent_space}}}\n'
        elif isinstance(value, list):
            hcl_string += f'{indent_space}{key} = [\n'
            for item in value:
                if isinstance(item, dict):
                    hcl_string += f'{indent_space}  {{\n'
                    hcl_string += to_hcl(item, indent + 2)
                    hcl_string += f'{indent_space}  }},\n'
                else:
                    hcl_string += f'{indent_space}  {json.dumps(item)},\n'
            hcl_string += f'{indent_space}]\n'
        elif isinstance(value, bool):
            hcl_string += f'{indent_space}{key} = {str(value).lower()}\n'
        elif isinstance(value, (int, float)):
            hcl_string += f'{indent_space}{key} = {value}\n'
        elif value is None:
             hcl_string += f'{indent_space}{key} = null\n'
        else:
            # Escape quotes and backslashes in strings
            escaped_value = str(value).replace('\\', '\\\\').replace('"', '\\"')
            hcl_string += f'{indent_space}{key} = "{escaped_value}"\n'
    return hcl_string


# --- Core Helper Functions ---

def get_ccr_command():
    """Returns the 'ccr' command and checks if it's in the system's PATH."""
    if not shutil.which("ccr"):
        raise RuntimeError("'ccr' command not found in system PATH.")
    return "ccr"

def get_repo_path_sync():
    """Gets the repo path from the ccr script, capturing stderr on failure."""
    try:
        ccr_command = get_ccr_command()
        command = f"{ccr_command} get-repo-path"
        result = subprocess.run(
            command,
            shell=True,
            capture_output=True,
            text=True,
            encoding='utf-8'
        )
        if result.returncode != 0:
            # Capture the specific error message from the script
            error_msg = result.stderr.strip()
            if not error_msg:
                error_msg = f"Command '{command}' failed with exit code {result.returncode} but no stderr output."
            return None, error_msg
        return result.stdout.strip(), None
    except Exception as e:
        print(f"Error getting repo path: {e}")
        return None, str(e)

def get_and_update_tf_file(cluster_to_update=None, new_config=None):
    """
    Reads or updates the clusters.tf file.
    - If no update params are provided, it parses and returns the file content.
    - If update params are provided, it rewrites the file.
    """
    repo_path, error = get_repo_path_sync()
    if error is not None:
        return {"error": f"Could not determine repository path: {error}"}
    
    tf_file_path = Path(repo_path) / "terraform" / "clusters.tf"
    if not tf_file_path.is_file():
        return {"error": f"Terraform file not found: {tf_file_path}"}

    try:
        with open(tf_file_path, 'r', encoding='utf-8') as f:
            tf_data = hcl2.load(f)

        clusters_variable = tf_data.get('variable', [{}])[0].get('clusters', {})
        current_clusters_config = clusters_variable.get('default', {})

        if cluster_to_update and new_config:
            if cluster_to_update not in current_clusters_config:
                return {"error": f"Cluster '{cluster_to_update}' not found in configuration."}
            
            current_clusters_config[cluster_to_update] = new_config

            with open(tf_file_path, 'r', encoding='utf-8') as f:
                original_content = f.read()
            
            start_marker = "default = {"
            start_index = original_content.find(start_marker)
            
            temp_content = original_content[start_index:]
            end_index = start_index + temp_content.rfind("}") + 1

            new_default_block = f"default = {{\n{to_hcl(current_clusters_config, 2)}  }}"
            
            final_content = original_content[:start_index] + new_default_block + original_content[end_index:]

            with open(tf_file_path, 'w', encoding='utf-8') as f:
                f.write(final_content)
            
            return {"success": True, "message": f"Updated configuration for {cluster_to_update}."}

        return current_clusters_config

    except Exception as e:
        return {"error": f"Failed to process {tf_file_path}: {e}"}


async def run_and_stream_command(websocket: WebSocket, command: str):
    try:
        process = await asyncio.create_subprocess_shell(
            command, stdout=subprocess.PIPE, stderr=subprocess.PIPE
        )
        async def stream_pipe(pipe, msg_type):
            async for line in pipe:
                await websocket.send_json({"type": msg_type, "data": line.decode('utf-8').strip()})
        await asyncio.gather(stream_pipe(process.stdout, "log"), stream_pipe(process.stderr, "log_error"))
        await process.wait()
        await websocket.send_json({"type": "command_end", "data": f"Command finished: {command}"})
    except Exception as e:
        await websocket.send_json({"type": "log_error", "data": f"Failed to execute command: {e}"})

def get_kube_contexts_sync():
    kubeconfig_path = Path.home() / ".kube" / "config"
    if not kubeconfig_path.is_file(): return []
    try:
        with open(kubeconfig_path, 'r') as f:
            return [context['name'] for context in yaml.safe_load(f).get('contexts', []) if 'name' in context]
    except Exception as e:
        return []

def get_current_context_sync():
    try:
        command = f"{get_ccr_command()} ctx"
        result = subprocess.run(command, shell=True, capture_output=True, text=True, encoding='utf-8')
        if result.returncode != 0:
            error_msg = result.stderr.strip()
            if not error_msg:
                error_msg = f"Command '{command}' failed with exit code {result.returncode} but no stderr output."
            return f"Error: {error_msg}"
        return result.stdout.strip()
    except Exception as e:
        return f"Error: {e}"

def get_nodes_sync():
    """Synchronous helper to get nodes via the ccr command with robust error handling."""
    try:
        command = f"{get_ccr_command()} list-nodes"
        result = subprocess.run(
            command,
            shell=True,
            capture_output=True,
            text=True,
            encoding='utf-8'
        )
        if result.returncode != 0:
            error_msg = result.stderr.strip()
            if not error_msg:
                error_msg = f"Command '{command}' failed with exit code {result.returncode} but no stderr output."
            return {"error": error_msg}

        if not result.stdout.strip():
            return {"error": "Command 'ccr list-nodes' returned no output. Is the current context valid and the cluster running?"}

        nodes_data = json.loads(result.stdout)
        nodes_list = []
        for item in nodes_data.get("items", []):
            name = item.get("metadata", {}).get("name", "N/A")
            status = "Unknown"
            conditions = item.get("status", {}).get("conditions", [])
            ready_condition = next((c for c in conditions if c.get("type") == "Ready"), None)
            if ready_condition: status = "Ready" if ready_condition.get("status") == "True" else "NotReady"
            labels = item.get("metadata", {}).get("labels", {})
            roles = [key.split('/')[-1] for key in labels if 'node-role.kubernetes.io' in key]
            if not roles: roles.append('worker')
            age = item.get("metadata", {}).get("creationTimestamp", "N/A")
            nodes_list.append({"name": name, "status": status, "roles": ", ".join(roles), "age": age})
        return nodes_list
    except json.JSONDecodeError:
        return {"error": "Failed to parse JSON output from 'ccr list-nodes'. The command did not return valid JSON."}
    except Exception as e:
        return {"error": f"An unexpected error occurred in get_nodes_sync: {e}"}

# --- WebSocket Endpoint ---
@app.websocket("/ws/commands")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    try:
        while True:
            message = await websocket.receive_json()
            msg_type = message.get("type")
            payload = message.get("payload", {})
            
            if msg_type == "get_initial_data":
                await websocket.send_json({"type": "tf_clusters", "data": get_and_update_tf_file()})
                await websocket.send_json({"type": "kube_contexts_list", "data": get_kube_contexts_sync()})
                await websocket.send_json({"type": "current_context", "data": get_current_context_sync()})
                await websocket.send_json({"type": "nodes_list", "data": get_nodes_sync()})

            elif msg_type == "get_nodes":
                 await websocket.send_json({"type": "nodes_list", "data": get_nodes_sync()})

            elif msg_type == "update_tf_cluster":
                cluster_name = payload.get("cluster_name")
                new_config = payload.get("config")
                
                update_result = get_and_update_tf_file(cluster_name, new_config)
                
                if update_result.get("error"):
                    await websocket.send_json({"type": "log_error", "data": update_result["error"]})
                else:
                    await websocket.send_json({"type": "log", "data": update_result["message"]})
                    ccr_command = get_ccr_command()
                    await run_and_stream_command(websocket, f"{ccr_command} tofu apply -auto-approve")
                    await websocket.send_json({"type": "tf_clusters", "data": get_and_update_tf_file()})
                    await websocket.send_json({"type": "nodes_list", "data": get_nodes_sync()})

            elif msg_type == "run_command":
                ccr_command = get_ccr_command()
                command_name = payload.get("command")
                args = payload.get("args", [])
                full_command = f"{ccr_command} {command_name} {' '.join(args)}"
                await run_and_stream_command(websocket, full_command)
                if command_name in ["ctx", "bootstrap"]:
                     await websocket.send_json({"type": "current_context", "data": get_current_context_sync()})
                     await websocket.send_json({"type": "nodes_list", "data": get_nodes_sync()})
                     await websocket.send_json({"type": "tf_clusters", "data": get_and_update_tf_file()})

    except WebSocketDisconnect:
        print("Client disconnected")
    except Exception as e:
        print(f"An error occurred in WebSocket: {e}")

# --- Root Endpoint for Frontend ---
@app.get("/")
async def read_index():
    return FileResponse('static/index.html')

if __name__ == "__main__":
    if not os.path.exists("static"): os.makedirs("static")
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
