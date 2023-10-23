package loginPage;

import javax.swing.JFrame;

public class LoginDriver {

	public static void main(String[] args) {
		LoginGui login = new LoginGui();
		
		login.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		login.setSize(400,150);
		login.setVisible(true);
		login.setLocation(400,400);
	}

}
