import functools
from typing import List, Any, Tuple
from xml.etree.ElementTree import Element
from util import needSetMacro, formatSCR, scr_w_sub, scr_wo_sub, output, errmsg, findXML, pickChild
from plugin import plugin


def checkname(func):
    import re
    pat = 'tb__(\d+)__([^_]\w+)__([lnh]vcc)'
    matcher = re.compile(pat, re.I)

    @functools.wraps(func)
    def wrapper(*args, **kwargs) -> str:
        msg = func(*args, **kwargs)
        found = matcher.search(msg)
        if found:
            return msg
        errmsg(f'{msg} can not match /{pat}/')
        raise SystemExit
    return wrapper


def checkfunc(func):
    from cache import cacheLib
    tblib = cacheLib()

    @functools.wraps(func)
    def wrapper(*args, **kwargs) -> str:
        msg = func(*args, **kwargs)
        if msg in tblib:
            return msg
        errmsg(f"{msg} is not found in TestItemLibrary.txt")
        return f'/* FUNCTION_NOT_FOUND */{msg}'

    def wrapper2(*args, **kwargs) -> str:
        return func(*args, **kwargs)

    if bool(tblib):
        return wrapper

    print('\nSkips verifying cst function name\n')
    return wrapper2


def testnum(node: Element) -> str:
    return node.attrib['name'].split('__')[1]


@checkfunc
def cstfunc(node: Element) -> str:
    return pickChild('CSTFunct')(node)


def load_scr(node: Element) -> str:
    text = pickChild('trimOption')(node)
    if (text.upper() != 'NONE') and (len(text) != 0):
        text = formatSCR(text)
        return f'LOAD_{str.upper(text)}'
    return f'LOAD_NONE'


def set_scr(node: Element) -> str:
    name = node.attrib['name']
    tb = name.split('__')[1]
    childNames = ['IgnoreBit']
    texts = [pickChild(x)(node) for x in childNames]
    if needSetMacro(*texts):
        return f'SET_{str.upper(formatSCR(scr_wo_sub(name)))}_TB{tb}'
    return 'SET_Default'


def testname(node: Element) -> str:
    return node.attrib['name'].split('__')[2]


def vcc(node: Element) -> str:
    name = node.attrib['name'].split('__')[-1]
    return name.upper()


def vio(node: Element) -> str:
    return vcc(node).replace('VCC', 'VIO')


@checkname
def fullname(node: Element) -> str:
    return node.attrib['name']


def genCode(ls: List[str]) -> str:
    [tn, func, setMacro, name, trimMacro, vcc, vio, fullname] = ls
    msg = ' , '.join([
        '{:>4}'.format(tn),
        '{:<55}'.format(func),
        '{:<24}'.format(setMacro),
        '{:<55}'.format(f'"{name}"'),
        '{:<20}'.format(trimMacro),
        '{:<4}'.format(vcc),
        '{:<4}'.format(vio)])
    return f'  {{ {msg} }}, // {fullname}'


def pipeline(root: Element) -> Tuple[list, list]:
    @plugin(testnum)
    @plugin(cstfunc)
    @plugin(set_scr)
    @plugin(testname)
    @plugin(load_scr)
    @plugin(vcc)
    @plugin(vio)
    @plugin(fullname)
    def fn(seq=[], nodes=[]) -> Tuple[list, list]:
        return [], root.findall('./TestBlock[@flow]')
    return fn()


def dump(root: Element, targetFile: str) -> Any:
    from constant import HEAD, TAIL
    seq, nodes = pipeline(root)
    output(targetFile, [HEAD, *[genCode(x) for x in seq], TAIL])


if __name__ == '__main__':
    print(__file__)
    root = findXML()
    dump(root, 'MTCT_flow.h')
