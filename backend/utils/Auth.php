<?php
require_once '../vendor/autoload.php';
use Firebase\JWT\JWT;
use Firebase\JWT\Key;

class Auth {
    private static $secret_key = "your-secret-key-change-this-in-production";
    private static $issuer_claim = "crm-app";
    private static $audience_claim = "crm-users";
    private static $issuer_at = null;
    private static $not_before_claim = null;
    private static $expire_claim = null;

    public static function generateToken($user_data) {
        self::$issuer_at = time();
        self::$not_before_claim = self::$issuer_at + 10;
        self::$expire_claim = self::$issuer_at + 3600; // 1 hour

        $token = array(
            "iss" => self::$issuer_claim,
            "aud" => self::$audience_claim,
            "iat" => self::$issuer_at,
            "nbf" => self::$not_before_claim,
            "exp" => self::$expire_claim,
            "data" => array(
                "id" => $user_data['id'],
                "company_id" => $user_data['company_id'],
                "email" => $user_data['email'],
                "first_name" => $user_data['first_name'],
                "last_name" => $user_data['last_name'],
                "role" => $user_data['role']
            )
        );

        return JWT::encode($token, self::$secret_key, 'HS256');
    }

    public static function validateToken($token) {
        try {
            $decoded = JWT::decode($token, new Key(self::$secret_key, 'HS256'));
            return $decoded->data;
        } catch (Exception $e) {
            return false;
        }
    }

    public static function getBearerToken() {
        $headers = getallheaders();
        if (isset($headers['Authorization'])) {
            if (preg_match('/Bearer\s(\S+)/', $headers['Authorization'], $matches)) {
                return $matches[1];
            }
        }
        return null;
    }

    public static function requireAuth() {
        $token = self::getBearerToken();
        if (!$token) {
            http_response_code(401);
            echo json_encode(array("message" => "Access denied. Token not provided."));
            exit();
        }

        $user_data = self::validateToken($token);
        if (!$user_data) {
            http_response_code(401);
            echo json_encode(array("message" => "Access denied. Invalid token."));
            exit();
        }

        return $user_data;
    }
}
?>
