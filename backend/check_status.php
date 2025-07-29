<?php
require_once 'config/database.php';
$db = new Database();
$conn = $db->getConnection();

// Check if receipts table exists
$stmt = $conn->prepare('SHOW TABLES LIKE "receipts"');
$stmt->execute();

if ($stmt->rowCount() > 0) {
    echo "RECEIPTS table exists!\n\n";
    
    $stmt = $conn->prepare('DESCRIBE receipts');
    $stmt->execute();
    echo "RECEIPTS table structure:\n";
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        echo "- {$row['Field']} ({$row['Type']}) {$row['Null']} {$row['Key']} {$row['Default']}\n";
    }
} else {
    echo "RECEIPTS table does not exist!\n";
    echo "Let's create it...\n";
}
?>
