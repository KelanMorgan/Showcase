package loginPage;

import java.awt.FlowLayout;
import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.Insets;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Timer;

import javax.swing.JButton;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTable;
import javax.swing.JTextField;
import javax.swing.table.DefaultTableModel;

public class AddToCart extends JFrame{
	private JButton logOut;
	private JButton addToCart;
	private JButton removeFromCart;
	private JButton viewInvoice;
	
	private JTextField quantityText;
	private JLabel quantityLabel;
	
	private JTable products;
	private JTable cart;
	
	private JLabel productsLabel;
	private JLabel cartLabel;
	
	private JPanel root;
	private JPanel buttons;
	private JPanel quantity;
	
	private GridBagConstraints grid;
	
	public AddToCart(int userID) {
		super("Add to cart");
		setLayout(new FlowLayout());
		
		//set window defaults
		setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		setSize(1150,550);
		setVisible(true);
		setLocation(400,400);
		
		//Initialize variables
		grid = new GridBagConstraints();
		root = new JPanel(new GridBagLayout());
		buttons = new JPanel(new GridBagLayout());
		
		Connection con = null;
	    Statement stat = null;
	    ResultSet result = null;
		
	    //labels
	    productsLabel = new JLabel("Products");
        grid.gridx = 0;
		grid.gridy = 0;
		root.add(productsLabel, grid);
		
		cartLabel = new JLabel("Cart");
        grid.gridx = 2;
		grid.gridy = 0;
		root.add(cartLabel, grid);
		
		//quantity
		quantity = new JPanel(new GridBagLayout());
        grid.gridx = 0;
		grid.gridy = 0;
		buttons.add(quantity, grid);
		
		quantityLabel = new JLabel("Quantity: ");
		grid.gridx = 0;
		grid.gridy = 0;
		quantity.add(quantityLabel, grid);
		
		quantityText = new JTextField();
		grid.gridx = 1;
		grid.gridy = 0;
		quantityText.setColumns(5);
		quantity.add(quantityText, grid);
		
		//buttons
        grid.gridx = 1;
		grid.gridy = 1;
		root.add(buttons, grid);
		
		addToCart = new JButton("Add to cart >");
        grid.gridx = 0;
		grid.gridy = 1;
		grid.insets = new Insets(10, 10, 0, 10); 
		grid.fill = GridBagConstraints.HORIZONTAL;
		buttons.add(addToCart, grid);
		
		removeFromCart = new JButton("< Remove From Cart");
        grid.gridx = 0;
		grid.gridy = 2;
		grid.insets = new Insets(10, 10, 0, 10); 
		grid.fill = GridBagConstraints.HORIZONTAL;
		buttons.add(removeFromCart, grid);
		
		//logout button
		logOut = new JButton("Log out");
        grid.gridx = 0;
		grid.gridy = 2;
		grid.anchor = GridBagConstraints.WEST;
		grid.fill = GridBagConstraints.NONE;
		root.add(logOut, grid);
		
		//Invoice button
		viewInvoice = new JButton("View Invoice");
        grid.gridx = 2;
        grid.gridy = 2;
        grid.anchor = GridBagConstraints.EAST;
        grid.fill = GridBagConstraints.NONE;
        root.add(viewInvoice, grid);
	    
	    try {
	        // make a connection to the database
	        con = DriverManager.getConnection("jdbc:mysql://localhost/manage", "root", "");

	        // Create a statement
	        stat = con.createStatement();

	        // query the db
	        result = stat.executeQuery("SELECT * FROM product");

	        // products table
	        DefaultTableModel model = new DefaultTableModel();
	        model.addColumn("Product ID");
	        model.addColumn("Product Name");
	        model.addColumn("Description");
	        model.addColumn("Price");
	        model.addColumn("Quantity");

	        while (result.next()) {
	            int id = result.getInt("productId");
	            String name = result.getString("name");
	            String discription = result.getString("description");
	            double price = result.getDouble("price");
	            int quantity = result.getInt("totalQuantity");

	            model.addRow(new Object[]{id, name, discription, price, quantity});
	        }

	        products = new JTable(model);
	        grid.gridx = 0;
			grid.gridy = 1;
			grid.fill = GridBagConstraints.HORIZONTAL;
			root.add(new JScrollPane(products), grid);
			
			//cart
			// query the db
			try { result.close(); } catch (SQLException ex) {}
	        result = stat.executeQuery(	"SELECT p.productID, p.name, p.description, ci.quantity, ci.price "
	        						+	"FROM product p "
	        						+	"INNER JOIN cartitems ci ON p.productID = ci.productID "
	        						+ 	"WHERE ci.customerID = " + userID + " AND ci.purchased = false");

	        // results
	        model = new DefaultTableModel();
	        model.addColumn("Product ID");
	        model.addColumn("Name");
	        model.addColumn("description");
	        model.addColumn("price");
	        model.addColumn("quantity");

	        while (result.next()) {
	            int id = result.getInt("productID");
	            String name = result.getString("name");
	            String description = result.getString("description");
	            double price = result.getDouble("price");
	            int quantity = result.getInt("quantity");

	            model.addRow(new Object[]{id, name, description, price, quantity});
	        }

	        cart = new JTable(model);
	        grid.gridx = 2;
			grid.gridy = 1;
			grid.fill = GridBagConstraints.HORIZONTAL;
			root.add(new JScrollPane(cart), grid);
			
	    } catch (SQLException ex) {
	        ex.printStackTrace();
	    } finally {
	        // Close the resources
	        try { result.close(); } catch (SQLException ex) {}
	        try { stat.close(); } catch (SQLException ex) {}
	        try { con.close(); } catch (SQLException ex) {}
	    }
		
		add(root);
		
		// action listener to the "log out" button
		logOut.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				LoginGui login = new LoginGui();
	            login.setVisible(true);
	            dispose();
			}
		});
		
		// action listener to the "add to cart" button
		addToCart.addActionListener(new ActionListener(){
			public void actionPerformed(ActionEvent e) {
		        try {
		        	Connection con = null;
		    	    PreparedStatement stat = null;
		        	
		        	con = DriverManager.getConnection("jdbc:mysql://localhost/manage", "root", "");

		        	// query the db
		            int quantity = Integer.parseInt(quantityText.getText());
		            
		            //get the id of the selected row in the products table
		            Object productID = products.getValueAt(products.getSelectedRow(), 0);
		            
			        // Create a statement
			        stat = con.prepareStatement("IF EXISTS(SELECT * FROM product WHERE productID = " + productID + " AND totalquantity >= " + quantity + ") THEN "
			        		+ "IF EXISTS(SELECT * FROM cartitems WHERE productID = " + productID + " AND purchased = 0 AND customerID = " + userID + ") THEN "
			        		+ "UPDATE cartitems SET quantity = quantity + " + quantity + ", price = (SELECT price FROM product WHERE productID = " + productID + ") * (quantity) WHERE productID = " + productID + " AND customerID = " + userID + "; "
			        		+ "ELSE "
			        		+ "INSERT INTO cartitems (productID, quantity, price, customerID, purchased) VALUES (" + productID + ", " + quantity + ", (SELECT price FROM product WHERE productID = " + productID + ") * " + quantity + ", " + userID + ", 0); "
			        		+ "END IF; "
			        		+ "UPDATE product SET totalquantity = totalquantity - " + quantity + " WHERE productID = " + productID + "; "
			        		+ "END IF; ");
			            
			        stat.executeUpdate();
			        
			        AddToCart addToCart = new AddToCart(userID);
		            addToCart.setVisible(true);
		            dispose();
		        } catch (NumberFormatException ex) {
		        	JOptionPane.showMessageDialog(root, "quantity must be a number", "Value Error", JOptionPane.ERROR_MESSAGE);	
		        } catch (SQLException ex) {
			        ex.printStackTrace();
			    } 
			}
		});
		
		// action listener to the "remove from cart" button
		removeFromCart.addActionListener(new ActionListener(){
			public void actionPerformed(ActionEvent e) {
				try {
		        	Connection con = null;
		    	    PreparedStatement stat = null;
		        	
		        	con = DriverManager.getConnection("jdbc:mysql://localhost/manage", "root", "");

		        	// query the db
		            int quantity = Integer.parseInt(quantityText.getText());
		            
		            //get the id of the selected row in the products table
		            Object productID = cart.getValueAt(cart.getSelectedRow(), 0);
		            
			        // Create a statement
		            
		            stat = con.prepareStatement("UPDATE cartitems \r\n"
		            		+ "SET quantity = quantity - " + quantity + ", \r\n"
		            		+ "    price = (SELECT price FROM product WHERE productID = " + productID + ") * (quantity)\r\n"
		            		+ "WHERE productID = " + productID + " \r\n"
		            		+ "  AND customerID = " + userID + " \r\n"
		            		+ "  AND purchased = false; \r\n");
		            		
		            stat.executeUpdate();
		            
		            stat = con.prepareStatement("UPDATE product \r\n"
		            		+ "SET totalquantity = totalquantity + " + quantity + " \r\n"
		            		+ "WHERE productID = " + productID + "; ");
		            
		            stat.executeUpdate();
			        
			        AddToCart addToCart = new AddToCart(userID);
		            addToCart.setVisible(true);
		            dispose();
		        } catch (NumberFormatException ex) {
		        	JOptionPane.showMessageDialog(root, "quantity must be a number", "Value Error", JOptionPane.ERROR_MESSAGE);	
		        } catch (SQLException ex) {
			        ex.printStackTrace();
			    }
			}
		});
		
        // action listener to the "View Invoice" button
        viewInvoice.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
            	InvoiceWindow invoiceWindow = new InvoiceWindow(userID);
                invoiceWindow.setVisible(true);
            }
        });
	}
}
