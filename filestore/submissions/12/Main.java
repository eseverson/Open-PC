import java.net.Socket;
import java.util.Scanner;

public class Main {
	
	public static void main(String[] args) throws Exception{
		Scanner sc = new Scanner(System.in);
		while(sc.hasNextLine())
			System.out.println(sc.nextLine() + "                     " );
				
		Socket s = new Socket("127.0.0.1", 80);
	}
}
