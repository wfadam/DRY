/**
 * Returns an integer that is parsed from a string with determined format
 * <p>
 *
 * @param	s	A string that starts with "set_Ignore_Limit_to_" followed by a number like "10" in dec or "0x10" in hex
 * @return      an integer converted from the tail of the input string
 */
public class SetIgnoreBitLimit {

	public static void main( String[] args ) {

		setIgnoreBitLimit( "set_Ignore_Limit_to_0" );
		setIgnoreBitLimit( "set_Ignore_Limit_to_10" );
		setIgnoreBitLimit( "set_Ignore_Limit_to_0x10" );
	}

    private static int setIgnoreBitLimit(String s) {
		int ignoreBitLimit = 0;
        try {
            ignoreBitLimit = Integer.decode( s.substring( s.lastIndexOf('_') + 1 ) );
            System.out.printf("\n*** Setting Ignore Bit Limit to %d\n", ignoreBitLimit);
        } catch ( Exception e ) {
            System.err.printf("\n*** Cannot get valid integer from \"%s\" ***\n\n", s);
            throw new RuntimeException(e);
        }
		return ignoreBitLimit;
    }

}
