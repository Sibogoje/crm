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

    if ($method === 'PUT') {
        // Update user profile
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!$data) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Invalid JSON data']);
            exit();
        }

        $firstName = $data['first_name'] ?? '';
        $lastName = $data['last_name'] ?? '';
        $email = $data['email'] ?? '';
        $phone = $data['phone'] ?? '';

        // Validate required fields
        if (empty($firstName) || empty($lastName) || empty($email)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'First name, last name, and email are required']);
            exit();
        }

        // Check if email is already taken by another user
        $emailCheckQuery = "SELECT id FROM users WHERE email = ? AND id != ?";
        $emailCheckStmt = $db->prepare($emailCheckQuery);
        $emailCheckStmt->bindParam(1, $email, PDO::PARAM_STR);
        $emailCheckStmt->bindParam(2, $user['id'], PDO::PARAM_INT);
        $emailCheckStmt->execute();
        $emailResult = $emailCheckStmt->fetchAll(PDO::FETCH_ASSOC);

        if (count($emailResult) > 0) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Email is already taken']);
            exit();
        }

        // Update user profile
        $updateQuery = "UPDATE users SET first_name = ?, last_name = ?, email = ?, phone = ?, updated_at = NOW() WHERE id = ?";
        $updateStmt = $db->prepare($updateQuery);
        $updateStmt->bindParam(1, $firstName, PDO::PARAM_STR);
        $updateStmt->bindParam(2, $lastName, PDO::PARAM_STR);
        $updateStmt->bindParam(3, $email, PDO::PARAM_STR);
        $updateStmt->bindParam(4, $phone, PDO::PARAM_STR);
        $updateStmt->bindParam(5, $user['id'], PDO::PARAM_INT);

        if ($updateStmt->execute()) {
            // Get updated user data
            $getUserQuery = "SELECT id, first_name, last_name, email, phone, company_id, created_at FROM users WHERE id = ?";
            $getUserStmt = $db->prepare($getUserQuery);
            $getUserStmt->bindParam(1, $user['id'], PDO::PARAM_INT);
            $getUserStmt->execute();
            $updatedUser = $getUserStmt->fetch(PDO::FETCH_ASSOC);

            echo json_encode([
                'success' => true,
                'message' => 'Profile updated successfully',
                'user' => $updatedUser
            ]);
        } else {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Failed to update profile']);
        }

    } else if ($method === 'GET') {
        // Get user profile
        $getUserQuery = "SELECT id, first_name, last_name, email, phone, company_id, created_at FROM users WHERE id = ?";
        $getUserStmt = $db->prepare($getUserQuery);
        $getUserStmt->bindParam(1, $user['id'], PDO::PARAM_INT);
        $getUserStmt->execute();
        $userData = $getUserStmt->fetch(PDO::FETCH_ASSOC);

        if ($userData) {
            echo json_encode([
                'success' => true,
                'data' => $userData
            ]);
        } else {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'User not found']);
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
