Okay, this is a solid and well-reasoned plan. The "Reward-Safety-First" approach is definitely the correct priority. Let's refine this into a new plan with pseudocode snippets for key implementation parts.

Postchain Retry Implementation Plan (v2 - With Pseudocode)

This plan outlines atomic steps for implementing a safe retry mechanism for postchain phases in Choir. Each step results in a valid build and can be deployed independently. Rewards are made idempotent first, then retry logic is layered on.

Core Idea: Client manages retry attempts. When a phase fails, the client can re-trigger the entire Postchain workflow for the original user query. Backend reward issuance functions will be idempotent.

1. Reward Operation ID Generation & Logging (Backend)

Description: Backend reward operations generate a unique internal_operation_id for each attempt to issue a reward. This ID is logged and returned in the reward response JSON. This ID tracks an attempt, not necessarily a successful on-chain transaction yet.

Result: Backend generates and returns internal_operation_id for reward attempts.

# Pseudocode for RewardsService (conceptual part of issue_novelty_reward)
import uuid
import logging

logger = logging.getLogger(__name__)

class RewardsService:
    # ... (other methods like calculate_novelty_reward)

    async def issue_novelty_reward(self, wallet_address: str, max_similarity: float, message_id: str, /*... other params ...*/) -> Dict[str, Any]:
        internal_operation_id = str(uuid.uuid4())
        logger.info(f"Initiating novelty reward operation {internal_operation_id} for message {message_id}, wallet {wallet_address}")

        # ... (existing logic to calculate reward_amount) ...
        reward_amount = await self.calculate_novelty_reward(max_similarity)

        if reward_amount <= 0:
            return {
                "success": False,
                "status": "skipped_low_novelty",
                "internal_operation_id": internal_operation_id,
                # ... other fields
            }

        # ... (logic to call self.sui_service.mint_choir) ...
        sui_result = await self.sui_service.mint_choir(wallet_address, reward_amount)

        response = {
            "success": sui_result["success"],
            "internal_operation_id": internal_operation_id,
            "sui_transaction_digest": sui_result.get("digest"),
            "reward_amount": reward_amount,
            "status": "sui_attempted" if sui_result["success"] else "sui_failed",
            "error": sui_result.get("error")
            # ... other fields
        }
        logger.info(f"Novelty reward operation {internal_operation_id} result: {response}")
        return response

    async def issue_citation_rewards(self, citing_wallet_address: str, cited_vector_ids: List[str], citing_message_id: str, /*... other params ...*/) -> Dict[str, Any]:
        batch_operation_id = str(uuid.uuid4())
        logger.info(f"Initiating citation rewards batch operation {batch_operation_id} for message {citing_message_id}")

        individual_reward_results = []
        total_reward_amount_issued_in_batch = 0
        any_success_in_batch = False

        for vector_id in cited_vector_ids:
            # ... (determine author_wallet_address for vector_id) ...
            author_wallet_address = "author_wallet_for_" + vector_id # Placeholder
            if not author_wallet_address or author_wallet_address == citing_wallet_address:
                continue

            individual_op_id = str(uuid.uuid4())
            # ... (calculate reward_amount_for_citation, e.g., 0.5 CHOIR) ...
            reward_amount_for_citation = 500_000_000 # 0.5 CHOIR

            sui_result = await self.sui_service.mint_choir(author_wallet_address, reward_amount_for_citation)

            op_result = {
                "cited_vector_id": vector_id,
                "author_wallet_address": author_wallet_address,
                "success": sui_result["success"],
                "internal_operation_id": individual_op_id,
                "sui_transaction_digest": sui_result.get("digest"),
                "error": sui_result.get("error")
            }
            individual_reward_results.append(op_result)
            if sui_result["success"]:
                total_reward_amount_issued_in_batch += reward_amount_for_citation
                any_success_in_batch = True

        logger.info(f"Citation rewards batch {batch_operation_id} results: {individual_reward_results}")
        return {
            "success": any_success_in_batch, # Overall success if at least one citation reward succeeded
            "batch_operation_id": batch_operation_id,
            "total_reward_amount_issued": total_reward_amount_issued_in_batch,
            "individual_rewards": individual_reward_results
        }

# Pseudocode for run_langchain_postchain_workflow (conceptual)

async def run_experience_vectors_phase(messages: List[BaseMessage], model_config: ModelConfig, thread_id: str, user_id: Optional[str], wallet_address: Optional[str]) -> ExperienceVectorsPhaseOutput:
    # ...
    rewards_service = RewardsService()
    # Assume novelty_reward_info is the dict returned by issue_novelty_reward
    novelty_reward_info = await rewards_service.issue_novelty_reward(wallet_address, max_similarity, message_id="some_message_id_context")
    # ...
    # Ensure ExperienceVectorsPhaseOutput.novelty_reward can store this dict or relevant parts
    # novelty_reward_info now contains internal_operation_id
    return ExperienceVectorsPhaseOutput(
        # ...,
        novelty_reward_info=novelty_reward_info # Pass the whole dict
    )

async def run_yield_phase(messages: List[BaseMessage], model_config: ModelConfig, user_id: Optional[str], wallet_address: Optional[str]) -> YieldPhaseOutput:
    # ...
    rewards_service = RewardsService()
    # Assume citation_reward_info is the dict returned by issue_citation_rewards
    citation_reward_info = await rewards_service.issue_citation_rewards(wallet_address, citations, message_id="some_message_id_context")
    # ...
    # Ensure YieldPhaseOutput.citation_reward can store this dict or relevant parts
    # citation_reward_info now contains batch_operation_id and individual_rewards with their own internal_operation_ids
    return YieldPhaseOutput(
        # ...,
        citation_reward_info=citation_reward_info # Pass the whole dict
    )

# In run_langchain_postchain_workflow, when yielding events:
# The 'novelty_reward' and 'citation_reward' fields in the event payload
# will now naturally include the internal_operation_id(s).
# For example:
# response_obj["novelty_reward"] = exp_vectors_output.novelty_reward_info # This dict has the ID
# response_obj["citation_reward"] = yield_result.citation_reward_info # This dict has the ID(s)
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Python name=api/app/postchain/langchain_workflow.py
IGNORE_WHEN_COPYING_END
2. Client Reward Operation ID Tracking

Description: Client parses internal_operation_id from reward responses (within PostchainEvent.novelty_reward and PostchainEvent.citation_reward dictionaries) and stores it in the Message model, associated with the specific reward and phase. Basic UI indicator for rewarded status.

Result: Client displays and stores internal_operation_ids for rewards.

// Pseudocode for Message class
class Message: ObservableObject /* ... */ {
    // ...
    // Store operation IDs, mapping Phase to a dictionary of reward type to operation ID
    // e.g., [.experienceVectors: ["novelty_reward_operation_id": "uuid1"]]
    // e.g., [.yield: ["citation_batch_operation_id": "uuid_batch", "cited_vector_op_ids": ["vec_id1": "uuid_cite1"]]]
    @Published var rewardOperationDetails: [Phase: [String: AnyCodable]] = [:]
    // ...

    // Existing updatePhase or a new method to handle PostchainEvent
    func processPostchainEvent(_ event: PostchainEvent, forPhase phase: Phase) {
        // ... (update content, provider, modelName, etc.)

        if let noveltyRewardData = event.noveltyReward, phase == .experienceVectors {
            // noveltyRewardData is a [String: Any] dictionary from the API
            // It should contain "internal_operation_id"
            self.rewardOperationDetails[phase, default: [:]]["novelty_reward_info"] = AnyCodable(noveltyRewardData)
            // For UI indication, you might pull out status or sui_transaction_digest here
            // self.noveltyRewardStatus = noveltyRewardData["status"] as? String
        }

        if let citationRewardData = event.citationReward, phase == .yield {
            // citationRewardData is a [String: Any] dictionary
            // It should contain "batch_operation_id" and "individual_rewards" list
            self.rewardOperationDetails[phase, default: [:]]["citation_reward_info"] = AnyCodable(citationRewardData)
            // For UI indication
            // self.citationRewardStatus = citationRewardData["status"] as? String
        }

        objectWillChange.send()
    }
}
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Swift name=Choir/Models/ConversationModels.swift
IGNORE_WHEN_COPYING_END
// Pseudocode for PostchainViewModel
// In updatePhaseData or a similar method that processes PostchainEvent
func handleEvent(_ event: PostchainEvent, forMessage message: Message) {
    let phaseEnum = Phase.from(event.phase) ?? .action // Map string to enum
    message.processPostchainEvent(event, forPhase: phaseEnum)
    // ... (update other VM properties)
}
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Swift name=Choir/ViewModels/PostchainViewModel.swift
IGNORE_WHEN_COPYING_END
3. Reward Transaction Database (Backend)

Description: Add RewardTransaction table (e.g., reward_transactions) to Qdrant (or a relational DB if preferred for transactional integrity, though Qdrant can work if schema is flat). This table tracks each reward attempt using internal_operation_id as primary key (or a Qdrant point ID mapping to it), idempotency_key, status (pending, success, failed), sui_transaction_digest, reward_amount, error_message, timestamps.

Modify backend RewardsService to create a pending record before calling SUI, and update it to success (with Sui digest) or failed after.

Result: Backend stores RewardTransaction records.

# Pydantic model for RewardTransaction (already provided in previous response, ensure it's used)
# See 'api/app/models/rewards.py' from previous response for RewardTransaction model
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Python name=api/app/models/rewards.py
IGNORE_WHEN_COPYING_END
# Pseudocode for DatabaseClient
class DatabaseClient:
    # ...
    async def create_reward_transaction(self, reward_tx_data: Dict[str, Any]) -> RewardTransaction:
        # Upsert point into QDRANT_REWARD_TRANSACTIONS_COLLECTION
        # Point ID could be reward_tx_data["transaction_id"] (internal_operation_id)
        # Payload contains all fields from reward_tx_data
        # Returns the created/updated RewardTransaction object
        logger.info(f"DB: Creating reward transaction: {reward_tx_data['transaction_id']}")
        # ... Qdrant upsert logic ...
        return RewardTransaction(**reward_tx_data) # Assuming conversion for simplicity

    async def update_reward_transaction_status(self, internal_operation_id: str, status: str, sui_digest: Optional[str] = None, error_msg: Optional[str] = None):
        # Fetch existing point by internal_operation_id
        # Update payload fields: status, sui_transaction_digest, error_message, updated_at
        # Upsert the point
        logger.info(f"DB: Updating reward transaction {internal_operation_id} to status {status}")
        # ... Qdrant update/upsert logic ...

    async def get_reward_transaction_by_idempotency_key(self, idempotency_key: str) -> Optional[RewardTransaction]:
        # Scroll/Search QDRANT_REWARD_TRANSACTIONS_COLLECTION
        # Filter by payload.idempotency_key == idempotency_key
        # If multiple, potentially get the latest or one with 'success' status
        logger.info(f"DB: Getting reward transaction by idempotency key: {idempotency_key}")
        # ... Qdrant search logic ...
        # return RewardTransaction(**found_payload) or None

    async def get_reward_transaction_by_operation_id(self, internal_operation_id: str) -> Optional[RewardTransaction]:
        # Retrieve point by internal_operation_id (if it's the Qdrant point ID)
        # Or search by payload.transaction_id == internal_operation_id
        logger.info(f"DB: Getting reward transaction by operation ID: {internal_operation_id}")
        # ... Qdrant retrieve/search logic ...
        # return RewardTransaction(**found_payload) or None
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Python name=api/app/database.py
IGNORE_WHEN_COPYING_END

(Qdrant collection for rewards: choir_reward_transactions)

4. Transaction Verification API (Backend)

Description: Add API endpoint /api/rewards/transaction_status/{internal_operation_id}. Client can query this to get the status of a reward operation, including the Sui digest if successful.

Result: Client can verify reward status.

# Suggested new file
from fastapi import APIRouter, HTTPException, Depends
from app.database import DatabaseClient
from app.config import Config
from app.models.rewards import RewardTransaction # Assuming RewardTransaction model
from typing import Optional
import uuid

router = APIRouter(prefix="/api/rewards", tags=["rewards"])
db_client = DatabaseClient(Config.from_env()) # Initialize or inject

@router.get("/transaction_status/{internal_operation_id}", response_model=Optional[RewardTransaction])
async def get_reward_transaction_status(internal_operation_id: uuid.UUID):
    # internal_operation_id_str = str(internal_operation_id) # If needed for DB query
    reward_tx = await db_client.get_reward_transaction_by_operation_id(str(internal_operation_id))
    if not reward_tx:
        raise HTTPException(status_code=404, detail="Reward transaction not found")
    return reward_tx
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Python name=api/app/routers/rewards.py
IGNORE_WHEN_COPYING_END

Modify api/main.py to include this new router.

5. Idempotent Novelty Rewards (Backend)

Description: Modify RewardsService.issue_novelty_reward():

Construct an idempotency_key (e.g., f"novelty:{message_id}:{wallet_address}").

Check RewardTransaction table for this idempotency_key with status="success".

If found, return existing success (with its internal_operation_id and sui_transaction_digest).

Else, generate new internal_operation_id, create pending RewardTransaction record, call SUI, then update record to success or failed.

Response indicates if reward was newly_issued or already_issued.

Result: Novelty rewards are idempotent.

# Pseudocode for RewardsService.issue_novelty_reward (refined from Step 1)
async def issue_novelty_reward(self, wallet_address: str, max_similarity: float, message_id: str) -> Dict[str, Any]:
    idempotency_key = f"novelty:{message_id}:{wallet_address}"

    existing_tx = await self.db_client.get_reward_transaction_by_idempotency_key(idempotency_key)
    if existing_tx and existing_tx.status == "success" and existing_tx.sui_transaction_digest:
        logger.info(f"Novelty reward for {idempotency_key} already issued (op_id: {existing_tx.transaction_id}, sui_digest: {existing_tx.sui_transaction_digest})")
        return {
            "success": True,
            "status": "already_issued",
            "internal_operation_id": str(existing_tx.transaction_id),
            "sui_transaction_digest": existing_tx.sui_transaction_digest,
            "reward_amount": existing_tx.reward_amount,
            # ... other relevant fields from existing_tx
        }

    internal_operation_id = uuid.uuid4()
    logger.info(f"Attempting novelty reward (op_id: {internal_operation_id}) for {idempotency_key}")

    reward_amount = await self.calculate_novelty_reward(max_similarity)
    if reward_amount <= 0:
        # Log this attempt as skipped in reward_transactions if desired, or just return
        # For simplicity here, we'll just return. A 'skipped' status could be added to RewardTransaction.
        return {
            "success": False, "status": "skipped_low_novelty",
            "internal_operation_id": str(internal_operation_id), "reward_amount": 0
        }

    await self.db_client.create_reward_transaction({
        "transaction_id": internal_operation_id, "idempotency_key": idempotency_key,
        "reward_type": "novelty", "wallet_address": wallet_address, "message_id": message_id,
        "status": "pending", "reward_amount": reward_amount
    })

    try:
        sui_result = await self.sui_service.mint_choir(wallet_address, reward_amount)
        if sui_result["success"]:
            await self.db_client.update_reward_transaction_status(
                str(internal_operation_id), "success", sui_digest=sui_result["digest"]
            )
            return {
                "success": True, "status": "newly_issued",
                "internal_operation_id": str(internal_operation_id),
                "sui_transaction_digest": sui_result["digest"], "reward_amount": reward_amount
            }
        else:
            await self.db_client.update_reward_transaction_status(
                str(internal_operation_id), "failed", error_msg=sui_result.get("error")
            )
            return {
                "success": False, "status": "sui_failed",
                "internal_operation_id": str(internal_operation_id),
                "error": sui_result.get("error"), "reward_amount": reward_amount
            }
    except Exception as e:
        logger.error(f"SUI call failed for op_id {internal_operation_id}: {e}", exc_info=True)
        await self.db_client.update_reward_transaction_status(str(internal_operation_id), "failed", error_msg=str(e))
        return {
            "success": False, "status": "exception_failed",
            "internal_operation_id": str(internal_operation_id), "error": str(e), "reward_amount": reward_amount
        }
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Python name=api/app/services/rewards_service.py
IGNORE_WHEN_COPYING_END
6. Idempotent Citation Rewards (Backend)

Description: Modify RewardsService.issue_citation_rewards():

For each potential citation recipient (author of cited_vector_id):

Construct idempotency_key (e.g., f"citation:{citing_message_id}:{cited_vector_id}:{author_wallet_address}").

Follow logic similar to Step 5 (check DB, create pending, SUI call, update DB).

Response aggregates results for each citation, indicating newly_issued or already_issued.

Result: Citation rewards are idempotent per cited item.

# Pseudocode for RewardsService.issue_citation_rewards
async def issue_citation_rewards(self, citing_wallet_address: str, cited_vector_ids: List[str], citing_message_id: str) -> Dict[str, Any]:
    batch_operation_id = str(uuid.uuid4()) # For the overall batch
    individual_reward_results = []
    total_reward_issued_in_batch = 0
    any_success_in_batch = False

    for vector_id in cited_vector_ids:
        author_wallet_address = await self.db_client.get_author_wallet_for_vector(vector_id) # Needs implementation
        if not author_wallet_address or author_wallet_address == citing_wallet_address: # No self-rewards
            # Log skip or add a specific status to individual_reward_results
            continue

        idempotency_key = f"citation:{citing_message_id}:{vector_id}:{author_wallet_address}"

        existing_tx = await self.db_client.get_reward_transaction_by_idempotency_key(idempotency_key)
        if existing_tx and existing_tx.status == "success" and existing_tx.sui_transaction_digest:
            op_result = {
                "cited_vector_id": vector_id, "author_wallet_address": author_wallet_address,
                "success": True, "status": "already_issued",
                "internal_operation_id": str(existing_tx.transaction_id),
                "sui_transaction_digest": existing_tx.sui_transaction_digest,
                "reward_amount": existing_tx.reward_amount
            }
            individual_reward_results.append(op_result)
            if existing_tx.reward_amount: total_reward_issued_in_batch += existing_tx.reward_amount
            any_success_in_batch = True
            continue

        individual_op_id = uuid.uuid4()
        reward_amount_for_citation = 500_000_000 # 0.5 CHOIR example

        await self.db_client.create_reward_transaction({
            "transaction_id": individual_op_id, "idempotency_key": idempotency_key,
            "reward_type": "citation", "wallet_address": author_wallet_address,
            "message_id": citing_message_id, "cited_vector_id": vector_id,
            "status": "pending", "reward_amount": reward_amount_for_citation
        })

        try:
            sui_result = await self.sui_service.mint_choir(author_wallet_address, reward_amount_for_citation)
            current_status = "sui_failed"
            op_success = False
            if sui_result["success"]:
                await self.db_client.update_reward_transaction_status(
                    str(individual_op_id), "success", sui_digest=sui_result["digest"]
                )
                current_status = "newly_issued"
                op_success = True
                total_reward_issued_in_batch += reward_amount_for_citation
                any_success_in_batch = True
            else:
                await self.db_client.update_reward_transaction_status(
                    str(individual_op_id), "failed", error_msg=sui_result.get("error")
                )

            op_result = {
                "cited_vector_id": vector_id, "author_wallet_address": author_wallet_address,
                "success": op_success, "status": current_status,
                "internal_operation_id": str(individual_op_id),
                "sui_transaction_digest": sui_result.get("digest"), "error": sui_result.get("error"),
                "reward_amount": reward_amount_for_citation
            }
            individual_reward_results.append(op_result)
        except Exception as e:
            await self.db_client.update_reward_transaction_status(str(individual_op_id), "failed", error_msg=str(e))
            individual_reward_results.append({
                "cited_vector_id": vector_id, "author_wallet_address": author_wallet_address,
                "success": False, "status": "exception_failed",
                "internal_operation_id": str(individual__op_id), "error": str(e),
                "reward_amount": reward_amount_for_citation
            })

    # Send notifications for successful rewards
    # ... self.notification_service.send_citation_notification(...) for each successful one ...

    return {
        "success": any_success_in_batch,
        "batch_operation_id": str(batch_operation_id),
        "total_reward_amount_issued_in_batch": total_reward_issued_in_batch, # Sum of amounts for 'newly_issued' or 'already_issued'
        "individual_rewards": individual_reward_results
    }
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Python name=api/app/services/rewards_service.py
IGNORE_WHEN_COPYING_END
7. Retry Context Foundation (Client)

Description: Implement basic RetryContext class in Swift, focusing on reward tracking and retry attempts. Add to Message class. Add serialization support for persistence.

Result: Client has data structures for tracking retries.

// Pseudocode for RetryContext (simplified for brevity)
// This would be part of Message.swift or a new RetryModels.swift

enum PhaseRetryStatus: String, Codable {
    case idle
    case success
    case failed_retry_pending // Failed, will auto-retry
    case failed_manual_pending // Failed max auto-retries, manual retry possible
    case retrying_auto
    case retrying_manual
}

class RetryContext: ObservableObject, Codable, Hashable {
    @Published var attemptsByPhase: [Phase: Int] = [:]
    @Published var lastErrorByPhase: [Phase: String?] = [:]
    @Published var statusByPhase: [Phase: PhaseRetryStatus] = [:]
    @Published var modelsTriedByPhase: [Phase: [ModelConfig]] = [:]
    // Stores the internal_operation_id from the backend for a reward attempt related to this phase/message
    // Keyed by reward type (e.g., "novelty", "citation_vector_id_xyz")
    @Published var rewardOperationIDsByPhase: [Phase: [String: String]] = [:]


    // Implement Codable conformance
    // Implement Hashable conformance
    // ...

    init() {
        // Initialize statuses to idle for all phases
        for phase in Phase.allCases {
            statusByPhase[phase] = .idle
            attemptsByPhase[phase] = 0
            modelsTriedByPhase[phase] = []
            rewardOperationIDsByPhase[phase] = [:]
        }
    }

    // Methods to update context
    func recordAttempt(phase: Phase, model: ModelConfig) {
        // ...
    }
    func recordSuccess(phase: Phase) {
        // ...
    }
    func recordFailure(phase: Phase, error: String, canAutoRetry: Bool) {
        // ...
    }
    func recordRewardOperation(phase: Phase, rewardType: String, operationID: String) {
        // rewardOperationIDsByPhase[phase, default: [:]][rewardType] = operationID
    }

    static func == (lhs: RetryContext, rhs: RetryContext) -> Bool {
        return lhs.attemptsByPhase == rhs.attemptsByPhase && // Add other properties
               lhs.statusByPhase == rhs.statusByPhase
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(attemptsByPhase) // Add other properties
        hasher.combine(statusByPhase)
    }
}

class Message: ObservableObject /* ... */ {
    // ...
    @Published var retryContext: RetryContext = RetryContext()
    // ...
}
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Swift name=Choir/Models/ConversationModels.swift
IGNORE_WHEN_COPYING_END
// Pseudocode for ThreadPersistenceService
// Ensure MessageData and ThreadData are updated to include RetryContext for Codable
struct MessageData: Codable {
    // ...
    let retryContext: RetryContext // Add this
    // ...
    init(from message: Message) {
        // ...
        self.retryContext = message.retryContext
        // ...
    }
    func toMessage() -> Message {
        let message = Message(/*...*/)
        message.retryContext = self.retryContext
        // ...
        return message
    }
}
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Swift name=Choir/Services/ThreadPersistenceService.swift
IGNORE_WHEN_COPYING_END
8. Retry Flag API (Backend)

Description: Add is_retry: Bool parameter to backend /api/postchain/langchain endpoint. Client sends this flag. Backend logs it but doesn't use it for reward decisions yet (idempotency handles safety).

Result: Backend is aware of retry attempts for logging/analytics.

// Pseudocode for PostchainRequest
struct PostchainRequest: APIRequest {
    // ...
    let isRetry: Bool // Add this

    enum CodingKeys: String, CodingKey {
        // ...
        case isRetry = "is_retry"
    }
}

// In PostchainAPIClient.streamPostchain
// ...
let requestBody = PostchainRequest(
    userQuery: query,
    threadId: threadId,
    modelConfigs: modelConfigsDict,
    stream: true,
    isRetry: isRetry // Pass this from a new parameter in streamPostchain
)
// ...
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Swift name=Choir/Networking/PostchainAPIClient.swift
IGNORE_WHEN_COPYING_END
# Pseudocode for SimplePostChainRequest (Pydantic model)
class SimplePostChainRequest(BaseModel):
    user_query: str
    thread_id: str
    model_configs: Optional[Dict[str, ModelConfig]] = None
    is_retry: bool = Field(default=False) # Add this

# In process_simple_postchain endpoint handler
# ...
# Pass is_retry to run_langchain_postchain_workflow
# await run_langchain_postchain_workflow(..., is_retry=request.is_retry)
# ...
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Python name=api/app/routers/postchain.py
IGNORE_WHEN_COPYING_END
9. Retry-Aware Reward Decisions (Backend)

Description: The idempotency implemented in Steps 5 & 6 inherently handles this. If a reward was already issued (checked via idempotency_key), it won't be re-issued. The is_retry flag passed to issue_..._reward functions can be used for more detailed logging or slightly different handling of RewardTransaction records if desired (e.g., linking retry attempts), but the core safety is by idempotency_key.

Result: Backend makes idempotent reward decisions. The is_retry flag can enhance logging of these decisions.

(No new distinct pseudocode beyond making issue_..._reward functions accept is_retry for logging/context).

10. Basic Automatic Retry (Non-Reward Phases - Client)

Description: Client-side: Implement retry logic in PostchainViewModel for non-reward phases (Action, Intention, Observation, Understanding). If a phase fails:

Update Message.retryContext (increment attempts, store error, set status to retrying_auto).

If attempts < MAX_AUTO_RETRIES_NON_REWARD:

Wait with exponential backoff.

Call apiClient.streamPostchain again with the original query and is_retry = true.

Else: Set status to failed_manual_pending.

UI shows retry indicators.

Result: App automatically retries non-reward phases.

// Pseudocode for PostchainViewModel (conceptual retry loop)

let MAX_AUTO_RETRIES_NON_REWARD = 3
let MAX_AUTO_RETRIES_REWARD = 2 // Potentially different for reward phases

func processWithRetry(_ input: String, forMessage message: Message, initialModelConfigs: [Phase: ModelConfig]) async {
    var currentAttempt = 0
    var currentModelConfigs = initialModelConfigs
    let originalUserQuery = input // Assuming input is the user's initial query for this message

    // Mark message as processing
    await MainActor.run { message.isStreaming = true }


    while true { // Retry loop for the whole Postchain
        currentAttempt += 1
        let isRetryRun = currentAttempt > 1

        // Update retry context for the start of this attempt (if it's a retry)
        if isRetryRun {
            // Potentially log that a full Postchain retry is starting for 'message'
            // message.retryContext.recordFullPostchainAttempt(modelsUsedThisRun)
        }

        // This streamTask should handle one full Postchain execution
        // The PostchainAPIClient.streamPostchain itself iterates through backend SSE events
        // The loop here in the ViewModel is for retrying the *entire* Postchain request if a phase fails critically.

        var processingError: Error? = nil
        var allPhasesSuccessful = true

        // Assume streamPostchain now takes an onPhaseEvent callback
        // to monitor individual phase statuses within a single Postchain run.
        // Or, the existing PostchainEvent stream is monitored here.
        // Let's assume we monitor PostchainEvent stream.

        // This needs to be structured to handle the stream of events from one API call
        // and then decide if a full retry of the API call is needed.

        // Simplified: For now, assume streamPostchain throws on first unrecoverable phase failure
        // or completes all phases. More granular phase-specific retry needs more state in RetryContext.

        // The `process` function in the ViewModel needs to be adapted.
        // When `handleEvent` in ViewModel receives an error status for a phase:
        // 1. Update message.retryContext for that phase.
        // 2. If phase is retryable AND attempts < max:
        //    - Set a flag in ViewModel to trigger a full Postchain retry.
        //    - The outer `process` call (initiated by user send) would then loop.
        // This is a bit tricky with the current structure.
        // For now, let's assume a simpler client-side retry: if any phase fails, client retries the whole thing.

        do {
            // Update coordinator about the message being processed
             if let coordinator = coordinator as? PostchainCoordinatorImpl {
                 coordinator.currentChoirThread = self.findThread(for: message) // find the thread object
                 coordinator.activeMessageId = message.id
             }

            // The process() method itself will use the apiClient to stream
            // We need to observe the events coming from that stream
            // This pseudocode is for the retry logic *around* the main processing call.

            // Let's refine. The `PostchainViewModel.process` is the one called by UI.
            // It should internally manage this retry loop.
            // When a phase fails (detected in `updatePhaseData` via PostchainEvent status="error"):
            // - `updatePhaseData` should update `message.retryContext`.
            // - If `message.retryContext` indicates a retry is possible for the failed phase:
            //   - `process` (this function) should catch this signal and loop.

            // This requires `process` to be more aware of individual phase outcomes.
            // The current `apiClient.streamPostchain` doesn't easily allow retrying *just one phase*.
            // So, client-side retry implies retrying the *entire Postchain request*.

            // --- Start of a single PostChain attempt ---
            var phaseFailureDetected: Phase? = nil

            // Reset message.retryContext.statusByPhase for phases not yet completed
            // or clear all at start of a new user message.
            // For a retry, we'd typically clear the status of the failed phase and subsequent ones.

            // This logic is illustrative for a single attempt; the main retry loop is outside.
            // This is what `viewModel.process(input)` would call internally.
            try await coordinator.processWithProgress(
                originalUserQuery, // Always use the original user query for this message
                modelConfigs: currentModelConfigs, // These might change per retry due to model switching
                // onProgress callback if needed
            ) { statusString in
                // Update UI with onProgress status
            }

            // After coordinator.processWithProgress finishes, check message.retryContext
            // This needs a robust way for `coordinator.processWithProgress` to signal specific phase failures
            // back to this retry loop, or for this loop to inspect `message.retryContext` updated by `updatePhaseData`.

            // Let's assume `updatePhaseData` sets a flag or throws if a phase fails and needs retry.
            // For this pseudocode, let's simplify: if coordinator.process throws, we catch it.
            // If it completes, we check if any phase in message.retryContext is in a failed state.

            var shouldRetryThisAttempt = false
            var failedPhaseForRetry: Phase? = nil

            for phase in Phase.allCases { // Check all phases in the message context
                if message.retryContext.statusByPhase[phase] == .failed_retry_pending ||
                   message.retryContext.statusByPhase[phase] == .failed_manual_pending { // Or other relevant failed states

                    let isRewardPhase = (phase == .experienceVectors || phase == .yield)
                    let maxRetries = isRewardPhase ? MAX_AUTO_RETRIES_REWARD : MAX_AUTO_RETRIES_NON_REWARD

                    if (message.retryContext.attemptsByPhase[phase] ?? 0) < maxRetries {
                        shouldRetryThisAttempt = true
                        failedPhaseForRetry = phase
                        message.retryContext.statusByPhase[phase] = .retrying_auto // Mark as actively retrying
                        break
                    } else {
                        // Max retries reached for this phase
                        message.retryContext.statusByPhase[phase] = .failed_manual_pending
                        allPhasesSuccessful = false // Mark that not all phases succeeded
                    }
                } else if message.retryContext.statusByPhase[phase] != .success && message.retryContext.statusByPhase[phase] != .idle {
                     // If any phase is not success or idle, it might be an issue or still running from a weird state.
                     // This logic needs to be robust. For now, assume only specific 'failed' states trigger retry.
                }
            }

            if !shouldRetryThisAttempt {
                // No phase triggered an automatic retry within its limit
                if allPhasesSuccessful {
                    await MainActor.run { message.isStreaming = false }
                    logger.info("Postchain processing successful for message \(message.id) after \(currentAttempt) attempts.")
                    return // Exit retry loop
                } else {
                    // Some phases might have hit max retries and are pending manual.
                    await MainActor.run { message.isStreaming = false } // Stop global streaming indicator
                    logger.warning("Postchain processing for message \(message.id) completed with some phases requiring manual retry.")
                    return // Exit retry loop
                }
            }

            // If we are here, shouldRetryThisAttempt is true for failedPhaseForRetry
            logger.info("Retrying Postchain for message \(message.id), attempt \(currentAttempt + 1) due to failure in phase \(failedPhaseForRetry?.rawValue ?? "unknown")")

            // Implement backoff
            let backoffSeconds = pow(2.0, Double(message.retryContext.attemptsByPhase[failedPhaseForRetry!] ?? 0)) // Exponential backoff
            try await Task.sleep(nanoseconds: UInt64(backoffSeconds * 1_000_000_000))

            // Potentially switch model for the failed phase if Step 16 is implemented
            // currentModelConfigs = selectNextModelForPhase(failedPhaseForRetry!, currentModels: currentModelConfigs, retryContext: message.retryContext)
            // message.retryContext.recordAttempt(phase: failedPhaseForRetry!, model: newConfigForPhase)

            // Increment attempt for the specific phase that caused this full retry
            message.retryContext.attemptsByPhase[failedPhaseForRetry!, default: 0] += 1

            // Loop continues for the next full Postchain attempt

        } catch { // Catch errors from coordinator.processWithProgress
            // This implies a more catastrophic failure of the whole Postchain run
            logger.error("Postchain attempt \(currentAttempt) for message \(message.id) failed entirely: \(error)")
            processingError = error
            allPhasesSuccessful = false

            // Check if overall attempts for the message are exhausted
            if currentAttempt >= MAX_AUTO_RETRIES_NON_REWARD { // Use a general max attempt for whole postchain
                await MainActor.run {
                    message.isStreaming = false
                    // Update all non-successful phases in retryContext to failed_manual_pending
                    for p in Phase.allCases where message.retryContext.statusByPhase[p] != .success {
                        message.retryContext.statusByPhase[p] = .failed_manual_pending
                        message.retryContext.lastErrorByPhase[p] = "Postchain run failed: \(error.localizedDescription)"
                    }
                }
                logger.error("Max Postchain retries reached for message \(message.id). Error: \(error.localizedDescription)")
                // Propagate or handle the final error
                throw error // Or set a final error state on the ViewModel/Message
            }

            // Backoff before retrying the whole Postchain
            let backoffSeconds = pow(2.0, Double(currentAttempt))
            try await Task.sleep(nanoseconds: UInt64(backoffSeconds * 1_000_000_000))
            // Loop continues
        }
    }
    // UI indicator would be based on message.retryContext.statusByPhase[phase]
}
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Swift name=Choir/ViewModels/PostchainViewModel.swift
IGNORE_WHEN_COPYING_END

Note: The client-side retry logic is complex. The above is a conceptual sketch. A robust implementation would need careful state management within PostchainViewModel and Message.retryContext to track individual phase statuses and decide when to retry the entire PostChain request.

11. Full Automatic Retry (Client - All Phases)

Description: Extend automatic retry logic (Step 10) to include experienceVectors and yield phases. Reward safety is ensured by backend idempotency (Steps 5, 6).

Result: Complete automatic retry with reward safety.

(Pseudocode is similar to Step 10, but the conditional skip for reward phases is removed from the client's retry decision logic. The MAX_AUTO_RETRIES_REWARD might be used).

12. Retry State Persistence (Client)

Description: Update ThreadPersistenceService.swift to ensure Message.retryContext (including rewardOperationDetails) is serialized and deserialized with MessageData.

Implement resumption of retries: When a thread is loaded, if RetryContext indicates a failed_retry_pending state for a message/phase, the UI could offer to resume, or (more advanced) a background task could attempt resumption.

Result: Persistent retry state across app launches.

// In MessageData
struct MessageData: Codable {
    // ...
    let retryContextData: Data? // Store RetryContext as Data

    init(from message: Message) {
        // ...
        self.retryContextData = try? JSONEncoder().encode(message.retryContext)
    }

    func toMessage() -> Message {
        let message = Message(/*...*/)
        if let data = self.retryContextData,
           let context = try? JSONDecoder().decode(RetryContext.self, from: data) {
            message.retryContext = context
        }
        // ...
        return message
    }
}

// In ThreadManager or AppCoordinator - on app launch or thread load
func checkForPendingRetries(thread: ChoirThread) {
    for message in thread.messages {
        for (phase, status) in message.retryContext.statusByPhase {
            if status == .failed_retry_pending {
                // UI: "A phase failed for this message. Retry now?"
                // OR: Automatically trigger retry if app policy allows
                // viewModel.processWithRetry(message.originalQuery, forMessage: message, ...)
            }
        }
    }
}
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Swift name=Choir/Services/ThreadPersistenceService.swift
IGNORE_WHEN_COPYING_END
13. Basic Manual Retry UI (Client)

Description: In PhaseCard.swift or MessageRow.swift, add a "Retry Phase" button if message.retryContext.statusByPhase[phase] == .failed_manual_pending.

Button action calls PostchainViewModel.process() with original query, is_retry = true, and potentially specific model choice for that phase.

Result: User can manually retry phases.

// Pseudocode in PhaseCard or similar
var body: some View {
    // ...
    if message.retryContext.statusByPhase[phase] == .failed_manual_pending {
        Button("Retry \(phase.description)") {
            // Clear the specific phase status or mark as retrying_manual
            message.retryContext.statusByPhase[phase] = .retrying_manual
            message.retryContext.attemptsByPhase[phase, default: 0] = 0 // Reset attempts for manual retry
            message.retryContext.lastErrorByPhase[phase] = nil

            Task {
                // originalQuery needs to be accessible, perhaps stored on Message or passed down
                // await viewModel.processWithRetry(message.originalUserQuery, forMessage: message, ...)
                // Or a dedicated manual retry function:
                // await viewModel.manualRetryPhase(phase, forMessage: message, withModel: selectedModelForRetry)
            }
        }
    }
    // ...
}
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Swift name=Choir/Views/PhaseCard.swift
IGNORE_WHEN_COPYING_END
14. Model Performance Tracking (Client & Backend)

Description:

Client: Message.retryContext stores modelsTriedByPhase.

Client: After each phase attempt, send telemetry (phase, model, status, duration, error if any) to a new backend analytics endpoint: /api/analytics/phase_performance.

Backend: New endpoint stores this telemetry.

Result: App tracks model performance.

// In updatePhaseData, when a phase status becomes 'success' or 'failed_*'
func sendPhasePerformanceTelemetry(message: Message, phase: Phase, status: PhaseRetryStatus, duration: TimeInterval, modelUsed: ModelConfig, error: String?) {
    let payload = PhasePerformanceData(
        phase: phase.rawValue,
        model_provider: modelUsed.provider,
        model_name: modelUsed.model,
        status: status.rawValue,
        duration_ms: Int(duration * 1000),
        error_message: error,
        thread_id: findThread(for: message)?.id.uuidString, // find thread for message
        message_id: message.id.uuidString
        // ... other context if needed
    )
    // apiClient.sendAnalytics(payload) // New APIClient method
}

struct PhasePerformanceData: Codable { /* ... define fields ... */ }
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Swift name=Choir/ViewModels/PostchainViewModel.swift
IGNORE_WHEN_COPYING_END
# Suggested new file
from fastapi import APIRouter, Depends
from pydantic import BaseModel
# ... (DB client, auth dependencies)

class PhasePerformanceData(BaseModel):
    phase: str
    model_provider: str
    model_name: str
    status: str
    duration_ms: int
    error_message: Optional[str] = None
    thread_id: Optional[str] = None
    message_id: Optional[str] = None
    # ... any other fields

router = APIRouter(prefix="/api/analytics", tags=["analytics"])

@router.post("/phase_performance")
async def log_phase_performance(data: PhasePerformanceData, /* current_user: User = Depends(get_current_user) */):
    # Store data in a new 'phase_performance_stats' table/collection in Qdrant/DB
    # await db_client.log_phase_performance(data.dict())
    logger.info(f"Received phase performance data: {data.phase} - {data.model_name} - {data.status}")
    return {"status": "logged"}
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Python name=api/app/routers/analytics.py
IGNORE_WHEN_COPYING_END

Modify api/main.py to include this new router.

15. Model Selection UI (Manual Retry - Client)

Description: When manual retry button (Step 13) is tapped, UI can optionally present a model picker for that phase. The chosen ModelConfig is passed to viewModel.manualRetryPhase(...).

ModelConfigView.swift can be adapted or a simpler picker used.

Result: User can select models for manual retries.

(UI specific, pseudocode similar to showing any picker and passing its selection).

16. Automatic Model Switching (Client)

Description: In PostchainViewModel's automatic retry loop (Step 10/11):

If a phase fails, consult message.retryContext.modelsTriedByPhase[phase].

Get a predefined fallback list of ModelConfig for that phase (e.g., from ModelConfigManager or hardcoded).

Select the next untried model from the list.

Update currentModelConfigs for the next attempt.

Store the newly tried model in message.retryContext.modelsTriedByPhase[phase].

Result: Intelligent model switching on automatic retries.

// Inside the retry loop of processWithRetry (conceptual)

// Before making the API call for a retry:
if let failedPhase = failedPhaseForRetry { // failedPhaseForRetry identified earlier
    let modelsAlreadyTried = message.retryContext.modelsTriedByPhase[failedPhase] ?? []
    let fallbackModelsForPhase = ModelConfigManager.shared.getFallbackModels(for: failedPhase) // New method

    var nextModelToTry: ModelConfig? = nil
    for fallbackModel in fallbackModelsForPhase {
        if !modelsAlreadyTried.contains(where: { $0.provider == fallbackModel.provider && $0.model == fallbackModel.model }) {
            nextModelToTry = fallbackModel
            break
        }
    }

    if let model = nextModelToTry {
        // Update currentModelConfigs for the specific phase
        var updatedConfigs = currentModelConfigs // currentModelConfigs is for the whole Postchain run
        updatedConfigs[failedPhase] = model
        currentModelConfigs = updatedConfigs // Use these for the next API call

        message.retryContext.modelsTriedByPhase[failedPhase, default: []].append(model)
    } else {
        // No more fallback models to try for this phase
        // The phase will likely go to failed_manual_pending after this attempt if it fails again
        logger.info("No more fallback models for phase \(failedPhase.rawValue)")
    }
}
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Swift name=Choir/ViewModels/PostchainViewModel.swift
IGNORE_WHEN_COPYING_END
17. Advanced Analytics (Backend)

Description: Implement backend analytics for model performance data collected in Step 14. Add dashboard/API to query aggregated statistics (success rates, avg duration, error types per model/phase).

Result: Data-driven model selection insights.

(Primarily backend database aggregation and new API endpoints for querying. Pseudocode would involve SQL-like queries or Qdrant aggregation if used).

This revised plan provides more concrete implementation details through pseudocode. Remember that the client-side retry logic, especially managing the state across full Postchain retries triggered by individual phase failures, will require careful implementation in PostchainViewModel and Message.retryContext.
