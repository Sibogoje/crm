<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

include_once '../config/database.php';
include_once '../classes/User.php';
include_once '../classes/Company.php';
include_once '../utils/SimpleAuth.php';

$database = new Database();
$db = $database->getConnection();

$user = new User($db);
$company = new Company($db);

$data = json_decode(file_get_contents("php://input"));

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    if (!empty($data->email) && !empty($data->password) && 
        !empty($data->first_name) && !empty($data->last_name) &&
        !empty($data->company_name) && !empty($data->company_email) &&
        !empty($data->company_phone) && !empty($data->company_address) &&
        !empty($data->company_tax_id)) {

        // Check if user already exists
        $user->email = $data->email;
        if ($user->emailExists()) {
            http_response_code(400);
            echo json_encode(array("message" => "User already exists."));
            exit;
        }

        // Create company first
        $company->name = $data->company_name;
        $company->email = $data->company_email;
        $company->phone = $data->company_phone;
        $company->address = $data->company_address;
        $company->tax_id = $data->company_tax_id;
        $company->logo_path = null;
        $company->currency = $data->currency ?? 'USD';
        $company->default_tax_rate = $data->default_tax_rate ?? 0.00;
        $company->invoice_prefix = $data->invoice_prefix ?? 'INV';

        if ($company->create()) {
            // Create user with the company_id from the created company
            $user->company_id = $company->id;
            $user->email = $data->email;
            $user->password_hash = password_hash($data->password, PASSWORD_BCRYPT);
            $user->first_name = $data->first_name;
            $user->last_name = $data->last_name;
            $user->role = 'admin';

            if ($user->create()) {
                $token = SimpleAuth::generateToken(array(
                    'id' => $user->id,
                    'company_id' => $company->id,
                    'email' => $data->email,
                    'first_name' => $data->first_name,
                    'last_name' => $data->last_name,
                    'phone' => isset($data->phone) ? $data->phone : null,
                    'role' => 'admin'
                ));

                http_response_code(201);
                echo json_encode(array(
                    "message" => "User was created.",
                    "token" => $token,
                    "user" => array(
                        "id" => $user->id,
                        "company_id" => $company->id,
                        "email" => $data->email,
                        "first_name" => $data->first_name,
                        "last_name" => $data->last_name,
                        "phone" => isset($data->phone) ? $data->phone : null,
                        "role" => 'admin'
                    )
                ));
            } else {
                http_response_code(503);
                echo json_encode(array("message" => "Unable to create user."));
            }
        } else {
            http_response_code(503);
            echo json_encode(array("message" => "Unable to create company."));
        }
    } else {
        http_response_code(400);
        echo json_encode(array("message" => "Unable to create user. Data is incomplete."));
    }
} else {
    http_response_code(405);
    echo json_encode(array("message" => "Method not allowed."));
}
?>
