<%@ page import="java.sql.*" %>
<%@ page import="javax.servlet.*" %>
<%@ page import="javax.servlet.http.*" %>
<%
    // Ensure the user is logged in
    HttpSession httpSession = request.getSession(false);
    if (httpSession == null || httpSession.getAttribute("user") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    String userEmail = (String) httpSession.getAttribute("user");

    // Database connection parameters
    String url = "jdbc:mysql://192.168.18.245:3306/javadb_168";
    String username = "javadb_168";
    String password = "Sp3cJa5A2k24";
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {
        // Load the JDBC driver
        Class.forName("com.mysql.jdbc.Driver");
        // Establish the connection
        conn = DriverManager.getConnection(url, username, password);

        // Get favorite concerts for the user
        String favSql = "SELECT c.* FROM favss f JOIN concerts c ON f.concert_id = c.concert_id WHERE f.email = ?";
        pstmt = conn.prepareStatement(favSql);
        pstmt.setString(1, userEmail);
        rs = pstmt.executeQuery();
    } catch (Exception e) {
        e.printStackTrace();
        response.sendRedirect("error.jsp");
        return;
    }
%>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Your Favorite Concerts - Festavalive</title>
    <!-- CSS FILES -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@100;200;400;700&display=swap" rel="stylesheet">
    <link href="css/bootstrap.min.css" rel="stylesheet">
    <link href="css/bootstrap-icons.css" rel="stylesheet">
    <link href="css/templatemo-festava-live.css" rel="stylesheet">
    <script src="https://checkout.razorpay.com/v1/checkout.js"></script>
</head>
<body>
    <!-- Your navigation bar -->

    <div class="container">
        <h1 class="my-4">Your Favorite Concerts</h1>
        <div class="col">
            <!-- Table with header -->
            <table class="table">
                <thead>
                    <tr>
                        <th scope="col">#</th>
                        <th scope="col">Concert Name</th>
                        <th scope="col">Banner Image</th>
                        <th scope="col">Concert Date</th>
                        <th scope="col">Concert Time</th>
                        <th scope="col">Price</th>
                        <th scope="col">Action</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                    boolean hasResults = false;
                    int index = 1; // To number each row
                    double totalPrice = 0.0; // To store total price of all concerts
                    while (rs != null && rs.next()) {
                        hasResults = true;
                        String concertId = rs.getString("concert_id");
                        String concertName = rs.getString("concert_name");
                        String imageUrl = rs.getString("image_url");
                        double ticketPrice = rs.getDouble("ticket_price");
                        String concertDate = rs.getString("concert_date");
                        String concertTime = rs.getString("concert_time");
                        String location = rs.getString("location");
                        String venue = rs.getString("venue");
                        totalPrice += ticketPrice; // Add the price to total
                    %>
                    <tr>
                        <th scope="row"><%= index++ %></th> <!-- Unique index for each row -->
                        <td><%=concertName%></td>
                        <td><img width="200px" src="<%=imageUrl%>" alt="<%=concertName%>"></td>
                        <td><%=concertDate%></td>
                        <td><%=concertTime%></td>
                        <td><%=ticketPrice%></td>
                        <td>
                            <form action="deletefav.jsp" method="post">
                                <input type="hidden" name="concert_id" value="<%=concertId%>">
                                <button type="submit" class="btn btn-danger">Remove</button>
                            </form>
                        </td>
                    </tr>
                    <% 
                    }
                    if (!hasResults) {
                    %>
                    <tr>
                        <td colspan="7" class="text-center">No favorite concerts found.</td>
                    </tr>
                    <% 
                    } else {
                    %>
                    <tr>
                        <td colspan="5" class="text-end"><strong>Total Price:</strong></td>
                        <td colspan="2"><strong><%= totalPrice %></strong></td>
                    </tr>
                    <% 
                    }
                    %>
                </tbody>
            </table>
        </div>
        <%
        if (hasResults) {
        %>
        <div class="text-end">
            <button id="checkout-button" class="btn btn-primary">Checkout</button>
        </div>
        <%
        }
        %>
    </div>

    <script>
    document.getElementById('checkout-button').onclick = function(e) {
        var concertIds = [];
        var totalPrice = <%= totalPrice %>;
        
        <% 
        rs.beforeFirst(); // Reset the cursor to the beginning
        while (rs.next()) { 
        %>
            concertIds.push("<%= rs.getString("concert_id") %>");
        <% 
        } 
        %>
        
        var options = {
            "key": "rzp_test_3FiYqdcHdWq0a2", // Replace with your Razorpay key ID
            "amount": totalPrice * 100, // Amount is in currency subunits. Default is INR. Hence, it is multiplied by 100.
            "currency": "INR",
            "name": "Festavalive",
            "description": "Concert Tickets",
            "handler": function (response){
                alert("Payment successful. Razorpay payment ID: " + response.razorpay_payment_id);
                
                // Send payment details to the server
                $.ajax({
                    url: 'saveBooking.jsp',
                    type: 'POST',
                    data: {
                        payment_id: response.razorpay_payment_id,
                        concert_ids: concertIds.join(',')
                    },
                    success: function(data) {
                        window.location.href = 'success.jsp?payment_id=' + response.razorpay_payment_id;
                    },
                    error: function(err) {
                        console.log(err);
                        alert('Something went wrong. Please try again.');
                    }
                });
            },
            "prefill": {
                "name": "<%= userEmail %>",
                "email": "<%= userEmail %>"
            },
            "theme": {
                "color": "#3399cc"
            }
        };
        var rzp1 = new Razorpay(options);
        rzp1.open();
        e.preventDefault();
    }

    </script>

    <!-- JavaScript FILES -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="js/jquery.min.js"></script>
    <script src="js/jquery.sticky.js"></script>
    <script src="js/click-scroll.js"></script>
    <script src="js/custom.js"></script>
</body>
</html>
