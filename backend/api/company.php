<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config/database.php';
require_once '../utils/SimpleAuth.php';

try {
    $userObj = SimpleAuth::requireAuth();
    $user = (array) $userObj; // Convert object to array for compatibility

    $database = new Database();
    $db = $database->getConnection();

    $method = $_SERVER['REQUEST_METHOD'];

    if ($method === 'GET') {
        // Get company information
        $getCompanyQuery = "SELECT * FROM companies WHERE id = ?";
        $getCompanyStmt = $db->prepare($getCompanyQuery);
        $getCompanyStmt->bindParam(1, $user['company_id'], PDO::PARAM_INT);
        $getCompanyStmt->execute();
        $companyData = $getCompanyStmt->fetch(PDO::FETCH_ASSOC);

        if ($companyData) {
            echo json_encode([
                'success' => true,
                'data' => [
                    'name' => $companyData['name'] ?? '',
                    'address' => $companyData['address'] ?? '',
                    'phone' => $companyData['phone'] ?? '',
                    'email' => $companyData['email'] ?? '',
                    'website' => $companyData['website'] ?? '',
                    'tax_number' => $companyData['tax_id'] ?? ''
                ]
            ]);
        } else {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'Company not found']);
        }

    } else if ($method === 'PUT') {
        // Update company information
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!$data) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Invalid JSON data']);
            exit();
        }

        $name = $data['name'] ?? '';
        $address = $data['address'] ?? '';
        $phone = $data['phone'] ?? '';
        $email = $data['email'] ?? '';
        $website = $data['website'] ?? '';
        $taxNumber = $data['tax_number'] ?? '';

        // Validate required fields
        if (empty($name)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Company name is required']);
            exit();
        }

        // Update company information
        $updateQuery = "UPDATE companies SET name = ?, address = ?, phone = ?, email = ?, website = ?, tax_id = ?, updated_at = NOW() WHERE id = ?";
        $updateStmt = $db->prepare($updateQuery);
        $updateStmt->bindParam(1, $name, PDO::PARAM_STR);
        $updateStmt->bindParam(2, $address, PDO::PARAM_STR);
        $updateStmt->bindParam(3, $phone, PDO::PARAM_STR);
        $updateStmt->bindParam(4, $email, PDO::PARAM_STR);
        $updateStmt->bindParam(5, $website, PDO::PARAM_STR);
        $updateStmt->bindParam(6, $taxNumber, PDO::PARAM_STR);
        $updateStmt->bindParam(7, $user['company_id'], PDO::PARAM_INT);

        if ($updateStmt->execute()) {
            echo json_encode([
                'success' => true,
                'message' => 'Company information updated successfully'
            ]);
        } else {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Failed to update company information']);
        }

    } else {
        http_response_code(405);
        echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    }

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}
?>
