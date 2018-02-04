import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStreamWriter;

final public class FastWriter {

	private static java.util.Map<String,String[]> fmtTab = new java.util.HashMap<String,String[]>();
	private static BufferedWriter out = new BufferedWriter(new OutputStreamWriter(System.out), 512);
	private static String regPat = "%[0-9]*[dxX]";
	final public static int NANDBLOCKS = 0x1000;
	final public static int NANDPLANES = 2;

	public static void main(String...args){


		long t0 = System.currentTimeMillis();

		for(int dut = 1; dut <= 1; dut ++) {
			for(int channel = 1; channel <= 1; channel ++) {
				for(int bb = 0; bb< NANDBLOCKS; bb ++) {
					FastWriter.printf("\tDUT%02d CH%d Chip%d Failed block 0x%4X (MLC page 0x%7X) CMD71 PLANE%d PRG/ERASE/BIST STATUS\n", 
							dut, channel, bb/NANDBLOCKS+1, bb, bb<<8, bb%NANDPLANES);
				}
			}
			FastWriter.flush();
		}
		double fastSec = (System.currentTimeMillis() - t0) / 1000.0;
		System.err.printf("FastWriter prints %d times in %.3fs\n", NANDBLOCKS, fastSec);

		t0 = System.currentTimeMillis();
		for(int dut = 1; dut <= 1; dut ++) {
			for(int channel = 1; channel <= 1; channel ++) {
				for(int bb = 0; bb< NANDBLOCKS; bb ++) {
					System.out.printf("\tDUT%02d CH%d Chip%d Failed block 0x%4X (MLC page 0x%7X) CMD71 PLANE%d PRG/ERASE/BIST STATUS\n", 
							dut, channel, bb/NANDBLOCKS+1, bb, bb<<8, bb%NANDPLANES);
				}
			}
		}
		double slowSec = (System.currentTimeMillis() - t0) / 1000.0;
		System.err.printf("System.out prints %d times in %.3fs\n", NANDBLOCKS, slowSec);
		System.err.printf("FastWriter is x%.1f times as fast as System.out\n", slowSec / fastSec);

	}

	final public static void println(String str) {
		try {
			out.write(str + "\n");
		} catch(IOException e) {
			throw new RuntimeException(e);
		}
	}

	final public static void printf(String fmt, int...args) {
		if(out == null) {
			return;
		}

		String[] fields = fmtTab.get(fmt);
		if(null == fields) {
			fields = getFields(fmt);
			fmtTab.put(fmt, fields);
		} 

		log(fields, args);
	}

	private static String[] getFields(String fmt) {
		String[] names = fmt.split(regPat);
		String[] typ = types(fmt);
		return zip(fmt, names, typ);
	}

	private static String[] zip(String original, String[] names, String[] typ) {
		String[] fields = new String[names.length + typ.length];

		int k = 0;
		fields = new String[names.length + typ.length];
		for(int i=0; i<names.length-1; i++) {
			fields[k] = names[i];
			k++;
			fields[k] = typ[i];
			k++;
		}
		fields[k] = names[names.length-1];

		return fields;
	}

	private static String[] types(final String fmt) {
		int len = fmt.split(regPat).length;

		if(len <= 1) {
			return new String[]{};
		}

		String[] typ = new String[len - 1];

		java.util.regex.Matcher m = java.util.regex.Pattern.compile(regPat).matcher(fmt);
		int i = 0;
		while(m.find()){
			typ[i] = m.group();
			i++;
		}

		return typ;
	}

	final private static char[] hex = {
		'0', '1', '2', '3',
		'4', '5', '6', '7',
		'8', '9', 'A', 'B',
		'C', 'D', 'E', 'F',
	};

	final private static char[] toDecChar(final int i) {
		if(i < 0) {
			return new char[]{};
		}
		if(i == 0) {
			return new char[]{hex[i]};
		}

		int numOfDigit = 0;
		int shiftVal = i;
		while(shiftVal > 0) {
			shiftVal = shiftVal/10;
			++numOfDigit;
		}
		char[] decC = new char[numOfDigit];

		decC[numOfDigit - 1] = hex[i % 10];
		for(int digitNum = 1; digitNum < numOfDigit; digitNum++) {
			decC[numOfDigit - 1 - digitNum] = hex[(i / ((int)Math.pow(10.0,digitNum*1.0))) % 10];
		}

		return decC;
	}


	final private static char[] toHexChar(final int i) {
		if(i <= 0) {
			return new char[]{hex[0]};
		}

		int numOfDigit = 0;
		int shiftVal = i;
		while(shiftVal > 0) {
			shiftVal = shiftVal>>4;
			++numOfDigit;
		}

		char[] hexC = new char[numOfDigit];

		for(int digitNum=0; digitNum<numOfDigit; digitNum++) {
			hexC[numOfDigit -1 -digitNum] = hex[ (i >> (digitNum * 4))&0xF ];
		}

		return hexC;
	}

	final public static void log(String[] fields, int...args) {
		if(args == null) {
			throw new RuntimeException("At least an int is required");
		}

		try {
			int i = 0;
			for(String str : fields) {
				if(i > args.length) {
					throw new RuntimeException("Unmatched count of format string and arguments");
				}

				if(str.startsWith("%")){
					if(str.endsWith("X") || str.endsWith("x")) {
						out.write(toHexChar(args[i]));
						++i;
					} else if(str.endsWith("d")) {
						out.write(toDecChar(args[i]));
						++i;
					}
				} else {
					out.write(str);
				}
			}
		} catch(java.io.IOException e) {
			throw new RuntimeException(e);
		}
	}

	final public static void flush(){
		try {
			out.flush();
		} catch(java.io.IOException e) {
			throw new RuntimeException(e);
		}
	}
}
