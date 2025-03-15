# 🔄 Revised Model Management Plan

## 🎯 Core Principles

1. **Runtime Configuration** - Enable/disable providers via function parameters
2. **Minimal Changes** - Keep existing model getters intact
3. **Central Control** - Manage providers in `initialize_model_list`
4. **Userland Flexibility** - Support dynamic provider selection

## ✅ Implementation Checklist

## Adding Providers

1. Install required package
2. Add API key to `Config` class
3. Create model getter function in `langchain_utils.py`
4. Add provider block in `initialize_model_list()`
5. Implement model creation in `get_base_model()`
6. Add streaming support in `get_streaming_model()`

## Disabling Providers

1. Pass disabled providers to `initialize_model_list()`

```python
models = initialize_model_list(config, disabled_providers={"openai"})
```

2. Update provider blocks with exclusion check:

```python
if provider not in disabled_providers and api_key_exists:
    add_models()
```

## Implementation Steps

1. Modify `initialize_model_list` signature:

```python:api/app/langchain_utils.py
def initialize_model_list(
    config: Config,
    disabled_providers: Set[str] = None
) -> List[ModelConfig]:
    """Initialize model list with provider control"""
    disabled_providers = disabled_providers or set()
```

2. Update provider blocks (example for OpenAI):

```python:api/app/langchain_utils.py
# Before
if config.OPENAI_API_KEY:
    models.extend(...)

# After
if "openai" not in disabled_providers and config.OPENAI_API_KEY:
    models.extend(...)
```

3. Update test script usage:

```python:api/tests/postchain/test_random_multimodel_stream.py
# Disable OpenAI in tests
models = initialize_model_list(config, disabled_providers={"openai"})
```

## 🧠 Key Implementation Insight

The `disabled_providers` parameter acts as a runtime filter while preserving:

- Existing model definitions
- API key validation
- Provider isolation
- Future expansion capabilities

This aligns with the Post Chain philosophy of minimal core + userland extensions.

## 📝 Usage Examples

**Disable Multiple Providers**

```python
models = initialize_model_list(
    config,
    disabled_providers={"openai", "azure"}
)
```

**Enable Specific Providers Only**

```python
all_providers = {"openai", "anthropic", "google", "mistral", "fireworks", "cohere", "groq"}
models = initialize_model_list(
    config,
    disabled_providers=all_providers - {"anthropic"}
)
```

**Temporary Provider Exclusion**

```python
temp_disabled = {"openai"} if os.getenv("CI") else set()
models = initialize_model_list(config, disabled_providers=temp_disabled)
```
