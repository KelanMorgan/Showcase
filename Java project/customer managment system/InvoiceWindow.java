package loginPage;

import javax.swing.*;
import java.awt.*;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

public class InvoiceWindow extends JFrame {
    private JLabel titleLabel;
    private JLabel totalLabel;

    public InvoiceWindow(int userID) {
        setTitle("Invoice");
        setSize(600, 400);
        setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);

        JPanel invoicePanel = new JPanel();
        invoicePanel.setLayout(new BorderLayout());

        // Create a title label for the invoice
        titleLabel = new JLabel("Invoice");
        titleLabel.setFont(new Font("Arial", Font.BOLD, 20));
        titleLabel.setHorizontalAlignment(JLabel.CENTER);
        titleLabel.setBorder(BorderFactory.createEmptyBorder(10, 0, 10, 0)); // Adjust vertical padding
        invoicePanel.add(titleLabel, BorderLayout.NORTH);

        // Create a panel for displaying the invoice items
        JPanel invoiceItemsPanel = new JPanel(new GridLayout(0, 4));
        invoiceItemsPanel.setBorder(BorderFactory.createEmptyBorder(0, 10, 0, 10)); // Adjust padding

        // Add labels for column headers
        invoiceItemsPanel.add(new JLabel("Product ID"));
        invoiceItemsPanel.add(new JLabel("Product Name"));
        invoiceItemsPanel.add(new JLabel("Quantity"));
        invoiceItemsPanel.add(new JLabel("Price"));

        // Query the database for cart items and populate the invoice
        Connection con = null;
        Statement stat = null;
        ResultSet result = null;

        double totalCost = 0.0;

        try {
            con = DriverManager.getConnection("jdbc:mysql://localhost/manage", "root", "");
            stat = con.createStatement();
            result = stat.executeQuery("SELECT p.productID, p.name, ci.quantity, ci.price " +
                    "FROM product p " +
                    "INNER JOIN cartitems ci ON p.productID = ci.productID " +
                    "WHERE ci.customerID = " + userID + " AND ci.purchased = false");

            while (result.next()) {
                int productID = result.getInt("productID");
                String productName = result.getString("name");
                int quantity = result.getInt("quantity");
                double price = result.getDouble("price");

                invoiceItemsPanel.add(new JLabel(String.valueOf(productID)));
                invoiceItemsPanel.add(new JLabel(productName));
                invoiceItemsPanel.add(new JLabel(String.valueOf(quantity)));
                invoiceItemsPanel.add(new JLabel("€" + price));

                totalCost += quantity * price;
            }
        } catch (SQLException ex) {
            ex.printStackTrace();
        } finally {
            try {
                if (result != null) result.close();
                if (stat != null) stat.close();
                if (con != null) con.close();
            } catch (SQLException ex) {
                ex.printStackTrace();
            }
        }

        // Create a total cost label
        totalLabel = new JLabel("Total Cost: €" + totalCost);
        totalLabel.setHorizontalAlignment(JLabel.RIGHT);
        invoiceItemsPanel.add(totalLabel);

        // Create a scroll pane for the invoice items panel
        JScrollPane scrollPane = new JScrollPane(invoiceItemsPanel);
        invoicePanel.add(scrollPane, BorderLayout.CENTER);

        add(invoicePanel);

        setLocationRelativeTo(null);
        setVisible(true);
    }
}