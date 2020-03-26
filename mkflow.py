from termcolor import colored 
from colorama import init 
init() 

def errmsg(msg):
    print(colored(msg, 'white', 'on_red'))

def findXML():
    from os import listdir
    xmlFiles = list(filter(lambda f: f.endswith('.xml'), listdir('.')))
    if len(xmlFiles) != 1:
        errmsg('\n\t'.join(['Expect one XML only:', *xmlFiles]) + '\n')
        raise SystemExit
    return xmlFiles[0]

def genFlowItem(xmlNode):
    lst = xmlNode.attrib['name'].split('__')
    name = f'"{lst[2]}"'
    return name

def readXMLFlow(flow = None):
    import xml.etree.ElementTree as ET
    root = ET.parse(XML_FILE).getroot()
    path = f'.//TestBlock[@flow=\'{flow}\']' if flow else f'.//TestBlock[@flow]'
    return [genFlowItem(x) for x in root.findall(path)]

def readFlowLib():
    try:
        f = open(SVN_FILE, 'r')
        lines = f.readlines()
        f.close()
        return lines
    except:
        errmsg(f'Can not find {SVN_FILE}')
        raise SystemExit

def cherryPick(expFlow, libFlow):
    import re
    flowItemRegExp = re.compile('\s*{\s*\d+,')
    actFlow = []
    for tb in expFlow:
        tbLower = tb.lower()
        isValidFlowItem = lambda line: line.lower().find(tbLower) > -1 and flowItemRegExp.match(line)
        found = list(filter(isValidFlowItem, libFlow))
        if len(found) > 0:
            actFlow.append(found[0])
        else:
            errmsg(f'Missing {tb}')
            actFlow.append(f'Missing {tb}\n')
    return actFlow
            
def output(actFlow):
    from MTCT_flow import head, tail
    outf = open('__' + SVN_FILE, 'w')
    outf.write(head)
    outf.write(''.join(actFlow))
    outf.write(tail)
    outf.close()

#===========================  Execution starts here  ============================

XML_FILE = findXML()
SVN_FILE = 'MTCT_flow.h'
ACT_FLOW_FILE = '__' + SVN_FILE

xmlFlow = readXMLFlow()
svnFlow = readFlowLib()
actFlow = cherryPick(xmlFlow, svnFlow)

output(actFlow)
print(f'\nCreated {ACT_FLOW_FILE} from {XML_FILE}\n')

