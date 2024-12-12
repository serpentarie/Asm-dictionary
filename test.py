import subprocess
import unittest

class Test(unittest.TestCase):

    def run_program(self, input_data):
        process = subprocess.Popen(
            ['./main'],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        stdout, stderr = process.communicate(input=input_data.encode())
        return stdout.decode(), stderr.decode()

    def test_existing_key(self):
        test_cases = {
            "third word\n": "third word explanation\n",
            "second word\n": "second word explanation\n",
            "first_word\n": "first word explanation\n",
        }
        for input_word, expected_output in test_cases.items():
            with self.subTest(word=input_word.strip()):
                stdout, stderr = self.run_program(input_word)
                self.assertEqual(stdout, expected_output)
                self.assertEqual(stderr, "")

    def test_non_existing_key(self):
        stdout, stderr = self.run_program("wow\n")
        self.assertEqual(stdout, "\n")
        self.assertEqual(stderr, "Key not found")

if __name__ == '__main__':
    unittest.main()
