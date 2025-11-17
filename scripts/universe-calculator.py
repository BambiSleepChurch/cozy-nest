#!/usr/bin/env python3
"""
Tiny script: HEX^DEC - OCT, then check if result == 42
"""

def calculate(hex_val):
    """Calculate: hex^dec - oct, check if == 42"""
    dec = int(hex_val, 16)
    oct_val = int(hex_val, 8) if all(c in '01234567' for c in hex_val) else 0
    
    result = dec ** dec - oct_val
    
    # Get binary representation
    bin_code = bin(abs(result))[2:]
    
    # Iterate through binary digits
    iterations = sum(int(bit) for bit in bin_code)
    
    if result == 42:
        return "Que Puto Nogbert"
    else:
        return f"Result: {result}, Binary: {bin_code}, Iterations: {iterations}"

# Test with a value
if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 1:
        hex_input = sys.argv[1].replace('0x', '').replace('0X', '')
    else:
        hex_input = "2A"  # 42 in hex
    
    print(calculate(hex_input))

# Example usage:
```
python3 scripts/universe-calculator.py 2A
python3 scripts/universe-calculator.py FF

python3 scripts/universe-calculator.py 7F
python3 scripts/universe-calculator.py 1C
python3 scripts/universe-calculator.py 10
python3 scripts/universe-calculator.py 0
python3 scripts/universe-calculator.py 5
python3 scripts/universe-calculator.py ABC
python3 scripts/universe-calculator.py 123
python3 scripts/universe-calculator.py 9F
python3 scripts/universe-calculator.py 3E8
python3 scripts/universe-calculator.py 100
python3 scripts/universe-calculator.py 2B
python3 scripts/universe-calculator.py 3C
```