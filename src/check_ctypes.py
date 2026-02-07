import ctypes
try:
    print(f"ctypes.ArgumentError is subclass of Exception: {issubclass(ctypes.ArgumentError, Exception)}")
    print(f"ctypes.ArgumentError is subclass of BaseException: {issubclass(ctypes.ArgumentError, BaseException)}")
    print(f"ctypes.ArgumentError MRO: {ctypes.ArgumentError.mro()}")
except Exception as e:
    print(e)
