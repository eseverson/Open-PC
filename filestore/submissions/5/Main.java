import java.util.Scanner;
import java.lang.Thread;

public class Main {
	
	public static void main(String[] args) throws Exception{
		Scanner sc = new Scanner(System.in);
		while(sc.hasNextLine())
			System.out.println(sc.nextLine() + "                     " );
		//Thread.sleep(12000);
	}
}
