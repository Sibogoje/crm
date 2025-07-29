<?php
require_once '../config/database.php';
require_once '../utils/SimpleAuth.php';
require_once '../classes/Receipt.php';

// Test connection
try {
    $database = new Database();
    $db = $database->getConnection();
    echo "Database connection: OK\n";
} catch (Exception $e) {
    echo "Database connection failed: " . $e->getMessage() . "\n";
    exit(1);
}

// Test Receipt class
try {
    $receipt = new Receipt($db);
    echo "Receipt class: OK\n";
} catch (Exception $e) {
    echo "Receipt class failed: " . $e->getMessage() . "\n";
    exit(1);
}

// Test if receipts table exists
try {
    $stmt = $db->prepare("SELECT COUNT(*) as count FROM receipts");
    $stmt->execute();
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    echo "Receipts table: OK (contains " . $result['count'] . " records)\n";
} catch (Exception $e) {
    echo "Receipts table check failed: " . $e->getMessage() . "\n";
    
    // Try to show table structure
    try {
        $stmt = $db->prepare("DESCRIBE receipts");
        $stmt->execute();
        $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo "Table structure:\n";
        foreach ($columns as $column) {
            echo "  " . $column['Field'] . " (" . $column['Type'] . ")\n";
        }
    } catch (Exception $e2) {
        echo "Could not describe table: " . $e2->getMessage() . "\n";
    }
}

// Test if invoices table exists (for foreign key reference)
try {
    $stmt = $db->prepare("SELECT COUNT(*) as count FROM invoices");
    $stmt->execute();
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    echo "Invoices table: OK (contains " . $result['count'] . " records)\n";
} catch (Exception $e) {
    echo "Invoices table check failed: " . $e->getMessage() . "\n";
}

echo "\nReceipts system test completed!\n";
?>
