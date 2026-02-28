import math
from datetime import datetime, timedelta

def calculate_next_revision(memory_strength: float, accuracy: float, current_revision_count: int):
    """
    Spaced Repetition Algorithm.
    Returns: (new_memory_strength, next_interval_days)
    """
    # 1. Update memory strength & Interval
    # Base adjustments according to prompt:
    # >= 80%: Increase memory strength significantly. Multiply interval.
    # 50 - 79%: Slight increase. Slight interval increase.
    # < 50%: Reduce memory strength. Reset interval.
    
    if accuracy >= 0.8:
        new_memory_strength = memory_strength + 15.0 # Significant increase
        interval_days = max(1, math.ceil(1.5 ** current_revision_count))
    elif accuracy >= 0.5:
        new_memory_strength = memory_strength + 5.0 # Slight increase
        interval_days = max(1, math.ceil(1.2 ** current_revision_count))
    else:
        new_memory_strength = memory_strength - 10.0 # Reduce
        interval_days = 1 # Reset interval
    
    # Cap between 0 and 100
    new_memory_strength = max(0.0, min(100.0, new_memory_strength))

    return new_memory_strength, interval_days

def get_forgetting_probability(memory_strength: float, days_since_revision: int):
    """
    Simple implementation of Ebbinghaus forgetting curve
    """
    # If newly learned and memory strength is low, forgets faster
    # R = e^(-t/S) where R is retention, t is time, S is relative strength of memory
    S = max(1.0, memory_strength / 10.0) # S scaled from memory strength
    probability_retained = math.exp(-days_since_revision / S)
    return 1.0 - probability_retained
