<?php
require_once 'config/database.php';

try {
    $database = new Database();
    $db = $database->getConnection();
    
    echo "Connected to database successfully!\n\n";
    
    // Check if invoices table exists and get its structure
    $query = "DESCRIBE invoices";
    $stmt = $db->prepare($query);
    $stmt->execute();
    
    echo "INVOICES table structure:\n";
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        echo "- {$row['Field']} ({$row['Type']}) {$row['Null']} {$row['Key']} {$row['Default']}\n";
    }
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
?>
