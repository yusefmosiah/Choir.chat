import os
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path
import json
from typing import List, Dict, Optional

class PostChainAnalyzer:
    """Utilities for analyzing PostChain test results"""

    def __init__(self, results_dir: str = "tests/results"):
        self.results_dir = Path(results_dir)
        self.test_runs = self._discover_test_runs()

    def _discover_test_runs(self) -> List[str]:
        """Find all test run directories"""
        return [d.name for d in self.results_dir.iterdir()
               if d.is_dir() and (d / "metadata.json").exists()]

    def load_test_data(self, test_id: str) -> Dict:
        """Load data for a specific test run"""
        test_dir = self.results_dir / test_id

        # Load metadata
        with open(test_dir / "metadata.json") as f:
            metadata = json.load(f)

        # Load interactions
        interactions = []
        with open(test_dir / "interactions.jsonl") as f:
            for line in f:
                interactions.append(json.loads(line))

        # Load final state
        with open(test_dir / "final_state.json") as f:
            final_state = json.load(f)

        return {
            "metadata": metadata,
            "interactions": interactions,
            "final_state": final_state
        }

    def get_test_summary(self) -> pd.DataFrame:
        """Summarize all test runs"""
        rows = []

        for test_id in self.test_runs:
            try:
                data = self.load_test_data(test_id)
                metadata = data["metadata"]

                # Extract key metrics
                row = {
                    "test_id": test_id,
                    "prompt": metadata["config"]["prompt"],
                    "duration": metadata.get("duration_seconds", 0),
                    "loops": metadata.get("loops_completed", 0),
                    "phases": len(metadata.get("phases_executed", [])),
                    "error": metadata.get("error", None) is not None
                }
                rows.append(row)
            except Exception as e:
                print(f"Error loading test {test_id}: {str(e)}")

        return pd.DataFrame(rows)

    def visualize_test(self, test_id: str):
        """Create visualizations for a test run"""
        data = self.load_test_data(test_id)
        interactions = pd.DataFrame(data["interactions"])

        # Create figure with subplots
        fig, axs = plt.subplots(2, 1, figsize=(12, 10))

        # Plot 1: Phase flow
        if "phase" in interactions.columns:
            # Extract timestamps as datetime
            interactions["time"] = pd.to_datetime(interactions["timestamp"])
            interactions["time_offset"] = (interactions["time"] - interactions["time"].min()).dt.total_seconds()

            # Plot phases over time
            phases = interactions["phase"].unique()
            phase_nums = {phase: i for i, phase in enumerate(sorted(phases))}
            interactions["phase_num"] = interactions["phase"].map(phase_nums)

            # Plot
            sns.scatterplot(x="time_offset", y="phase", data=interactions,
                           hue="loop", palette="viridis", s=100, ax=axs[0])
            axs[0].set_title(f"Phase Flow - Test {test_id}")
            axs[0].set_xlabel("Time (seconds)")
            axs[0].set_ylabel("Phase")

        # Plot 2: Confidence scores
        if "confidence" in interactions.columns:
            sns.lineplot(x=range(len(interactions)), y="confidence",
                       data=interactions, marker="o", ax=axs[1])
            axs[1].set_title("Confidence Scores")
            axs[1].set_xlabel("Step")
            axs[1].set_ylabel("Confidence")
            axs[1].grid(True)

        plt.tight_layout()

        # Save figure
        output_path = self.results_dir / test_id / "visualization.png"
        plt.savefig(output_path)
        plt.close()

        print(f"Visualization saved to {output_path}")

    def compare_tests(self, test_ids: List[str], metric: str = "duration"):
        """Compare metrics across multiple test runs"""
        data = []

        for test_id in test_ids:
            test_data = self.load_test_data(test_id)
            metadata = test_data["metadata"]

            # Extract metrics
            if metric == "duration":
                value = metadata.get("duration_seconds", 0)
            elif metric == "loops":
                value = metadata.get("loops_completed", 0)
            elif metric == "confidence":
                # Calculate average confidence from interactions
                interactions = pd.DataFrame(test_data["interactions"])
                value = interactions["confidence"].mean()
            else:
                value = None

            data.append({
                "test_id": test_id,
                "value": value,
                "prompt": metadata["config"]["prompt"][:30] + "..."
            })

        # Create comparison bar chart
        df = pd.DataFrame(data)
        plt.figure(figsize=(10, 6))
        bars = sns.barplot(x="test_id", y="value", data=df)

        # Add value labels
        for i, bar in enumerate(bars.patches):
            value = df.iloc[i]["value"]
            bars.text(bar.get_x() + bar.get_width()/2.,
                     bar.get_height() + 0.1,
                     f"{value:.2f}",
                     ha="center")

        plt.title(f"Comparison of {metric} across test runs")
        plt.ylabel(metric.capitalize())
        plt.xlabel("Test ID")
        plt.xticks(rotation=45)

        # Save figure
        output_path = self.results_dir / f"comparison_{metric}.png"
        plt.savefig(output_path)
        plt.close()

        print(f"Comparison chart saved to {output_path}")
