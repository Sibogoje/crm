<?php
require_once '../config/database.php';
require_once '../classes/Receipt.php';
require_once '../utils/SimpleAuth.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    $database = new Database();
    $db = $database->getConnection();
    $receipt = new Receipt($db);

    // Get the Authorization header
    $headers = getallheaders();
    $authHeader = $headers['Authorization'] ?? '';
    
    if (empty($authHeader) || !str_starts_with($authHeader, 'Bearer ')) {
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'message' => 'Authorization token required'
        ]);
        exit();
    }
    
    $token = substr($authHeader, 7); // Remove 'Bearer ' prefix
    $user = SimpleAuth::validateToken($token);
    
    if (!$user) {
        http_response_code(401);
        echo json_encode([
            'success' => false,
            'message' => 'Invalid or expired token'
        ]);
        exit();
    }

    $method = $_SERVER['REQUEST_METHOD'];
    $path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
    $path_parts = explode('/', $path);
    $receipt_id = end($path_parts);
    
    // Also check for id in query parameters (for DELETE requests with ?id=123)
    if (!is_numeric($receipt_id) && isset($_GET['id'])) {
        $receipt_id = $_GET['id'];
    }

    switch ($method) {
        case 'GET':
            if (is_numeric($receipt_id)) {
                // Get single receipt
                $result = $receipt->getById($receipt_id, $user['company_id']);
                if ($result) {
                    echo json_encode([
                        'success' => true,
                        'data' => $result
                    ]);
                } else {
                    http_response_code(404);
                    echo json_encode([
                        'success' => false,
                        'message' => 'Receipt not found'
                    ]);
                }
            } elseif (isset($_GET['invoice_id'])) {
                // Get receipts by invoice ID
                $invoice_id = $_GET['invoice_id'];
                if (!$invoice_id) {
                    http_response_code(400);
                    echo json_encode([
                        'success' => false,
                        'message' => 'Invoice ID is required'
                    ]);
                    break;
                }
                $receipts = $receipt->getByInvoiceId($invoice_id, $user['company_id']);
                echo json_encode([
                    'success' => true,
                    'data' => $receipts
                ]);
            } else {
                // Get all receipts for the company
                $receipts = $receipt->getAll($user['company_id']);
                echo json_encode([
                    'success' => true,
                    'data' => $receipts
                ]);
            }
            break;

        case 'POST':
            $input = json_decode(file_get_contents('php://input'), true);
            
            // Validate required fields
            $required_fields = ['invoice_id', 'amount', 'payment_method'];
            foreach ($required_fields as $field) {
                if (!isset($input[$field])) {
                    http_response_code(400);
                    echo json_encode([
                        'success' => false,
                        'message' => "Missing required field: $field"
                    ]);
                    exit();
                }
            }
            
            $input['company_id'] = $user['company_id'];
            $new_receipt = $receipt->create($input);
            
            if ($new_receipt) {
                http_response_code(201);
                echo json_encode([
                    'success' => true,
                    'data' => $new_receipt
                ]);
            } else {
                http_response_code(400);
                echo json_encode([
                    'success' => false,
                    'message' => 'Failed to create receipt'
                ]);
            }
            break;

        case 'PUT':
            if (!is_numeric($receipt_id)) {
                http_response_code(400);
                echo json_encode([
                    'success' => false,
                    'message' => 'Invalid receipt ID'
                ]);
                break;
            }

            $input = json_decode(file_get_contents('php://input'), true);
            $input['company_id'] = $user['company_id'];
            
            $updated_receipt = $receipt->update($receipt_id, $input);
            if ($updated_receipt) {
                echo json_encode([
                    'success' => true,
                    'data' => $updated_receipt
                ]);
            } else {
                http_response_code(400);
                echo json_encode([
                    'success' => false,
                    'message' => 'Failed to update receipt'
                ]);
            }
            break;

        case 'DELETE':
            if (!is_numeric($receipt_id)) {
                http_response_code(400);
                echo json_encode([
                    'success' => false,
                    'message' => 'Invalid receipt ID'
                ]);
                break;
            }

            if ($receipt->delete($receipt_id, $user['company_id'])) {
                echo json_encode([
                    'success' => true,
                    'message' => 'Receipt deleted successfully'
                ]);
            } else {
                http_response_code(400);
                echo json_encode([
                    'success' => false,
                    'message' => 'Failed to delete receipt'
                ]);
            }
            break;

        default:
            http_response_code(405);
            echo json_encode([
                'success' => false,
                'message' => 'Method not allowed'
            ]);
            break;
    }

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Server error: ' . $e->getMessage()
    ]);
}
?>
