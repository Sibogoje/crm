<?php
// Test script to test the quotes API endpoint

// Get a token first by logging in
$login_data = array(
    "email" => "admin@yourcompany.com", // Replace with actual email
    "password" => "password123" // Replace with actual password
);

$login_response = file_get_contents('http://localhost/crm/backend/api/login.php', false, stream_context_create(array(
    'http' => array(
        'method' => 'POST',
        'header' => 'Content-Type: application/json',
        'content' => json_encode($login_data)
    )
)));

echo "Login Response:\n";
echo $login_response . "\n\n";

$login_result = json_decode($login_response, true);
if (isset($login_result['token'])) {
    $token = $login_result['token'];
    echo "Token: $token\n\n";
    
    // Now test the quotes endpoint
    $quotes_response = file_get_contents('http://localhost/crm/backend/api/quotes.php', false, stream_context_create(array(
        'http' => array(
            'method' => 'GET',
            'header' => 'Authorization: Bearer ' . $token
        )
    )));
    
    echo "Quotes Response:\n";
    echo $quotes_response . "\n";
} else {
    echo "Login failed\n";
}
?>
