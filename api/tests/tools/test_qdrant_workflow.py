"""Tests for the Qdrant workflow integration with LangGraph."""

import uuid
import logging
import pytest
from typing import Dict, List, Any, Optional

from langchain_core.messages import AIMessage, HumanMessage, SystemMessage

from app.config import Config
from app.tools.qdrant import qdrant_search, qdrant_store, qdrant_delete
from app.tools.qdrant_workflow import create_qdrant_workflow
from app.langchain_utils import initialize_tool_compatible_model_list


@pytest.mark.asyncio
async def test_qdrant_tools_directly():
    """Test the Qdrant tools directly to verify they function before testing in the workflow."""
    # Setup logging
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger(__name__)

    # Generate unique test content
    test_content = f"Vector storage direct test content {uuid.uuid4()}"

    # Test store operation
    logger.info(f"Storing content: {test_content}")
    store_result = await qdrant_store.ainvoke(test_content)
    logger.info(f"Store result: {store_result}")

    # Verify the store worked
    assert "Successfully stored" in store_result
    vector_id = store_result.split("ID: ")[1]

    # Test search operation
    logger.info(f"Searching for content using first few words")
    search_query = " ".join(test_content.split()[:3])
    search_result = await qdrant_search.ainvoke(search_query)
    logger.info(f"Search result: {search_result[:200]} ...")

    # Verify search found the content
    assert test_content in search_result

    # Test delete operation
    logger.info(f"Deleting vector with ID: {vector_id}")
    delete_result = await qdrant_delete.ainvoke(vector_id)
    logger.info(f"Delete result: {delete_result}")

    # Verify deletion worked
    assert "Successfully deleted" in delete_result

    # Search again to verify it's gone
    second_search = await qdrant_search.ainvoke(search_query)
    assert test_content not in second_search

    logger.info("All direct tool tests passed")
    return True


@pytest.mark.asyncio
async def test_qdrant_workflow_single_model():
    """Test the end-to-end Qdrant workflow with a single model."""
    # Verify tools work directly first
    tools_working = await test_qdrant_tools_directly()
    assert tools_working, "Tools must work directly before testing in workflow"

    # Setup
    config = Config()
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger(__name__)

    # Get a tool-compatible model
    # Exclude openrouter as it might not be configured in tests
    tool_models = initialize_tool_compatible_model_list(config, disabled_providers={"openrouter"})
    if not tool_models:
        pytest.skip("No tool-compatible models available")

    model_config = tool_models[0]
    logger.info(f"Testing with model: {model_config}")

    # Create the workflow
    workflow = create_qdrant_workflow(model_config=model_config, config=config)

    # Test store with more explicit instructions
    test_content = f"Vector storage test content {uuid.uuid4()}"

    # Use a more specific system message and instructions
    system_message = SystemMessage(
        content=(
            "You are a helpful assistant with access to vector database operations. "
            "You have three tools available:\n"
            "1. qdrant_store - to store information in the database\n"
            "2. qdrant_search - to search for information\n"
            "3. qdrant_delete - to delete information\n"
            "Use these tools when explicitly asked."
        )
    )

    human_message = HumanMessage(
        content=(
            f"I need you to store the following text in the database using the qdrant_store tool. "
            f"Here is the exact text to store: '{test_content}'. "
            f"Do not paraphrase or modify the text. Just call the qdrant_store tool with this text."
        )
    )

    # Run the workflow for storage
    logger.info("Starting workflow for storage operation")
    store_result = await workflow.ainvoke({"messages": [system_message, human_message]})

    # Log all messages for debugging
    logger.info("Response details:")
    for i, msg in enumerate(store_result["messages"]):
        logger.info(f"Message {i}: {type(msg).__name__}")
        logger.info(f"  Content: {msg.content[:100]}...")
        if hasattr(msg, "tool_calls") and msg.tool_calls:
            logger.info(f"  Tool calls: {msg.tool_calls}")

    # Check if any message contains the confirmation of storage
    found_store_confirmation = False
    vector_id = None

    for msg in store_result["messages"]:
        if "Successfully stored" in msg.content:
            found_store_confirmation = True
            # Try to extract the vector ID
            try:
                vector_id = msg.content.split("ID: ")[1].strip()
                logger.info(f"Found vector ID: {vector_id}")
            except (IndexError, AttributeError):
                pass
            break

    assert found_store_confirmation, "Storage confirmation not found in any message"

    # If we have a vector ID, test search and delete operations
    if vector_id:
        # Test search
        search_message = HumanMessage(
            content=(
                f"Use the qdrant_search tool to search for information containing the words "
                f"'{' '.join(test_content.split()[:3])}'"
            )
        )

        search_result = await workflow.ainvoke({"messages": store_result["messages"] + [search_message]})

        # Check if search results contain the original text
        search_found = False
        for msg in search_result["messages"]:
            if test_content in msg.content:
                search_found = True
                break

        assert search_found, "Search operation did not find the stored content"
        logger.info("Search operation successful")

        # Test delete
        delete_message = HumanMessage(
            content=f"Use the qdrant_delete tool to delete the vector with ID: {vector_id}"
        )

        delete_result = await workflow.ainvoke({"messages": search_result["messages"] + [delete_message]})

        # Check if delete was successful
        delete_success = False
        for msg in delete_result["messages"]:
            if "Successfully deleted" in msg.content and vector_id in msg.content:
                delete_success = True
                break

        assert delete_success, "Delete operation did not complete successfully"
        logger.info("Delete operation successful")

        logger.info("All workflow operations completed successfully")
    else:
        # If we didn't get a vector ID but the store confirmation was found
        # This is a partial success
        logger.warning("Store operation confirmed but couldn't extract vector ID for further tests")


@pytest.mark.asyncio
async def test_multi_model_compatibility():
    """Test Qdrant tools with multiple model providers."""
    config = Config()
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger(__name__)

    # Get tool-compatible models
    tool_models = initialize_tool_compatible_model_list(config, disabled_providers={"openrouter"})

    if len(tool_models) < 2:
        pytest.skip("At least 2 different tool-compatible models needed for multi-model testing")

    # Limit to at most 3 models for test duration
    if len(tool_models) > 3:
        tool_models = tool_models[:3]

    results = {}
    for model_config in tool_models:
        try:
            logger.info(f"Testing with model: {model_config}")

            # Create workflow with this model
            workflow = create_qdrant_workflow(model_config=model_config, config=config)

            # Test basic operations
            test_content = f"Test for {model_config}: Vector data {uuid.uuid4()}"
            system_message = SystemMessage(content=(
                "You are a helpful assistant with access to vector database operations. "
                "Use the qdrant_store tool to store information when asked."
            ))

            # Store content
            store_message = HumanMessage(content=f"Please store this exact text: '{test_content}'")

            store_result = await workflow.ainvoke({
                "messages": [system_message, store_message]
            })

            # Check if storage was successful and extract vector ID
            vector_id = None
            store_success = False

            for msg in store_result["messages"]:
                if "Successfully stored" in msg.content:
                    store_success = True
                    try:
                        vector_id = msg.content.split("ID: ")[1].strip()
                        logger.info(f"Found vector ID: {vector_id}")
                    except (IndexError, AttributeError):
                        pass
                    break

            # Search for content
            search_success = False
            if store_success:
                search_message = HumanMessage(
                    content=f"Use the qdrant_search tool to find information about: {test_content[:20]}"
                )

                search_result = await workflow.ainvoke({
                    "messages": store_result["messages"] + [search_message]
                })

                # Check if search returned the original content
                for msg in search_result["messages"]:
                    if test_content in msg.content:
                        search_success = True
                        break

            # Delete if we have a vector ID
            delete_success = False
            if vector_id:
                delete_message = HumanMessage(
                    content=f"Delete the vector with ID: {vector_id} using the qdrant_delete tool"
                )

                delete_result = await workflow.ainvoke({
                    "messages": store_result["messages"] + [delete_message]
                })

                # Check if deletion was successful
                for msg in delete_result["messages"]:
                    if "Successfully deleted" in msg.content and vector_id in msg.content:
                        delete_success = True
                        break

            # Record results
            results[str(model_config)] = {
                "store_success": store_success,
                "search_success": search_success,
                "delete_success": delete_success if vector_id else None
            }

        except Exception as e:
            logger.error(f"Error testing {model_config}: {str(e)}")
            results[str(model_config)] = {"error": str(e)}

    # Generate report
    logger.info("\n===== Model Compatibility Report =====")
    for model, result in results.items():
        logger.info(f"\n{model}:")
        if "error" in result:
            logger.info(f"  ❌ Error: {result['error']}")
        else:
            logger.info(f"  Store: {'✅' if result['store_success'] else '❌'}")
            logger.info(f"  Search: {'✅' if result['search_success'] else '❌'}")
            logger.info(f"  Delete: {'✅' if result['delete_success'] else '❌' if result['delete_success'] == False else '⚠️ Not tested'}")

    # Make sure at least one model succeeded completely
    assert any(
        result.get("store_success") and result.get("search_success") and result.get("delete_success")
        for model, result in results.items() if "error" not in result
    ), "No model completed all operations successfully"


if __name__ == "__main__":
    import asyncio
    logging.basicConfig(level=logging.INFO)
    asyncio.run(pytest.main(["-xvs", __file__]))
