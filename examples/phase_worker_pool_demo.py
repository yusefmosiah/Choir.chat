#!/usr/bin/env python
"""
Phase Worker Pool Demonstration

This script demonstrates the Phase Worker Pool architecture by setting up
and running a simple example of processing different modalities through
the PostChain.
"""

import asyncio
import logging
from typing import Dict, Any

from choir.actor_model.phase_worker_pool import (
    PhaseType, PhaseTypeRegistry, WorkerPoolManager, WorkerPool,
    ModelWorker, ActorFactory, ModalityDetector, PostChain,
    TextActionActor, AudioActionActor, VideoActionActor, CodeActionActor,
    TextActionState, AudioActionState, VideoActionState, CodeActionState,
    Message, MessageType
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Example specialized Experience actors for different domains
class TextExperienceActor(TextActionActor):
    """Text-based Experience actor"""

    async def process(self, message: Message) -> Any:
        input_data = message.content["input"]
        action_result = message.content["action_result"]

        if self.worker_pool:
            result = await self.worker_pool.process_task({
                "type": "knowledge_retrieval",
                "content": input_data,
                "parameters": {"max_results": 5}
            })
        else:
            result = f"Retrieved knowledge for: {input_data[:30]}..."

        return {"enriched_response": f"{action_result} + knowledge context", "retrieved_docs": result}

class MedicalExperienceActor(TextExperienceActor):
    """Specialized Experience actor for medical domain"""

    async def process(self, message: Message) -> Any:
        result = await super().process(message)
        result["domain"] = "medical"
        result["enriched_response"] += " (with medical expertise)"
        return result

class LegalExperienceActor(TextExperienceActor):
    """Specialized Experience actor for legal domain"""

    async def process(self, message: Message) -> Any:
        result = await super().process(message)
        result["domain"] = "legal"
        result["enriched_response"] += " (with legal expertise)"
        return result

class FinancialExperienceActor(TextExperienceActor):
    """Specialized Experience actor for financial domain"""

    async def process(self, message: Message) -> Any:
        result = await super().process(message)
        result["domain"] = "financial"
        result["enriched_response"] += " (with financial expertise)"
        return result


async def setup_workers() -> WorkerPoolManager:
    """Set up worker pools with various model configurations"""
    manager = WorkerPoolManager()

    # Create text worker pools
    text_action_pool = WorkerPool("text_action_pool", ModelWorker)
    text_action_pool.add_worker(ModelWorker("text1", "gpt-4", ["text", "chat"]))
    text_action_pool.add_worker(ModelWorker("text2", "claude-3-opus", ["text", "chat"]))
    manager.register_pool(text_action_pool)

    # Create specialized domain pools
    medical_pool = WorkerPool("text_experience_medical_pool", ModelWorker)
    medical_pool.add_worker(ModelWorker("med1", "medical-llm", ["text", "medical"]))
    manager.register_pool(medical_pool)

    legal_pool = WorkerPool("text_experience_legal_pool", ModelWorker)
    legal_pool.add_worker(ModelWorker("legal1", "legal-llm", ["text", "legal"]))
    manager.register_pool(legal_pool)

    financial_pool = WorkerPool("text_experience_financial_pool", ModelWorker)
    financial_pool.add_worker(ModelWorker("fin1", "financial-llm", ["text", "financial"]))
    manager.register_pool(financial_pool)

    # Create audio worker pools
    audio_action_pool = WorkerPool("audio_action_pool", ModelWorker)
    audio_action_pool.add_worker(ModelWorker("audio1", "whisper", ["audio", "transcription"]))
    manager.register_pool(audio_action_pool)

    # Create video worker pools
    video_action_pool = WorkerPool("video_action_pool", ModelWorker)
    video_action_pool.add_worker(ModelWorker("video1", "clip", ["video", "vision"]))
    manager.register_pool(video_action_pool)

    # Create code worker pools
    code_action_pool = WorkerPool("code_action_pool", ModelWorker)
    code_action_pool.add_worker(ModelWorker("code1", "code-llm", ["code", "completion"]))
    manager.register_pool(code_action_pool)

    return manager

async def setup_registry() -> PhaseTypeRegistry:
    """Set up actor registry with different implementations"""
    registry = PhaseTypeRegistry()

    # Register Action actors for different modalities
    registry.register_actor(PhaseType.ACTION, "text", TextActionActor)
    registry.register_actor(PhaseType.ACTION, "audio", AudioActionActor)
    registry.register_actor(PhaseType.ACTION, "video", VideoActionActor)
    registry.register_actor(PhaseType.ACTION, "code", CodeActionActor)

    # Register specialized Experience actors
    registry.register_actor(PhaseType.EXPERIENCE, "text", TextExperienceActor)
    registry.register_actor(PhaseType.EXPERIENCE, "medical", MedicalExperienceActor)
    registry.register_actor(PhaseType.EXPERIENCE, "legal", LegalExperienceActor)
    registry.register_actor(PhaseType.EXPERIENCE, "financial", FinancialExperienceActor)

    # Register default implementations for other phases
    # In a real system, you would have specialized implementations for each phase and modality
    registry.register_actor(PhaseType.INTENTION, "default", TextActionActor)
    registry.register_actor(PhaseType.OBSERVATION, "default", TextActionActor)
    registry.register_actor(PhaseType.UNDERSTANDING, "default", TextActionActor)
    registry.register_actor(PhaseType.YIELD, "default", TextActionActor)

    return registry

async def process_examples(post_chain: PostChain):
    """Process different example inputs through the chain"""

    # Text example
    logger.info("Processing text input...")
    text_result = await post_chain.process("What is the capital of France?")
    logger.info(f"Text result: {text_result}")

    # Code example
    logger.info("\nProcessing code input...")
    code_input = """def fibonacci(n):
    if n <= 1:
        return n
    else:
        return fibonacci(n-1) + fibonacci(n-2)
    """
    code_result = await post_chain.process(code_input)
    logger.info(f"Code result: {code_result}")

    # Simulated audio example
    logger.info("\nProcessing audio input...")
    audio_input = {"audio": "sample_audio_data", "sample_rate": 16000}
    audio_result = await post_chain.process(audio_input)
    logger.info(f"Audio result: {audio_result}")

    # Simulated video example
    logger.info("\nProcessing video input...")
    video_input = {"video": "sample_video_data", "frame_rate": 30}
    video_result = await post_chain.process(video_input)
    logger.info(f"Video result: {video_result}")

async def main():
    """Main function to run the demonstration"""
    logger.info("Setting up Phase Worker Pool demonstration")

    # Set up the worker pools
    worker_pool_manager = await setup_workers()

    # Set up the actor registry
    registry = await setup_registry()

    # Create actor factory
    factory = ActorFactory(registry, worker_pool_manager)

    # Create modality detector
    modality_detector = ModalityDetector()

    # Create PostChain orchestrator
    post_chain = PostChain(factory, modality_detector)

    # Process examples
    await process_examples(post_chain)

    logger.info("Demonstration completed")

if __name__ == "__main__":
    asyncio.run(main())
