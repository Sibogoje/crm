<?php
require_once '../config/database.php';
require_once '../classes/Invoice.php';
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
    $invoice = new Invoice($db);

    // Get the Authorization header
    $headers = getallheaders();
    $authHeader = $headers['Authorization'] ?? '';
    
    if (empty($authHeader) || !str_starts_with($authHeader, 'Bearer ')) {
        http_response_code(401);
        echo json_encode(['error' => 'Authorization token required']);
        exit();
    }
    
    $token = substr($authHeader, 7); // Remove 'Bearer ' prefix
    $user = SimpleAuth::validateToken($token);
    
    if (!$user) {
        http_response_code(401);
        echo json_encode(['error' => 'Invalid or expired token']);
        exit();
    }

    $method = $_SERVER['REQUEST_METHOD'];
    $path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
    $path_parts = explode('/', $path);
    $invoice_id = end($path_parts);

    switch ($method) {
        case 'GET':
            if (is_numeric($invoice_id)) {
                // Get single invoice
                $result = $invoice->getById($invoice_id, $user['company_id']);
                if ($result) {
                    echo json_encode($result);
                } else {
                    http_response_code(404);
                    echo json_encode(['error' => 'Invoice not found']);
                }
            } else {
                // Get all invoices for the company
                $invoices = $invoice->getAll($user['company_id']);
                echo json_encode($invoices);
            }
            break;

        case 'POST':
            if ($invoice_id === 'convert-quote') {
                // Convert quote to invoice
                $input = json_decode(file_get_contents('php://input'), true);
                $quote_id = $input['quote_id'] ?? null;
                
                if (!$quote_id) {
                    http_response_code(400);
                    echo json_encode(['error' => 'Quote ID is required']);
                    break;
                }
                
                $new_invoice = $invoice->createFromQuote($quote_id, $user['company_id']);
                if ($new_invoice) {
                    http_response_code(201);
                    echo json_encode($new_invoice);
                } else {
                    http_response_code(400);
                    echo json_encode(['error' => 'Failed to create invoice from quote']);
                }
            } else {
                // Create new invoice
                $input = json_decode(file_get_contents('php://input'), true);
                
                // Validate required fields
                $required_fields = ['client_id', 'invoice_date', 'subtotal', 'tax_amount', 'total_amount', 'items'];
                foreach ($required_fields as $field) {
                    if (!isset($input[$field])) {
                        http_response_code(400);
                        echo json_encode(['error' => "Missing required field: $field"]);
                        exit();
                    }
                }
                
                $input['company_id'] = $user['company_id'];
                $new_invoice = $invoice->create($input);
                
                if ($new_invoice) {
                    http_response_code(201);
                    echo json_encode($new_invoice);
                } else {
                    http_response_code(400);
                    echo json_encode(['error' => 'Failed to create invoice']);
                }
            }
            break;

        case 'PUT':
            if (!is_numeric($invoice_id)) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid invoice ID']);
                break;
            }

            $input = json_decode(file_get_contents('php://input'), true);
            $input['company_id'] = $user['company_id'];
            
            $updated_invoice = $invoice->update($invoice_id, $input);
            if ($updated_invoice) {
                echo json_encode($updated_invoice);
            } else {
                http_response_code(400);
                echo json_encode(['error' => 'Failed to update invoice']);
            }
            break;

        case 'DELETE':
            if (!is_numeric($invoice_id)) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid invoice ID']);
                break;
            }

            if ($invoice->delete($invoice_id, $user['company_id'])) {
                echo json_encode(['message' => 'Invoice deleted successfully']);
            } else {
                http_response_code(400);
                echo json_encode(['error' => 'Failed to delete invoice']);
            }
            break;

        default:
            http_response_code(405);
            echo json_encode(['error' => 'Method not allowed']);
            break;
    }

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Server error: ' . $e->getMessage()]);
}
?>
