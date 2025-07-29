<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

include_once '../config/database.php';
include_once '../classes/Client.php';
include_once '../utils/SimpleAuth.php';

$database = new Database();
$db = $database->getConnection();

$client = new Client($db);

// Get authenticated user data
$user_data = SimpleAuth::requireAuth();

switch ($_SERVER['REQUEST_METHOD']) {
    case 'GET':
        if (isset($_GET['id'])) {
            // Get single client
            $client->id = $_GET['id'];
            $client->company_id = $user_data->company_id;
            $client->readOne();

            if ($client->name != null) {
                $client_arr = array(
                    "id" => $client->id,
                    "name" => $client->name,
                    "email" => $client->email,
                    "phone" => $client->phone,
                    "address" => $client->address,
                    "tax_id" => $client->tax_id,
                    "client_company" => $client->client_company,
                    "created_at" => $client->created_at,
                    "updated_at" => $client->updated_at
                );

                http_response_code(200);
                echo json_encode($client_arr);
            } else {
                http_response_code(404);
                echo json_encode(array("message" => "Client not found."));
            }
        } else {
            // Get all clients
            $stmt = $client->readAll($user_data->company_id);
            $num = $stmt->rowCount();

            if ($num > 0) {
                $clients_arr = array();
                $clients_arr["records"] = array();

                while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                    extract($row);
                    $client_item = array(
                        "id" => $id,
                        "name" => $name,
                        "email" => $email,
                        "phone" => $phone,
                        "address" => $address,
                        "tax_id" => $tax_id,
                        "client_company" => $client_company,
                        "created_at" => $created_at,
                        "updated_at" => $updated_at
                    );
                    array_push($clients_arr["records"], $client_item);
                }

                http_response_code(200);
                echo json_encode($clients_arr);
            } else {
                http_response_code(200);
                echo json_encode(array("records" => array()));
            }
        }
        break;

    case 'POST':
        $data = json_decode(file_get_contents("php://input"));

        if (!empty($data->name) && !empty($data->email) && 
            !empty($data->phone) && !empty($data->address)) {

            $client->id = uniqid('client_', true);
            $client->company_id = $user_data->company_id;
            $client->name = $data->name;
            $client->email = $data->email;
            $client->phone = $data->phone;
            $client->address = $data->address;
            $client->tax_id = $data->tax_id ?? null;
            $client->client_company = $data->client_company ?? null;

            if ($client->create()) {
                http_response_code(201);
                echo json_encode(array(
                    "message" => "Client created successfully.",
                    "id" => $client->id
                ));
            } else {
                http_response_code(503);
                echo json_encode(array("message" => "Unable to create client."));
            }
        } else {
            http_response_code(400);
            echo json_encode(array("message" => "Unable to create client. Data is incomplete."));
        }
        break;

    case 'PUT':
        $data = json_decode(file_get_contents("php://input"));

        if (!empty($data->id) && !empty($data->name) && !empty($data->email) && 
            !empty($data->phone) && !empty($data->address)) {

            $client->id = $data->id;
            $client->company_id = $user_data->company_id;
            $client->name = $data->name;
            $client->email = $data->email;
            $client->phone = $data->phone;
            $client->address = $data->address;
            $client->tax_id = $data->tax_id ?? null;
            $client->client_company = $data->client_company ?? null;

            if ($client->update()) {
                http_response_code(200);
                echo json_encode(array("message" => "Client updated successfully."));
            } else {
                http_response_code(503);
                echo json_encode(array("message" => "Unable to update client."));
            }
        } else {
            http_response_code(400);
            echo json_encode(array("message" => "Unable to update client. Data is incomplete."));
        }
        break;

    case 'DELETE':
        $data = json_decode(file_get_contents("php://input"));

        if (!empty($data->id)) {
            $client->id = $data->id;
            $client->company_id = $user_data->company_id;

            if ($client->delete()) {
                http_response_code(200);
                echo json_encode(array("message" => "Client deleted successfully."));
            } else {
                http_response_code(503);
                echo json_encode(array("message" => "Unable to delete client."));
            }
        } else {
            http_response_code(400);
            echo json_encode(array("message" => "Unable to delete client. ID is required."));
        }
        break;

    default:
        http_response_code(405);
        echo json_encode(array("message" => "Method not allowed."));
        break;
}
?>
