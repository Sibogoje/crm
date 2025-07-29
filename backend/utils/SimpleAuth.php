<?php
class SimpleAuth {
    private static $secret_key = "your-secret-key-change-this-in-production-make-it-long-and-random";
    
    public static function generateToken($user_data) {
        $header = json_encode(['typ' => 'JWT', 'alg' => 'HS256']);
        $payload = json_encode([
            'iss' => 'crm-app',
            'aud' => 'crm-users',
            'iat' => time(),
            'exp' => time() + 3600, // 1 hour
            'data' => $user_data
        ]);
        
        $headerEncoded = self::base64UrlEncode($header);
        $payloadEncoded = self::base64UrlEncode($payload);
        
        $signature = hash_hmac('sha256', $headerEncoded . "." . $payloadEncoded, self::$secret_key, true);
        $signatureEncoded = self::base64UrlEncode($signature);
        
        return $headerEncoded . "." . $payloadEncoded . "." . $signatureEncoded;
    }
    
    public static function validateToken($token) {
        $parts = explode('.', $token);
        if (count($parts) !== 3) {
            return false;
        }
        
        $header = $parts[0];
        $payload = $parts[1];
        $signature = $parts[2];
        
        $expectedSignature = hash_hmac('sha256', $header . "." . $payload, self::$secret_key, true);
        $expectedSignatureEncoded = self::base64UrlEncode($expectedSignature);
        
        if (!hash_equals($signature, $expectedSignatureEncoded)) {
            return false;
        }
        
        $payloadData = json_decode(self::base64UrlDecode($payload), true);
        
        if (!$payloadData || !isset($payloadData['exp']) || $payloadData['exp'] < time()) {
            return false;
        }
        
        return $payloadData['data'];
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
        
        return (object) $user_data;
    }
    
    private static function base64UrlEncode($data) {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }
    
    private static function base64UrlDecode($data) {
        return base64_decode(str_pad(strtr($data, '-_', '+/'), strlen($data) % 4, '=', STR_PAD_RIGHT));
    }
}
?>
