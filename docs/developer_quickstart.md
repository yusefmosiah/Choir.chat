# Developer Quickstart: Building Your First Choir MCP Server (Python)

Welcome to the Choir developer quickstart! This guide will walk you through building a simple Model Context Protocol (MCP) server using the Python SDK, specifically tailored for the Choir platform. By the end of this guide, you'll have a basic MCP server running that you can connect to a client and start extending with your own Choir phase logic.

**Prerequisites:**

*   **Python 3.10+ Installed:** Ensure you have Python 3.10 or a later version installed on your system.
*   **uv Package Manager (Recommended):** We recommend using `uv` for Python package management. If you don't have it installed, follow the instructions [here](https://astral.sh/uv).
*   **Basic Python Knowledge:** Familiarity with Python syntax and asynchronous programming (`async/await`) is helpful.
*   **Understanding of MCP Core Concepts (Recommended):** While not strictly required, it's beneficial to have a basic understanding of MCP concepts like servers, clients, tools, and resources. You can review the [Core Architecture documentation](/docs/concepts/architecture) for a quick overview.

**Step 1: Set Up Your Development Environment**

1.  **Create a Project Directory:**
    ```bash
    mkdir choir-mcp-server-quickstart
    cd choir-mcp-server-quickstart
    ```

2.  **Create a Virtual Environment (using uv):**
    ```bash
    uv venv
    source .venv/bin/activate  # On Linux/macOS
    .venv\Scripts\activate     # On Windows
    ```

3.  **Install the MCP Python SDK and httpx (for our example):**
    ```bash
    uv add "mcp[cli]" httpx
    ```

4.  **Create Your Server File:**
    ```bash
    touch server.py
    ```

**Step 2: Build a Basic MCP Server in Python**

Open `server.py` in your code editor and paste the following code:

```python
import asyncio
import httpx
import mcp.types as types
from mcp.server import Server
from mcp.server.stdio import stdio_server

# Initialize MCP Server
app = Server("choir-quickstart-server")

# National Weather Service API Base URL
NWS_API_BASE = "https://api.weather.gov"

@app.list_tools()
async def list_tools() -> list[types.Tool]:
    """Declare the tools this server provides."""
    return [
        types.Tool(
            name="get_alerts",
            description="Get weather alerts for a US state. Input is Two-letter US state code (e.g. CA, NY)",
            inputSchema={
                "type": "object",
                "properties": {
                    "state": {"type": "string", "description": "Two-letter US state code (e.g. CA, NY)"}
                },
                "required": ["state"]
            }
        ),
        types.Tool(
            name="get_forecast",
            description="Get weather forecast for a specific latitude/longitude",
            inputSchema={
                "type": "object",
                "properties": {
                    "latitude": {"type": "number", "description": "Latitude of the location"},
                    "longitude": {"type": "number", "description": "Longitude of the location"},
                },
                "required": ["latitude", "longitude"]
            }
        ),
    ]

@app.call_tool()
async def call_tool(name: str, arguments: dict) -> list[types.TextContent | types.ImageContent | types.EmbeddedResource]:
    """Implement tool execution logic."""
    if name == "get_alerts":
        state = arguments.get("state")
        if not state:
            return [types.TextContent(type="text", text="Error: Missing 'state' argument.")]
        return await get_weather_alerts(state)
    elif name == "get_forecast":
        latitude = arguments.get("latitude")
        longitude = arguments.get("longitude")
        if not latitude or not longitude:
            return [types.TextContent(type="text", text="Error: Missing 'latitude' or 'longitude' arguments.")]
        return await get_weather_forecast(latitude, longitude)
    else:
        return [types.TextContent(type="text", text=f"Error: Tool '{name}' not found.")]


async def get_weather_alerts(state: str) -> list[types.TextContent]:
    """Helper function to fetch weather alerts from NWS API."""
    url = f"{NWS_API_BASE}/alerts/active/area/{state.upper()}"
    async with httpx.AsyncClient() as client:
        response = await client.get(url)
        if response.status_code == 200:
            data = response.json()
            if data and data["features"]:
                alerts = [feature["properties"]["event"] for feature in data["features"]]
                return [types.TextContent(type="text", text=f"Weather alerts for {state.upper()}: {', '.join(alerts)}")]
            else:
                return [types.TextContent(type="text", text=f"No active weather alerts found for {state.upper()}")]
        else:
            return [types.TextContent(type="text", text=f"Error fetching weather alerts for {state.upper()}")]


async def get_weather_forecast(latitude: float, longitude: float) -> list[types.TextContent]:
    """Helper function to fetch weather forecast from NWS API."""
    points_url = f"{NWS_API_BASE}/points/{latitude},{longitude}"
    async with httpx.AsyncClient() as client:
        points_response = await client.get(points_url)
        if points_response.status_code == 200:
            points_data = points_response.json()
            forecast_url = points_data["properties"]["forecast"]
            forecast_response = await client.get(forecast_url)
            if forecast_response.status_code == 200:
                forecast_data = forecast_response.json()
                periods = forecast_data["properties"]["periods"]
                forecast_text = "\n".join([f"{p['name']}: {p['shortForecast']}, Temperature: {p['temperature']}°{p['temperatureUnit']}" for p in periods[:3]]) # Show next 3 periods
                return [types.TextContent(type="text", text=f"Weather forecast for {latitude}, {longitude}:\n{forecast_text}")]
            else:
                return [types.TextContent(type="text", text=f"Error fetching forecast data.")]
        else:
            return [types.TextContent(type="text", text=f"Error fetching location data.")]


async def main():
    """Main function to run the MCP server."""
    async with stdio_server() as streams:
        await app.run(
            streams[0],
            streams[1],
            app.create_initialization_options()
        )

if __name__ == "__main__":
    asyncio.run(main)
Use code with caution.
Markdown
Step 3: Run Your MCP Server

Open your terminal in the choir-mcp-server-quickstart directory.

Run the server using the mcp run command (provided by the mcp[cli] package):

mcp run server.py
Use code with caution.
Bash
You should see output indicating that your server is running and connected via stdio.

Step 4: Test Your Server with MCP Inspector

To test your server interactively, we'll use the MCP Inspector tool.

Open a new terminal window (leave your server running in the first terminal).

Run the MCP Inspector using npx:

npx @modelcontextprotocol/inspector
Use code with caution.
Bash
In the Inspector UI:

Connection Pane: Select "Stdio Transport". The "Command" field should be pre-filled with something like node ...inspector/inspector.js. Replace the entire "Command" field with: uv run path/to/your/server.py. Make sure to replace path/to/your/server.py with the absolute path to your server.py file (e.g., /Users/yourusername/choir-mcp-server-quickstart/server.py).

Click "Connect".

If connection is successful: You should see the "Resources", "Prompts", and "Tools" tabs become active.

If connection fails: Check the "Notifications" pane in the Inspector for error messages and double-check your server path and configuration.

Explore the "Tools" Tab:

You should see the two tools you defined in your server: get_alerts and get_forecast.

Click on get_alerts. You'll see the "Input Schema" for the state argument.

Enter a two-letter US state code (e.g., CA) in the "state" input field.

Click "Call Tool".

You should see the tool execution result in the "Output" pane, displaying weather alerts for California (or an error message if there are issues).

Experiment with the get_forecast tool, providing latitude and longitude coordinates.

Congratulations! You've built and tested your first Choir MCP server!

Key Takeaways:

MCP Server Structure: You've seen the basic structure of an MCP server using the Python SDK, including:

Initializing the Server instance.

Using decorators (@app.list_tools(), @app.call_tool()) to define tools and their handlers.

Using stdio_server() to connect to the stdio transport.

Tool Definition and Execution: You've learned how to:

Define MCP tools with types.Tool and JSON Schemas for input arguments.

Implement tool execution logic in Python functions decorated with @app.call_tool().

Return tool results as types.TextContent or other content types.

Testing with MCP Inspector: You've used the MCP Inspector to interactively test your server, list tools, call tools, and view results.

Next Steps:

Explore Resources and Prompts: Extend your server to implement MCP resources and prompts, following the examples in the MCP documentation.

Integrate with Real-World Data Sources: Connect your MCP server to your own data sources, APIs, or databases to build more useful and personalized tools and resources.

Build More Complex Tools and Workflows: Create more sophisticated MCP tools that perform complex operations, orchestrate multiple steps, or interact with external systems in more advanced ways.

Connect to Claude Desktop (or other MCP Clients): Configure Claude Desktop (or other MCP clients) to connect to your server and use your custom tools and resources within a real AI application environment.

Dive Deeper into MCP Documentation: Explore the full MCP documentation to learn about advanced features, transports, security considerations, and best practices for building robust and scalable MCP integrations.
