"""Tests for the Qdrant vector database tools."""

import uuid
import pytest
from typing import Dict, List, Any

from langchain_core.messages import AIMessage, HumanMessage, SystemMessage
from langgraph.prebuilt import ToolNode

from app.config import Config
from app.tools.qdrant import qdrant_search, qdrant_store, qdrant_delete
from app.langchain_utils import initialize_tool_compatible_model_list


@pytest.mark.asyncio
async def test_qdrant_store_tool():
    """Test the Qdrant store tool."""
    test_content = f"Test content for store tool {uuid.uuid4()}"

    # Use the store tool
    result = await qdrant_store.ainvoke(test_content)

    # Verify results
    assert "Successfully stored" in result
    assert "ID" in result

    # Extract the ID for later use
    vector_id = result.split("ID: ")[1]
    return vector_id


@pytest.mark.asyncio
async def test_qdrant_search_tool():
    """Test the Qdrant search tool."""
    # First store something to search for
    test_content = f"Test content for search tool {uuid.uuid4()}"
    store_result = await qdrant_store.ainvoke(test_content)

    # Use the search tool with the first few words
    search_query = test_content.split()[:3]
    result = await qdrant_search.ainvoke(" ".join(search_query))

    # Verify results
    assert "Found semantically similar information" in result
    assert test_content in result


@pytest.mark.asyncio
async def test_qdrant_delete_tool():
    """Test the Qdrant delete tool."""
    # First store something to get an ID
    test_content = f"Test content for delete tool {uuid.uuid4()}"
    store_result = await qdrant_store.ainvoke(test_content)

    # Extract the ID from the result
    vector_id = store_result.split("ID: ")[1]

    # Delete the vector
    delete_result = await qdrant_delete.ainvoke(vector_id)

    # Verify deletion
    assert "Successfully deleted" in delete_result
    assert vector_id in delete_result

    # Verify the vector is no longer retrievable via search
    search_query = test_content.split()[:3]
    search_result = await qdrant_search.ainvoke(" ".join(search_query))
    assert test_content not in search_result


@pytest.mark.asyncio
async def test_qdrant_tool_node():
    """Test Qdrant tools via ToolNode."""
    # Create the tool node
    qdrant_tools = [qdrant_search, qdrant_store]
    tool_node = ToolNode(qdrant_tools)

    # Generate unique test content
    test_content = f"Test content for ToolNode {uuid.uuid4()}"

    # Create an AI message with store tool call
    message_with_store_call = AIMessage(
        content="",
        tool_calls=[
            {
                "name": "qdrant_store",
                "args": {"content": test_content},
                "id": "tool_call_id_1",
                "type": "function",
            }
        ],
    )

    # Invoke the tool node for store
    store_result = await tool_node.ainvoke({"messages": [message_with_store_call]})

    # Verify store execution
    assert "messages" in store_result
    assert "Successfully stored" in store_result["messages"][0].content

    # Create a search message
    search_query = test_content.split()[:3]
    message_with_search_call = AIMessage(
        content="",
        tool_calls=[
            {
                "name": "qdrant_search",
                "args": {"query": " ".join(search_query)},
                "id": "tool_call_id_2",
                "type": "function",
            }
        ],
    )

    # Invoke the tool node for search
    search_result = await tool_node.ainvoke({"messages": [message_with_search_call]})

    # Verify search execution
    assert "messages" in search_result
    assert "Found semantically similar information" in search_result["messages"][0].content
    assert test_content in search_result["messages"][0].content


@pytest.mark.asyncio
async def test_qdrant_tool_sequence():
    """Test a sequence of Qdrant tool operations."""
    # 1. Store some content
    test_content = f"Test content for sequence {uuid.uuid4()}"
    store_result = await qdrant_store.ainvoke(test_content)
    assert "Successfully stored" in store_result
    vector_id = store_result.split("ID: ")[1]

    # 2. Search for the content
    search_query = test_content.split()[:3]
    search_result = await qdrant_search.ainvoke(" ".join(search_query))
    assert test_content in search_result

    # Note: Delete will be tested later after implementing the delete method


@pytest.mark.asyncio
async def test_qdrant_tool_node_with_delete():
    """Test Qdrant delete tool via ToolNode."""
    # Create the tool node with all tools
    qdrant_tools = [qdrant_search, qdrant_store, qdrant_delete]
    tool_node = ToolNode(qdrant_tools)

    # Generate unique test content
    test_content = f"Test content for ToolNode delete {uuid.uuid4()}"

    # 1. Store content first to get an ID
    message_with_store_call = AIMessage(
        content="",
        tool_calls=[
            {
                "name": "qdrant_store",
                "args": {"content": test_content},
                "id": "tool_call_id_1",
                "type": "function",
            }
        ],
    )

    store_result = await tool_node.ainvoke({"messages": [message_with_store_call]})
    store_response = store_result["messages"][0].content

    # Extract the vector ID
    vector_id = store_response.split("ID: ")[1]

    # 2. Delete the vector
    message_with_delete_call = AIMessage(
        content="",
        tool_calls=[
            {
                "name": "qdrant_delete",
                "args": {"vector_id": vector_id},
                "id": "tool_call_id_2",
                "type": "function",
            }
        ],
    )

    delete_result = await tool_node.ainvoke({"messages": [message_with_delete_call]})

    # Verify deletion
    assert "Successfully deleted" in delete_result["messages"][0].content

    # 3. Verify the content is no longer searchable
    search_query = test_content.split()[:3]
    message_with_search_call = AIMessage(
        content="",
        tool_calls=[
            {
                "name": "qdrant_search",
                "args": {"query": " ".join(search_query)},
                "id": "tool_call_id_3",
                "type": "function",
            }
        ],
    )

    search_result = await tool_node.ainvoke({"messages": [message_with_search_call]})
    assert test_content not in search_result["messages"][0].content
