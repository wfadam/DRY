import re
import os
import glob
import sys
import subprocess
from typing import Any, List, Dict, Callable
from termcolor import colored # type: ignore
from colorama import init # type: ignore 
from os.path import join as pj
init() 

REV = '2.6'

def suspend() -> Any:
    import psutil   # type: ignore
    me = psutil.Process()
    parent = psutil.Process(me.ppid())
    grandparent = psutil.Process(parent.ppid())
    if grandparent.cmdline()[0].lower().find('explorer.exe') >= 0:
        input('\nPress ENTER to continue')

def errout(msg: str) -> Any:
    print(f"\n{__file__.split('.')[0]} version: {REV}\n")
    print(colored(msg, 'white', 'on_red'))
    suspend()
    raise SystemExit

def checkPath(path: str) -> Any:
    if not os.path.exists(path):
        errout(f'{path} does not exist')

def getSrcRoot() -> str:
    cwd = os.getcwd()
    tech = confDB['tech']
    idx = cwd.lower().rfind(f'{tech.lower()}\\')
    if idx < 0:
        errout(f'Folder "{tech}" is not in {cwd}')
    return pj(cwd[:idx], tech)

def isSvnPath() -> bool:
    return os.path.exists(pj(SRC_ROOT, 'lib'))

def pathOf(key: str) -> str:
    prod_or_lib = confDB['prod'] if key == 'coderev' else 'lib'
    if isSvnPath():
        return pj(SRC_ROOT, prod_or_lib, *confDB[key].split('_', 1))
    else:
        return pj(SRC_ROOT, f'{prod_or_lib}_{confDB[key]}')

def recordFile(fname: str) -> Any:
    key = os.path.basename(fname).split('.')[0]
    if key in func2path:
        func2path[key].append(fname)
    else:
        func2path[key] = [fname]

def removeBlockComment(msg: str) -> str:
    match = re.compile(r'//.*')
    commentstart = [x.span()[0] for x in re.finditer(r'/\*', msg)]
    commentstop = [x.span()[1] for x in re.finditer(r'\*/', msg)]
    for start, stop in zip(commentstart, commentstop):
        msg = (' ' * (stop - start)).join([msg[0:start], msg[stop:]])
    return msg

def removeLineComment(msg: str) -> str:
    lines = []
    match = re.compile(r'//.*')
    for x in msg.splitlines():
        found = match.search(x)
        if found:
            lines.append(x.replace(found.group(), ''))
        else:
            lines.append(x)
    return '\n'.join(lines)

def readSRC(fname: str) -> str:
    checkPath(fname)
    with open(fname) as f:
        msg = f.read()
    msg = removeBlockComment(msg)
    msg = removeLineComment(msg)
    return msg

def genFuncDeclare(func: str) -> str:
    msg = readSRC(toPath(func))
    match = re.compile(f'.*\\b{func}\\b.*?\(.*\)')
    found = match.search(msg)
    if found:
        return f'{found.group().strip()};'
    errout(f'Failed to find function "{func}" in {toPath(func)}')
    return ''

def toPath(name: str) -> str:
    try:
        return func2path[name][0]
    except:
        errout(f'File {name}.c/.h is not found')

def saveFile(fname: str, lines: List[str]) -> Any:
    with open(fname, 'w') as f:
        f.write('\n'.join(lines))

def scanFunc(name: str) -> Any:
    global calledSubs
    msg = readSRC(toPath(name))
    match = re.compile(r'\b[_a-z]\w*\b', re.I)
    todo = set([x.group() for x in match.finditer(msg)])    # the functions been called
    todo = todo - set([name])   # remove the function {name} itself because its caller has recorded it
    todo = todo - calledSubs    # remove known called functions
    todo = todo & set(func2path.keys()) # functions to be scanned in next round
    calledSubs |= set(todo) # record functions called by function {name}
    [scanFunc(x) for x in todo]

def checkFlowTB(name: str = 'MTCT_flow') -> Any:
    global calledSubs
    msg = readSRC(toPath(name))
    match = re.compile(r'\b[_a-z]\w*\b', re.I)
    todo = set([x.group() for x in match.finditer(msg)])    # the functions been called
    tbs = set(filter(lambda x: x.startswith('t_') or x.startswith('d_'), todo))
    tbs = tbs - calledSubs
    if len(tbs) > 0:
        errout('Can not find:\n\t' 
            + '\n\t'.join([x + ".h" for x in tbs])
            + '\nunder CTF_test_items/ or test_items/')
           
def getIncFiles(fname: str) -> List[str]:
    match = re.compile(r'#include\s+"(\w+)')
    msg = readSRC(fname)
    ls = []
    for line in msg.splitlines():
        found = match.search(line)
        if found:
            ls.append(found.group(1))
    return ls
    
def copyFiles(dst: str) -> Any:
    if len(calledSubs) == 0:
        errout('No file is copied. Something wrong !')

    bat = pj(dst, 'copy.bat')
    saveFile(bat, [f'copy "{toPath(x)}" .' for x in calledSubs])
    subprocess.check_output(bat, cwd=dst)
    os.remove(bat)
    print(f'{len(calledSubs)} copied')
    global ctf_tb_cnt
    ls = list(filter(lambda p: p.find('CTF_test_items') > -1, [toPath(x) for x in calledSubs]))
    ctf_tb_cnt = len(ls)

def genFiles(dst: str) -> Any:
    flatSubs = set(calledSubs)
    flatSubs -= set(getIncFiles(toPath('MTCT_flow')))
    flatSubs -= set(getIncFiles(toPath('Macro')))
    flatSubs -= set(getIncFiles(toPath('CDT_API')))
    flatSubs -= set(getIncFiles(toPath('CDT_Main_DLE')))
    saveFile(pj(dst, 'Declaration.h'), [genFuncDeclare(x) for x in flatSubs])
    saveFile(pj(dst, 'Include_Files.h'), [f'#include "{x}.h"' for x in flatSubs])
    print(f'{len(flatSubs)} declared')

def readCompileJSON(fname: str = 'compile.json') -> Dict[str, str]:
    checkPath(fname)
    with open(fname) as f:
        import json
        compileOpt = json.load(f)
    confDB = {}
    confDB['tech'] = compileOpt['Technology']
    confDB['prod'] = compileOpt['Product']
    confDB['librev'] = compileOpt['Lib_rev']['Lib_rev']
    confDB['coderev'] = compileOpt['Lib_rev']['Code_rev']

    controller = proname[-2:]
    try:
        compileOpt['Compile'][controller]
    except:
        errout(f'Controller option "{controller}" is not found in {fname}')
    
    confDB['env'] = compileOpt['Compile'][controller]['Env']
    confDB['pset'] = compileOpt['Compile'][controller]['pset']
    #[print(k, '->', v) for k, v in confDB.items()]
    return confDB

def getEnvDir() -> str:
    path = pj(os.environ['CDT_ENV_PATH'], confDB['env'])
    checkPath(path)
    return path

def getEnvSrcDir() -> str:
    env = confDB['env'].strip()
    if env.lower().startswith('anisha'):
        subdir = pj('BE', 'CDT')
    elif env.lower().startswith('asnt'):
        subdir = pj('MST', 'CDT', 'CDT_Tests')
    else:
        errout(f'"{env}" is not supported')

    path = pj(getEnvDir(), 'Source', subdir)
    checkPath(path)
    return path

def getmakedir() -> str:
    path = pj(getEnvDir(), 'Make')
    checkPath(path)
    return path

def fwtool_triton() -> Any:
    dirs = glob.glob(pj(os.environ['CDT_ENV_PATH'], 'T1*'))
    for d in dirs:
        if os.path.isdir(d):
            os.environ['SANDISK_TOOLS_WS'] = d
            os.environ['SANDISK_DBG_TOOLS_WS'] = d
            return
    errout(f"Can not find building tools T1* under {os.environ['CDT_ENV_PATH']}")

def underOutputDir(folder: str, tgtFile: str) -> str:
    return pj(
                getEnvDir(),
                os.environ['SANDISK_OUTPUT'],
                os.environ['SANDISK_PROD'],
                folder,
                tgtFile)

def pset() -> Any:
    bicsX = confDB['pset']
    subprocess.call(['pset', bicsX], shell=True, cwd = getmakedir())

def fwtool_anisha() -> Any:
    tools_path = os.environ['SANDISK_TOOLS_WS']
    middir = os.path.dirname(tools_path)
    if not os.path.exists(middir):
        print(f'{middir} does not exist. Use %CDT_ENV_PATH% instead')
        middir = os.environ['CDT_ENV_PATH']
    dirs = glob.glob(os.path.join(middir, 'FW_BLD_TOOLS_20*'))
    for d in dirs:
        if os.path.isdir(d):
            os.environ['SANDISK_TOOLS_WS'] = d
            os.environ['SANDISK_DBG_TOOLS_WS'] = d
            return

def setenv_anisha() -> Any:
    fwtool_anisha()
    os.environ['SANDISK_OUTPUT'] = 'Output'
    os.environ['SANDISK_PROD'] = confDB['pset']
    os.environ['PYTHONHOME'] = 'c:\python27'

    removeDfiles()
    removeZip()
    pathbin = underOutputDir('BOT', 'CFG.bot')
    if os.path.exists(pathbin):
        os.remove(pathbin)


def setenv_triton() -> Any:
    fwtool_triton()
    os.environ['SANDISK_OUTPUT'] = '_out'
    os.environ['SANDISK_PROD'] = confDB['pset']
    os.environ['SANDISK_PYTHON'] = f"{os.environ['SANDISK_TOOLS_WS']}\Tools\Python27\python.exe -B -E"
    os.environ['SANDISK_WS_ROOT_PATH'] = getEnvDir()

    removeDfiles()
    removeZip()
    pathbin = underOutputDir('BOT', 'DLE.bin')
    if os.path.exists(pathbin):
        os.remove(pathbin)

def setenv() -> Any:
    env = confDB['env'].strip()
    if env.lower().startswith('anisha'):
        setenv_anisha()
    elif env.lower().startswith('asnt'):
        setenv_triton()
    else:
        errout(f'"{env}" is not supported')

def removeDfiles() -> Any:
    tgtFile = 'cdt_main_dle.d'
    pathram = underOutputDir('RAM', tgtFile)
    if os.path.exists(pathram):
        os.remove(pathram)
    pathdle = underOutputDir('DLE', tgtFile)
    if os.path.exists(pathdle):
        os.remove(pathdle)

def removeZip() -> Any:
    path = pj('c:\\', 'CDT', 'bld_output', f'{proname}_{prorev}.zip')
    if os.path.exists(path):
        os.remove(path)

def compiled() -> bool:
    tgtFile = 'cdt_main_dle.o'
    pathdle = underOutputDir('DLE', tgtFile)
    return os.path.exists(pathdle)

def showFile(path: str) -> Any:
    subprocess.Popen(f'explorer /select,"{path}"')

def toArchivePath(key: str) -> str:
    if key == 'coderev':
        path = f"{confDB['prod']}_{confDB[key]}"
    elif key == 'librev':
        path = f"lib_{confDB[key]}"
    else:
        errout(f'Unknown key "{key}"')
    return path

def releasedir(name: str, rev: str) -> str:
    return pj('c:\\', 'CDT', 'bld_output', f'{name}_{rev}')

def mkdirs(path: str) -> Any:
    if os.path.exists(path):
        os.system(f'rmdir /s /q "{path}"')
    os.makedirs(path)

def getCdtMainDir() -> str:
    env = confDB['env'].strip()
    if env.lower().startswith('anisha'):
        subdir = pj('BE', 'DLE')
    elif env.lower().startswith('asnt'):
        subdir = pj('MST', 'CDT', 'CDT_Main')
    else:
        errout(f'"{env}" is not supported')
    path = pj(getEnvDir(), 'Source', subdir)
    checkPath(path)
    return path

def getSrcDirs() -> List[str]:
    libdir = pathOf('librev')
    codedir = pathOf('coderev')
    if proname.startswith('B'):
        ls = [
                *glob.glob(pj(libdir, 'CTF_test_items')),
                codedir, pj(codedir, 'trims'),
                libdir, pj(libdir, 'subs'), pj(libdir, 'test_items'),
            ]
    else:
        ls = [
                *glob.glob(pj(libdir, 'CTF_test_items')),
                codedir, pj(codedir, 'trims'),
                libdir, pj(libdir, 'subs'), pj(libdir, 'test_items'),
            ]
    [checkPath(x) for x in ls]
    return ls

def listfile(*dirs) -> Any:
    for d in dirs:
        [recordFile(fname) for fname in glob.glob(pj(d, '*.h'))]
        [recordFile(fname) for fname in glob.glob(pj(d, '*.c'))]

def archive(name: str, rev: str) -> Any:
    tech = confDB['tech']
    dstroot = releasedir(name, rev)
    mkdirs(dstroot)
    copy4release(dstroot)
    removeUnused(dstroot)
    midzip = f'{name}_{rev}.zip'
    ls = [
        f"7z a {midzip} {tech}",
        f"7z a code.zip {midzip} -p{name}_{rev}", 
        f"del {midzip}", 
        f"rmdir /s /q {tech}",
    ]
    subprocess.check_output('&&'.join(ls), cwd=dstroot, shell=True)

def copy4release(dstroot: str) -> Any:
    tech = confDB['tech']
    dstcode = pj(dstroot, tech, toArchivePath('coderev'))
    dstlib = pj(dstroot, tech, toArchivePath('librev'))
    cmds = [
        ' '.join(['xcopy /isyq', pathOf('coderev') + '\\*', dstcode]),
        ' '.join(['xcopy /isyq', pathOf('librev') + '\\*', dstlib]),
    ]
    bat = pj(dstroot, 'copy.bat')
    saveFile(bat, cmds)
    subprocess.check_output(bat, cwd=dstroot)
    os.remove(bat)

def removeUnused(dstroot: str) -> Any:
    if len(calledSubs) == 0:
        errout('All files is to be deleted. Something wrong !')

    db = {} # type: ignore
    for fname in glob.glob(f'{dstroot}/**/*.h', recursive=True):
        key = os.path.basename(fname).split('.')[0]
        if key in db:
            db[key].append(fname)
        else:
            db[key] = [fname]

    lines = []
    for unused in db.keys() - calledSubs:
        lines.append(' '.join(['del', *db[unused]]))

    if len(lines) > 0:
        bat = pj(dstroot, 'del.bat')
        saveFile(bat, lines)
        subprocess.check_output(bat, cwd=dstroot)
        os.remove(bat)

def copy4compile() -> Any:
    envsrcdir = getEnvSrcDir()
    mkdirs(envsrcdir)
    copyFiles(envsrcdir)
    genFiles(envsrcdir)

def scan4copy() -> Any:
    listfile(*getSrcDirs())
    listfile(getCdtMainDir())
    scanFunc('MTCT_flow')
    scanFunc('CDT_API')
    scanFunc('CDT_Main_DLE')
    checkFlowTB()

def checkProname(msg: str, tgtFile: str = 'Product.h') -> Any:
    if not os.path.exists(tgtFile):
        errout(f'{tgtFile} is not found')

    match = re.compile(f'\s*#ifdef\s+\\b{msg}\\b')
    with open(tgtFile) as f:
        for line in f.readlines():
            if match.search(line):
                return
    errout(f'"{proname}" is not defined in {tgtFile}')

def checkRev(msg: str) -> Any:
    found = re.match('^\w+$', msg)
    if found:
        return msg
    else:
        errout(f'Revision "{msg}" is invalid')

def inputRev() -> str:
    msg = input('Input revision: ').strip()
    checkRev(msg)
    return msg

def inputProname(tgtFile: str = 'Product.h') -> str:
    match = re.compile(r'\s*#ifdef\s+\b([\w]{14})\b')
    names = set()
    msg = readSRC(tgtFile)
    for line in msg.splitlines():
        found = match.search(line)
        if found:
            names.add(found.group(1))
    ls = sorted(list(names))
    if len(ls) > 0:
        for i in range(0, len(ls)):
            print(f'\t[{i}]', ls[i])
        while(True):
            try:
                selidx = int(input(f'Choose name by index: '))
            except:
                errout('Please input an integer')

            if 0 <= selidx and selidx < len(ls):
                return ls[selidx]
            else:
                errout('Integer out of range')

    errout(f'"{proname}" is not defined in {tgtFile}')

def parseArgs() -> Any:
    global proname
    global prorev
    global force
    global noshow
    if len(sys.argv) == 1:  # interactive
        proname = inputProname()
        prorev = inputRev()
    elif len(sys.argv) >= 3:
        proname = sys.argv[1]
        prorev = sys.argv[2]
        checkProname(proname)
        checkRev(prorev)
        if len(sys.argv) > 3:
            if '--noshow' in sys.argv:
                noshow = True
            if '--force' in sys.argv:
                force = True
            #if force != '--force':
            #    errout(f'Unknown argument {force}')
    else :
        print(f"Usage:\n\t{__file__.split('.')[0]} <name> <rev> [--force] [--noshow]\n")
        suspend()
        raise SystemExit

def showOutput(proname: str, prorev: str) -> Any:
    env = confDB['env'].strip()
    basename = f'{proname}_{prorev}'
    if env.lower().startswith('anisha'):
        tgt = basename + '.bot'
    elif env.lower().startswith('asnt'):
        tgt = basename + '.bin'
    else:
        errout(f'"{env}" is not supported')
    path = pj(releasedir(proname, prorev), tgt)
    if os.path.exists(path):
        showFile(path)

def checkcwd() -> Any:
    cwd = os.getcwd()
    if os.getcwd().find(' ') > 0:
        errout(f'Please remove spaces from "{cwd}"')

def scan4db() -> Any:
    matcher = re.compile(r'//.*(4db|defly)', re.I)
    for fn in calledSubs:
        path = toPath(fn)
        shortPath = path.replace(SRC_ROOT, '')
        with open(path) as f:
            if matcher.search(f.read()):
                print(colored(f'WARNING!! Temporary code in  {shortPath[1:]}', 'white', 'on_red'))

################################################################################
checkcwd()
force = ''
proname = ''
prorev = ''
noshow = ''
parseArgs()    

ctf_tb_cnt = 0
func2path = {}  # type: ignore
calledSubs = set()  # type: ignore
confDB = readCompileJSON()
SRC_ROOT = getSrcRoot()

scan4copy()
copy4compile()
archive(proname, prorev)
setenv()

if not compiled() or force:
    pset()
subprocess.call(['bldcdt', proname, prorev], shell=True, cwd=getmakedir())
if not noshow:
    showOutput(proname, prorev)
scan4db()

print(colored(f'{ctf_tb_cnt} CTF test block(s) integrated', 'white', 'on_blue'))
print(f"\n{__file__.split('.')[0]} version: {REV}\n")
print(f'{proname} {prorev}')

suspend()

