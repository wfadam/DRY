import java.util.*;

public class DungeonGame {
        final static int[][] dungeon = {
                { 1 , 1 , 2 , 3, 3 },
                { 4 , 4 , 5 , 6, 6 },
                { 7 , 7 , 8 , 9, 9 },
                { 1 , 1 , 2 , 3, 3 },
                { 4 , 4 , 5 , 6, 6 },
                { 7 , 7 , 8 , 9, 9 },
                { 1 , 1 , 2 , 3, 3 },
                { 4 , 4 , 5 , 6, 6 },
                { 7 , 7 , 8 , 9, 9 },
                { 1 , 1 , 2 , 3, 3 },
                { 4 , 4 , 5 , 6, 6 },
                { 7 , 7 , 8 , 9, 9 },

        };
        static Integer[] xy = {0, 0};

        public static void main(String...args){
                System.out.println( "=======================> Dungeon Map" );
                for ( int[] row : dungeon ) {
                        System.out.println( Arrays.toString(row) );
                }
                System.out.println( "\n=======================> Path To Princess" );
                preorderTraversal(50, dungeon);
        }


        final public static void preorderTraversal(int health, int[][] mapArr) {
                if ( mapArr.length == 0 || mapArr[0].length == 0 ) return;

                Integer[] xY = {0,0};
                Deque<Integer[]> s = new ArrayDeque<Integer[]>();
                s.push( new Integer[]{ xY[0], xY[1], health } );
                while ( ! s.isEmpty() ) { 
                        health += mapArr[ xY[0] ][ xY[1] ];
                        System.out.printf("%s:%d ,", Arrays.toString(xY), health);
                        if ( ( xY[0]+1 == mapArr.length ) && ( xY[1]+1 == mapArr[0].length ) ) { 
                                System.out.println();
                        }   

                        if ( xY[1]+1 <  mapArr[0].length ) { // save right
                                s.push( new Integer[]{ xY[0], xY[1]+1, health  } );
                        }   
                        if ( xY[0]+1 < mapArr.length ) { // move down
                                xY[0]+=1;;
                        } else {
                                Integer[] c = s.pop();
                                xY = new Integer[]{ c[0], c[1] };
                                health = c[2];
                        }   
                }   

        }   
}
