import math

def calculate_next_revision(memory_strength: float, accuracy: float, current_revision_count: int):
    """
    Spaced Repetition Algorithm.

    Spec-aligned scheduling:
      Weak (strength <= 40)   → 4 days
      Moderate (strength 41-70) → 6 days
      Strong (strength > 70)  → 8 days

    Performance adjustments:
      >= 80% accuracy: +15 strength, keep/advance interval
      50-79% accuracy: +5 strength,  keep interval
      < 50% accuracy:  -10 strength, reset to 4 days (weak)

    Returns: (new_memory_strength, next_interval_days)
    """
    # 1. Update memory strength based on quiz accuracy
    if accuracy >= 0.8:
        new_memory_strength = memory_strength + 15.0
    elif accuracy >= 0.5:
        new_memory_strength = memory_strength + 5.0
    else:
        new_memory_strength = memory_strength - 10.0

    # Cap between 0 and 100
    new_memory_strength = max(0.0, min(100.0, new_memory_strength))

    # 2. Determine interval based on updated memory strength (spec thresholds)
    if new_memory_strength <= 40:
        interval_days = 4   # Weak
    elif new_memory_strength <= 70:
        interval_days = 6   # Moderate
    else:
        interval_days = 8   # Strong

    # 3. If performance was very poor, force short interval
    if accuracy < 0.5:
        interval_days = 4

    return new_memory_strength, interval_days


def get_forgetting_probability(memory_strength: float, days_since_revision: int):
    """
    Simple implementation of Ebbinghaus forgetting curve.
    """
    S = max(1.0, memory_strength / 10.0)
    probability_retained = math.exp(-days_since_revision / S)
    return 1.0 - probability_retained
