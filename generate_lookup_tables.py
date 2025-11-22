#!/usr/bin/env python3
"""
Generate 128-position lookup tables for Nebulords paddle control.
Interpolates from the existing 32 positions to create smooth 128-position control.
"""

# Existing 32 paddle positions (X, Y offsets from ship center)
paddle_positions_32 = [
    (4, 28),    # 0: South
    (2, 26),    # 1
    (-1, 24),   # 2
    (-3, 22),   # 3
    (-5, 21),   # 4
    (-6, 18),   # 5
    (-8, 15),   # 6: West
    (-8, 12),   # 7
    (-8, 8),    # 8: North-West
    (-8, 4),    # 9
    (-8, 1),    # 10
    (-6, -2),   # 11
    (-5, -5),   # 12
    (-4, -7),   # 13
    (-2, -9),   # 14
    (1, -10),   # 15
    (4, -11),   # 16: North
    (6, -10),   # 17
    (8, -9),    # 18: North-East
    (10, -7),   # 19
    (13, -5),   # 20
    (14, -2),   # 21
    (16, 1),    # 22: East
    (16, 4),    # 23
    (16, 8),    # 24
    (16, 12),   # 25
    (16, 15),   # 26
    (14, 18),   # 27
    (13, 21),   # 28
    (11, 22),   # 29
    (9, 24),    # 30
    (6, 26),    # 31
]

# Ball follow positions (relative to paddle, approximately 1.4x further from ship)
# Extracted from __BF1_0 through __BF1_31
ball_positions_32 = [
    (10, 39),   # 0
    (6, 36),    # 1
    (1, 34),    # 2
    (-3, 31),   # 3
    (-3, 29),   # 4
    (-5, 25),   # 5
    (-7, 21),   # 6 (updated from -8 to -7)
    (-7, 17),   # 7
    (-7, 11),   # 8
    (-7, 6),    # 9
    (-7, 1),    # 10
    (-5, -3),   # 11
    (-3, -7),   # 12
    (-5, -10),  # 13
    (-2, -13),  # 14
    (2, -14),   # 15
    (6, -15),   # 16
    (9, -14),   # 17
    (11, -13),  # 18
    (14, -10),  # 19
    (21, -7),   # 20
    (23, -3),   # 21
    (26, 1),    # 22
    (26, 6),    # 23
    (26, 11),   # 24
    (26, 17),   # 25
    (26, 21),   # 26
    (23, 25),   # 27
    (21, 29),   # 28
    (15, 31),   # 29
    (13, 34),   # 30
    (9, 36),    # 31
]

def interpolate_positions(positions_32, num_output=128):
    """Interpolate 32 positions into num_output positions."""
    positions_128 = []

    for i in range(num_output):
        # Map i (0-127) to position in 32-element array
        # Each of the 32 positions covers 4 output positions (128/32 = 4)
        base_idx = (i // 4) % 32
        next_idx = (base_idx + 1) % 32

        # Interpolation factor (0.0 to 1.0 within each segment)
        t = (i % 4) / 4.0

        # Linear interpolation
        x0, y0 = positions_32[base_idx]
        x1, y1 = positions_32[next_idx]

        x = int(round(x0 + (x1 - x0) * t))
        y = int(round(y0 + (y1 - y0) * t))

        positions_128.append((x, y))

    return positions_128

def format_as_bB_data(positions, name_prefix):
    """Format positions as batari Basic data tables."""
    x_values = [pos[0] for pos in positions]
    y_values = [pos[1] for pos in positions]

    # Format X data table
    x_lines = [f"data {name_prefix}_x"]
    for i in range(0, len(x_values), 16):
        chunk = x_values[i:i+16]
        x_lines.append("  " + ", ".join(str(v) for v in chunk))
    x_lines.append("end")

    # Format Y data table
    y_lines = [f"data {name_prefix}_y"]
    for i in range(0, len(y_values), 16):
        chunk = y_values[i:i+16]
        y_lines.append("  " + ", ".join(str(v) for v in chunk))
    y_lines.append("end")

    return "\n".join(x_lines) + "\n\n" + "\n".join(y_lines)

# Generate 128-position tables
paddle_128 = interpolate_positions(paddle_positions_32)
ball_128 = interpolate_positions(ball_positions_32)

# Generate batari Basic data tables
print("; Lookup tables for 128-position paddle control")
print("; Generated from 32 manual positions with linear interpolation")
print()
print("; P1 Paddle position offsets (add to player0x/player0y)")
print(format_as_bB_data(paddle_128, "p1_paddle"))
print()
print()
print("; P1 Ball follow position offsets (add to player0x/player0y)")
print(format_as_bB_data(ball_128, "p1_ball"))
print()
print()
print("; P2 Paddle position offsets (add to player1x/player1y)")
print(format_as_bB_data(paddle_128, "p2_paddle"))
print()
print()
print("; P2 Ball follow position offsets (add to player1x/player1y)")
print(format_as_bB_data(ball_128, "p2_ball"))
print()
print(f"; Total positions: {len(paddle_128)}")
print(f"; Memory usage: {len(paddle_128) * 4 * 2} bytes for all 4 tables")
