package loginPage;
import java.sql.*;

import java.awt.FlowLayout;
import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.Insets;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

import javax.swing.JButton;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JTextField;
import javax.swing.plaf.DimensionUIResource;

public class LoginGui extends JFrame{
	
	//attributes
	private JLabel usernameLabel;
	private JLabel passwordLabel;
	
	private JTextField usernameText;
	private JTextField passwordText;
	
	private JButton login;
	private JButton clear;
	
	private GridBagConstraints grid;
	
	private JPanel root;
	private JPanel inputs;
	private JPanel create;
	private JPanel buttons;
    
	public LoginGui(){
		super("Login");
		setLayout(new FlowLayout());
		
		//set window defaults
		setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		setSize(400,150);
		setVisible(true);
		setLocation(400,400);
		
		//Initialize panels
		grid = new GridBagConstraints();
		root = new JPanel(new GridBagLayout());
		inputs = new JPanel(new GridBagLayout());
		create = new JPanel(new GridBagLayout());
		buttons = new JPanel(new GridBagLayout());
		
		//add panels to the root panel
		grid.gridx = 0;
		grid.gridy = 0;
		root.add(inputs, grid);
		
		grid.gridx = 0;
		grid.gridy = 1;
		root.add(create, grid);
		
		grid.gridx = 0;
		grid.gridy = 2;
		root.add(buttons, grid);
		
		//add labels and text fields to the inputs panel
		usernameLabel = new JLabel("Username: ");
		grid.gridx = 0;
		grid.gridy = 0;
		inputs.add(usernameLabel, grid);
		
		usernameText = new JTextField();
		usernameText.setPreferredSize(new DimensionUIResource(200,25));
		grid.gridx = 1;
		grid.gridy = 0;
		inputs.add(usernameText, grid);
		
		passwordLabel = new JLabel("Password: ");
		grid.gridx = 0;
		grid.gridy = 1;
		inputs.add(passwordLabel, grid);
		
		passwordText = new JTextField();
		passwordText.setPreferredSize(new DimensionUIResource(200,25));
		grid.gridx = 1;
		grid.gridy = 1;
		inputs.add(passwordText, grid);
		
		//add the buttons to the button panel
		login = new JButton(" Login ");
		grid.gridx = 0;
		grid.gridy = 0;
		grid.insets = new Insets(0, 0, 0, 60); 
		buttons.add(login, grid);
		
		clear = new JButton(" Clear ");
		grid.gridx = 1;
		grid.gridy = 0;
		grid.insets = new Insets(0, 60, 0, 0); 
		buttons.add(clear, grid);
		
		
		add(root);
		
		// action listeners for the buttons
		login.addActionListener(new ActionListener(){
			public void actionPerformed(ActionEvent e) {
				Connection con = null;
			    Statement stat = null;
			    ResultSet result = null;
			    
			    String username;
			    String password;
				
			    try {
			        // make a connection to the database
			        con = DriverManager.getConnection("jdbc:mysql://localhost/manage", "root", "");
		
			        // Create a statement
			        stat = con.createStatement();
		
			        // query the db
			        result = stat.executeQuery("SELECT * FROM customer");
		
			        // results
			        boolean found = false;
			        
			        while (result.next()) {
			            username = result.getString("userName");
			            password = result.getString("password");
			            if (username.equals(usernameText.getText()) && password.equals(passwordText.getText())) {
			                found = true;
			                break;
			            }
			        }
			        if (found) {
			        	AddToCart addToCart = new AddToCart(result.getInt("customerID"));
			            addToCart.setVisible(true);
			            dispose();
			        }
			        else if (usernameText.getText().equals("") || passwordText.getText().equals("")){
			        	JOptionPane.showMessageDialog(root, "all fields must be filled out", "Login Error", JOptionPane.ERROR_MESSAGE);
			        }
			    	else {
			        	JOptionPane.showMessageDialog(root, "Username or password are incorect", "Login Error", JOptionPane.ERROR_MESSAGE);
			        }
			    } catch (SQLException ex) {
			        ex.printStackTrace();
			    } finally {
			        // Close the resources
			        try { result.close(); } catch (Exception ex) {}
			        try { stat.close(); } catch (Exception ex) {}
			        try { con.close(); } catch (Exception ex) {}
			    }
			}
		});
		
		clear.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				usernameText.setText("");
				passwordText.setText("");
			}
		});
	}
}
