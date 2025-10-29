import subprocess
import struct
import os

def run_test_case(a, b, n, n_prime, expected_res, size):
    """
    Runs a single test case by invoking the compiled binary and passing the inputs.
    """
    # Prepare the input data as a binary file
    input_file = "test_input.bin"
    with open(input_file, "wb") as f:
        for array in [a, b, n, n_prime]:
            f.write(struct.pack(f"<{size}I", *array))

    # Run the compiled binary
    result = subprocess.run(["./montgomery_test"], capture_output=True, text=True)

    # Check the output
    if result.returncode != 0:
        print("Error running test case:", result.stderr)
        return False

    # Parse the output
    output_lines = result.stdout.splitlines()
    if "Montgomery multiplication passed!" in output_lines:
        return True
    else:
        print("Test failed!")
        print("Expected:", expected_res)
        print("Output:", output_lines)
        return False


def main():
    """
    Main function to run multiple test cases.
    """
    # Define test cases
    test_cases = [
        {
            "a": [0x7464ec63, 0x9247068d, 0x27b8ad5c, 0x78b4ba89, 0x4ff7b6ad, 0x79ce2d6b, 0x54a8e031, 0xfd7d6067, 0x5aef5635, 0x6a5fad35, 0xc41a9536, 0x03afd67b, 0xf34d27a3, 0xe3cea227, 0x3edca85c, 0x97438ef7, 0x936c2dd9, 0x368ac963, 0xd0c9a7b2, 0x0c89d25c, 0x19274d51, 0x4b7f6d60, 0x5a57ae7d, 0x963d8b19, 0x6e58b537, 0x9926f18a, 0x80971e79, 0xfe93cd3d, 0xa94dff06, 0x744729e0, 0x6bb08769, 0x8258cc8b],
            "b": [0xa81c26a3, 0x5182030a, 0xda348178, 0xdfdc4ca3, 0xabc9b408, 0xb0ead53f, 0xec50a292, 0xa3a165a7, 0x40199f0a, 0x79bc3718, 0x976db655, 0xb066e445, 0x5ff10a6b, 0x3553506f, 0x1852a802, 0x0bcc65b8, 0xbfa1b627, 0x65d81a54, 0x2f0f410c, 0xa3c7734b, 0x952a71cc, 0x696615f9, 0xe834fd3f, 0xeacc8b6f, 0x87efd558, 0xe582e641, 0x6aaf3f32, 0x31bd8cba, 0xd9161d75, 0xa6515499, 0x6432d9f5, 0xa4593898],
            "n": [0xd6708e39, 0x8fd8f6ef, 0xf0d0b4c5, 0x4ab8ed5d, 0x6a8cf293, 0xd02eec97, 0xf5432bfd, 0xa9796545, 0x09f1dc73, 0xde45da8a, 0xc119c572, 0x5197441a, 0x2245cc6f, 0x17e051b7, 0x4c3bf5d3, 0x7b32f01a, 0x3a28e993, 0x8e0cb6ac, 0x6076791f, 0xa0ff7977, 0x2f8325f6, 0xfdaea31c, 0x1c2f7e7b, 0xee6a2bda, 0x1e92095f, 0x69bb300e, 0x9985138e, 0xde2d02af, 0x03ef239b, 0x8fa831c4, 0x78d4946c, 0xca174a5c],
            "n_prime": [0xd99cfff7, 0x66d5d9a1, 0x982538cd, 0xfcaae0be, 0x2bff5dcd, 0x900d557d, 0x4fce0d05, 0xc68d63be, 0x8d856b52, 0x581ffa6d, 0x9c0d0c36, 0xb8add071, 0xd56d2a26, 0xb14b57bf, 0x7b097b90, 0x79e77aab, 0x6c790550, 0xf305dc6f, 0x5e0a3df5, 0x71a9d6b2, 0xcb1af2b9, 0x9659b4a6, 0x43ab6fac, 0xd414126c, 0x5531de8b, 0x38ee7009, 0x54a7cd6d, 0x79b33b00, 0x4aefee1e, 0x57949d8f, 0x291126cf, 0xf1922b2d],
            "expected_res": [0x6f73dca3, 0x57d8d8ce, 0x15c46a97, 0x687e5e6b, 0x200c59d0, 0x241229f8, 0x82816b5a, 0x1733a791, 0xfe61b476, 0xc2e694e7, 0xcc4630ed, 0x40b827ce, 0x0d6a29ef, 0x64e66c68, 0xec5f5681, 0x710f980f, 0xfc451057, 0xe9ce4590, 0x642f3453, 0x54725c91, 0x3193e9f7, 0x9c04e33c, 0xfdb83c82, 0x66ac1a02, 0x1a5a7ba7, 0x9e9fc81c, 0x9582fd04, 0x007e5f97, 0xf77e091c, 0xa541c254, 0x8b0b4a07, 0x7b4afb24],
            "size": 32
        },
        # Add more test cases here
    ]

    # Run all test cases
    for i, test_case in enumerate(test_cases):
        print(f"Running test case {i + 1}...")
        if run_test_case(
            test_case["a"],
            test_case["b"],
            test_case["n"],
            test_case["n_prime"],
            test_case["expected_res"],
            test_case["size"]
        ):
            print(f"Test case {i + 1} passed!\n")
        else:
            print(f"Test case {i + 1} failed!\n")

if __name__ == "__main__":
    main()