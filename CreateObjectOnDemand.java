import java.lang.reflect.Constructor;
import java.lang.reflect.Method;

public class CreateObjectOnDemand {

	public static void main ( String[] args ) {
		System.out.println("Running...");
		try {
			Object x = getInstance( "B", "netflix" );
			runMethod ( x, "show", "hard way" );

			B b = new B("apple");
			b.show("easy way");

		} catch ( Exception e ) {
			throw new RuntimeException ( e );
		}
	}

	static Object getInstance ( String className, Object...args ) {
		Object o;
		try {
			o = Class.forName( className ).getConstructor(String.class).newInstance( args );
		} catch ( Exception e ) {
			throw new RuntimeException ( e );
		}
		return o;
	}

	static Object runMethod ( Object o, String mName, Object...args ) {
		Object rslt;
		try {
			rslt = o.getClass().getMethod( mName, String.class).invoke( o, args );
		} catch ( Exception e ) {
			throw new RuntimeException ( e );
		}
		return rslt;
	}

}

class B {
	private String name;
	public B ( String name ) {
		this.name = name;
	}

	public void show ( String s ) {
		System.out.printf( "Instance \"%s\" of %s was constructed %s\n", this.name, getClass(), s );
	}
}



