import magic
try:
    print("Magic module imported successfully")
    # print(f"Magic version: {magic.version()}") # Skipped
    m = magic.Magic(mime=True)
    print("Magic instance created")
    print(f"Result: {m.from_buffer(b'test')}")
except Exception as e:
    print(f"Error: {e}")
except OSError as e:
    print(f"OSError (likely DLL missing): {e}")
