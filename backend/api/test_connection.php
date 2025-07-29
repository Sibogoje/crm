<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

include_once '../config/database.php';

$database = new Database();
$db = $database->getConnection();

if ($db) {
    echo json_encode([
        'status' => 'success',
        'message' => 'Database connection successful!'
    ]);
} else {
    echo json_encode([
        'status' => 'error',
        'message' => 'Database connection failed!'
    ]);
}
?>
