import magic
try:
    print("Testing magic with string input...")
    m = magic.Magic(mime=True)
    # This should fail if it expects bytes
    try:
        print(f"Result: {m.from_buffer('test string')}")
    except Exception as e:
        print(f"Caught expected error: {type(e).__name__}: {e}")
        import traceback
        traceback.print_exc()

    print("Testing magic with bytes input...")
    print(f"Result: {m.from_buffer(b'test bytes')}")

except Exception as e:
    print(f"Global error: {e}")
