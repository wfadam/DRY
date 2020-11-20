from typing import Callable, TypeVar
from xml.etree.ElementTree import Element
F = TypeVar('F', bound=Callable[[Element], str])


def plugin(callee: F):
    import functools

    def decorator(func: Callable[[Element], str]):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            seq, nodes = func(*args, **kwargs)
            rslt = [[callee(x)] for x in nodes]
            if len(seq) == 0:
                return rslt, nodes
            else:
                return [[*x[0], *x[1]] for x in zip(rslt, seq)], nodes
        return wrapper
    return decorator
