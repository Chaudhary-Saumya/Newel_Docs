import magic
try:
    print("Testing magic with empty bytes input...")
    m = magic.Magic(mime=True)
    try:
        print(f"Result: {m.from_buffer(b'')}")
    except Exception as e:
        print(f"Caught expected error: {type(e).__name__}: {e}")
        import traceback
        traceback.print_exc()

except Exception as e:
    print(f"Global error: {e}")
