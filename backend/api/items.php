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
include_once '../classes/Item.php';
include_once '../utils/SimpleAuth.php';

$database = new Database();
$db = $database->getConnection();

$item = new Item($db);

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

try {
    $decoded = SimpleAuth::validateToken($jwt);
    $user_id = $decoded['id'];
    $company_id = $decoded['company_id'];
} catch (Exception $e) {
    http_response_code(401);
    echo json_encode(array("message" => "Access denied. Invalid token."));
    exit;
}

$method = $_SERVER['REQUEST_METHOD'];

switch($method) {
    case 'GET':
        if (isset($_GET['id'])) {
            // Get single item
            $item->id = $_GET['id'];
            $item->company_id = $company_id;
            
            if ($item->readOne()) {
                echo json_encode(array(
                    "status" => "success",
                    "data" => array(
                        "id" => $item->id,
                        "company_id" => $item->company_id,
                        "name" => $item->name,
                        "description" => $item->description,
                        "price" => $item->price,
                        "category" => $item->category,
                        "is_service" => $item->is_service,
                        "created_at" => $item->created_at,
                        "updated_at" => $item->updated_at
                    )
                ));
            } else {
                http_response_code(404);
                echo json_encode(array("status" => "error", "message" => "Item not found."));
            }
        } else {
            // Get all items for the company
            $stmt = $item->read($company_id);
            $num = $stmt->rowCount();
            
            if ($num > 0) {
                $items_arr = array();
                
                while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                    extract($row);
                    $item_item = array(
                        "id" => $id,
                        "company_id" => $company_id,
                        "name" => $name,
                        "description" => $description,
                        "price" => floatval($price),
                        "category" => $category,
                        "is_service" => boolval($is_service),
                        "created_at" => $created_at,
                        "updated_at" => $updated_at
                    );
                    array_push($items_arr, $item_item);
                }
                
                echo json_encode(array("status" => "success", "data" => $items_arr));
            } else {
                echo json_encode(array("status" => "success", "data" => array()));
            }
        }
        break;
        
    case 'POST':
        $data = json_decode(file_get_contents("php://input"));
        
        if (!empty($data->name) && !empty($data->price)) {
            $item->company_id = $company_id;
            $item->name = $data->name;
            $item->description = $data->description ?? '';
            $item->price = $data->price;
            $item->category = $data->category ?? '';
            $item->is_service = $data->is_service ?? false;
            
            if ($item->create()) {
                http_response_code(201);
                echo json_encode(array(
                    "status" => "success",
                    "message" => "Item was created.",
                    "data" => array("id" => $item->id)
                ));
            } else {
                http_response_code(503);
                echo json_encode(array("status" => "error", "message" => "Unable to create item."));
            }
        } else {
            http_response_code(400);
            echo json_encode(array("status" => "error", "message" => "Unable to create item. Data is incomplete."));
        }
        break;
        
    case 'PUT':
        $data = json_decode(file_get_contents("php://input"));
        
        if (!empty($data->id) && !empty($data->name) && !empty($data->price)) {
            $item->id = $data->id;
            $item->company_id = $company_id;
            $item->name = $data->name;
            $item->description = $data->description ?? '';
            $item->price = $data->price;
            $item->category = $data->category ?? '';
            $item->is_service = $data->is_service ?? false;
            
            if ($item->update()) {
                http_response_code(200);
                echo json_encode(array("status" => "success", "message" => "Item was updated."));
            } else {
                http_response_code(503);
                echo json_encode(array("status" => "error", "message" => "Unable to update item."));
            }
        } else {
            http_response_code(400);
            echo json_encode(array("status" => "error", "message" => "Unable to update item. Data is incomplete."));
        }
        break;
        
    case 'DELETE':
        $data = json_decode(file_get_contents("php://input"));
        
        if (!empty($data->id)) {
            $item->id = $data->id;
            $item->company_id = $company_id;
            
            if ($item->delete()) {
                http_response_code(200);
                echo json_encode(array("status" => "success", "message" => "Item was deleted."));
            } else {
                http_response_code(503);
                echo json_encode(array("status" => "error", "message" => "Unable to delete item."));
            }
        } else {
            http_response_code(400);
            echo json_encode(array("status" => "error", "message" => "Unable to delete item. Data is incomplete."));
        }
        break;
        
    default:
        http_response_code(405);
        echo json_encode(array("status" => "error", "message" => "Method not allowed."));
        break;
}
?>
