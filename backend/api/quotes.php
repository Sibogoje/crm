<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config/database.php';
require_once '../utils/SimpleAuth.php';
require_once '../classes/Quote.php';

try {
    // Get database connection
    $database = new Database();
    $db = $database->getConnection();
    
    // Initialize quote object
    $quote = new Quote($db);
    
    // Get JWT token from headers
    $headers = getallheaders();
    $jwt = null;

    if (isset($headers['Authorization'])) {
        $jwt = str_replace('Bearer ', '', $headers['Authorization']);
    }

    if (!$jwt) {
        http_response_code(401);
        echo json_encode(array("message" => "Access denied. No token provided."));
        exit;
    }

    $decoded = SimpleAuth::validateToken($jwt);
    if (!$decoded) {
        http_response_code(401);
        echo json_encode(array("message" => "Access denied. Invalid token."));
        exit;
    }
    
    $companyId = $decoded['company_id'];
    $userId = $decoded['id'];
    
    error_log("Quotes API - Company ID: $companyId, User ID: $userId, Method: " . $_SERVER['REQUEST_METHOD']);
    
    // Handle different HTTP methods
    switch ($_SERVER['REQUEST_METHOD']) {
        case 'GET':
            if (isset($_GET['id'])) {
                // Get specific quote
                $quoteId = $_GET['id'];
                $result = $quote->getById($quoteId, $companyId);
                
                if ($result) {
                    // Get quote items
                    $items = $quote->getQuoteItems($quoteId);
                    $result['items'] = $items;
                    
                    echo json_encode([
                        'status' => 'success',
                        'data' => $result
                    ]);
                } else {
                    echo json_encode([
                        'status' => 'error',
                        'message' => 'Quote not found'
                    ]);
                }
            } else {
                // Get all quotes
                $quotes = $quote->getAll($companyId);
                
                // Get items for each quote
                foreach ($quotes as &$q) {
                    $q['items'] = $quote->getQuoteItems($q['id']);
                }
                
                echo json_encode([
                    'status' => 'success',
                    'data' => $quotes
                ]);
            }
            break;
            
        case 'POST':
            // Create new quote
            $input = json_decode(file_get_contents('php://input'), true);
            
            if (!$input) {
                throw new Exception('Invalid JSON data');
            }
            
            // Generate quote number if not provided
            if (!isset($input['quote_number']) || empty($input['quote_number'])) {
                $input['quote_number'] = $quote->generateQuoteNumber($companyId);
            }
            
            $result = $quote->create($input, $companyId);
            
            if ($result) {
                echo json_encode([
                    'status' => 'success',
                    'data' => $result,
                    'message' => 'Quote created successfully'
                ]);
            } else {
                throw new Exception('Failed to create quote');
            }
            break;
            
        case 'PUT':
            // Update quote
            if (!isset($_GET['id'])) {
                throw new Exception('Quote ID is required for update');
            }
            
            $quoteId = $_GET['id'];
            $input = json_decode(file_get_contents('php://input'), true);
            
            if (!$input) {
                throw new Exception('Invalid JSON data');
            }
            
            $result = $quote->update($quoteId, $input, $companyId);
            
            if ($result) {
                echo json_encode([
                    'status' => 'success',
                    'data' => $result,
                    'message' => 'Quote updated successfully'
                ]);
            } else {
                throw new Exception('Failed to update quote');
            }
            break;
            
        case 'DELETE':
            // Delete quote
            if (!isset($_GET['id'])) {
                throw new Exception('Quote ID is required for deletion');
            }
            
            $quoteId = $_GET['id'];
            $result = $quote->delete($quoteId, $companyId);
            
            if ($result) {
                echo json_encode([
                    'status' => 'success',
                    'message' => 'Quote deleted successfully'
                ]);
            } else {
                throw new Exception('Failed to delete quote');
            }
            break;
            
        default:
            throw new Exception('Method not allowed');
    }
    
} catch (Exception $e) {
    error_log("Quotes API Error: " . $e->getMessage());
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage()
    ]);
}
?>
