class PostChainTester:
    """Minimal test framework for PostChain evaluation"""

    def __init__(self, chain_factory, test_id: str = None):
        """
        Args:
            chain_factory: Function that returns a configured PostChain
            test_id: Optional identifier for this test run
        """
        self.chain_factory = chain_factory
        self.test_id = test_id or f"test_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        self.interactions = []
        self.metadata = {}

        # Create output directory
        self.output_dir = Path(f"tests/results/{self.test_id}")
        self.output_dir.mkdir(parents=True, exist_ok=True)

    def analyze(self) -> Dict:
        """Analyze test results"""
        if not self.interactions:
            return {"error": "No interactions recorded"}

        # Convert to DataFrame for analysis
        df = pd.DataFrame(self.interactions)

        # Phase distribution
        phase_counts = df["phase"].value_counts().to_dict()

        # Loop analysis
        loop_counts = df["loop"].value_counts().to_dict()
        max_loop = df["loop"].max() if not df["loop"].empty else 0

        # Confidence analysis if available
        confidence_stats = {}
        avg_confidence = None
        if "confidence" in df.columns:
            confidence_values = df["confidence"].dropna()
            if not confidence_values.empty:
                avg_confidence = confidence_values.mean()
                confidence_stats = {
                    "mean": avg_confidence,
                    "min": confidence_values.min(),
                    "max": confidence_values.max()
                }

        # Timing analysis
        if "timestamp" in df.columns:
            df["timestamp"] = pd.to_datetime(df["timestamp"])
            duration = (df["timestamp"].max() - df["timestamp"].min()).total_seconds()
        else:
            duration = None

        # Phase transition analysis
        transitions = {}
        if len(df) > 1 and "phase" in df.columns:
            # Get non-null phases
            phases = df["phase"].dropna().tolist()

            # Calculate transitions
            for i in range(len(phases) - 1):
                if phases[i] is not None and phases[i+1] is not None:
                    transition_key = f"{phases[i]}->{phases[i+1]}"
                    transitions[transition_key] = transitions.get(transition_key, 0) + 1

        return {
            "phase_distribution": phase_counts,
            "loop_distribution": loop_counts,
            "max_loop": max_loop,
            "loops": max_loop + 1,  # For backward compatibility
            "avg_confidence": avg_confidence,  # For backward compatibility
            "confidence_stats": confidence_stats,
            "duration_seconds": duration,
            "interaction_count": len(df),
            "transitions": transitions  # Add transitions for backward compatibility
        }

    # ... rest of the class methods ...
