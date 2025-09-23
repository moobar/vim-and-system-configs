#!/usr/bin/env python3
import ast
import sys


def list_functions_from_file(filepath):
    """
    Safely parses a Python file and yields the names of all function definitions,
    including async functions.
    """
    try:
        with open(filepath, "r") as source_file:
            source_code = source_file.read()

        tree = ast.parse(source_code)

        # Walk the tree and yield the name of each function node
        for node in ast.walk(tree):
            # MODIFIED: Check for both standard and async function definitions
            if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                yield node.name
    except FileNotFoundError:
        print(f"Error: File not found at '{filepath}'", file=sys.stderr)
    except Exception as e:
        print(f"Error parsing file: {e}", file=sys.stderr)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: list_py_functions.py <path_to_python_file>", file=sys.stderr)
        sys.exit(1)

    filepath = sys.argv[1]
    for func_name in list_functions_from_file(filepath):
        print(func_name)
